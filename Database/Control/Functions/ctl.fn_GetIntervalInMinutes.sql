﻿CREATE FUNCTION [ctl].[fn_GetIntervalInMinutes] (
	@pIntervalLength INT
	,@pIntervalCode VARCHAR(20)
	,@pETLExecutionId INT = - 1
	,@pPathId INT = - 1
	,@pVerbose BIT = 0
	) RETURNS BIGINT
/*****************************************************************************
File:		fn_GetIntervalInMinutes.sql
Name:		fn_GetIntervalInMinutes
Purpose:    Gives the inteval in minutes based on Interval code and Interval Length

select ctl.fn_GetIntervalInMinutes(2,'YRLY',-1,-1,0)

Parameters:	

Called by: ETL
Calls:          

Errors:		

Author:		ochowkwale
Date:		20190307

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20190307	ochowkwale		Initial iteration.

******************************************************************************/
BEGIN
	DECLARE @CurrentDtm DATETIME = GETDATE()
	DECLARE @pIntervalMinutes BIGINT 

	SELECT @pIntervalMinutes = CASE @pIntervalCode
			WHEN 'MIN'
				THEN @pIntervalLength
			WHEN 'HR'
				THEN DATEDIFF(mi, @CurrentDtm, DATEADD(hh, @pIntervalLength, @CurrentDtm))
			WHEN 'DY'
				THEN DATEDIFF(mi, @CurrentDtm, DATEADD(dd, @pIntervalLength, @CurrentDtm))
			WHEN 'WK'
				THEN DATEDIFF(mi, @CurrentDtm, DATEADD(wk, @pIntervalLength, @CurrentDtm))
			WHEN 'MT'
				THEN DATEDIFF(mi, @CurrentDtm, DATEADD(mm, @pIntervalLength, @CurrentDtm))
			WHEN 'YR'
				THEN DATEDIFF(mi, @CurrentDtm, DATEADD(yyyy, @pIntervalLength, @CurrentDtm))
			WHEN 'IMM'
				THEN 0
			ELSE	 0
			END 

	RETURN @pIntervalMinutes
END
