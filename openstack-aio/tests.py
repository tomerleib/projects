import keystoneauth1.exceptions as ks_exceptions
from keystoneauth1 import session, loading
from keystoneclient import client as ksclient

# Importing the URL and the password for authentication

with open('/root/openrc', 'rt') as in_file:
    line = in_file.readline()
    while line:
        if line.find("OS_AUTH_URL") > -1:
            url = line.split("=")[1].split("//")[1].split("/")[0]
        if line.find("OS_PASSWORD") > -1:
            p = line.split("=")[1].split("'")[1]
        line = in_file.readline()

new_url = 'http://' + url
loader = loading.get_plugin_loader('password')
auth = loader.load_from_options(auth_url=new_url, username="admin",
                                password=p, project_name="admin",
                                user_domain_id="default",
                                project_domain_id="default")

sess = session.Session(auth=auth)


def keystone_tests():
    """
    Intend to test the followings:
    1) Test if it is possible to connect to the keystone server.
    2) Create new project.
    3) Create new user.
    """
    try:
        keystone = ksclient.Client(session=sess)
        project_list = len(keystone.projects.list())
        test_project = keystone.projects.create(
            name="test2", description="Test Project2!",
            domain="default", enabled=True)
        current_projects = len(keystone.projects.list())
        if current_projects > project_list:
            print("Created new project successfully")
            test_project.delete()
        user = keystone.users.create(
            name="test_user4", domain="default",
            password="password123", enabled=True)
        userlist = keystone.users.list()
        print("Current users are " + str(len(userlist)))
        user.delete()
    except ks_exceptions as conn_err:
        print(conn_err)


keystone_tests()
