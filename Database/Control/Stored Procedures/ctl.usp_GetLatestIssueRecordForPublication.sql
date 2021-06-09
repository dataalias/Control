CREATE PROCEDURE [ctl].[usp_GetLatestIssueRecordForPublication]
		 @pPublicationCode		varchar(50) 
		,@pVerbose				int = 0
AS

/*****************************************************************************
 File:           GetLatestIssueRecordForPublication.sql
 Name:           usp_GetLatestIssueRecordForPublication
 Purpose:        Allows for the creation of new issues.


	exec ctl.[usp_GetLatestIssueRecordForPublication] NULL, 1
	exec ctl.[usp_GetLatestIssueRecordForPublication] 'ASSIGNMENTOVERRIDEFACT-AU', 1
	exec ctl.[usp_GetLatestIssueRecordForPublication] 'CANVAS-AB' ,1 

 Parameters:    

 Called by:      Application
 Calls:          

 Author:         dbay
 Date:           20161114

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date      Author			Description
--------  ---------------	---------------------------------------------------
20161114  Barry Day			Original draft
20161116  Barry Day			Support for institution code filtering
20161205  Barry Day			Existence check
20170110  ffortunato		Adding parameters to allow for getting publication
							list from based on a specific publisher code.
							Adding try catch block and throwing custom
							message.
20170120  ffortunato		publication code should be varchar(50)
20170327  ffortunato		DW-635 ORDER BY should use data, not primary key
20180323  ffortunato		Removing fully qualified reference to BPI_DW_STAGE
							database to allow for easier compile in db project.
							
20180828  ffortunato		InterfaceCode moving to publisher 'CANVAS'		
******************************************************************************/

DECLARE	 @Rows                     int
		,@Err                      int
		,@ErrMsg                   nvarchar(2000)
		,@ParametersPassedChar     varchar(1000)

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @Rows					= @@ROWCOUNT
        ,@Err					= 50000
		,@ErrMsg				= 'Stored Procedure: ' + OBJECT_NAME(@@PROCID) + ' failed.' + Char(13)
		,@ParametersPassedChar	= char (13) + 'Parameters Passed: ' + char (13) +
		'	@pPublisherCode	: '	+ isnull(@pPublicationCode, 'NULL')   + char (13) +
		'	@pVerbose		: '	+ isnull(cast(@pVerbose as varchar(10)),'NULL')  +   char (13)


if		@pVerbose				= 1
begin
		print @ParametersPassedChar
end

BEGIN try

IF @pPublicationCode IS NULL
	SET @pPublicationCode = ''

IF EXISTS (
SELECT
	TopIssue.IssueId
	, TopIssue.IssueName
FROM
(
	SELECT 
		iss.IssueId
		, iss.IssueName
		, pn.PublicationName
		, rs.StatusCode
		, iss.IssueConsumedDate
		, ROW_NUMBER() OVER (PARTITION BY iss.PublicationId ORDER BY SrcDFCreatedDate DESC)	AS rn  
	FROM 
		[ctl].[Issue]					AS iss
		INNER JOIN [ctl].[RefStatus]	AS rs	ON iss.StatusId      = rs.StatusId
		INNER JOIN [ctl].[Publication]	AS pn	ON iss.PublicationId = pn.PublicationId
		INNER JOIN [ctl].[Publisher]	AS pr	ON pr.PublisherId    = pn.PublisherId
	WHERE
		pr.InterfaceCode	= 'CANVAS'
		AND pn.PublicationCode  = @pPublicationCode
)	AS TopIssue
WHERE
	rn = 1
	AND TopIssue.StatusCode = 'IP'
	AND TopIssue.IssueConsumedDate IS NULL
)
BEGIN
SELECT
	TopIssue.[PublicationId]
	, TopIssue.[PublicationName]
	, TopIssue.[PublicationCode]
	, TopIssue.IssueId
	, TopIssue.StatusId
	, TopIssue.ReportDate
	, TopIssue.SrcDFPublisherId
	, TopIssue.SrcDFPublicationId
	, TopIssue.SrcDFIssueId
	, TopIssue.SrcDFCreatedDate
	, TopIssue.IssueName
	, TopIssue.PublicationSeq
	, TopIssue.FirstRecordSeq
	, TopIssue.LastRecordSeq
	, TopIssue.FirstRecordChecksum
	, TopIssue.LastRecordChecksum
	, TopIssue.PeriodStartTime
	, TopIssue.PeriodEndTime
	, TopIssue.IssueConsumedDate
	, TopIssue.RecordCount
	, TopIssue.CreatedBy
	, TopIssue.CreatedDtm
	, TopIssue.ModifiedBy
	, TopIssue.ModifiedDtm
FROM
(
	SELECT 
		pn.[PublicationId]
		, pn.[PublicationName]
		, pn.[PublicationCode]
		, iss.IssueId
		, iss.StatusId
		, rs.StatusCode
		, iss.ReportDate
		, iss.SrcDFPublisherId
		, iss.SrcDFPublicationId
		, iss.SrcDFIssueId
		, iss.SrcDFCreatedDate
		, iss.IssueName
		, iss.PublicationSeq
		, iss.FirstRecordSeq
		, iss.LastRecordSeq
		, iss.FirstRecordChecksum
		, iss.LastRecordChecksum
		, iss.PeriodStartTime
		, iss.PeriodEndTime
		, iss.IssueConsumedDate
		, iss.RecordCount
		, iss.CreatedBy
		, iss.CreatedDtm
		, iss.ModifiedBy
		, iss.ModifiedDtm
		-- since src date isn't required this should order by issueid
		, ROW_NUMBER() OVER (PARTITION BY iss.PublicationId ORDER BY /*SrcDFCreatedDate*/ iss.IssueId DESC)	AS rn  
	FROM 
		[ctl].[Issue]					AS iss
		INNER JOIN [ctl].[RefStatus]	AS rs	ON iss.StatusId      = rs.StatusId
		INNER JOIN [ctl].[Publication]	AS pn	ON iss.PublicationId = pn.PublicationId
		INNER JOIN [ctl].[Publisher]	AS pr	ON pr.PublisherId    = pn.PublisherId
	WHERE
		pr.InterfaceCode	= 'CANVAS'
		AND pn.PublicationCode  = @pPublicationCode
)	AS TopIssue
WHERE
	rn = 1 -- We only want to return one record. The latest one hense the partition.
	AND TopIssue.StatusCode = 'IP'
	AND TopIssue.IssueConsumedDate IS NULL
ORDER BY
	TopIssue.PublicationName
END
ELSE
BEGIN
	SELECT 0 AS IssueId, 'NA' AS IssueName

	if		@pVerbose				= 1
	begin
			print 'No Issue found for the associated PublicationCode.'
	end
END

END try

begin catch

	select	 @Err				= @@ERROR + 100000
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + char(13)
								+ @ErrMsg + char(13) + ERROR_MESSAGE () + char(13)
								+ isnull(@ParametersPassedChar, 'Parm was NULL')
	;throw  @Err, @ErrMsg, 1

end catch
