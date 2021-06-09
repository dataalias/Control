CREATE PROCEDURE pg.usp_ExecuteSSISPackage (
	 @pServerName						varchar(255)	= 'N/A'
	,@pSSISFolder						varchar(255)	= 'N/A'
	,@pSSISProject						varchar(255)	= 'N/A'
	,@pSSISPackage						varchar(255)	= 'N/A'
	,@pSSISParameters					udt_SSISPackageParameters readonly
	,@pAllowMultipleInstances			bit				= 0
	,@pExecuteProcessStatus				varchar(20)		output
	,@pETLExecutionId					int				= -1
	,@pPathId							int				= -1
	,@pVerbose							bit				= 0)
AS
/*****************************************************************************
File:		usp_ExecuteSSISPackage.sql
Name:		usp_ExecuteSSISPackage

Purpose:	The parameters for this procedure are used to create and run
			a nes SSIS execution. Identify server, pacgage and parameters.

Parameters:	
		 @pServerName			Sever that contains the SISS package
		,@pSSISFolder			 
		,@pSSISProject			 
		,@pSSISPackage			 
		,@pSSISParameters		User defined table that has three columns. 
		,@pAllowMultipleInstances Determines if several instances of the same SSIS package can run at once.
								1 - Yes : Allow new instance to invoke even if one is currently running.
								0 - No	: If an instance of the package is running do not allow another to run.

		,@pExecuteProcessStatus	'IAR' -- Instance already running.
								'INR' -- Instance not running.
								'IRS' -- Instance run suceeded.
								'IRF' -- Instance run failed.
THIS ONE
		,@pExecuteProcessStatus	'IAR' -- Instance already running.
								'INR' -- Instance not running.
								'ISS' -- Instance start succeeded.
								'ISF' -- Instance start failed.

			ObjectType
			ParameterName
			ParameterValue

		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0


Execution

declare @SSISParameters		pg.udt_SSISPackageParameters

	insert into	@SSISParameters values (30,'pkg_PostingGroupId',		46)
	insert into	@SSISParameters values (30,'pkg_PostingGroupBatchSeq',	1)
	insert into	@SSISParameters values (30,'pkg_PostingGroupBatchId',	6)

exec pg.usp_ExecuteSSISPackage 

		 @pServerName			= 'DEDTEDLSQL01'
		,@pSSISFolder			= 'ETLFolder'
		,@pSSISProject			= 'MARS'
		,@pSSISPackage			= 'Controller_MARS.dtsx'
		,@pSSISParameters		= @SSISParameters
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0
		 

Called By:	The completion of any process or scheudled job at 
			30 min interval.

Calls:		Any process that is ready to run.

Author:		ffortunato
Date:		20181130

*******************************************************************************
       Change History
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------

20181130	ffortunato		Initial Iteration
20181206	ffortunato		Any number of parameters
20181207	ffortunato		JSON for steplog.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@ProcessStartDtm		datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@ServerName			varchar(50)		= @@SERVERNAME
		,@CurrentUser			varchar(256)	= CURRENT_USER
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@SubStepNumber			varchar(23)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL

		-- Program Specific Parameters
		,@ExecutionId			int				= -1
		,@ReferenceId			int				= -1
		,@LoopMax				int				= -1
		,@LoopCount				int				= -1
		,@ObjectType			int				= -1
		,@ParameterName			nvarchar(128)	= 'N/A'
		,@ParameterValue		sql_variant		= 'N/A'		
		,@JSONAdd				nvarchar(400)	= NULL
		,@ReplaceJSONToken		nvarchar(10)	= ',"":""}'


exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec pg.usp_ExecuteSSISPackage' + @CRLF +
      '     @pServerName = ''' + isnull(@pServerName ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISFolder = ''' + isnull(@pSSISFolder ,'NULL') + '''' + @CRLF + 
	  '    ,@pSSISProject = ''' + isnull(@pSSISProject ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISPackage = ''' + isnull(@pSSISPackage ,'NULL') + '''' + @CRLF + 
	  '    ,@pAllowMultipleInstances = ''' + isnull(cast(@pAllowMultipleInstances as varchar(20)) ,'NULL') + '''' + @CRLF + 
	  '    ,@pExecuteProcessStatus = ''' + isnull(@pExecuteProcessStatus ,'NULL') + '''' + @CRLF + 
 --     '    ,@SSISParameters = ' + isnull(cast(@SSISParameters as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

select	  @pExecuteProcessStatus = 'ISF' -- Instnace start failed.

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
-- This section of code determines if any dependent jobs can be run based 
-- on other processes completeing.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Is Instance Running'
			,@StepNumber		= @StepNumber + 0
			,@StepOperation		= 'select'
			,@StepDesc			= 'Going to determine if the instance is running.'
			,@JSONSnippet		= ' {"@pServerName":"'	+ isnull(@pServerName ,'NULL')+'",' +
									'"@pSSISFolder":"'	+ isnull(@pSSISFolder ,'NULL') +'",' +
									'"@pSSISProject":"'	+ isnull(@pSSISProject ,'NULL') +'",' +
									'"@pSSISPackage":"'	+ isnull(@pSSISPackage ,'NULL') + '"' + @ReplaceJSONToken

	If exists (	select top 1 1 
				FROM	 [$(SSISDB)].catalog.executions		  E
				JOIN	 [$(SSISDB)].catalog.folders		  F
				ON		 F.name								= E.folder_name
				JOIN	 [$(SSISDB)].catalog.projects		  P
				ON		 P.folder_id						= F.folder_id
				AND		 P.name								= E.project_name
				JOIN	 [$(SSISDB)].catalog.packages		  PKG
				ON		 PKG.project_id						= P.project_id
				AND		 PKG.name							= E.package_name
				where    E.folder_name						= @pSSISFolder
				and		 E.project_name						= @pSSISProject
				and		 E.package_name						= @pSSISPackage
				and		 E.status							= 2) -- Status 2 = Executing)

		select	 @pExecuteProcessStatus = 'IAR' -- 'Instance Already Running'

	else
		select	 @pExecuteProcessStatus = 'INR' -- 'Instance not running'


	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pExecuteProcessStatus":"'  + isnull(@pExecuteProcessStatus, 'Bad Value') + '",' +
									'"@pAllowMultipleInstances":"' + isnull(cast(@pAllowMultipleInstances as varchar(2)),'Bad Value') + '"}' 
	
	exec [audit].usp_InsertStepLog
				@MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	-- Either serveral instances can be run at once or there is no instance of the job currently running.
	If ((@pAllowMultipleInstances = 1 ) or (@pAllowMultipleInstances = 0 and @pExecuteProcessStatus = 'INR'))
	begin

		-- Note when calling the next package Batch and Posting Group must be sent as well.
		select	 @StepName			= 'Execute Posting Group'
				,@StepNumber		= @StepNumber + 1
				,@StepOperation		= 'execute'
				,@StepDesc			= 'Execute SSIS Package: ' + isnull(@pSSISPackage, 'Error')
				,@JSONSnippet		= ' {"@pServerName":"'	+ isnull(@pServerName ,'NULL')+'",' +
										'"@pSSISFolder":"'	+ isnull(@pSSISFolder ,'NULL') +'",' +
										'"@pSSISProject":"'	+ isnull(@pSSISProject ,'NULL') +'",' +
										'"@pSSISPackage":"'	+ isnull(@pSSISPackage ,'NULL') + '"' + @ReplaceJSONToken

		select	 @ReferenceId				= isnull(er.reference_id,-1)
		from	 [$(SSISDB)].catalog.environment_references er 
		join	 [$(SSISDB)].catalog.projects prj
		on		 er.project_id				= prj.project_id
		where	 er.environment_name		= @ServerName
		and		 er.environment_folder_name = @pSSISFolder
		and		 prj.[name]					= @pSSISProject

		select	 @JSONAdd	= ',"@ReferenceId":"' + cast(isnull(@ReferenceId,-1) as nvarchar(10)) + '"' + @ReplaceJSONToken
		select	 @JSONSnippet = replace(@JSONSnippet,@ReplaceJSONToken,@JSONAdd); 
		select	 @JSONAdd	= NULL

		exec	 [$(SSISDB)].catalog.create_execution
				 @folder_name				= @pSSISFolder
				,@project_name				= @pSSISProject
				,@package_name				= @pSSISPackage
				,@reference_id				= @ReferenceId
				,@execution_id				= @ExecutionId  output

		select	 @JSONAdd					= ',"@ExecutionId":"' + cast(isnull(@ExecutionId,-1) as nvarchar(10)) + '"' + @ReplaceJSONToken
		select	 @JSONSnippet				= replace(@JSONSnippet,@ReplaceJSONToken,@JSONAdd); 
		select	 @JSONAdd					= NULL

		if exists (select top 1 1 from @pSSISParameters)

		begin -- Load parameters

			select	 @LoopMax				= max(ParameterId)
			from	 @pSSISParameters
	
			select	 @LoopCount				= 1

			select	 @JSONAdd				= ',"Parameters":{' + @ReplaceJSONToken + '}'
			select	 @JSONSnippet			= replace(@JSONSnippet,@ReplaceJSONToken,@JSONAdd); 
			select	 @JSONAdd				= NULL

			while	 @LoopCount				<= @LoopMax

			begin

				select 
						 @ObjectType				= ObjectType
						,@ParameterName				= ParameterName
						,@ParameterValue			= ParameterValue
				from	 @pSSISParameters
				where	 ParameterId				= @LoopCount

				select	 @JSONAdd	=	'"Set' + cast(@LoopCount as varchar(3)) + '":{"@ObjectType":"'		+ cast(isnull(@ObjectType,-1) as nvarchar(10)) + 
										'","@ParameterName":"'	+ cast(isnull(@ParameterName,-1) as nvarchar(128)) + 
										'","@ParameterValue":"'	+ cast(isnull(@ParameterValue,-1) as nvarchar(128)) + '"}' + @ReplaceJSONToken

				select	 @JSONSnippet = replace(@JSONSnippet,@ReplaceJSONToken,@JSONAdd); 
				select	 @JSONAdd	= NULL

				exec	 [$(SSISDB)].catalog.[set_execution_parameter_value]
						 @execution_id				= @ExecutionId
						,@object_type				= @ObjectType
						,@parameter_name			= @ParameterName
						,@parameter_value			= @ParameterValue
    
				select	 @LoopCount					= @LoopCount + 1
						,@ObjectType				= -1
						,@ParameterName				= 'N/A'
						,@ParameterValue			= 'N/A'		

			end  -- while	 @LoopCount					<= @LoopMax

		end  -- Load parameters

		select	 @JSONSnippet		= replace(@JSONSnippet,@ReplaceJSONToken,'}'); 
   
		exec	 [$(SSISDB)].catalog.[start_execution]
				 @execution_id		=  @ExecutionId

		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
	
		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
	end -- if
	else if ((@pAllowMultipleInstances = 0) and (@pExecuteProcessStatus = 'IAR'))
	begin
		-- There is nothing to do here. Only one instance can run at a time so send back IAR and let calling procedure figure out what to do.	
		select	 @JSONSnippet = '{"comment":"SSIS Package: '+isnull(@pSSISPackage,'No Package Name.')+ ' not run because another instance is already running."}'
		
	end -- if @pAllowMultipleInstances = 0
	else
	begin
			select	 @JSONSnippet = '{"comment":"SSIS Package: '+isnull(@pSSISPackage,'No Package Name.')+ ' not run because current status could not be established."}'
			;throw  50011, 'Could not establish if SSIS can run.', 1	-- Custom Error: 100001
	end

	select	 @JSONSnippet		= NULL
	select	 @pExecuteProcessStatus = 'ISS' -- Instance run succeded.

end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= getdate()

	if		 @@trancount > 1
		rollback transaction

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 1000000 -- Need to increase number to throw message.

	select	 @pExecuteProcessStatus = 'ISF' -- Instance run failed.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------

select 	 @PreviousDtm			= @CurrentDtm
select	 @CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
