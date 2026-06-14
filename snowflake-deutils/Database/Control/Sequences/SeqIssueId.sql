/**********************************************************************************************************************
file:           Issue_Id_Seq.sql
name:           SEQ_ISSUE_ID

purpose:        Provides an explicit sequence for DATA_HUB.ISSUE.IssueId so that
                the next value can be retrieved from Python before an INSERT,
                eliminating the post-insert MAX(IssueId) race condition.

deployment:     Run Step 1 first to capture the current max IssueId, then
                substitute that value into Step 2 before executing.

called by:
calls:

author:         ffortunato
date:           2026-04-20

**********************************************************************************************************************/

-- Step 1: Run this query and note the result.
--   SELECT IFNULL(MAX(IssueId), 0) + 1 AS next_start FROM DATA_HUB.ISSUE;

-- Step 2: Replace <next_start> with the value returned above, then execute.
CREATE SEQUENCE IF NOT EXISTS DATA_HUB.SEQ_ISSUE_ID
    START  = 1
    INCREMENT = 1
    ORDER;

/*
***********************************************************************************************************************
       change history
***********************************************************************************************************************
date        author          description
----------  -------------   ------------------------------------------------------------------------------------------
2026-04-20  ffortunato      initial iteration — explicit sequence replacing AUTOINCREMENT on DATA_HUB.ISSUE.IssueId
**********************************************************************************************************************/
