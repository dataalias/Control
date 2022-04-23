from DataHub.data_hub import *
from datetime import datetime


dl_bucket = 'dev-ascent-datalake'
dl_path_crz = 'RawData/8x8CC/8x8CRZ/'
dl_path_cr = 'RawData/8x8CC/8x8CR/'
dl_path_cri = 'RawData/8x8CC/8x8CRI/'



pub_list_parms = {}
pub_list_parms['PublisherCode'] = '8x8CC'
pub_list_parms['CurrentDate'] = datetime.today().strftime('%Y-%b-%d %H:%M:%S')

issue_updates = {}

# Instantiate data hub.
MyDataHub = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub.get_publication_list(pub_list_parms)

"""
print('Publication List V')
for x in MyDataHub.publication_list:
    print(x)
"""

print('Issue List V')
for y in MyDataHub.issue_list:
    print(y)

MyDataHub.set_publication_code('8x8CRZ')
MyDataHub.insert_new_issue()
MyDataHub.set_publication_code('8x8CR')
MyDataHub.insert_new_issue()
MyDataHub.set_publication_code('8x8CRI')
MyDataHub.insert_new_issue()


MyDataHub.set_publication_code('8x8CRZ')
issue_updates = {'DataLakePath': 'CRZ_MONKEY'}
MyDataHub.set_issue_val(issue_updates)

MyDataHub.set_publication_code('8x8CR')
issue_updates = {'DataLakePath': 'CR_MONKEY'}
MyDataHub.update_issue(issue_updates)

MyDataHub.set_publication_code('8x8CRI')
issue_updates = {'DataLakePath': 'set_issue_Val', 'SrcDFPublisherId': 'nom nom nom'}
MyDataHub.set_issue_val(issue_updates)
issue_updates = {'IssueName': 'update_issue'}
issue_updates.update({'SrcDFPublicationId': 'whaaaaaaaaaa'})
MyDataHub.update_issue(issue_updates)


print('Issue List V')
for y in MyDataHub.issue_list:
    print(y)


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  04/22/2022  Initial Iteration
                        

*******************************************************************************
"""