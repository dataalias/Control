CREATE FUNCTION [ctl].[fn_GetLastSuccessfulIssuePeriodEndDtm]
(
	   @pInstitutionCode	varchar(50)
	  ,@pPublicationCode	varchar(50)
	  ,@pIsFullLoad			int			= -1
	  --,@pExtraDaysToLoad	int			= 3
)	RETURNS DATETIME
AS

/*****************************************************************************
File:		fn_GetLastSuccessfulIssueLogicalEndDtm.sql
Name:		fn_GetLastSuccessfulIssueLogicalEndDtm
Purpose:	Pass in a publication code (likely Canvas), and get the PeriodEndTime
from the last successful execution. This can be used for filtering data. It checks for 
the last execution that was 100% successful.

select ctl.fn_GetLastSuccessfulIssuePeriodEndDtm('AU','SUBMISSIONDIM-AU',0) as PeriodStartTime
select ctl.fn_GetLastSuccessfulIssuePeriodEndDtm('AU','SUBMISSIONDIM-AU',1) as PeriodStartTime

select ctl.fn_GetLastSuccessfulIssuePeriodEndDtm('UoR','SUBMISSIONDIM-UoR',0) as PeriodStartTime
select ctl.fn_GetLastSuccessfulIssuePeriodEndDtm('AU','DISCUSSIONENTRYDIM-AU',0) as PeriodStartTime

Parameters: @pPublisherCode, @pPublicationCode    

Called by:	Multiple LMS SSIS Stage Packages
Calls:		N/A      

Errors:		

Author:		Jeff Prom
Date:		2017-10-30
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
2018-01-03	Jeff Prom		Removed the package parameter. we won't be checking the catalog anymore.
							Added PublisherCode parameter. This will be used to check for successful loads.
2018-01-10	Jeff Prom		Came up with version #3
2018-02-12	Jeff Prom		Added @pExtraDaysToLoad. Set it to 3. We found that Canvas can send
							data 42 hours back.
2019-03-07	Omkar Chowkwale	Replaced the logic for finding the last successful IssueId from ETLExecutionId
							to be based on IssueId alone
20201118	ffortunato		removing warnings.
******************************************************************************/

BEGIN
	----------------------------------------------------
	-- Testing
	--DECLARE @pInstitutionCode	varchar(50) = 'AU'
	--DECLARE @pPublicationCode	varchar(50) = 'DISCUSSIONENTRYDIM-AU'
	--DECLARE @pIsFullLoad		INT			= -1
	----------------------------------------------------

	DECLARE @PeriodStartTime	DATETIME
	DECLARE @ExtraDaysToLoad	int			= 3
		,@IssueId INT

	IF (@pIsFullLoad = 1)
		SET @PeriodStartTime = '1900-01-01'

	ELSE
		BEGIN

		--Find the last successful IssueId for that publication
		set @IssueId = (
			select		 max(iss.IssueId)
			from		 ctl.Issue						AS iss
			INNER JOIN	 ctl.RefStatus					AS rs	
			ON			 iss.StatusId					 = rs.StatusId
			INNER JOIN	 ctl.Publication				AS pn	
			ON			 iss.PublicationId				 = pn.PublicationId
			where  		 pn.PublicationCode				 = @pPublicationCode
			and			 rs.StatusCode					 = 'IC'
			)

		-- Now find the PeriodStartTime by Publication using the ETLExecutionID
		select @PeriodStartTime = (
			select	 coalesce(iss.PeriodEndTime, '1900-01-01')		AS PeriodStartTime
			from	 ctl.Issue		AS iss
			where	 iss.IssueId	= @IssueId
		)

		-- apply extra days to load option
		select @PeriodStartTime = dateadd(dd, -@ExtraDaysToLoad, @PeriodStartTime)

		-- Testing
		-- select @PeriodStartTime as PeriodStartTime

		END

	-- Override (For Testing)
	--SET @PeriodStartTime = '2017-12-01'
	--SET @PeriodStartTime = '1900-01-01'


	-- Return the result of the function
	--select @PeriodStartTime
	RETURN coalesce(@PeriodStartTime,'1900-01-01')

END