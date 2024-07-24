CREATE FUNCTION [ctl].[fn_GetLastSuccessfulETLExecutionID]
(
	   @pInstitutionCode	varchar(50)
	  ,@pIsFullLoad			INT			= -1
)	RETURNS INT
AS

/*****************************************************************************
File:		fn_GetLastSuccessfulETLExecutionID.sql
Name:		fn_GetLastSuccessfulETLExecutionID
Purpose:	Pass in an institution code, and get the ETLExecutionID
from the last successful execution. This can be used for filtering data. It checks for 
the last execution that was 100% successful.

select ctl.fn_GetLastSuccessfulETLExecutionID('AU', 0) as IssueId
select ctl.fn_GetLastSuccessfulETLExecutionID('AU', 1) as IssueId

select ctl.fn_GetLastSuccessfulETLExecutionID('UoR', 0) as IssueId
select ctl.fn_GetLastSuccessfulETLExecutionID('UoR', 1) as IssueId

Parameters: @pPublisherCode, @pPublicationCode    

Called by:	Multiple LMS SSIS Stage Packages
Calls:		N/A      

Errors:		

Author:		Jeff Prom
Date:		2018-02-07
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20201118	ffortunato		cleaning up warnings
******************************************************************************/

BEGIN
	----------------------------------------------------
	-- Testing
	--DECLARE @pInstitutionCode	varchar(50) = 'AU'
	--DECLARE @pIsFullLoad		INT			= 0
	----------------------------------------------------

	DECLARE @ETLExecutionID		INT				= -1
	DECLARE @StepLogMessage		VARCHAR(256)	= 'Canvas Data Load Complete - ' + @pInstitutionCode

	IF (@pIsFullLoad = 1)
		SET @ETLExecutionID = -2 -- catch any entries with a -1

	ELSE
		-- Find the ETLExecutionID from the last successful canvas data load using Step Logs.
		SET		@ETLExecutionID = (
			select max(ETLExecutionId) 
			from	[audit].StepLog 
			where	isnull(StepName,'NoMatch')		= @StepLogMessage 
			and		isnull(StepStatus,'NoMatch')	= 'Success')

	----------------------------------------------------
	-- Return the result of the function
	--select @ETLExecutionID as ETLExecutionID
	RETURN @ETLExecutionID

END

