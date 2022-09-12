
from dh.data_hub import *
import time


# Variable declarations.



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
time.sleep(2)
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
time.sleep(2)
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


