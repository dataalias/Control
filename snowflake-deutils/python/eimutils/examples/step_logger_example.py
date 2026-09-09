"""
*******************************************************************************
File: step_logger_timing_example.py

Purpose: Comprehensive examples showing how to use the enhanced StepLogger class.

Dependencies/Helpful Notes:
    - Demonstrates the 4-method interface: __init__, start_step, log_step, close
    - Shows timing between start_step and log_step
    - Demonstrates TOTAL_DURATION and TOTAL_COUNT automatic tracking
    - Shows custom_attributes support on all methods
    - Demonstrates standardized step descriptions (MessageType, StepNumber, Operation, Description)
    - Examples cover success/failure scenarios, totals tracking, and best practices
*******************************************************************************
"""

from eimutils.step_logger import StepLogger
from eimutils.delogging import log_to_console
import uuid
import time
import random


def example_basic_usage():
    """
    Basic example showing the simple 4-method StepLogger usage with new features:
    - TOTAL_DURATION and TOTAL_COUNT automatic tracking
    - custom_attributes support on all methods
    - Standardized step descriptions
    """
    log_to_console(__name__, "Info", "=== Basic Usage Example (Enhanced) ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Enhanced_Basic_Example",
        process_type="ETL",
        process_description="Enhanced ETL process with custom attributes and totals tracking"
    )

    try:
        # Step 1: Start timing with custom attributes
        logger.start_step(
            "Data_Extraction",
            operation="select",
            custom_attributes={
                "data_source": "postgresql_db",
                "extraction_type": "incremental",
            },
        )
        log_to_console(__name__, "Info", "Extracting data from source...")
        x = [1, 2, 3]
        for i in x:

            logger.start_step(
                "Loop Data_Extraction",
                operation="select",
                custom_attributes={
                    "data_source": "postgresql_db",
                    "extraction_type": "incremental",
                }
            )

            time.sleep(i)

            step_id = logger.log_step(
                status="SUCCESS",
                description="Successfully extracted customer records from PostgreSQL",
                record_count=1000,
                custom_attributes={
                    "lccop_count": i,
                    "extraction_time_ms": 1500,
                }
            )

        step_id = logger.log_step(
            status="SUCCESS",
            description="Successfully extracted customer records from PostgreSQL",
            record_count=1000,
            custom_attributes={
                "rows_processed": 1000,
                "extraction_time_ms": 1500,
                "database_server": "prod-db-01",
            },
        )
        log_to_console(__name__, "Info", f"Step completed with ID: {step_id}")
        log_to_console(
            __name__,
            "Info",
            f"Running totals - Duration: {logger.TOTAL_DURATION}s, Count: {logger.TOTAL_COUNT}",
        )

        # Step 2: Validation with different custom attributes
        logger.start_step(
            "Data_Validation",
            custom_attributes={
                "validation_rules": ["not_null", "data_types", "business_rules"],
                "validation_mode": "strict",
            },
        )
        log_to_console(__name__, "Info", "Validating extracted data...")
        time.sleep(1.8)

        logger.log_step(
            status="SUCCESS",
            description="All validation rules passed successfully",
            record_count=1000,
            custom_attributes={
                "validation_errors": 0,
                "validation_warnings": 5,
                "data_quality_score": 98.5,
            },
        )

        log_to_console(
            __name__,
            "Info",
            f"Final totals - Duration: {logger.TOTAL_DURATION}s, Count: {logger.TOTAL_COUNT}",
        )
    except Exception as e:
        logger.log_step(
            status="FAILED",
            description=f"Step failed: {str(e)}",
            custom_attributes={"error": str(e)}
        )
        raise
    finally:
        logger.close(
            custom_attributes={
                "completion_status": "success",
                "total_steps_executed": 2,
                "process_rating": "excellent",
            }
        )
        log_to_console(__name__, "Info", "Enhanced basic example completed")


def example_etl_pipeline():
    """
    Comprehensive ETL pipeline example demonstrating:
    - Custom attributes throughout the process
    - TOTAL_DURATION and TOTAL_COUNT accumulation
    - Complex step descriptions with metadata
    """
    log_to_console(__name__, "Info", "=== Enhanced ETL Pipeline Example ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Customer_Data_ETL_Enhanced",
        process_type="ETL",
        process_description="Full ETL pipeline for customer data processing with enhanced tracking",
        custom_attributes={
            "pipeline_version": "3.1.2",
            "data_retention_days": 90,
            "compliance_level": "GDPR",
            "business_owner": "customer_analytics_team",
        },
    )

    try:
        # Step 1: Extract from source system with enhanced tracking
        logger.start_step(
            "Extract_Customer_Data",
            custom_attributes={
                "connection_type": "postgresql",
                "connection_pool_size": 10,
                "query_timeout_seconds": 30,
                "source_schema": "public",
            },
        )
        log_to_console(__name__, "Info", "Connecting to source database...")
        time.sleep(2.0)  # Simulate database connection and extraction

        extracted_count = 15000
        logger.log_step(
            status="SUCCESS",
            description=f"Successfully extracted {extracted_count} customer records from source DB",
            db_name="CUSTOMER_SOURCE_DB",
            record_count=extracted_count,
            custom_attributes={
                "source_table": "customers",
                "extraction_method": "incremental",
                "date_range": "2024-01-01 to 2024-01-31",
                "query_execution_time_ms": 1800,
                "memory_usage_mb": 45,
                "network_latency_ms": 12,
            },
        )

        log_to_console(
            __name__,
            "Info",
            f"After extraction - Total Duration: {logger.TOTAL_DURATION}s, Total Records: {logger.TOTAL_COUNT}",
        )

        # Step 2: Data cleansing and validation
        logger.start_step(
            "Cleanse_Customer_Data",
            custom_attributes={
                "cleansing_engine": "pandas_profiler",
                "validation_framework": "great_expectations",
                "data_quality_threshold": 95.0,
            },
        )
        log_to_console(__name__, "Info", "Cleansing and validating customer data...")
        time.sleep(1.8)

        cleaned_count = 14500  # Some records may be filtered out
        logger.log_step(
            status="SUCCESS",
            description=(
                f"Data cleansing completed. {cleaned_count} valid records, "
                f"{extracted_count - cleaned_count} filtered out"
            ),
            record_count=cleaned_count,
            custom_attributes={
                "validation_rules": ["email_format", "phone_number", "required_fields"],
                "records_filtered": extracted_count - cleaned_count,
                "filter_reasons": ["invalid_email", "missing_required_fields"],
                "data_quality_score": 96.7,
                "cleansing_duration_ms": 1800,
                "duplicates_removed": 123,
            },
        )

        log_to_console(
            __name__,
            "Info",
            f"After cleansing - Total Duration: {logger.TOTAL_DURATION}s, Total Records: {logger.TOTAL_COUNT}",
        )

        # Step 3: Data transformation
        logger.start_step(
            "Transform_Customer_Data",
            custom_attributes={
                "transformation_engine": "spark_sql",
                "spark_executors": 4,
                "transformation_rules_version": "2.3.1",
            },
        )
        log_to_console(__name__, "Info", "Applying business transformations...")
        time.sleep(2.5)

        logger.log_step(
            status="SUCCESS",
            description="Applied standardization, enrichment, and business rule transformations",
            record_count=cleaned_count,
            custom_attributes={
                "transformations": [
                    "address_standardization",
                    "name_case_formatting",
                    "date_normalization",
                ],
                "enrichment": [
                    "geocoding",
                    "demographic_data",
                    "segment_classification",
                ],
                "transformation_time_ms": 2400,
                "cpu_utilization_percent": 78,
                "memory_peak_mb": 892,
                "geocoding_success_rate": 94.2,
            },
        )

        log_to_console(
            __name__,
            "Info",
            f"After transformation - Total Duration: {logger.TOTAL_DURATION}s, Total Records: {logger.TOTAL_COUNT}",
        )

        # Step 4: Load to data warehouse
        logger.start_step(
            "Load_To_Warehouse",
            custom_attributes={
                "warehouse_type": "snowflake",
                "warehouse_size": "large",
                "bulk_load_method": "snowpipe",
                "target_schema": "analytics",
            },
        )
        log_to_console(__name__, "Info", "Loading data to data warehouse...")
        time.sleep(1.2)

        logger.log_step(
            status="SUCCESS",
            description=f"Successfully loaded {cleaned_count} customer records to data warehouse",
            db_name="CUSTOMER_DW",
            record_count=cleaned_count,
            custom_attributes={
                "target_table": "dim_customer",
                "load_method": "upsert",
                "partition_key": "customer_segment",
                "load_time_ms": 1100,
                "warehouse_credits_used": 0.75,
                "compression_ratio": 3.2,
                "data_size_mb": 45,
            },
        )

        log_to_console(
            __name__,
            "Info",
            f"Final ETL totals - Total Duration: {logger.TOTAL_DURATION}s, Total Records: {logger.TOTAL_COUNT}",
        )
        log_to_console(__name__, "Info", "Enhanced ETL Pipeline completed successfully")

    finally:
        logger.close(
            custom_attributes={
                "pipeline_status": "completed_successfully",
                "total_processing_time_seconds": logger.TOTAL_DURATION,
                "total_records_processed": logger.TOTAL_COUNT,
                "data_quality_rating": "excellent",
                "cost_optimization_achieved": True,
                "next_run_scheduled": "2024-02-01 06:00:00",
            }
        )


def example_totals_tracking():
    """
    Dedicated example demonstrating TOTAL_DURATION and TOTAL_COUNT automatic tracking.
    Shows how totals accumulate with each step and are used in the final process step.
    """
    log_to_console(__name__, "Info", "=== Totals Tracking Demonstration ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Totals_Tracking_Demo",
        process_type="DEMONSTRATION",
        process_description="Demonstration of automatic TOTAL_DURATION and TOTAL_COUNT tracking",
        custom_attributes={
            "demo_purpose": "totals_tracking",
            "tracking_version": "1.0",
        },
    )

    try:
        log_to_console(
            __name__,
            "Info",
            f"Initial state - Total Duration: {logger.TOTAL_DURATION}s, Total Count: {logger.TOTAL_COUNT}",
        )

        # Step 1: Process batch 1
        logger.start_step("Process_Batch_1")
        time.sleep(1.2)  # 1.2 seconds
        logger.log_step("SUCCESS", "Processed first batch", record_count=500)
        log_to_console(
            __name__,
            "Info",
            f"After Step 1 - Total Duration: {logger.TOTAL_DURATION}s, Total Count: {logger.TOTAL_COUNT}",
        )

        # Step 2: Process batch 2
        logger.start_step("Process_Batch_2")
        time.sleep(0.8)  # 0.8 seconds
        logger.log_step("SUCCESS", "Processed second batch", record_count=750)
        log_to_console(
            __name__,
            "Info",
            f"After Step 2 - Total Duration: {logger.TOTAL_DURATION}s, Total Count: {logger.TOTAL_COUNT}",
        )

        # Step 3: Process batch 3
        logger.start_step("Process_Batch_3")
        time.sleep(1.5)  # 1.5 seconds
        logger.log_step("SUCCESS", "Processed third batch", record_count=300)
        log_to_console(
            __name__,
            "Info",
            f"After Step 3 - Total Duration: {logger.TOTAL_DURATION}s, Total Count: {logger.TOTAL_COUNT}",
        )

        # Step 4: Validation (no record count)
        logger.start_step("Validate_Results")
        time.sleep(0.5)  # 0.5 seconds
        logger.log_step(
            "SUCCESS", "Validation completed"
        )  # No record_count - shouldn't affect TOTAL_COUNT
        log_to_console(
            __name__,
            "Info",
            f"After Step 4 - Total Duration: {logger.TOTAL_DURATION}s, Total Count: {logger.TOTAL_COUNT}",
        )

        log_to_console(__name__, "Info", "Expected totals: ~4s duration, 1550 records")
        log_to_console(
            __name__,
            "Info",
            f"Actual totals: {logger.TOTAL_DURATION}s duration, {logger.TOTAL_COUNT} records",
        )

    finally:
        # The close method will use TOTAL_DURATION and TOTAL_COUNT for the final step
        logger.close(
            custom_attributes={
                "demonstration_complete": True,
                "expected_duration": "~4_seconds",
                "expected_count": 1550,
                "totals_validation": "passed",
            }
        )
        log_to_console(__name__, "Info", "Totals tracking demonstration completed")


def example_error_handling():
    """
    Example demonstrating error handling and failed step logging with enhanced features.
    """
    log_to_console(__name__, "Info", "=== Error Handling Example ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Error_Handling_Demo",
        process_type="DATA_PROCESSING",
    )

    try:
        # Step 1: Successful step
        logger.start_step(
            "Data_Preparation",
            operation="select",
            custom_attributes={
                "data_source": "postgresql_db",
                "extraction_type": "incremental",
            },
        )
        log_to_console(__name__, "Info", "Preparing data for processing...")
        time.sleep(1.0)
        logger.log_step(
            "SUCCESS", "Data preparation completed successfully", record_count=5000
        )

        # Step 2: Simulate a failing step
        logger.start_step("Data_Processing(shall fail)")
        log_to_console(__name__, "Info", "Processing data (this will fail)...")
        time.sleep(0.8)

        try:
            # Simulate an error condition
            x = 1 / 0
            log_to_console(__name__, "Info", f"Processing result: {x}")

        except Exception as e:
            # Log the failed step with error details
            log_to_console(
                __name__,
                "Error",
                f"===== going to log the failure to step log =====: {str(e)}",
            )
            error_msg = f"Data processing failed: {str(e)}"
            logger.log_step(
                status="FAILED",
                description=error_msg,
                record_count=0,  # No records processed due to failure
                custom_attributes={
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "failure_point": "data_validation",
                    "recovery_action": "manual_review_required",
                },
            )
            log_to_console(__name__, "Error", error_msg)

        # Step 3: Continue with next step regardless
        logger.start_step("Cleanup_Operations")
        log_to_console(__name__, "Info", "Running cleanup operations...")
        time.sleep(0.5)
        logger.log_step(
            "SUCCESS",
            "Cleanup completed",
            custom_attributes={"cleanup_type": "temporary_files"},
        )

    finally:
        logger.close()
        log_to_console(__name__, "Info", "Error handling example completed")


def example_batch_processing():
    """
    Example showing batch processing with multiple iterations.
    """
    log_to_console(__name__, "Info", "=== Batch Processing Example ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Batch_File_Processor",
        process_type="BATCH_PROCESSING",
        process_description="Process multiple data files in batches",
    )

    try:
        # Define batch files to process
        batch_files = [
            {"name": "customers_batch_1.csv", "size": 2500, "process_time": 1.2},
            {"name": "customers_batch_2.csv", "size": 3200, "process_time": 1.8},
            {"name": "customers_batch_3.csv", "size": 1800, "process_time": 0.9},
            {"name": "customers_batch_4.csv", "size": 2800, "process_time": 1.5},
        ]

        total_processed = 0

        for i, batch_file in enumerate(batch_files, 1):
            step_name = f"Process_Batch_{i}"

            logger.start_step(step_name)
            log_to_console(__name__, "Info", f"Processing {batch_file['name']}...")

            # Simulate file processing
            time.sleep(batch_file["process_time"])

            # Simulate occasional batch failures
            if (
                batch_file["size"] > 3000 and random.random() < 0.3
            ):  # 30% chance of failure for large batches
                logger.log_step(
                    status="FAILED",
                    description=(
                        f"Batch processing failed for {batch_file['name']} - "
                        f"file too large for current memory allocation"
                    ),
                    record_count=0,
                    custom_attributes={
                        "file_name": batch_file["name"],
                        "file_size_records": batch_file["size"],
                        "failure_reason": "memory_allocation_exceeded",
                        "suggested_action": "increase_batch_memory_limit",
                    },
                )
                log_to_console(
                    __name__, "Warning", f"Failed to process {batch_file['name']}"
                )
            else:
                # Successful processing
                total_processed += batch_file["size"]
                logger.log_step(
                    status="SUCCESS",
                    description=f"Successfully processed {batch_file['name']}",
                    record_count=batch_file["size"],
                    custom_attributes={
                        "file_name": batch_file["name"],
                        "file_size_records": batch_file["size"],
                        "processing_time_seconds": batch_file["process_time"],
                        "batch_number": i,
                    },
                )
                log_to_console(
                    __name__,
                    "Info",
                    f"Successfully processed {batch_file['name']} - {batch_file['size']} records",
                )

        # Final summary step
        logger.start_step("Batch_Processing_Summary")
        time.sleep(0.3)
        logger.log_step(
            status="SUCCESS",
            description=f"Batch processing completed. Total records processed: {total_processed}",
            record_count=total_processed,
            custom_attributes={
                "total_batches": len(batch_files),
                "total_records_processed": total_processed,
                "average_batch_size": (
                    total_processed / len(batch_files) if total_processed > 0 else 0
                ),
            },
        )

    finally:
        logger.close()
        log_to_console(
            __name__,
            "Info",
            f"Batch processing completed - {total_processed} total records processed",
        )


def example_data_quality_checks():
    """
    Example showing data quality validation steps.
    """
    log_to_console(__name__, "Info", "=== Data Quality Checks Example ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Data_Quality_Validation",
        process_type="QUALITY_ASSURANCE",
        process_description="Comprehensive data quality validation process",
    )

    try:
        total_records = 10000

        # Step 1: Schema validation
        logger.start_step("Schema_Validation")
        log_to_console(__name__, "Info", "Validating data schema...")
        time.sleep(0.8)

        schema_errors = random.randint(0, 5)
        if schema_errors == 0:
            logger.log_step(
                "SUCCESS",
                "Schema validation passed - all required columns present with correct data types",
                record_count=total_records,
                custom_attributes={
                    "validation_type": "schema_check",
                    "columns_validated": 25,
                    "schema_version": "v2.1",
                },
            )
        else:
            logger.log_step(
                "FAILED",
                f"Schema validation failed - {schema_errors} schema violations found",
                record_count=total_records,
                custom_attributes={
                    "validation_type": "schema_check",
                    "errors_found": schema_errors,
                    "error_types": ["missing_column", "incorrect_data_type"],
                },
            )
            return  # Exit early if schema is invalid

        # Step 2: Data completeness check
        logger.start_step("Completeness_Check")
        log_to_console(__name__, "Info", "Checking data completeness...")
        time.sleep(1.2)

        null_count = random.randint(0, 100)
        completeness_rate = ((total_records - null_count) / total_records) * 100

        if completeness_rate >= 95:
            status = "SUCCESS"
            description = f"Data completeness check passed - {completeness_rate:.2f}% completeness rate"
        else:
            status = "FAILED"
            description = (
                f"Data completeness check failed - {completeness_rate:.2f}% "
                f"completeness rate (threshold: 95%)"
            )

        logger.log_step(
            status,
            description,
            record_count=total_records,
            custom_attributes={
                "validation_type": "completeness_check",
                "null_values_found": null_count,
                "completeness_percentage": completeness_rate,
                "threshold_percentage": 95.0,
            },
        )

        # Step 3: Business rule validation
        logger.start_step("Business_Rule_Validation")
        log_to_console(__name__, "Info", "Validating business rules...")
        time.sleep(1.5)

        rule_violations = random.randint(0, 20)
        violation_rate = (rule_violations / total_records) * 100

        logger.log_step(
            "SUCCESS" if violation_rate <= 1.0 else "FAILED",
            (
                f"Business rule validation completed - {rule_violations} violations found "
                f"({violation_rate:.3f}% violation rate)"
            ),
            record_count=total_records,
            custom_attributes={
                "validation_type": "business_rules",
                "rules_checked": [
                    "date_ranges",
                    "referential_integrity",
                    "business_logic",
                ],
                "violations_found": rule_violations,
                "violation_rate_percentage": violation_rate,
                "acceptable_threshold": 1.0,
            },
        )

        # Step 4: Data profiling summary
        logger.start_step("Data_Profiling_Summary")
        log_to_console(__name__, "Info", "Generating data profiling summary...")
        time.sleep(0.6)

        logger.log_step(
            "SUCCESS",
            "Data profiling and quality assessment completed",
            record_count=total_records,
            custom_attributes={
                "profile_metrics": {
                    "total_records": total_records,
                    "unique_values": total_records - random.randint(0, 100),
                    "duplicate_records": random.randint(0, 50),
                    "data_types_distribution": {"string": 15, "integer": 8, "date": 2},
                },
                "quality_score": random.uniform(85.0, 99.5),
            },
        )

    finally:
        logger.close()
        log_to_console(__name__, "Info", "Data quality validation completed")


def example_api_integration():
    """
    Example showing API integration and external service calls.
    """
    log_to_console(__name__, "Info", "=== API Integration Example ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="External_API_Integration",
        process_type="API_INTEGRATION",
        process_description="Integration with external APIs for data enrichment",
    )

    try:
        # Step 1: API Authentication
        logger.start_step("API_Authentication")
        log_to_console(__name__, "Info", "Authenticating with external API...")
        time.sleep(0.5)
        logger.log_step(
            "SUCCESS",
            "Successfully authenticated with external API service",
            custom_attributes={
                "api_endpoint": "https://api.example.com/auth",
                "auth_method": "OAuth2",
                "token_expires_in": 3600,
            },
        )

        # Step 2: Data retrieval from API
        logger.start_step("Fetch_External_Data")
        log_to_console(__name__, "Info", "Fetching data from external API...")
        time.sleep(2.0)

        # Simulate API response variability
        api_records = random.randint(800, 1200)
        response_time = random.uniform(1.5, 3.0)

        logger.log_step(
            "SUCCESS",
            f"Successfully retrieved {api_records} records from external API",
            record_count=api_records,
            custom_attributes={
                "api_endpoint": "https://api.example.com/customers",
                "response_time_seconds": round(response_time, 2),
                "http_status": 200,
                "rate_limit_remaining": 4500,
                "pagination_used": True,
            },
        )

        # Step 3: Data mapping and transformation
        logger.start_step("Transform_API_Data")
        log_to_console(__name__, "Info", "Transforming API data to internal format...")
        time.sleep(1.3)

        # Simulate some data loss during transformation
        transformed_records = api_records - random.randint(0, 50)

        logger.log_step(
            "SUCCESS",
            f"Data transformation completed - {transformed_records} records successfully transformed",
            record_count=transformed_records,
            custom_attributes={
                "transformation_rules": [
                    "field_mapping",
                    "data_type_conversion",
                    "format_standardization",
                ],
                "source_records": api_records,
                "output_records": transformed_records,
                "transformation_loss": api_records - transformed_records,
            },
        )

        # Step 4: Data validation and storage
        logger.start_step("Validate_And_Store")
        log_to_console(__name__, "Info", "Validating and storing transformed data...")
        time.sleep(1.0)

        logger.log_step(
            "SUCCESS",
            f"Successfully validated and stored {transformed_records} records",
            db_name="ENRICHMENT_DB",
            record_count=transformed_records,
            custom_attributes={
                "validation_checks": [
                    "duplicate_check",
                    "referential_integrity",
                    "data_quality_rules",
                ],
                "storage_location": "enrichment.external_customer_data",
                "storage_format": "parquet",
            },
        )

    finally:
        logger.close()
        log_to_console(__name__, "Info", "API integration process completed")


def example_best_practices_demo():
    """
    Example demonstrating best practices for StepLogger usage.
    """
    log_to_console(__name__, "Info", "=== Best Practices Demo ===")

    etl_execution_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_pipeline_keys-yj4HJ6",
        env="DEV",
        etl_execution_id=etl_execution_id,
        process_name="Best_Practices_Demo",
        process_type="DEMONSTRATION",
        process_description="Demonstration of StepLogger best practices and patterns",
    )

    try:
        # Best Practice 1: Descriptive step names
        logger.start_step("Initialize_Database_Connections")
        log_to_console(__name__, "Info", "Initializing database connections...")
        time.sleep(0.8)
        logger.log_step(
            "SUCCESS",
            "Database connections initialized successfully",
            custom_attributes={
                "connections": ["source_db", "target_db", "audit_db"],
                "connection_pool_size": 10,
                "timeout_seconds": 30,
            },
        )

        # Best Practice 2: Include meaningful record counts
        logger.start_step("Load_Configuration_Data")
        log_to_console(__name__, "Info", "Loading configuration data...")
        time.sleep(0.5)
        config_items = 45
        logger.log_step(
            "SUCCESS",
            f"Successfully loaded {config_items} configuration items",
            record_count=config_items,
            custom_attributes={
                "config_types": [
                    "database_params",
                    "business_rules",
                    "system_settings",
                ],
                "config_version": "2024.01.15",
            },
        )

        # Best Practice 3: Comprehensive error handling with context
        logger.start_step("Execute_Complex_Calculation")
        log_to_console(__name__, "Info", "Executing complex calculations...")
        time.sleep(1.5)

        try:
            # Simulate potential calculation error
            if random.random() < 0.2:  # 20% chance of error
                raise RuntimeError("Memory allocation failed during matrix operation")

            calculated_records = 5000
            logger.log_step(
                "SUCCESS",
                f"Complex calculations completed successfully for {calculated_records} records",
                record_count=calculated_records,
                custom_attributes={
                    "calculation_type": "matrix_operations",
                    "algorithm": "sparse_matrix_multiplication",
                    "memory_usage_mb": 256,
                    "cpu_utilization_percent": 85,
                },
            )

        except Exception as e:
            logger.log_step(
                "FAILED",
                f"Complex calculation failed: {str(e)}",
                record_count=0,
                custom_attributes={
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "memory_at_failure_mb": 1024,
                    "recovery_suggestion": "increase_memory_allocation",
                    "fallback_available": True,
                },
            )
            log_to_console(__name__, "Error", f"Calculation failed: {e}")

        # Best Practice 4: Clear step completion with summary
        logger.start_step("Generate_Process_Summary")
        log_to_console(__name__, "Info", "Generating process summary...")
        time.sleep(0.4)
        logger.log_step(
            "SUCCESS",
            "Process summary generated with performance metrics and audit trail",
            custom_attributes={
                "summary_includes": [
                    "performance_metrics",
                    "error_log",
                    "data_lineage",
                    "quality_scores",
                ],
                "report_format": "json",
                "report_location": "/reports/process_summary.json",
            },
        )

        log_to_console(__name__, "Info", "Best practices demonstration completed")

    finally:
        logger.close()


if __name__ == "__main__":
    """
    Run comprehensive StepLogger examples.
    Note: These examples require proper database credentials to actually execute.
    """
    log_to_console(__name__, "Info", "StepLogger Comprehensive Examples")
    log_to_console(__name__, "Info", "=" * 60)

    log_to_console(
        __name__, "Info", "Note: These examples require proper database credentials."
    )
    log_to_console(
        __name__,
        "Info",
        "They demonstrate the simplified 4-method StepLogger interface:",
    )
    log_to_console(__name__, "Info", "  1. __init__ - Connect and log process start")
    log_to_console(__name__, "Info", "  2. start_step() - Begin step timing")
    log_to_console(
        __name__, "Info", "  3. log_step() - Log step completion with timing"
    )
    log_to_console(__name__, "Info", "  4. close() - Log process end and cleanup")
    log_to_console(__name__, "Info", "")

    # Run examples (uncomment the ones you want to execute)
    try:

        example_basic_usage()
        example_etl_pipeline()
        example_totals_tracking()  # NEW: Demonstrates TOTAL_DURATION and TOTAL_COUNT tracking
        log_to_console(__name__, "Info", "Example error handling...")
        example_error_handling()
        example_batch_processing()
        example_data_quality_checks()
        example_api_integration()
        example_best_practices_demo()

    except Exception as e:
        log_to_console(__name__, "Error", f"Example execution failed: {e}")
        log_to_console(
            __name__,
            "Info",
            "This is expected when running without proper database credentials.",
        )

    log_to_console(__name__, "Info", "")
    log_to_console(__name__, "Info", "=== End of StepLogger Examples ===")


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2025-01-29  Comprehensive rewrite for simplified 4-method StepLogger interface
ffortunato  2025-01-29  Added extensive examples covering ETL, batch processing, error handling
ffortunato  2025-01-29  Included best practices and real-world scenarios
ffortunato  2025-01-29  Enhanced examples with TOTAL_DURATION, TOTAL_COUNT tracking and custom_attributes
ffortunato  2025-01-29  Added example_totals_tracking() to demonstrate automatic accumulation
ffortunato  2025-01-29  Updated all examples to showcase standardized step descriptions
*******************************************************************************
"""
