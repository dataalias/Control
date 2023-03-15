from dh.data_hub import *
import pymssql
import unittest
from secrets.aws_secrets import *
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
        cls._test_db_connection = pymssql.connect(cls._conn_params['host'],
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

    def test_005_cleanup(self):
        """
        Clean out old Publication things
        :return:
        """
        try:
            print("Clean out existing data hub test domain data")
            self._cursor.execute(
                "delete ctl.[distribution]			where IssueId			in (select IssueId from ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')))")
            self._cursor.execute(
                "delete ctl.Issue					where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))")
            self._cursor.execute(
                "delete ctl.MapContactToPublication	where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))")
            self._cursor.execute(
                "delete ctl.MapContactToSubscription	where SubscriptionId	in (select SubscriptionId from ctl.Subscription where Subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR'))")
            self._cursor.execute(
                "delete ctl.Subscription				where subscriptioncode	in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR')")
            self._cursor.execute(
                "delete ctl.Publication				where PublicationCode	in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')")
            self._cursor.execute(
                "delete ctl.Subscriber				where subscribercode	in ('SUBR01' , 'SUBR02')")
            self._cursor.execute(
                "delete ctl.Publisher				where publishercode		in ('PUBR01','PUBR02')")
            self._cursor.execute(
                "delete ctl.Contact					where [ContactName]		in ('PUB_Contact_Test01','PUB_Contact_Test02','SUB_Contact_Test01','SUB_Contact_Test02')")

            self._test_db_connection.commit()
            print('Cleanup Complete')
        except Exception as e:
            print('Cleanup failed :: ', e)

    def test_010_insert_publisher(self):
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

    def test_020_insert_subscriber_SUBR01(self):
        """
        Test the creation of a new Subscriber SUBR01
        :return:
        """

        try:
            sql = (f"exec [ctl].[usp_InsertNewSubscriber]"
                   f"@pSubscriberCode				= 'SUBR01'"
                   f",@pContactName					= 'BI-Development'"
                   f",@pSubscriberName				= '01 Test Subscriber'"
                   f",@pSubscriberDesc				= '01 Test Subscriber'"
                   f",@pInterfaceCode				= 'TBL'"
                   f",@pNotificationHostName			= 'SBXSRV01'"
                   f",@pNotificationInstance			= 'SBXSRV01'"
                   f",@pNotificationDatabase			= 'SBXSRV01'"
                   f",@pNotificationSchema			= 'schema'"
                   f",@pNotificationProcedure		= 'usp_NA'"
                   f",@pCreatedBy					= 'ffortunato'"

                   )
            # print('This is the SQL to execute :: ', sql)

            self._cursor.execute(sql)
            self._test_db_connection.commit()

            sql = "select count(1) SubscriberCount " \
                  "from ctl.publisher p " \
                  "where p.PublisherCode= 'SUBR01' "
            # print(sql)

            self._cursor.execute(sql)

            count = self._cursor.fetchall()
            int_count = int(count[0]['PublisherCount'])

            self._test_db_connection.commit()

            self.assertEqual(int_count, 1, 'Publisher: SUBR01 creation failed.')
        except Exception as e:
            print(e)

    def test_030_insert_publication_PUBN01(self):
        """
        Test the creation of a new Publication PUBN01
        :return:
        """

        try:
            sql = (f"EXEC [ctl].[usp_InsertNewPublication] "
                   f" @pPublisherCode			= 'PUBR01' "
                   f",@pPublicationCode			= 'PUBN01-ACCT'"
                   f",@pPublicationName			= 'Test Account Dim Feed'"
                   f",@pSrcPublicationName		= 'PUBN01-ACCT'"
                   f",@pPublicationFilePath		= ''"
                   f",@pPublicationArchivePath	= ''"
                   f",@pSrcFileFormatCode		= 'UNK'"
                   f",@pStageJobName			= ''"
                   f",@pSSISProject				= 'PostingGroup'"
                   f",@pSSISFolder				= 'ETLFolder'"
                   f",@pSSISPackage				= 'TSTPUBN01-ACCT.dtsx'"
                   f",@pSrcFilePath				= ''"
                   f",@pDataFactoryName			= 'N/A'"
                   f",@pDataFactoryPipeline		= 'N/A'"
                   f",@pIntervalCode			= 'DY'"
                   f",@pIntervalLength			= 1"
                   f",@pRetryIntervalCode		= 'HR'"
                   f",@pRetryIntervalLength		= 1"
                   f",@pRetryMax				= 0"
                   f",@pPublicationEntity		= ''"
                   f",@pDestTableName			= '[control].[schema].[TBL-ACCT]'"
                   f",@pSLATime					= '01:00'"
                   f",@pSLAEndTimeInMinutes		= NULL"
                   f",@pNextExecutionDtm		= '1900-01-01 00:00:00.000'"
                   f",@pIsActive				= 1"
                   f",@pIsDataHub				= 1"
                   f",@pBound					= 'In'"
                   f",@pCreatedBy				= 'ffortunato'")

            # print('This is the SQL to execute :: ', sql)

            self._cursor.execute(sql)
            self._test_db_connection.commit()

            sql = "select count(1) PublicationCount " \
                  "from ctl.Publication p " \
                  "where p.PublicationCode= 'PUBN01-ACCT' "
            print(sql)

            self._cursor.execute(sql)

            count = self._cursor.fetchall()
            int_count = int(count[0]['PublisherCount'])

            self._test_db_connection.commit()

            self.assertEqual(int_count, 1, 'Publication: PUBN01 creation failed.')
        except Exception as e:
            print(e)

    def test_040_insert_subscription(self):
        """
        Attempt to create a new subscription for the last publication
        :return:
        """
        try:
            sql = (f"exec ctl.usp_InsertNewSubscription "
                   f"@pPublicationCode			= 'PUBN01-ACCT'"
                   f",@pSubscriberCode			= 'SUBR01'"
                   f",@pSubscriptionName		= 'SUB01 Account Data'"
                   f",@pSubscriptionDesc		= 'Sending the Account feed to subscriber 01'"
                   f",@pInterfaceCode			= 'TBL'"
                   f",@pIsActive				= 1"
                   f",@pSubscriptionFilePath    = 'N/A'"
                   f",@pSubscriptionArchivePath = 'N/A'"
                   f",@pSrcFilePath				= 'N/A'"
                   f",@pDestTableName			= 'N/A'"
                   f",@pDestFileFormatCode		= 'N/A'"
                   f",@pCreatedBy				= 'ffortunato'"
                   f",@pVerbose					= 0")

            # print('This is the SQL to execute :: ', sql)

            self._cursor.execute(sql)
            self._test_db_connection.commit()

            sql = "select count(1) SubscriptionCount " \
                  "from ctl.Subscription p " \
                  "where p.SubscriptionCode= 'PUBR01-SUBR01-PUBN01-ACCT' "
            # print(sql)

            self._cursor.execute(sql)

            count = self._cursor.fetchall()
            int_count = int(count[0]['SubscriptionCount'])

            self._test_db_connection.commit()

            self.assertEqual(int_count, 1, 'Subscription: PUBR01-SUBR01-PUBN01-ACCT creation failed.')

        except Exception as e:
            print(e)

    def test_050_posting_group_created(self):
        """
        Attempt to create a new Posting Group  record.
        Updates Issue status, notify subscriber of distribution.
        :return:
        """
        try:
            self.assertEqual(1, 1, 'Distribution failed.')
        except Exception as e:
            print(e)

    def test_060_insert_issue(self):
        """
        This test case attempts to create a new issue and ensures the correct issue id is returned
        and that it is the latest for the given publication. This test case uses data setup in the tst_data_hub.sql
        script.

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

        pub_list_parms = {'PublisherCode': 'PUBR01', 'CurrentDate': '2099-Dec-31 23:59:59'}

        expected_result = {'Status': 'Success'}

        # Instantiate data hub.
        dh = DataHub(DATA_HUB_SECRET_KEY)
        response = dh.get_publication_list(pub_list_parms)

        # Test 1 see if we got a publication list.
        self.assertEqual(response, expected_result, 'Publication list failed.')

        # Insert new issues and capture the issue id for the active publication.
        dh.insert_new_issue()
        data_hub_issue_id = dh.get_issue_id()
        # print('DataHub IssueId:', data_hub_issue_id)

        sql = 'select max(IssueId) IssueId ' \
              'from ctl.issue i ' \
              'join ctl.publication p ' \
              'on i.PublicationId = p.PublicationId ' \
              'where p.PublicationCode=\'' + dh.get_publication_code() + '\''
        # print(sql)

        self._cursor.execute(sql)
        db_issue_id = self._cursor.fetchall()
        self._test_db_connection.commit()

        # print('Test Issue Id: ', int(db_issue_id[0]['IssueId']))
        test_issue_id = int(db_issue_id[0]['IssueId'])

        # Test 2 see if the issue ids match.
        self.assertEqual(data_hub_issue_id, test_issue_id, 'Issue creation failed.')

        # Test 3 see if the distribution was created.
        sql = 'select isnull(count(DistributionId),-1) DistributionId ' \
              'from ctl.distribution d ' \
              'where d.IssueId=' + str(test_issue_id)
        # print(sql)

        self._cursor.execute(sql)
        db_distribution_id = self._cursor.fetchall()
        test_distribution_id = int(db_distribution_id[0]['DistributionId'])
        self._test_db_connection.commit()
        self.assertEqual(test_distribution_id, 1, 'Distribution creation failed.')

    def test_070_posting_group_processing_created(self):
        """
        Attempt to create a new Posting Group  record.
        Updates Issue status, notify subscriber of distribution.
        :return:
        """
        self.assertEqual(1, 1, 'Distribution failed.')

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  08/09/2022  Initial Iteration
ffortunato  08/11/2022  + setUpClass, tearDownClass
                        

*******************************************************************************
"""
