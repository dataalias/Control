from posting_group import PostingGroup
import pyodbc
import unittest
from aws_secrets import *
import tracemalloc

DATA_HUB_SECRET_KEY = 'dev/devadw/DataHub/Glue_svc'


class DataHubTestCase(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """
        The setup class is run prior to each test case.
        :return:
        """
        tracemalloc.start()  # This is a thing that unit test asked for :-)
        cls._conn_params = get_secret(DATA_HUB_SECRET_KEY)
        cls._test_db_connection = pyodbc.connect(cls._conn_params['host'],
                                                  cls._conn_params['user'],
                                                  cls._conn_params['password'],
                                                  cls._conn_params['database'])

        cls._cursor = cls._test_db_connection.cursor(as_dict=True)

        # print('DataHubTestCase.setUpClass :: db connection created')

    @classmethod
    def tearDownClass(cls):
        """
        The tearDownClass is run after each test case.
        :return:
        """

        cls._cursor.close()
        cls._test_db_connection.commit()
        cls._test_db_connection.close()
        # print('DataHubTestCase.setUpClass :: db connection closed')

    def test_010_cleanup(self):
        """
        Clean out old Publication things
        :return:
        """
        try:
            
            self._cursor.execute(
                "delete ctl.Contact					where [ContactName]		in ('PUB_Contact_Test01','PUB_Contact_Test02','SUB_Contact_Test01','SUB_Contact_Test02')")

            self._test_db_connection.commit()
            print('Cleanup Complete')
        except Exception as e:
            print('Cleanup failed :: ', e)

    def test_010_do_something(self):
        """
        Test the creation of a new Publisher PUBR01.
        :return:
        """

        try:
            sql = (f"exec [ctl].usp_InsertNewPublisher "
                   f"@pPublisherCode			= 'PUBR01'"
                   f",@pContactName			    = 'BI-Development'"
                   f",@pPublisherName			= '01 Test Publisher'"
                   f",@pPublisherDesc			= 'First Test Publisher'"
                   f",@pInterfaceCode			= 'TBL'"
                   f",@pCreatedBy				= 'unittest'"
                   f",@pSiteURL				    = NULL"
                   f",@pSiteUser				= NULL"
                   f",@pSitePassword			= NULL"
                   f",@pSiteHostKeyFingerprint	= NULL"
                   f",@pSitePort				= NULL"
                   f",@pSiteProtocol			= NULL"
                   f",@pPrivateKeyPassPhrase	= NULL"
                   f",@pPrivateKeyFile			= NULL"
                   f",@pETLExecutionId			= 0"
                   f",@pPathId					= 0"
                   f",@pVerbose				    = 0"
                   )
            # print('This is the SQL to execute :: ', sql)

            self._cursor.execute(sql)
            self._test_db_connection.commit()

            sql = "select count(1) PublisherCount " \
                  "from ctl.publisher p " \
                  "where p.PublisherCode= 'PUBR01' "
            # print(sql)

            self._cursor.execute(sql)

            publisher_count = self._cursor.fetchall()
            count = int(publisher_count[0]['PublisherCount'])

            self._test_db_connection.commit()

            self.assertEqual(count, 1, 'Publisher: PUBR01 creation failed.')
        except Exception as e:
            print(e)



"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  20230524    + initial iteration.
                        

*******************************************************************************
"""
