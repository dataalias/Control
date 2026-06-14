CREATE OR REPLACE PROCEDURE DATA_HUB.TEMP_INIT_SEQ_ISSUE_ID()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    var get_max = snowflake.createStatement({
        sqlText: 'SELECT IFNULL(MAX(IssueId), 0) + 1000 AS NEXT_START FROM DATA_HUB.ISSUE'
    })
    var result = get_max.execute()
    result.next()
    var next_start = result.getColumnValue('NEXT_START')

    snowflake.execute({
        sqlText: 'CREATE SEQUENCE IF NOT EXISTS DATA_HUB.SEQ_ISSUE_ID START = ' + next_start + ' INCREMENT = 1 ORDER'
    })

    return 'Created DATA_HUB.SEQ_ISSUE_ID starting at ' + next_start
$$;

CALL DATA_HUB.TEMP_INIT_SEQ_ISSUE_ID();

DROP PROCEDURE IF EXISTS DATA_HUB.TEMP_INIT_SEQ_ISSUE_ID();
