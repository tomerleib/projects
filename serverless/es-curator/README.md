# ELK Curator

## What is Elasticsearch Curator?
From the official docs:
> Elasticsearch Curator helps you curate, or manage, your Elasticsearch indices and snapshots by:
> 1. Obtaining the full list of indices (or snapshots) from the cluster, as the actionable list
> 2. Iterate through a list of user-defined filters to progressively remove indices (or snapshots) from this actionable list as needed.
> 3. Perform various actions on the items which remain in the actionable list.

https://www.elastic.co/guide/en/elasticsearch/client/curator/current/about.html

## About Serverless Framework
https://serverless.com

Serverless goal is to build the entire platform around the code by using Cloudformation at it's core. So for example, you can specify your VPC, SG, KMS, IAM and triggers for your Lambda.

You will need to change the serverless.yml parameters to match the settings that match the environment of your choice.

## Secrets
For encryption of secrets with Serverless and KMS, I've used the plugin serverless-kms-secrets.
https://www.npmjs.com/package/serverless-kms-secrets

## Function
This is a python 2.7 function that helps simplify the processing of backup and data retention in Elasticsearch cluster.

The process (which ofcourse can be refactored as you wish) is doing the following actions:

1. Attempt to connect to the cluster
2. Check for the cluster health, if it is <span style="color:red"> **Red**</span>, an alert will be sent to a Slack channel and the code will abort.
3. Check for if the snapshots repository exist (I've encountered some issues where the repository settings removed after the Master nodes were replaced during spot termination), if the repository don't exist, the function will attempt to create it.
4. Perform a snapshot of the cluster and report to Slack on success.
5. Delete indices that are a month old (you can change it of you wish).

## Example usage
### Encrypt Secrets
* In your service root, run:

```bash
npm install --save-dev serverless-kms-secrets
```

* Add the plugin to `serverless.yml`:

```yml
plugins:
  - serverless-kms-secrets
```

* Configure the plugin into the custom block in `serverless.yml`. For example:

```yml
custom:
  serverless-kms-secrets:
    secretsFile: kms-secrets.${opt:stage, self:provider.stage}.${opt:region, self:provider.region}.yml (optional)
  kmsSecrets: ${file(kms-secrets.${opt:stage, self:provider.stage}.${opt:region, self:provider.region}.yml)}
```

* By default, the plugin creates secrets to the file kms-secrets.[stage].[region].yml. This can be overriden with the secretsFile parameter in the serverless-kms-secrets configuration.

Add Decrypt permissions to your lambda function with e.g. this block in IamRoleStatements:

```yml
    - Effect: Allow
      Action:
      - KMS:Decrypt
      Resource: ${self:custom.kmsSecrets.keyArn}
```
### Usage
#### Encrypting Variables
To encrypt a variable using the key defined in the configuration, enter
```
sls encrypt -n VARIABLE_NAME -v myvalue [-k keyId]
```

e.g.

```
sls encrypt -n SLACK_API_TOKEN -v xoxp-1234567890-1234567890-123467890-a12346 -k 999999-9999-99999-999
```
The keyid (-k) parameter is taken from the remaining part of the key ARN and is mandatory for the first encrypted variable, but optional for the later ones (will be read from the secrets file).
The encrypted variable is written to your secrets file (kms-secrets.[stage].[region].yml by default)

You may also pack multiple secrets into one KMS encrypted string. This simplifies consuming the secrets in the Lambda function since all secrets can be decrypted with one single KMS.Decrypt call. To encrypt multiple secrets into one single string, use the following notation:

```
sls encrypt -n VARIABLE_NAME:SECRET_NAME -v myvalue [-k keyId]
```

e.g.

```
sls encrypt -n SECRETS:SLACK_API_TOKEN -v xoxp-1234567890-1234567890-123467890-a12346 -k 999999-9999-99999-999
```

Would encrypt and add the SLACK_API_TOKEN into the (JSON) secret SECRETS.

NOTE: you may get warnings about the missing kms-secrets file when encrypting your first variables for a specific stage / region. The warning will go away once the file has been created by the plugin.

### Serverless deployment
Execute the following code to create the CFN stack
```bash
serverless deploy
```

If any changes were made to the code, you can execute the following to update only the function instead of the entire stack:

```bash
serverless deploy -f function_name
```
