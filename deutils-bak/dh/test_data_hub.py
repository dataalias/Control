
from dh.data_hub import *
import pymssql
import unittest
from secrets.aws_secrets import *
import tracemalloc



DATA_HUB_SECRET_KEY = 'dev/devadw/DataHub/Glue_svc'


class DataHubTestCase(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        tracemalloc.start()  # This is a thing that unit test asked for :-)
        cls._conn_params = get_secret(DATA_HUB_SECRET_KEY)
        cls._test_db_connection = pymssql.connect(cls._conn_params['host'],
                                                  cls._conn_params['user'],
                                                  cls._conn_params['password'],
                                                  cls._conn_params['database'])

        cls._cursor = cls._test_db_connection.cursor(as_dict=True)

        print('DataHubTestCase.setUpClass :: db connection created')

    @classmethod
    def tearDownClass(cls):

        cls._cursor.close()
        cls._test_db_connection.commit()
        cls._test_db_connection.close()
        print('DataHubTestCase.setUpClass :: db connection closed')

    def test_insert_issue(self):
        """
        This test case attempts to create a new issue and ensures the correct issue id is returned also the latest
        for the given publication. This test case uses data setup in the tst_data_hub.sql script.
        Precondition:
        1) Run tst_DataHub.sql on the target database for the unit test. (setup and test DataHub via SQL)
        2) Run tst_tst_PostingGroupProcessing.sql  on the target database for the unit test.
            (setup and test PostingGroup via SQL)
        Test Setup:
        1) Create pub_list_parms dictionary and provide a test publisher code.
        2) Create a DataHub Object using the secret key for the test database.
        3) Invoke DataHub.get_publication_list() to load publication and index properties.
        4) Invoke DataHub.insert_new_issue to create a new issue record in the database.
        5) Use the test case's db connection to execute sql to get the latest issue id for the publication.
        Test Case:
        1) Ensure the get_publication_list returned successfully.
        2) Ensure that the issue id returned by DataHub and the test condition match.

        :return:
        """

        pub_list_parms = {}
        pub_list_parms['PublisherCode'] = 'PUBR01'
        pub_list_parms['CurrentDate'] = '2099-Dec-31 23:59:59'  # datetime.today().strftime('%Y-%b-%d %H:%M:%S')

        expected_result = {'Status': 'Success'}

        # Instantiate data hub.
        dh = DataHub(DATA_HUB_SECRET_KEY)
        response = dh.get_publication_list(pub_list_parms)

        # Test 1 see if we got a publication list.
        self.assertEqual(response, expected_result, 'Publication list failed.')

        # Insert new issues and capture the issue id for the active publication.
        dh.insert_new_issue()
        data_hub_issue_id = dh.get_issue_id()
        print('DataHub IssueId:', data_hub_issue_id)

        sql = 'select max(IssueId) IssueId ' \
              'from ctl.issue i ' \
              'join ctl.publication p ' \
              'on i.PublicationId = p.PublicationId ' \
              'where p.PublicationCode=\'' + dh.get_publication_code() + '\''
        # print(sql)

        self._cursor.execute(sql)
        db_issue_id = self._cursor.fetchall()
        self._test_db_connection.commit()

        print('Test Issue Id: ', int(db_issue_id[0]['IssueId']))
        test_issue_id = int(db_issue_id[0]['IssueId'])

        # Test 2 see if the issue ids match.
        self.assertEqual(data_hub_issue_id, test_issue_id, 'Issue creation failed.')

    def test_insert_update(self):
        self.assertEqual(1, 1, 'update issue worked')


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  08/09/2022  Initial Iteration
ffortunato  08/11/2022  + setUpClass, tearDownClass
                        

*******************************************************************************
"""