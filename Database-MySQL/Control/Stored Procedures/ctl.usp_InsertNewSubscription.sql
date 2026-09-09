create procedure [ctl].[usp_InsertNewSubscription] (    
	 @pPublicationCode			varchar(50)
	,@pSubscriberCode			varchar(100)
	,@pSubscriptionName			varchar(250)
	,@pSubscriptionDesc			varchar(1000)
	,@pInterfaceCode			varchar(20)			= 'N/A'
	,@pIsActive					int					= 0
	,@pSubscriptionFilePath     varchar(255)		= 'N/A'
	,@pSubscriptionArchivePath	varchar(255)		= 'N/A'
	,@pSrcFilePath				varchar(255)		= 'N/A'
	,@pDestTableName			varchar(255)		= 'N/A'
	,@pDestFileFormatCode		varchar(20)			= 'N/A'
	,@pCreatedBy				varchar(50)			= 'UNK'
	,@pVerbose					int					= 0 
) as 
/*****************************************************************************
File:		[usp_InsertNewSubscription].sql
Name:		[usp_InsertNewSubscription]
Purpose:	

exec ctl.[usp_InsertNewSubscription]  'ASSIGNMENTDIM-AU','EDL','Canvas AU assignment_dim to EDL',
	'DimAssignment','tstFolder','tstSSISPowerShell','FileStaging.dtsx','CanvasData'
	,'Staging*',getdate(),getdate()+100,'ffortunato',1

    
Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20091020

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170427	ffortunato		changing flowerbox. formatting variables. using
							standard logging. throwing errors.

20180411	ffortunato		changing from start and end to IsActive.
20180711	ffortunato		formatting
20180711	ffortunato		changing the field size for name and code.
20180906	ffortunato		changing the field size for name and code.
20190305	ochowkwale		Subscription export configuration setup
20210430	ffortunato		better error logging for jason c.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

declare  @rows					int
        ,@ErrNum				int
		,@ErrMsg				nvarchar(2048)
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)
        ,@CreatedDate			datetime
        ,@PublicationId			int
        ,@SubscriberId			int
        ,@SubscriptionCode		varchar(100)
		,@CRLF					varchar(20)			=  char(13) + char(10)
		,@SQLErrorMsg			varchar(500)		= 'No Errors.'


----------------------------------------------------------------------------------
--  initializations
----------------------------------------------------------------------------------
select   @rows					= @@rowcount
        ,@ErrNum				= @@error
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + isnull(OBJECT_NAME(@@PROCID),'ctl.usp_InsertNewSubscription') + ' failed.' + @CRLF
        ,@CreatedDate			= getdate()
        ,@PublicationId			= -1
        ,@SubscriberId			= -1
        ,@ParametersPassedChar	= 
			'***** Parameters Passed to exec ctl.usp_InsertNewSubscription' + @CRLF +
			'     @pPublicationCode = ''' + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
			'    ,@pSubscriberCode = ''' + isnull(@pSubscriberCode ,'NULL') + '''' + @CRLF + 
			'    ,@pSubscriptionName = ''' + isnull(@pSubscriptionName ,'NULL') + '''' + @CRLF + 
			'    ,@pSubscriptionDesc = ''' + isnull(@pSubscriptionDesc ,'NULL') + '''' + @CRLF + 
			'    ,@pInterfaceCode = ''' + isnull(@pInterfaceCode ,'NULL') + '''' + @CRLF + 
			'    ,@pIsActive = ' + isnull(cast(@pIsActive as varchar(100)),'NULL') + @CRLF + 
			'    ,@pSubscriptionFilePath = ' + isnull(cast(@pSubscriptionFilePath as varchar(255)),'NULL') + @CRLF + 
			'    ,@pSubscriptionArchivePath = ' + isnull(cast(@pSubscriptionArchivePath as varchar(255)),'NULL') + @CRLF + 
			'    ,@pSrcFilePath = ' + isnull(cast(@pSrcFilePath as varchar(255)),'NULL') + @CRLF + 
			'    ,@pDestTableName = ' + isnull(cast(@pDestTableName as varchar(255)),'NULL') + @CRLF + 
			'    ,@pDestFileFormatCode = ' + isnull(cast(@pDestFileFormatCode as varchar(255)),'NULL') + @CRLF + 
			'    ,@pCreatedBy = ''' + isnull(@pCreatedBy ,'NULL') + '''' + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
			'***** End of Parameters' + @CRLF 

if @pVerbose = 1 begin
  print ' **********'
  print @ParametersPassedChar
  print ' **********'
end

----------------------------------------------------------------------------------
--  main
----------------------------------------------------------------------------------
begin try

if  ((@pCreatedBy = 'UNK') or (@pCreatedBy is null))
begin
	select @pCreatedBy = CURRENT_USER
end

select	 @publicationid			= isnull(PublicationId ,-1)
from	 ctl.Publication
where	 PublicationCode		= @pPublicationCode

print  '@publicationid: ' + isnull(cast(@publicationid as varchar (20)),'WTF')

select	 @SubscriberId			= isnull(SubscriberId ,-1)
from	 ctl.Subscriber
where	 SubscriberCode			= @pSubscriberCode

print  '@SubscriberId: ' + isnull(cast(@SubscriberId as varchar (20)),'WTF')



if @pVerbose					= 1 
begin
	print '@publicationid : ' + @pPublicationCode + ' ' + cast(@PublicationId as varchar (50))
	print '@subscriberid  : ' + @pSubscriberCode  + ' ' + cast(@SubscriberId as varchar (50))
--	print '@SubscriberCode  : ' + @SubscriberCode  + ' ' + cast(@SubscriberId as varchar (50))
	print '@SubscriptionCode  Len : ' + isnull(cast(len (@SubscriptionCode) as varchar(20)),'Len NULL')
	print ' If previous values are -1 there is an issue'
	print @ParametersPassedChar
end

if  (@PublicationId				= -1 OR 
	@SubscriberId				= -1 OR
	@PublicationId				is null OR
	@SubscriberId				is null)
	begin
		select	 @ErrNum		= 100001
				,@ErrMsg		= 'ErrorNumber: ' 
								+ CAST (@ErrNum AS varchar(10)) + @CRLF
								+ @FailedProcedure + @CRLF 
								+ 'Custom Error: Subscriber or Publication Id could not be found '
								+ 'based on the provided data.'

		if @ErrNum < 50000  select @ErrNum = @ErrNum + 1000000
		;throw	 @ErrNum, @ErrMsg, 1	-- Sql Server Error

	end

end try

begin catch

if  (@PublicationId				= -1 OR 
	@SubscriberId				= -1 OR
	@PublicationId				is null OR
	@SubscriberId				is null)
begin

		;throw  @ErrNum, @ErrMsg, 1	-- Custom Error: 100001

end else begin

		select    @ErrNum			= @@ERROR
				,@ErrMsg			= 'ErrorNumber: ' + CAST (@ErrNum AS varchar(10)) + @CRLF
									+ @FailedProcedure + @CRLF
									+ ERROR_MESSAGE () + @CRLF
									+ ISNULL(@ParametersPassedChar, 'Parmeter was NULL')
	
		if @ErrNum < 50000  select @ErrNum = @ErrNum + 1000000
		;throw  @ErrNum, @ErrMsg, 1
	end
end catch

begin try

	select	 @SubscriptionCode		= psh.PublisherCode + '-' 
									+ scr.SubscriberCode + '-' 
									+ pca.PublicationCode
	from	 ctl.Publisher			  psh
	join	 ctl.Publication		  pca
	on		 psh.PublisherId		= pca.PublisherId
	join	 ctl.Subscriber			  scr
	on		 scr.SubscriberId		= @SubscriberId
	where	 pca.PublicationId		= @PublicationId

	insert into ctl.Subscription (
		 PublicationId
		,SubscriberId
		,SubscriptionCode
		,SubscriptionName
		,SubscriptionDesc
		,InterfaceCode
		,IsActive
		,SubscriptionFilePath
		,SubscriptionArchivePath
		,SrcFilePath
		,DestTableName
		,DestFileFormatCode
		,CreatedDtm
		,CreatedBy
		,ModifiedDtm
		,ModifiedBy
	) values (
		 @PublicationId
		,@SubscriberId
		,@SubscriptionCode
		,@pSubscriptionName
		,@pSubscriptionDesc
		,@pInterfaceCode
		,@pIsActive
		,@pSubscriptionFilePath
		,@pSubscriptionArchivePath
		,@pSrcFilePath
		,@pDestTableName
		,@pDestFileFormatCode
		,@CreatedDate
		,@pCreatedBy
		,@CreatedDate
		,@pCreatedBy
	)

end try-- main

begin catch 

		select   @ErrNum			= @@ERROR
				,@ErrMsg			= 'ErrorNumber: ' + CAST (@ErrNum as varchar(10)) + @CRLF
									+ @FailedProcedure + @CRLF
									+ ERROR_MESSAGE () + @CRLF
									+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
	
		if @ErrNum < 50000  select @ErrNum = @ErrNum + 1000000
		;throw  @ErrNum, @ErrMsg, 1

end catch

