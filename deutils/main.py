from S3.S3ReadObject import Read_Objects_From_S3
from dh.data_hub import *
import time
import json
import boto3
from datetime import datetime
from secrets.aws_secrets import *

# Opening JSON file


# returns JSON object as
# a dictionary


try:
    config_data = Read_Objects_From_S3("dev-ascent-de-assets", "DataHubStagingEvent/config/S3_file_event_lambda.json")
    file_content = config_data.get()['Body'].read()
    json_content = json.loads(file_content)
    print(json_content["__Header"]["Env"]["EnvironmentAbbreviation"])

except Exception as e:
    print(e)

# Variable declarations.

# exit(1)

pub_list_parms = {}
pub_list_parms['PublisherCode'] = 'PUBR01'
pub_list_parms['CurrentDate'] = '2099-Dec-31 23:59:59'  # datetime.today().strftime('%Y-%b-%d %H:%M:%S')

issue = {}


# So Starteth main.


print(__name__, ': about to make a data hub')
# Instantiate data hub.

# Inititate a datahub object for each publisher involved with the test
print(__name__, ': Create object MyDataHub_PUBR01')
MyDataHub_PUBR01 = DataHub('dev/devadw/DataHub/Glue_svc')
print(__name__, ': Create object MyDataHub_PUBR02')
MyDataHub_PUBR02 = DataHub('dev/devadw/DataHub/Glue_svc')

print(__name__, ': Create object MyDataHub_PUBR03')
MyDataHub_PUBR03 = DataHub('dev/devadw/DataHub/Glue_svc')

print(__name__, ': Create object MyDataHub_PUBR04')
MyDataHub_PUBR04 = DataHub('dev/devadw/DataHub/Glue_svc')
print(__name__, ': Create object MyDataHub_PUBR05')
MyDataHub_PUBR05 = DataHub('dev/devadw/DataHub/Glue_svc')
print(__name__, ': Create object MyDataHub_PUBR06')
MyDataHub_PUBR06 = DataHub('dev/devadw/DataHub/Glue_svc')
print(__name__, ': Create object MyDataHub_PUBR07')
MyDataHub_PUBR07 = DataHub('dev/devadw/DataHub/Glue_svc')



response = MyDataHub_PUBR01.get_publication_list(pub_list_parms)
print(__name__, ': Get publication list PUBR01: ', response)

for r in MyDataHub_PUBR01.publication_list:
    print(r)

for x in MyDataHub_PUBR01.issue_list:
    print(x)


pub_list_parms['PublisherCode'] = 'PUBR02' #swapping over to the other publisher
response = MyDataHub_PUBR02.get_publication_list(pub_list_parms)
print(__name__, ': Get publication list PUBR02: ', response)

print('My Publication code: ', MyDataHub_PUBR01.get_publication_code())

MyDataHub_PUBR01.set_publication_code('PUBN01-ACCT')
MyDataHub_PUBR01.insert_new_issue()


issue['IssueName'] = 'PUBN01-ACCT_20220805_moo.dat'
issue['StatusCode'] = 'IS'

MyDataHub_PUBR01.update_issue(issue)
issue['StatusCode'] = 'IL'

MyDataHub_PUBR01.update_issue(issue)
print(__name__, 'IssueId: ', MyDataHub_PUBR01.get_issue_id(), ' Publication Code: ', MyDataHub_PUBR01.get_publication_code())
MyDataHub_PUBR01.notify_subscriber_of_distribution()

MyDataHub_PUBR01.set_publication_code('PUBN02-ASSG')
MyDataHub_PUBR01.insert_new_issue()

issue['IssueName'] = 'PUBN02-ASSG_20220805_w00.dat'
issue['StatusCode'] = 'IS'

MyDataHub_PUBR01.update_issue(issue)


issue['IssueName'] = 'PUBN02-ASSG_20220805_w01.dat'
issue['StatusCode'] = 'IL'

MyDataHub_PUBR01.update_issue(issue)
print(__name__, 'IssueId: ', MyDataHub_PUBR01.get_issue_id(), ' Publication Code: ', MyDataHub_PUBR01.get_publication_code())
MyDataHub_PUBR01.notify_subscriber_of_distribution()


issue['IssueName'] = 'PUBN03-COUR_20220805_w01.dat'

MyDataHub_PUBR02.set_publication_code('PUBN03-COUR')
MyDataHub_PUBR02.insert_new_issue()

issue['StatusCode'] = 'IS'

MyDataHub_PUBR02.update_issue(issue)

issue['StatusCode'] = 'IL'

MyDataHub_PUBR02.update_issue(issue)
print(__name__, 'IssueId: ', MyDataHub_PUBR02.get_issue_id(), ' Publication Code: ', MyDataHub_PUBR02.get_publication_code())
MyDataHub_PUBR02.notify_subscriber_of_distribution()
"""
print(datetime.now())

MyDataHub_PUBR03 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR04 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR05 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR06 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR07 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR08 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR09 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR10 = DataHub('dev/devadw/DataHub/Glue_svc')
print('10 data hubs', datetime.now())
MyDataHub_PUBR11 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR12 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR13 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR14 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR15 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR16 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR17 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR18 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR19 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR20 = DataHub('dev/devadw/DataHub/Glue_svc')
print('20 data hubs', datetime.now())
MyDataHub_PUBR21 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR22 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR23 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR24 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR25 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR26 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR27 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR28 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR29 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR30 = DataHub('dev/devadw/DataHub/Glue_svc')
print('30 data hubs', datetime.now())
MyDataHub_PUBR31 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR32 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR33 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR34 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR35 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR36 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR37 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR38 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR39 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR40 = DataHub('dev/devadw/DataHub/Glue_svc')
print('40 data hubs', datetime.now())
MyDataHub_PUBR41 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR42 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR43 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR44 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR45 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR46 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR47 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR48 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR49 = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub_PUBR50 = DataHub('dev/devadw/DataHub/Glue_svc')
"""
print('50 data hubs', datetime.now())

region_name = "us-east-1"
secret_name = "dev/devadw/DataHub/Glue_svc"

for i in range(100):
    try:
        MySecret = get_secret("dev/devadw/DataHub/Glue_svc")
        print(i, ' ', MySecret)
    except Exception as e:
        print(e)



print('done')
