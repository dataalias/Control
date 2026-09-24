"""
***********************************************************************************************************************
File: basic_usage.py

Purpose: Basic examples of using StepLoggerSnowflake in Snowflake native environment.

These examples demonstrate how to use the Snowflake-native StepLogger in:
- Python worksheets
- Stored procedures
- Snowpark applications

***********************************************************************************************************************
"""


def example_basic_snowflake_usage():
    """
    Basic example showing StepLoggerSnowflake usage in Snowflake environment.

    This can be run in:
    - Snowflake Python Worksheet
    - Snowflake Stored Procedure
    - Snowpark application
    """
    from snowflake.snowpark.context import get_active_session
    from step_logger_snowflake import StepLoggerSnowflake

    # Get active Snowflake session
    session = get_active_session()

    # Initialize logger
    etl_execution_id = __name__
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=etl_execution_id,
        process_name="Basic_Snowflake_Example",
        process_type="ETL",
        process_description="Basic example of StepLogger in Snowflake",
        custom_attributes={
            "version": "1.0",
            "environment_type": "snowflake_native",
        },
    )

    try:
        # Step 1: Data extraction
        logger.start_step(
            "Extract_Customer_Data",
            operation="EXTRACT",
            custom_attributes={
                "source_table": "customers",
                "extraction_method": "full_load",
            },
        )

        # Simulate data extraction
        df = session.sql("SELECT COUNT(*) as cnt FROM SAMPLE_DATA.TPCH_SF1.CUSTOMER")
        result = df.collect()
        record_count = result[0]["CNT"]

        logger.log_step(
            status="SUCCESS",
            description=f"Successfully extracted {record_count} customer records",
            record_count=record_count,
            custom_attributes={"extraction_time_ms": 1500},
        )

        # Step 2: Data transformation
        logger.start_step("Transform_Data", operation="TRANSFORM")

        # Simulate transformation
        transformed_count = record_count - 10

        logger.log_step(
            status="SUCCESS",
            description="Data transformation completed",
            record_count=transformed_count,
            custom_attributes={"records_filtered": 10},
        )

        print(
            f"Process completed - Total Duration: {logger.TOTAL_DURATION}s, "
            f"Total Records: {logger.TOTAL_COUNT}"
        )

    finally:
        logger.close(
            custom_attributes={
                "completion_status": "success",
                "total_steps": 2,
            }
        )


def example_with_error_handling():
    """
    Example showing error handling with StepLoggerSnowflake.
    """
    from snowflake.snowpark.context import get_active_session
    from step_logger_snowflake import StepLoggerSnowflake

    session = get_active_session()
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=__name__,
        process_name="Error_Handling_Example",
    )

    try:
        # Successful step
        logger.start_step("Data_Preparation")
        # ... processing ...
        logger.log_step("SUCCESS", "Data preparation completed", record_count=5000)

        # Step that will fail
        logger.start_step("Data_Processing")
        try:
            # Simulate error
            result = 1 / 0
            print(result)
        except Exception as e:
            logger.log_step(
                status="FAILED",
                description=f"Data processing failed: {str(e)}",
                record_count=0,
                custom_attributes={
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                },
            )

        # Continue with cleanup
        logger.start_step("Cleanup_Operations")
        logger.log_step("SUCCESS", "Cleanup completed")

    finally:
        logger.close()


def example_batch_processing():
    """
    Example showing batch processing with StepLoggerSnowflake.
    """
    from snowflake.snowpark.context import get_active_session
    from step_logger_snowflake import StepLoggerSnowflake

    session = get_active_session()
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=__name__,
        process_name="Batch_Processing_Example",
        process_description="Process multiple batches of data",
    )

    try:
        # Define batches to process
        batches = [
            {"name": "batch_1", "table": "CUSTOMER", "filter": "C_NATIONKEY < 5"},
            {
                "name": "batch_2",
                "table": "CUSTOMER",
                "filter": "C_NATIONKEY >= 5 AND C_NATIONKEY < 10",
            },
            {"name": "batch_3", "table": "CUSTOMER", "filter": "C_NATIONKEY >= 10"},
        ]

        for i, batch in enumerate(batches, 1):
            step_name = f"Process_Batch_{i}"

            logger.start_step(
                step_name,
                operation="BATCH_PROCESS",
                custom_attributes={"batch_info": batch},
            )

            # Process batch
            query = f"""
                SELECT COUNT(*) as cnt 
                FROM SAMPLE_DATA.TPCH_SF1.{batch['table']}
                WHERE {batch['filter']}
            """
            result = session.sql(query).collect()
            batch_count = result[0]["CNT"]

            logger.log_step(
                status="SUCCESS",
                description=f"Successfully processed {batch['name']}",
                record_count=batch_count,
                custom_attributes={
                    "batch_number": i,
                    "batch_name": batch["name"],
                },
            )

        # Summary
        logger.start_step("Generate_Summary")
        logger.log_step(
            status="SUCCESS",
            description=f"Batch processing completed. Total batches: {len(batches)}",
            custom_attributes={
                "total_batches": len(batches),
                "total_records_processed": logger.TOTAL_COUNT,
            },
        )

    finally:
        logger.close()


def example_with_factory():
    """
    Example showing factory pattern usage (auto-detects environment).
    """
    from step_logger_factory import get_step_logger

    # Factory automatically detects we're in Snowflake and returns StepLoggerSnowflake
    logger = get_step_logger(
        etl_execution_id=__name__,
        process_name="Factory_Pattern_Example",
        process_description="Example using factory for multi-environment support",
    )

    try:
        logger.start_step("Process_Data")
        # ... processing ...
        logger.log_step("SUCCESS", "Data processed successfully", record_count=1000)

    finally:
        logger.close()


# Main execution
if __name__ == "__main__":
    """
    Run examples in Snowflake Python Worksheet or Stored Procedure.
    """
    print("=" * 60)
    print("StepLoggerSnowflake Examples")
    print("=" * 60)

    try:
        print("\n1. Basic Usage Example:")
        example_basic_snowflake_usage()

        print("\n2. Error Handling Example:")
        example_with_error_handling()

        print("\n3. Batch Processing Example:")
        example_batch_processing()

        print("\n4. Factory Pattern Example:")
        example_with_factory()

        print("\n" + "=" * 60)
        print("All examples completed successfully!")
        print("=" * 60)

    except Exception as e:
        print(f"Example execution failed: {e}")
        import traceback

        traceback.print_exc()
