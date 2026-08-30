"""
*******************************************************************************
File: data_hub_example.py

Purpose: Comprehensive examples showing how to use the DataHub class to interact
with the DataHub database for managing publications and issues.

Dependencies/Helpful Notes:
    - Demonstrates initialization with AWS secret key
    - Shows how to get publication lists using various parameters
    - Demonstrates setting publication codes and working with issues
    - Shows inserting and updating issues
    - Demonstrates checking if issues are absent
    - Examples cover common workflows and best practices

Usage:
    Before running, ensure you have:
    1. AWS credentials configured
    2. Access to the appropriate AWS Secrets Manager secret
    3. Database permissions for the target environment

    Note: Test data is automatically set up at the beginning and cleaned up
    at the end of the examples. The setup_test_data() and cleanup_test_data()
    functions handle this automatically.

Example:
    python data_hub_example.py
*******************************************************************************
"""

from eimutils.data_hub import DataHub
from eimutils.delogging import log_to_console
from datetime import datetime
import os


def setup_test_data(dh):
    """
    Set up test data in the database for examples.
    This function creates test publishers, publications, contacts, and issues.

    :param dh: DataHub instance with active database connection
    """
    log_to_console(__name__, "Info", "Setting up test data...")

    sql = """
-- Clean up any existing test data first
delete from DATA_HUB.Issue where publicationcode in (
    select publicationcode from DATA_HUB.publication
    where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')
);
delete from DATA_HUB.Subscription where subscriptioncode in (
    'PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT',
    'PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG',
    'PUBR02-SUBR02-PUBN03-COUR'
);
delete from DATA_HUB.Publication where PublicationCode in (
    'PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'
);
delete from DATA_HUB.Subscriber where subscribercode in ('SUBR01', 'SUBR02');
delete from DATA_HUB.Publisher where publishercode in ('PUBR01','PUBR02');
delete from DATA_HUB.Contact where ContactName in (
    'PUB_Contact_Test01','PUB_Contact_Test02',
    'SUB_Contact_Test01','SUB_Contact_Test02'
);

-- Insert Contacts
insert into data_hub.contact (
    CompanyName, ContactName, Tier, Email, createdby, createddtm
) VALUES
    ('CO_Test_01', 'PUB_Contact_Test01', '1',
     'PUB_Contact_Test01@myaddress.com', 'UnitTest', CURRENT_DATE),
    ('CO_Test_01', 'PUB_Contact_Test02', '1',
     'PUB_Contact_Test02@myaddress.com', 'UnitTest', CURRENT_DATE),
    ('CO_Test_01', 'SUB_Contact_Test01', '1',
     'SUB_Contact_Test01@myaddress.com', 'UnitTest', CURRENT_DATE),
    ('CO_Test_01', 'SUB_Contact_Test02', '1',
     'SUB_Contact_Test02@myaddress.com', 'UnitTest', CURRENT_DATE);

-- Insert Publishers
INSERT INTO DATA_HUB.Publisher (
    PublisherCode, ContactId, PublisherName, PublisherDesc,
    InterfaceCode, CreatedBy, CREATEDDTM
) VALUES
    ('PUBR02', -1, '02 Test Publisher', 'Second Test Publisher',
     'TBL', 'data_hub_example', CURRENT_DATE),
    ('PUBR01', -1, '01 Test Publisher', 'First Test Publisher',
     'TBL', 'data_hub_example', CURRENT_DATE);

-- Insert Publications
INSERT INTO DATA_HUB.PUBLICATION(
    PublisherCode, PublicationCode, PublicationName, PublicationDesc,
    SrcPublicationCode, SrcPublicationName, PublicationEntity,
    PUBLICATIONBUCKET, INTERVALCODE, INTERVALLENGTH, SLATIME,
    NextExecutionDtm, CreatedBy, CreatedDtm
) VALUES
    ('PUBR01', 'PUBN01-ACCT', 'Test Account Dim Feed', '',
     '', 'PUBN02-ACCT', '', 'Unknown', 'DY', 1, '10:00',
     '2024-04-17 15:41:38.29', 'data hub example', current_date),
    ('PUBR01', 'PUBN02-ASSG', 'Test Assignment Dim Feed', '',
     '', 'PUBN02-ASSG', '', 'Unknown', 'DY', 1, '10:00',
     '2024-04-17 15:41:38.29', 'data hub example', current_date),
    ('PUBR02', 'PUBN03-COUR', 'Test Course Dim Feed', '',
     '', 'PUBN02-COUR', '', 'Unknown', 'DY', 1, '10:00',
     '2024-04-17 15:41:38.29', 'data hub example', current_date);

-- Insert Issues
INSERT INTO DATA_HUB.ISSUE (
    PublicationCode, StatusCode, ReportDate, SrcDFPublisherId,
    SrcDFPublicationId, SrcDFIssueId, SrcIssueName, SrcDFCreatedDate,
    DataLakePath, IssueName, PublicationSeq, DailyPublicationSeq,
    FirstRecordSeq, LastRecordSeq, FirstRecordChecksum, LastRecordChecksum,
    PeriodStartTime, PeriodEndTime, PeriodStartTimeUTC, PeriodEndTimeUTC,
    IssueConsumedDate, RecordCount, RetryCount, ETLExecutionId,
    CreatedBy, CreatedDtm, ModifiedBy, ModifiedDtm
) VALUES
    ('PUBN01-ACCT', 'IC', '1900-01-01', -1, -1, -1, 'Account.csv',
     '1900-01-01', '/internal/pubr01/account/', '19000101_Account.csv',
     -1, -1, -1, -1, 'N/A', 'N/A', '1900-01-01', '1900-01-01',
     '1900-01-01', '1900-01-01', '1900-01-01', -1, -1, -1,
     CURRENT_USER, CURRENT_TIMESTAMP, CURRENT_USER, CURRENT_TIMESTAMP),
    ('PUBN02-ASSG', 'IC', '1900-01-01', -1, -1, -1, 'Assignment.csv',
     '1900-01-01', '/internal/pubr01/assignment/', '19000101_Assignment.csv',
     -1, -1, -1, -1, 'N/A', 'N/A', '1900-01-01', '1900-01-01',
     '1900-01-01', '1900-01-01', '1900-01-01', -1, -1, -1,
     CURRENT_USER, CURRENT_TIMESTAMP, CURRENT_USER, CURRENT_TIMESTAMP),
    ('PUBN03-COUR', 'IC', '1900-01-01', -1, -1, -1, 'Course.csv',
     '1900-01-01', '/internal/pubr02/course/', '19000101_Course.csv',
     -1, -1, -1, -1, 'N/A', 'N/A', '1900-01-01', '1900-01-01',
     '1900-01-01', '1900-01-01', '1900-01-01', -1, -1, -1,
     CURRENT_USER, CURRENT_TIMESTAMP, CURRENT_USER, CURRENT_TIMESTAMP);
"""

    try:
        dh.db_connection.execute_string(sql)
        dh.db_connection.commit()
        log_to_console(__name__, "Info", "Test data setup completed successfully")
    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to setup test data: {err}")
        raise


def cleanup_test_data(dh):
    """
    Clean up test data from the database after examples.
    This function removes all test publishers, publications, contacts, and issues.

    :param dh: DataHub instance with active database connection
    """
    log_to_console(__name__, "Info", "Cleaning up test data...")

    sql = """
delete from DATA_HUB.Issue where publicationcode in (
    select publicationcode from DATA_HUB.publication
    where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')
);
delete from DATA_HUB.Subscription where subscriptioncode in (
    'PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT',
    'PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG',
    'PUBR02-SUBR02-PUBN03-COUR'
);
delete from DATA_HUB.Publication where PublicationCode in (
    'PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'
);
delete from DATA_HUB.Subscriber where subscribercode in ('SUBR01', 'SUBR02');
delete from DATA_HUB.Publisher where publishercode in ('PUBR01','PUBR02');
delete from DATA_HUB.Contact where ContactName in (
    'PUB_Contact_Test01','PUB_Contact_Test02',
    'SUB_Contact_Test01','SUB_Contact_Test02'
);
"""

    try:
        dh.db_connection.execute_string(sql)
        dh.db_connection.commit()
        log_to_console(__name__, "Info", "Test data cleanup completed successfully")
    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to cleanup test data: {err}")
        raise


def example_initialize_datahub():
    """
    Example 1: Initialize DataHub class with AWS secret key and environment.
    This is the first step in using the DataHub class.
    """
    log_to_console(__name__, "Info", "=== Example 1: Initialize DataHub ===")

    # Set up environment variables (or use your actual secret ARN)
    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        # Initialize DataHub instance
        dh = DataHub(secret_key=secret_key, env=env)

        log_to_console(__name__, "Info", "DataHub initialized successfully")
        log_to_console(__name__, "Info", f"Database: {dh.database}")
        log_to_console(__name__, "Info", f"Environment: {env}")

        # Clean up connection
        del dh

    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to initialize DataHub: {err}")
        raise


def example_get_publication_list_by_publisher():
    """
    Example 2: Get publication list by PublisherCode.
    This is the most common way to retrieve publications.
    """
    log_to_console(
        __name__, "Info", "=== Example 2: Get Publication List by Publisher ==="
    )

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # Get publications for a specific publisher
        params = {
            "PublisherCode": "PUBR01",
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }

        response = dh.get_publication_list(params)

        if response["Status"] == "Success":
            log_to_console(
                __name__, "Info", f"Found {len(dh.publication_list)} publications"
            )
            log_to_console(
                __name__, "Info", f"Current publication code: {dh.publication_code}"
            )
            log_to_console(
                __name__, "Info", f"Current publication index: {dh.publication_idx}"
            )

            # Display publication details
            if not dh.publication_list.empty:
                for idx, row in dh.publication_list.iterrows():
                    pub_code = row.get("PUBLICATIONCODE", "N/A")
                    pub_name = row.get("PUBLICATIONNAME", "N/A")
                    log_to_console(
                        __name__,
                        "Info",
                        f"  Publication {idx}: {pub_code} - {pub_name}",
                    )
        else:
            error_msg = response.get("Message", "Unknown error")
            log_to_console(
                __name__, "Warning", f"Failed to get publication list: {error_msg}"
            )

        del dh

    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to get publication list: {err}")
        raise


def example_set_publication_code():
    """
    Example 3: Set a specific publication code and get current publication details.
    This allows you to switch between publications in the list.
    """
    log_to_console(__name__, "Info", "=== Example 3: Set Publication Code ===")

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # First, get the publication list
        params = {
            "PublisherCode": "PUBR01",
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }
        dh.get_publication_list(params)

        # Get the current publication code (defaults to first in list)
        initial_code = dh.get_publication_code()
        log_to_console(__name__, "Info", f"Initial publication code: {initial_code}")

        # Set a specific publication code
        target_code = "PUBN01-ACCT"
        dh.set_publication_code(target_code)
        log_to_console(__name__, "Info", f"Set publication code to: {target_code}")

        # Get current publication details
        current_pub = dh.get_current_publication()
        if current_pub:
            pub_name = current_pub.get("PUBLICATIONNAME", "N/A")
            pub_code = current_pub.get("PUBLICATIONCODE", "N/A")
            log_to_console(__name__, "Info", f"Current publication name: {pub_name}")
            log_to_console(
                __name__, "Info", f"Current publication code: {pub_code}"
            )

        # Get publication index
        pub_idx = dh.get_publication_idx()
        log_to_console(__name__, "Info", f"Publication index: {pub_idx}")

        del dh

    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to set publication code: {err}")
        raise


def example_insert_new_issue():
    """
    Example 4: Insert a new issue into the database.
    This demonstrates the workflow for creating a new issue record.
    """
    log_to_console(__name__, "Info", "=== Example 4: Insert New Issue ===")

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # Get publication list
        params = {
            "PublisherCode": "PUBR01",
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }
        dh.get_publication_list(params)

        # Set the publication code
        dh.set_publication_code("PUBN01-ACCT")

        # Prepare issue data
        current_date = params["CurrentDate"]
        issue_data = {
            "IssueName": "Account_20241001.csv",
            "SrcIssueName": "Account.csv",
            "StatusCode": "IC",  # Issue Created
            "ETLExecutionId": "example_insert_new_issue",
            "ReportDate": current_date,
            "PeriodStartTime": current_date,
            "PeriodEndTime": current_date,
            "PeriodStartTimeUTC": f"{current_date} +0000",
            "PeriodEndTimeUTC": f"{current_date} +0000",
            "DataLakePath": "/internal/pubr01/account/",
            "RecordCount": 0,
            "RetryCount": 0,
        }

        # Set issue values in the class
        dh.set_issue_val(issue_data)

        # Insert the new issue
        response = dh.insert_new_issue()

        if response["Status"] == "Success":
            # Get the newly created IssueId
            issue_id = dh.get_issue_id()
            log_to_console(
                __name__,
                "Info",
                f"Successfully inserted new issue with IssueId: {issue_id}",
            )
        else:
            log_to_console(__name__, "Error", f"Failed to insert issue: {response}")

        del dh

    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to insert new issue: {err}")
        raise


def example_update_issue():
    """
    Example 5: Update an existing issue in the database.
    This demonstrates how to modify issue records after they've been created.
    """
    log_to_console(__name__, "Info", "=== Example 5: Update Issue ===")

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # Get publication list
        params = {
            "PublisherCode": "PUBR01",
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }
        dh.get_publication_list(params)

        # Set the publication code
        dh.set_publication_code("PUBN01-ACCT")

        # Get current issue ID (assuming issue exists)
        issue_id = dh.get_issue_id()
        log_to_console(__name__, "Info", f"Current issue ID: {issue_id}")

        if issue_id == -1:
            log_to_console(
                __name__, "Warning", "No issue found. Creating a new issue first..."
            )
            # Create a new issue first
            issue_data = {
                "IssueName": "Account_20241001.csv",
                "SrcIssueName": "Account.csv",
                "StatusCode": "IC",
                "ETLExecutionId": "example_update_issue",
                "ReportDate": params["CurrentDate"],
                "PeriodStartTime": params["CurrentDate"],
                "PeriodEndTime": params["CurrentDate"],
                "PeriodStartTimeUTC": f"{params['CurrentDate']} +0000",
                "PeriodEndTimeUTC": f"{params['CurrentDate']} +0000",
                "DataLakePath": "/internal/pubr01/account/",
            }
            dh.set_issue_val(issue_data)
            dh.insert_new_issue()
            issue_id = dh.get_issue_id()

        # Update issue with new values
        update_data = {
            "StatusCode": "PR",  # Processing
            "RecordCount": 1500,
            "FirstRecordSeq": 1,
            "LastRecordSeq": 1500,
            "ETLExecutionId": "example_update_issue_updated",
        }

        response = dh.update_issue(update_data)

        if response["Status"] == "Success":
            log_to_console(__name__, "Info", f"Successfully updated issue {issue_id}")
            log_to_console(
                __name__, "Info", f"Updated status code: {update_data['StatusCode']}"
            )
            log_to_console(
                __name__, "Info", f"Updated record count: {update_data['RecordCount']}"
            )
        else:
            log_to_console(__name__, "Error", f"Failed to update issue: {response}")

        del dh

    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to update issue: {err}")
        raise


def example_check_issue_absent():
    """
    Example 6: Check if an issue is absent (hasn't been processed yet).
    This is useful for preventing duplicate processing.
    """
    log_to_console(__name__, "Info", "=== Example 6: Check if Issue is Absent ===")

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # Check if a file has been processed
        file_name = "Account_20241001.csv"
        is_absent = dh.is_issue_absent(file_name)

        if is_absent:
            log_to_console(
                __name__, "Info", f"File '{file_name}' is absent - should be processed"
            )
        else:
            log_to_console(
                __name__, "Info", f"File '{file_name}' already exists - skip processing"
            )

        # Check another file
        file_name2 = "NewFile_20241002.csv"
        is_absent2 = dh.is_issue_absent(file_name2)
        log_to_console(
            __name__,
            "Info",
            f"File '{file_name2}' is {'absent' if is_absent2 else 'already processed'}",
        )

        del dh

    except Exception as err:
        log_to_console(__name__, "Error", f"Failed to check issue absence: {err}")
        raise


def example_get_publication_list_by_filename():
    """
    Example 7: Get publication list by FileName.
    This is useful when you have a file and need to find its associated publication.
    """
    log_to_console(
        __name__, "Info", "=== Example 7: Get Publication List by FileName ==="
    )

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # Get publication by file name
        params = {
            "FileName": "Account.csv",
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }

        response = dh.get_publication_list(params)

        if response["Status"] == "Success":
            log_to_console(
                __name__, "Info", f"Found publication for file: {params['FileName']}"
            )
            log_to_console(__name__, "Info", f"Publication code: {dh.publication_code}")
        else:
            log_to_console(
                __name__,
                "Warning",
                f"No publication found for file: {params['FileName']}",
            )

        del dh

    except Exception as err:
        log_to_console(
            __name__, "Error", f"Failed to get publication by filename: {err}"
        )
        raise


def example_get_publication_list_by_issue_id():
    """
    Example 8: Get publication list by IssueId.
    This is useful when you have an issue ID and need to retrieve its publication details.
    """
    log_to_console(
        __name__, "Info", "=== Example 8: Get Publication List by IssueId ==="
    )

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        dh = DataHub(secret_key=secret_key, env=env)

        # Get publication by issue ID (example ID - replace with actual ID)
        params = {
            "IssueId": 1,  # Replace with actual issue ID
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }

        response = dh.get_publication_list(params)

        if response["Status"] == "Success":
            log_to_console(
                __name__, "Info", f"Found publication for IssueId: {params['IssueId']}"
            )
            log_to_console(__name__, "Info", f"Publication code: {dh.publication_code}")
        else:
            log_to_console(
                __name__,
                "Warning",
                f"No publication found for IssueId: {params['IssueId']}",
            )

        del dh

    except Exception as err:
        log_to_console(
            __name__, "Error", f"Failed to get publication by issue ID: {err}"
        )
        raise


def example_complete_workflow():
    """
    Example 9: Complete workflow - from checking if issue exists to inserting/updating.
    This demonstrates a typical ETL workflow using the DataHub class.
    """
    log_to_console(__name__, "Info", "=== Example 9: Complete Workflow ===")

    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"

    try:
        # Step 1: Initialize DataHub
        dh = DataHub(secret_key=secret_key, env=env)
        log_to_console(__name__, "Info", "Step 1: DataHub initialized")

        # Step 2: Get publication list
        params = {
            "PublisherCode": "PUBR01",
            "CurrentDate": f"{datetime.now():%Y-%m-%d %H:%M:%S.%f}",
        }
        response = dh.get_publication_list(params)
        if response["Status"] != "Success":
            raise Exception("Failed to get publication list")
        log_to_console(__name__, "Info", "Step 2: Publication list retrieved")

        # Step 3: Set publication code
        dh.set_publication_code("PUBN01-ACCT")
        log_to_console(
            __name__, "Info", f"Step 3: Set publication code to {dh.publication_code}"
        )

        # Step 4: Check if issue already exists
        file_name = "Account_20241001.csv"
        is_absent = dh.is_issue_absent(file_name)
        status_msg = "absent" if is_absent else "already processed"
        log_to_console(__name__, "Info", f"Step 4: Issue check - file is {status_msg}")

        # Step 5: Prepare issue data
        issue_data = {
            "IssueName": file_name,
            "SrcIssueName": "Account.csv",
            "StatusCode": "IC",
            "ETLExecutionId": "example_complete_workflow",
            "ReportDate": params["CurrentDate"],
            "PeriodStartTime": params["CurrentDate"],
            "PeriodEndTime": params["CurrentDate"],
            "PeriodStartTimeUTC": f"{params['CurrentDate']} +0000",
            "PeriodEndTimeUTC": f"{params['CurrentDate']} +0000",
            "DataLakePath": "/internal/pubr01/account/",
            "RecordCount": 0,
        }
        dh.set_issue_val(issue_data)
        log_to_console(__name__, "Info", "Step 5: Issue data prepared")

        # Step 6: Insert or update issue
        if is_absent:
            response = dh.insert_new_issue()
            if response["Status"] == "Success":
                issue_id = dh.get_issue_id()
                log_to_console(
                    __name__, "Info", f"Step 6: New issue inserted with ID: {issue_id}"
                )
        else:
            # Update existing issue
            update_data = {
                "StatusCode": "PR",
                "RecordCount": 1500,
            }
            response = dh.update_issue(update_data)
            if response["Status"] == "Success":
                issue_id = dh.get_issue_id()
                log_to_console(
                    __name__, "Info", f"Step 6: Existing issue updated (ID: {issue_id})"
                )

        # Step 7: Get final issue details
        final_issue_id = dh.get_issue_id()
        current_pub = dh.get_current_publication()
        log_to_console(__name__, "Info", f"Step 7: Final issue ID: {final_issue_id}")
        log_to_console(
            __name__,
            "Info",
            f"Step 7: Publication: {current_pub.get('PUBLICATIONNAME', 'N/A')}",
        )

        del dh
        log_to_console(__name__, "Info", "Workflow completed successfully!")

    except Exception as err:
        log_to_console(__name__, "Error", f"Workflow failed: {err}")
        raise


def main():
    """
    Main function to run all examples.
    Comment out examples you don't want to run.
    This function sets up test data at the beginning and cleans it up at the end.
    """
    log_to_console(__name__, "Info", "=" * 60)
    log_to_console(__name__, "Info", "DataHub Class Examples")
    log_to_console(__name__, "Info", "=" * 60)

    # Initialize DataHub for setup/cleanup
    secret_key = os.environ.get(
        "AWS_SECRET_ARN_SF_CONN",
        "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_myorg_dev_care_keys-OGR2iI",
    )
    env = "dev"
    dh_setup = None

    try:
        # Set up test data before running examples
        dh_setup = DataHub(secret_key=secret_key, env=env)
        setup_test_data(dh_setup)
        # Keep dh_setup for cleanup in finally block

        # Basic examples
        example_initialize_datahub()

        example_get_publication_list_by_publisher()

        example_set_publication_code()

        # Issue management examples
        # These examples now have test data available
        example_insert_new_issue()

        example_update_issue()

        example_check_issue_absent()

        # Advanced examples
        example_get_publication_list_by_filename()

        # example_get_publication_list_by_issue_id()

        # Complete workflow
        example_complete_workflow()

        log_to_console(__name__, "Info", "=" * 60)
        log_to_console(__name__, "Info", "All examples completed!")
        log_to_console(__name__, "Info", "=" * 60)

    except Exception as err:
        log_to_console(__name__, "Error", f"Examples failed: {err}")
        raise
    finally:
        # Clean up test data after all examples
        try:
            if "dh_setup" in locals() and dh_setup is not None:
                cleanup_test_data(dh_setup)
                del dh_setup
            else:
                dh_cleanup = DataHub(secret_key=secret_key, env=env)
                cleanup_test_data(dh_cleanup)
                del dh_cleanup
            log_to_console(__name__, "Info", "Test data cleanup completed")
        except Exception as cleanup_err:
            log_to_console(
                __name__, "Warning", f"Failed to cleanup test data: {cleanup_err}"
            )


if __name__ == "__main__":
    main()
