from __future__ import print_function

import boto3
import json
import os
import datetime
import curator

from elasticsearch import Elasticsearch
from elasticsearch import exceptions
from slackclient import SlackClient
from pybase64 import b64decode


encrypted_elk_password = os.environ['kmsEncryptedPassword']
encrypted_slack_token = os.environ['kmsEncryptedToken']
slack_token = boto3.client('kms').decrypt(
    CiphertextBlob=b64decode(encrypted_slack_token))['Plaintext']
elk_password = boto3.client('kms').decrypt(
    CiphertextBlob=b64decode(encrypted_elk_password))['Plaintext']
es = Elasticsearch(
    ['es-cluster.local'],
    http_auth=('admin', elk_password),
    scheme="https",
    port=9020,
    timeout=60
)
repository_body = {
    "type": "s3",
    "settings": {
        "bucket": "elk-snapshots",
        "storage_class": "standard_ia"
    }
}
slack_channel = os.environ['slackChannel']
sc = SlackClient(slack_token)
time = datetime.datetime.now().strftime("%Y%m%d-%H:%M")
snapshot_name = "snapshot-" + time


def slackpost(color, msg):
    slack_attch = [{
        "title": "Elasticsearch Backup",
        "fallback": "",
        "color": color,
        "text": msg
    }]

    sc.api_call(
        "chat.postMessage",
        channel=slack_channel,
        attachments=json.dumps(slack_attch)
    )


def lambda_handler(event, context):
    """ Prior to running snapshots, we're checking if we can connect,
    and if for the current status of the cluster and the repository.
    """
    try:
        health = es.cat.health().split(" ")[3]
        repo = es.cat.repositories()
        if health == 'red':
            slackpost('danger', 'Cluster status is RED! Investigate ASAP!! ')
            exit
        if repo is None:
            slackpost(
                'warning',
                'Missing repository for snapshot.'
                'Trying to recreate the repository...')
            try:
                es.snapshot.create_repository(
                    repository='s3', body=repository_body)
                es.snapshot.get_repository('s3')
                slackpost('good', 'Successfully re-created the repository.')
            except exceptions.NotFoundError as e:
                slackpost(
                    'danger', 'Failed to create the repository. Please check!')
        # Create the snapshot
        ilo = curator.IndexList(es)
        create_snapshot = curator.Snapshot(ilo=ilo,
                                           repository='s3',
                                           name=snapshot_name)
        create_snapshot.do_action()
        create_snapshot_status = create_snapshot.get_state()

        if create_snapshot_status == 'SUCCESS':
            msg = "Successfully created new snapshot:\n" + snapshot_name
            color = 'good'
            slackpost(color, msg)
        else:
            msg = "Failed to create new snapshot"
            color = 'danger'
            slackpost(color, msg)

        # Deleting old indices
        ilo.filter_by_age(source='creation_date', direction='older',
                          unit='months', unit_count=1)
        curator.DeleteIndices(ilo)
    except exceptions.ConnectionError as e:
        slackpost('danger', e)
