"""
*******************************************************************************
File: test_data_hub.py

Purpose: Integration tests for the DataHub class and Snowflake connection.

Dependencies/Helpful Notes :

*******************************************************************************
"""

from eimutils.utils import get_snowflake_connection_from_secret, log_to_console
import unittest
import tracemalloc
import os
from eimutils.data_hub import DataHub
from datetime import datetime


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_data_hub.py")
    print("=" * 70)


class DataHubIntegrationTest(unittest.TestCase):

    sf_conn = None
    dh = None

    @classmethod
    def setUpClass(cls):
        tracemalloc.start()
        os.environ["ENV"] = "dev"
        os.environ["AWS_SECRET_ARN_SF_CONN"] = (
            "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI"
        )
        os.environ["AWS_REGION"] = "us-west-2"

        try:
            cls.sf_conn = get_snowflake_connection_from_secret(
                os.environ["AWS_SECRET_ARN_SF_CONN"],
                os.environ["ENV"],
                os.environ["AWS_REGION"],
                "RAW",
                "MY_ORG",
                "CARE",
                "MY_ORG_DEV_RAW",
            )
            cls.dh = DataHub(os.environ["AWS_SECRET_ARN_SF_CONN"], os.environ["ENV"])
            log_to_console(__name__, "Info", "DataHubIntegrationTest.setUpClass :: Complete.")
        except Exception as e:
            raise unittest.SkipTest(f"Skipping DataHub integration tests: credentials unavailable ({e})")

    @classmethod
    def tearDownClass(cls):
        if cls.sf_conn:
            cls.sf_conn.close()
        if cls.dh:
            cls.dh.close()
        log_to_console(__name__, "Info", "DataHubIntegrationTest.tearDownClass :: Complete.")

    def test_010_get_aws_secret(self):
        try:
            log_to_console(__name__, "Info", "test_010_get_aws_secret :: Starting.")
            secrets = self.dh.secret
            has_expected_key = "SFSVCUSERRAW" in secrets or "SFSVCUSER" in secrets
            self.assertTrue(has_expected_key, "Expected SFSVCUSERRAW or SFSVCUSER in secret.")
            log_to_console(__name__, "Info", "test_010_get_aws_secret :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_010_get_aws_secret :: Failed :: {str(err)}")
            assert False, err

    def test_020_get_snowflake_connection(self):
        try:
            log_to_console(__name__, "Info", "test_020_get_snowflake_connection :: Starting.")
            self.assertIsNotNone(self.sf_conn, "Expected a valid Snowflake connection.")
            log_to_console(__name__, "Info", "test_020_get_snowflake_connection :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_020_get_snowflake_connection :: Failed :: {str(err)}")
            assert False, err

    def test_030_cleanup_and_prep_data_hub(self):
        try:
            log_to_console(__name__, "Info", "test_030_cleanup_and_prep_data_hub :: Starting.")
            sql = """
delete from DATA_HUB.Issue          where publicationcode   in (select publicationcode from DATA_HUB.publication
    where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'));
delete from DATA_HUB.Subscription   where subscriptioncode  in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT',
    'PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR');
delete from DATA_HUB.Publication    where PublicationCode   in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR');
delete from DATA_HUB.Subscriber     where subscribercode    in ('SUBR01' , 'SUBR02');
delete from DATA_HUB.Publisher      where publishercode     in ('PUBR01','PUBR02');
delete from DATA_HUB.Contact        where ContactName       in ('PUB_Contact_Test01',
    'PUB_Contact_Test02','SUB_Contact_Test01','SUB_Contact_Test02');


insert into data_hub.contact (
CompanyName
,ContactName
,Tier
,Email
,createdby
,createddtm
) values (
'CO_Test_01',
'PUB_Contact_Test01'
, '1'
, 'PUB_Contact_Test01@myaddress.com'
,'UnitTest'
,CURRENT_DATE
);

insert into data_hub.contact (CompanyName
,ContactName
,Tier
,Email
,createdby
,createddtm) values (
'CO_Test_01',
'PUB_Contact_Test02'
, '1'
, 'PUB_Contact_Test02@myaddress.com'
,'UnitTest'
,CURRENT_DATE);

insert into data_hub.contact (CompanyName
,ContactName
,Tier
,Email
,createdby
,createddtm) values (
'CO_Test_01',
'SUB_Contact_Test01'
, '1'
, 'SUB_Contact_Test01@myaddress.com'
,'UnitTest'
,CURRENT_DATE);

insert into data_hub.contact ( CompanyName
,ContactName
,Tier
,Email
,createdby
,createddtm) values (
'CO_Test_01',
'SUB_Contact_Test02'
, '1'
, 'SUB_Contact_Test02@myaddress.com'
,'UnitTest'
,CURRENT_DATE);

INSERT INTO DATA_HUB.Publisher (
PublisherCode
,ContactId
,PublisherName
,PublisherDesc
,InterfaceCode
,CreatedBy
,CREATEDDTM
)values(
'PUBR02'
,-1
, '02 Test Publisher'
, 'Second Test Publisher'
, 'TBL'
, 'ffortunato'
,CURRENT_DATE
);

INSERT INTO DATA_HUB.Publisher (
PublisherCode
,ContactId
,PublisherName
,PublisherDesc
,InterfaceCode
,CreatedBy
,CREATEDDTM
)values(
'PUBR01'
,-1
, '01 Test Publisher'
, 'First Test Publisher'
, 'TBL'
, 'ffortunato'
,CURRENT_DATE
);

INSERT INTO  DATA_HUB.PUBLICATION(
     PublisherCode
    ,PublicationCode
    ,PublicationName
    ,PublicationDesc
    ,SrcPublicationCode
    ,SrcPublicationName
    ,PublicationEntity
    ,PUBLICATIONBUCKET
    ,INTERVALCODE
    ,INTERVALLENGTH
    ,SLATIME
    ,NextExecutionDtm
    ,CreatedBy
    ,CreatedDtm
) values (
'PUBR01'
,'PUBN01-ACCT'
,'Test Account Dim Feed'
,''
,''
,'PUBN02-ACCT'
,''
, 'Unknown'
, 'DY'
, 1
, '10:00'
, '2024-04-17 15:41:38.29'
, 'data hub test'
,current_date
);

INSERT INTO  DATA_HUB.PUBLICATION(
     PublisherCode
    ,PublicationCode
    ,PublicationName
    ,PublicationDesc
    ,SrcPublicationCode
    ,SrcPublicationName
    ,PublicationEntity
    ,PUBLICATIONBUCKET
    ,INTERVALCODE
    ,INTERVALLENGTH
    ,SLATIME
    ,NextExecutionDtm
    ,CreatedBy
    ,CreatedDtm
) values (
'PUBR01'
,'PUBN02-ASSG'
,'Test Assignment Dim Feed'
,''
,''
,'PUBN02-ASSG'
,''
, 'Unknown'
, 'DY'
, 1
, '10:00'
, '2024-04-17 15:41:38.29'
, 'data hub test'
,current_date
);

INSERT INTO  DATA_HUB.PUBLICATION(
     PublisherCode
    ,PublicationCode
    ,PublicationName
    ,PublicationDesc
    ,SrcPublicationCode
    ,SrcPublicationName
    ,PublicationEntity
    ,PUBLICATIONBUCKET
    ,INTERVALCODE
    ,INTERVALLENGTH
    ,SLATIME
    ,NextExecutionDtm
    ,CreatedBy
    ,CreatedDtm
) values (
'PUBR02'
,'PUBN03-COUR'
,'Test Course Dim Feed'
,''
,''
,'PUBN02-COUR'
,''
,'Unknown'
,'DY'
,1
,'10:00'
,'2024-04-17 15:41:38.29'
,'data hub test'
,current_date
);



INSERT INTO DATA_HUB.ISSUE (
PublicationCode
,StatusCode
,ReportDate
,SrcDFPublisherId
,SrcDFPublicationId
,SrcDFIssueId
,SrcIssueName
,SrcDFCreatedDate
,DataLakePath
,IssueName
,PublicationSeq
,DailyPublicationSeq
,FirstRecordSeq
,LastRecordSeq
,FirstRecordChecksum
,LastRecordChecksum
,PeriodStartTime
,PeriodEndTime
,PeriodStartTimeUTC
,PeriodEndTimeUTC
,IssueConsumedDate
,RecordCount
,RetryCount
,ETLExecutionId
,CreatedBy
,CreatedDtm
,ModifiedBy
,ModifiedDtm
) values (
'PUBN01-ACCT'
,'IC'
,'1900-01-01'
,-1
,-1
,-1
,'Account.csv'
,'1900-01-01'
,'/internal/pubr01/account/'
,'19000101_Account.csv'
,-1
,-1
,-1
,-1
,'N/A'
,'N/A'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,-1
,-1
,-1
,CURRENT_USER
,CURRENT_TIMESTAMP
,CURRENT_USER
,CURRENT_TIMESTAMP
);



INSERT INTO DATA_HUB.ISSUE (
PublicationCode
,StatusCode
,ReportDate
,SrcDFPublisherId
,SrcDFPublicationId
,SrcDFIssueId
,SrcIssueName
,SrcDFCreatedDate
,DataLakePath
,IssueName
,PublicationSeq
,DailyPublicationSeq
,FirstRecordSeq
,LastRecordSeq
,FirstRecordChecksum
,LastRecordChecksum
,PeriodStartTime
,PeriodEndTime
,PeriodStartTimeUTC
,PeriodEndTimeUTC
,IssueConsumedDate
,RecordCount
,RetryCount
,ETLExecutionId
,CreatedBy
,CreatedDtm
,ModifiedBy
,ModifiedDtm
) values (
'PUBN02-ASSG'
,'IC'
,'1900-01-01'
,-1
,-1
,-1
,'Assignment.csv'
,'1900-01-01'
,'/internal/pubr01/assignment/'
,'19000101_Assignment.csv'
,-1
,-1
,-1
,-1
,'N/A'
,'N/A'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,-1
,-1
,-1
,CURRENT_USER
,CURRENT_TIMESTAMP
,CURRENT_USER
,CURRENT_TIMESTAMP
);


INSERT INTO DATA_HUB.ISSUE (
PublicationCode
,StatusCode
,ReportDate
,SrcDFPublisherId
,SrcDFPublicationId
,SrcDFIssueId
,SrcIssueName
,SrcDFCreatedDate
,DataLakePath
,IssueName
,PublicationSeq
,DailyPublicationSeq
,FirstRecordSeq
,LastRecordSeq
,FirstRecordChecksum
,LastRecordChecksum
,PeriodStartTime
,PeriodEndTime
,PeriodStartTimeUTC
,PeriodEndTimeUTC
,IssueConsumedDate
,RecordCount
,RetryCount
,ETLExecutionId
,CreatedBy
,CreatedDtm
,ModifiedBy
,ModifiedDtm
) values (
'PUBN03-COUR'
,'IC'
,'1900-01-01'
,-1
,-1
,-1
,'Course.csv'
,'1900-01-01'
,'/internal/pubr02/course/'
,'19000101_Course.csv'
,-1
,-1
,-1
,-1
,'N/A'
,'N/A'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,'1900-01-01'
,-1
,-1
,-1
,CURRENT_USER
,CURRENT_TIMESTAMP
,CURRENT_USER
,CURRENT_TIMESTAMP
);
"""
            self.sf_conn.execute_string(sql)
            self.sf_conn.commit()
            log_to_console(__name__, "Info", "test_030_cleanup_and_prep_data_hub :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_030_cleanup_and_prep_data_hub :: Failed :: {str(err)}")
            assert False, err

    def test_040_dh_class_issue_insert(self):
        try:
            log_to_console(__name__, "Info", "test_040_dh_class_issue_insert :: Starting.")
            params = {
                "PublisherCode": "PUBR01",
                "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
            }
            self.dh.get_publication_list(params)
            self.dh.set_publication_code("PUBN01-ACCT")

            issue = {
                "IssueName": "Account_20241001.csv",
                "SrcIssueName": "Account.csv",
                "StatusCode": "IC",
                "ETLExecutionId": "test_040_dh_class_issue_insert",
                "PeriodStartTime": params["CurrentDate"],
                "PeriodEndTime": params["CurrentDate"],
                "PeriodStartTimeUTC": f"{params['CurrentDate']} +0000",
                "PeriodEndTimeUTC": f"{params['CurrentDate']} +0000",
            }
            self.dh.set_issue_val(issue)
            self.dh.insert_new_issue()
            issue_id = self.dh.get_issue_id()

            cursor = self.sf_conn.cursor()
            cursor.execute(
                "SELECT IssueId, StatusCode FROM DATA_HUB.Issue WHERE IssueId = %s",
                (issue_id,),
            )
            row = cursor.fetchone()
            cursor.close()

            self.assertIsNotNone(row, "Expected inserted issue to be found.")
            self.assertEqual(row[1], "IC", "Expected StatusCode to be IC.")
            log_to_console(__name__, "Info", "test_040_dh_class_issue_insert :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_040_dh_class_issue_insert :: Failed :: {str(err)}")
            assert False, err

    def test_050_dh_class_get_current_publication(self):
        try:
            log_to_console(__name__, "Info", "test_050_dh_get_current_publication :: Starting.")
            self.dh.set_publication_code("PUBN01-ACCT")
            current_publication = self.dh.get_current_publication()
            self.assertEqual(current_publication["PUBLICATIONNAME"], "Test Account Dim Feed")
            log_to_console(__name__, "Info", "test_050_dh_get_current_publication :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_050_dh_get_current_publication :: Failed :: {str(err)}")
            assert False, err

    def test_060_context_manager(self):
        try:
            log_to_console(__name__, "Info", "test_060_context_manager :: Starting.")
            with DataHub(os.environ["AWS_SECRET_ARN_SF_CONN"], os.environ["ENV"]) as dh:
                params = {
                    "PublisherCode": "PUBR01",
                    "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
                }
                result = dh.get_publication_list(params)
                self.assertEqual(result["Status"], "Success", "Expected Success inside context.")

            self.assertIsNone(
                dh.db_connection,
                "Expected connection to be None after exiting context manager.",
            )
            log_to_console(__name__, "Info", "test_060_context_manager :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_060_context_manager :: Failed :: {str(err)}")
            assert False, err

    def test_070_update_issue(self):
        try:
            log_to_console(__name__, "Info", "test_070_update_issue :: Starting.")
            # Relies on state set in test_040 (publication_idx + IssueId on cls.dh)
            update = {"StatusCode": "IP", "RecordCount": 42}
            result = self.dh.update_issue(update)
            self.assertEqual(result["Status"], "Success")

            issue_id = self.dh.get_issue_id()
            cursor = self.sf_conn.cursor()
            cursor.execute(
                "SELECT StatusCode, RecordCount FROM DATA_HUB.Issue WHERE IssueId = %s",
                (issue_id,),
            )
            row = cursor.fetchone()
            cursor.close()

            self.assertIsNotNone(row, "Expected issue row to exist after update.")
            self.assertEqual(row[0], "IP", "Expected StatusCode to be IP.")
            self.assertEqual(row[1], 42, "Expected RecordCount to be 42.")
            log_to_console(__name__, "Info", "test_070_update_issue :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_070_update_issue :: Failed :: {str(err)}")
            assert False, err

    def test_080_is_issue_absent(self):
        try:
            log_to_console(__name__, "Info", "test_080_is_issue_absent :: Starting.")
            # Account.csv was inserted in test_040 — should NOT be absent
            self.assertFalse(
                self.dh.is_issue_absent("Account.csv"),
                "Expected Account.csv to be present (not absent).",
            )
            # Nonexistent file — should be absent
            self.assertTrue(
                self.dh.is_issue_absent("no_such_file_xyz_99999.csv"),
                "Expected no_such_file_xyz_99999.csv to be absent.",
            )
            log_to_console(__name__, "Info", "test_080_is_issue_absent :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_080_is_issue_absent :: Failed :: {str(err)}")
            assert False, err

    def test_085_write_issue_insert(self):
        try:
            log_to_console(__name__, "Info", "test_085_write_issue_insert :: Starting.")
            params = {
                "PublisherCode": "PUBR01",
                "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
            }
            self.dh.get_publication_list(params)
            self.dh.set_publication_code("PUBN02-ASSG")

            issue = {
                "IssueName": "Assignment_20241001.csv",
                "SrcIssueName": "Assignment.csv",
                "StatusCode": "IC",
                "ETLExecutionId": "test_085_write_issue_insert",
                "PeriodStartTime": params["CurrentDate"],
                "PeriodEndTime": params["CurrentDate"],
                "PeriodStartTimeUTC": f"{params['CurrentDate']} +0000",
                "PeriodEndTimeUTC": f"{params['CurrentDate']} +0000",
            }
            result = self.dh.write_issue(issue)
            self.assertEqual(result["Status"], "Success", "Expected Status=Success after write_issue insert.")

            issue_id = self.dh.get_issue_id()
            self.assertIsNotNone(issue_id, "Expected IssueId to be assigned after insert.")
            self.assertNotEqual(str(issue_id), "-1", "Expected a real IssueId, not -1.")

            cursor = self.sf_conn.cursor()
            cursor.execute(
                "SELECT IssueId, StatusCode FROM DATA_HUB.Issue WHERE IssueId = %s",
                (issue_id,),
            )
            row = cursor.fetchone()
            cursor.close()

            self.assertIsNotNone(row, "Expected inserted issue to exist in DB.")
            self.assertEqual(row[1], "IC", "Expected StatusCode=IC after write_issue insert.")
            log_to_console(__name__, "Info", "test_085_write_issue_insert :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_085_write_issue_insert :: Failed :: {str(err)}")
            assert False, err

    def test_086_write_issue_update(self):
        try:
            log_to_console(__name__, "Info", "test_086_write_issue_update :: Starting.")
            # Relies on test_085 having inserted PUBN02-ASSG and left IssueId set on self.dh
            result = self.dh.write_issue({"StatusCode": "CM", "RecordCount": 99})
            self.assertEqual(result["Status"], "Success", "Expected Status=Success after write_issue update.")

            issue_id = self.dh.get_issue_id()
            cursor = self.sf_conn.cursor()
            cursor.execute(
                "SELECT StatusCode, RecordCount FROM DATA_HUB.Issue WHERE IssueId = %s",
                (issue_id,),
            )
            row = cursor.fetchone()
            cursor.close()

            self.assertIsNotNone(row, "Expected issue row to exist after update.")
            self.assertEqual(row[0], "CM", "Expected StatusCode=CM after write_issue update.")
            self.assertEqual(row[1], 99, "Expected RecordCount=99 after write_issue update.")
            log_to_console(__name__, "Info", "test_086_write_issue_update :: Complete.")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_086_write_issue_update :: Failed :: {str(err)}")
            assert False, err

    def test_900_cleanup_data_hub(self):
        try:
            log_to_console(__name__, "Info", "test_900_cleanup_data_hub :: Starting.")
            sql = """
delete from DATA_HUB.Issue                              where publicationcode   in (select publicationcode
    from DATA_HUB.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'));
delete from DATA_HUB.Subscription                       where subscriptioncode  in (
    'PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR');
delete from DATA_HUB.Publication                        where PublicationCode   in (
    'PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR');
delete from DATA_HUB.Subscriber                         where subscribercode    in ('SUBR01' , 'SUBR02');
delete from DATA_HUB.Publisher                          where publishercode     in ('PUBR01','PUBR02');
delete from DATA_HUB.Contact                            where ContactName       in (
    'PUB_Contact_Test01','PUB_Contact_Test02','SUB_Contact_Test01','SUB_Contact_Test02');
"""
            self.sf_conn.execute_string(sql)
            self.sf_conn.commit()
            log_to_console(__name__, "Info", f"test_900_cleanup_data_hub :: Complete. :: {sql}")
        except Exception as err:
            log_to_console(__name__, "Error", f"test_900_cleanup_data_hub :: Failed :: {str(err)}")
            assert False, err


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  11/01/2023  Initial Iteration
ffortunato  01/16/2024  Pipeline
ffortunato  02/26/2024  Broken. Can't get a secret from unittest :-|
ffortunato  11/04/2024  + test_030_cleanup_and_prep_data_hub
                        + test_040_dh_class_issue_insert
dliu        12/04/2024  + test_050_dh_class_current publication
ffortunato  2026-04-20  o shared setUpClass/tearDownClass (single connection)
                        o renamed class to DataHubIntegrationTest
                        o fixed set_publication_code assignment bug in test_040
                        o fixed double insert_new_issue call in test_040
                        o fixed + err (TypeError) in test_050, test_900
                        o fixed Error log level in except blocks
                        o parameterized verification query in test_040
                        + test_060_context_manager
                        + test_070_update_issue
                        + test_080_is_issue_absent

*******************************************************************************
"""
