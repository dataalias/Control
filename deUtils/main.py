"""
import sys
sys.path.insert(1,'D:\\Users\\ffortunato\\source\\AscentRepo\\deDataHub\\src_dh_layer\\python')

#import python
from data_hub import DataHub

DATA_HUB_SECRET_KEY = 'dev/devadw/DataHub/Glue_svc'

print('test_060_insert_issue')
pub_list_parms = {'PublisherCode': 'PUBR01', 'CurrentDate': '2099-Dec-31 23:59:59'}

expected_result = {'Status': 'Success'}

# Instantiate data hub.
dh = DataHub(DATA_HUB_SECRET_KEY)
response = dh.get_publication_list(pub_list_parms)

print(dh.publication_code)

"""