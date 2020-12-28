CREATE PROCEDURE [ctl].[usp_GetPublicationList]
	 @pPublisherCode			varchar(50) 
	,@pVerbose					int = 0
AS

/*****************************************************************************
 File:			usp_GetPublicationList.sql
 Name:			usp_GetPublicationList
 Purpose:		Returns all publications related to a particular publisher.
				Both Active and InActive publications are returned.
				It is the applications responsibility to decide what to do
				with active or inactive records.

	exec ctl.[usp_GetPublicationList] NULL, 1
	exec ctl.[usp_GetPublicationList] 'CANVAS-AU', 1
	exec ctl.[usp_GetPublicationList] 'CANVAS-AB' ,1 

 Parameters:    

 Called by:		Application
 Calls:          

 Author:		dbay
 Date:			20161114
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
 Date		Author			Description
 --------	-------------	-----------------------------------------------------
 20161114	Barry Day		Original draft
 20161116	Barry Day		Support for institution code filtering
 20161205	Barry Day		Existence check
 20170109	ffortunato		Adding parameters to allow for getting publication 
							list from based on a specific publisher code.
 20170110	ffortunato		Error handling
 20170120a	ffortunato		publication code should be varchar(50)
 20170120b	ffortunato		returning 2 additional attributes
							PublicationFilePath
							PublicationArchivePath
20170126	ffortunato		adding IsActive indicator to result set.
******************************************************************************/

DECLARE	 @Rows					int
		,@Err					int
		,@ErrMsg				nvarchar(2000)
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @Rows					= @@ROWCOUNT
        ,@Err					= 50000
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) + ' failed.' + Char(13)
		,@ParametersPassedChar	= char (13) + 'Parameters Passed: ' + char (13) +
		'	@pPublisherCode : '	+ isnull(@pPublisherCode, 'NULL')   + char (13) +
		'	@pVerbose : '		+ isnull(cast(@pVerbose as varchar(10)),'NULL')  +   char (13)


if		@pVerbose				= 1
begin
		print @ParametersPassedChar
end

-- If not PublisherCode is provided error out.
-- If PublisherCode can't be looked up error out.

begin try

IF @pPublisherCode IS NULL or not exists (
	SELECT	top 1 1 
	FROM	[ctl].[Publication]	  pn
	JOIN	[ctl].[Publisher]	  pr 
	ON		pr.PublisherId		= pn.PublisherId
	WHERE	pr.PublisherCode	= @pPublisherCode)

begin

	select @ErrMsg				=  'Custom Error: PublisherCode not found. Publication list cannont be created.'

	if		@pVerbose			= 1
	begin
			print				'Message Output: ' + @ErrMsg
	end

	;throw  100001, @ErrMsg, 103
	
end

end try

begin catch

	select	 @Err				= isnull(@@ERROR,@Err)  --@@Error will be zero so make sure to get the right error number with an if.
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + char(13)
								+ @FailedProcedure + char(13)
								+ ERROR_MESSAGE () + char(13)
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
	;throw  @Err, @ErrMsg, 1

end catch

	-- Return the list of publications.

begin try

	SELECT	 pn.[PublicationId]
			,pn.[PublicationName]
			,pn.[PublicationCode]
			,pn.PublicationFilePath
			,pn.PublicationArchivePath
			,pn.IsActive
	FROM 	[ctl].[Publication]		as pn
	join	[ctl].[Publisher]		as pr 
	ON		pr.PublisherId			= pn.PublisherId
	WHERE	pr.PublisherCode		= @pPublisherCode

end	try

begin catch

	select   @Err				= @@ERROR
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + char(13)
								+ @FailedProcedure + char(13) + 'Publication list cannot be created'
								+ ERROR_MESSAGE () + char(13)
								+ isnull(@ParametersPassedChar, 'Parmeter list was NULL')
	;throw  @Err, @ErrMsg, 1

end catch
