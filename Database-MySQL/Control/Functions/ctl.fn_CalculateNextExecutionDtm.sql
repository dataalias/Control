CREATE FUNCTION [dbo].[fn_CalculateNextExecutionDtm] (
	@CurrentDtm DATETIME
	,@CurrentNextExecutionDtm DATETIME
	,@IntervalCode VARCHAR(20)
	,@IntervalLength INT
	)
RETURNS DATETIME
AS
/*****************************************************************************
File:		fn_CalculateNextExecutionDtm.sql
Name:		fn_CalculateNextExecutionDtm
Purpose:	Pass in a publication code (likely Canvas), and get the PeriodEndTime
from the last successful execution. This can be used for filtering data. It checks for 
the last execution that was 100% successful.

select [dbo].[fn_CalculateNextExecutionDtm]('2017-04-26 08:26:53.000', '2017-04-25 18:26:53.000', 'DLY',1)

Parameters: @pCurrentDtm, @CurrentNextExecutionDtm, @IntervalCode, @IntervalLength INT    

Called by:	Multiple LMS SSIS Stage Packages
Calls:		N/A      

Errors:		

Author:		Omkar Chowkwale
Date:		2020-07-28
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20200728	Omkar Chowkwale	Initial Iteration
20210329	ffortunato		Removing some warnings.
******************************************************************************/
BEGIN
	DECLARE @NextExecutionDtm DATETIME

--It will change only when calculated Next Expected Execution Runtime does not exceed the interval length from Current Date.
-- 1) Find the normalized "Number of intervals" between Previous expected execution runtime and Current Date : (DATEDIFF(mi, NextExecutionDtm, @CreatedDate) / IntervalLength)
-- 2) One additional interval is added to that number to get the next expected execution runtime from current date: 1 + "Number of intervals"
-- 3) Calculate the total "Interval Length" between Previous NextExecutionDtm and the next expected execution runtime : Interval Length * (1 + "Number of intervals")
-- 4) Add the "Interval Length" to Previous expected execution runtime
	SELECT @NextExecutionDtm = CASE @IntervalCode
			WHEN 'MN'
				THEN CASE 
						WHEN DATEDIFF(mi, @CurrentDtm, DATEADD(mi, @IntervalLength * (1 + (DATEDIFF(mi, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)) <= @IntervalLength
							THEN DATEADD(mi, @IntervalLength * (1 + (DATEDIFF(mi, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)
						ELSE @CurrentNextExecutionDtm
						END
			WHEN 'HR'
				THEN CASE 
						WHEN DATEDIFF(hh, @CurrentDtm, DATEADD(hh, @IntervalLength * (1 + (DATEDIFF(hh, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)) <= @IntervalLength
							THEN DATEADD(hh, @IntervalLength * (1 + (DATEDIFF(hh, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)
						ELSE @CurrentNextExecutionDtm
						END
			WHEN 'DY'
				THEN CASE 
						WHEN DATEDIFF(dd, @CurrentDtm, DATEADD(dd, @IntervalLength * (1 + (DATEDIFF(dd, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)) <= @IntervalLength
							THEN DATEADD(dd, @IntervalLength * (1 + (DATEDIFF(dd, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)
						ELSE @CurrentNextExecutionDtm
						END
			WHEN 'WK'
				THEN CASE 
						WHEN DATEDIFF(wk, @CurrentDtm, DATEADD(wk, @IntervalLength * (1 + (DATEDIFF(wk, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)) <= @IntervalLength
							THEN DATEADD(wk, @IntervalLength * (1 + (DATEDIFF(wk, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)
						ELSE @CurrentNextExecutionDtm
						END
			WHEN 'MT'
				THEN CASE 
						WHEN DATEDIFF(mm, @CurrentDtm, DATEADD(mm, @IntervalLength * (1 + (DATEDIFF(mm, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)) <= @IntervalLength
							THEN DATEADD(mm, @IntervalLength * (1 + (DATEDIFF(mm, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)
						ELSE @CurrentNextExecutionDtm
						END
			WHEN 'YR'
				THEN CASE 
						WHEN DATEDIFF(yyyy, @CurrentDtm, DATEADD(yyyy, @IntervalLength * (1 + (DATEDIFF(yyyy, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)) <= @IntervalLength
							THEN DATEADD(yyyy, @IntervalLength * (1 + (DATEDIFF(yyyy, @CurrentNextExecutionDtm, @CurrentDtm) / @IntervalLength)), @CurrentNextExecutionDtm)
						ELSE @CurrentNextExecutionDtm
						END
			ELSE @CurrentNextExecutionDtm
			END

	RETURN @NextExecutionDtm
END
