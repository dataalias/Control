/******************************************************************************
File:           tst_PostingGroupProcessing.sql
Name:           tst_PostingGroupProcessing

Purpose:        Series of test cases for posting groups. This series of scripts
				test the sunny day scenario of posting groups running. 
				PRECONDITION: The associated data hub test script must be run
				prior to executing this script.
				POSTCODITION: Two series of data loads for the test feeds
				and the associated dim and fact loads should be in a state of 
				PC complete.

				01) Script Cleans up previous run.
				10) script builds the assoicated posting groups for the loaded files.
				20) script builds the assoicated posting groups for the down stream processes (DIM, FACT and SQL Job loads).
				30) script builds the dependencies between each of the posting groups children and parents. 
					(When Child processes complete the Partent process is kicked off.)
				40) script kicks off round 1 of processing. Using first round of loaded files (from previous script)
				50) script kicks off round 2 of file loads
				60) script kicks off round 2 of posting group processing. Using second round of loaded files (from this script 50)


Parameters:     The parameters for this procedure are those from the posting 

  ,@Verbose     

  ,@PassVerbose 


Execution:      N/A

Called By:      QA

Author:         ffortunato
Date:           20161206

*******************************************************************************
       Change History
*******************************************************************************
Date      Author         Description
--------  -------------  ------------------------------------------------------

20161206  ffortunato     initial iteration
20180802  ffortunato     revaming after code changes to pg operations.
20180907  ffortunato     Doing look ups based on file name rather than hard
						 coded ids.
20180921  ffortunato     final updates for second round of processes to fire.
20201201  ffortunato     Adding cour2 file to complete.
20210325  ffortunato     FeedFOrmat --> FileFormatCode
20211008  ffortunato     Cleanup based on code changes.
******************************************************************************/


-------------------------------------------------------------------------------
-- Declarations
-------------------------------------------------------------------------------
-- Verbose Helps dtermin how much output you want to see from the 
-- test process.
/*
use Control
go
*/
-- Cleanup

/*
select top 1000 * from   [pg].[PostingGroup]  order by 1 asc 
select top 1000 * from   [pg].[PostingGroupProcessing] order by 1 asc 
select top 1000 * from   [pg].[PostingGroupProcessingStatus]
select top 1000 * from   [pg].[PostingGroupDependency]
select top 1000 * from   [pg].[PostingGroupBatch] 
select top 1000 * from   [pg].refstatus

*/

-- 01) Script cleans up previous run.

delete PGP
from  [pg].[PostingGroupProcessing] PGP
join pg.PostingGroup PG
on PGP.PostingGroupId = PG.PostingGroupId
where PG.PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'PUBR02-SUBR01-PUBN03-COUR'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD'
,'TST-COUR-FACT-LOAD'
,'TST-SQL-JOB-EXEC')


delete PGD
from [pg].[PostingGroupDependency]PGD
join pg.PostingGroup PG
on PGD.ParentId = PG.PostingGroupId
where PG.PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'PUBR02-SUBR01-PUBN03-COUR'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD'
,'TST-COUR-FACT-LOAD'
,'TST-SQL-JOB-EXEC')

delete PGD
from [pg].[PostingGroupDependency]PGD
join pg.PostingGroup PG
on PGD.ChildId = PG.PostingGroupId
where PG.PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'PUBR02-SUBR01-PUBN03-COUR'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD'
,'TST-COUR-FACT-LOAD'
,'TST-SQL-JOB-EXEC')


delete pg.PostingGroup 
where PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'PUBR02-SUBR01-PUBN03-COUR'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD'
,'TST-COUR-FACT-LOAD'
,'TST-SQL-JOB-EXEC')

print 'Clean Up complete'

--delete [pg].[PostingGroupBatch] 
--where PostingGroupBatchId = (select max(PostingGroupBatchId) from pg.[PostingGroupBatch])

--delete [pg].[PostingGroup] 
--delete [audit].StepLog


-- Reset Key Values.
/*
DBCC CHECKIDENT ('audit.[StepLog]', RESEED, 11000);
GO
*/


/*
select top 10 * from pg.[PostingGroupProcessing] order by 1 desc
select top 10 * from pg.[PostingGroup] order by 1 desc

declare @PGPReSeed int = -1
select @PGPReSeed = max(PostingGroupProcessingId) + 1 from pg.PostingGroupProcessing


DBCC CHECKIDENT ('pg.[PostingGroupProcessing]', RESEED, @PGPReSeed);
GO

DBCC CHECKIDENT ('pg.[PostingGroupBatch]', RESEED, 0);
GO


DBCC CHECKIDENT ('pg.[PostingGroup]', RESEED, 332);
GO

DBCC CHECKIDENT ('pg.[PostingGroupDependency]', RESEED, 0);
GO
*/
-------------------------------------------------------------------------------
-- Declaration and Initialization
-------------------------------------------------------------------------------

declare @Verbose        int
       ,@PassVerbose    bit
	   ,@BatchId        int
	   ,@PostingGroup   int
	   ,@PGBatchSeq		BIGINT
	   ,@PGParentId		int = -1
	   ,@PGChildId		int = -1

select  @Verbose		= 0
       ,@PassVerbose	= 0
	   ,@BatchId		= -1
	   ,@PostingGroup	= -1
	   ,@PGBatchSeq		= -1
	   

/*
@Verbose -- Parameter for local testing.
0 - Nothing
1 - Everything
2 - All Print Statments
3 - All Select Statments

@PassVerbose -- Parameter for testing procedures.
0 - False
1 - True
*/


-------------------------------------------------------------------------------
-- _If needed_ create a new batch record.
-------------------------------------------------------------------------------

DECLARE @CurDt DATETIME = GETDATE()
DECLARE @CurDtInt INT = CAST(CONVERT(VARCHAR(20),@CurDt,112) AS VARCHAR(20))
/*
IF NOT EXISTS (SELECT TOP 1 1 FROM  [pg].[PostingGroupBatch] WHERE dateid = @CurDtInt)
BEGIN

	INSERT INTO [pg].[PostingGroupBatch](
	dateid,createdby,createddtm) VALUES(
	CAST(CONVERT(VARCHAR(20),@CurDt,112) AS INT),'ffortunato',@CurDt)
end
*/

-------------------------------------------------------------------------------
-- 10) Create Posting Group records.
-- Create domain data specific to posting groups.
-- These are the inital connections of publications to an associated posting group.
-- There are the data staged from data hub.
-------------------------------------------------------------------------------

-- execute the scripts to create test domain data. It must pair to the datahub test scripts
	IF EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='PostingGroup') 
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR01-SUBR01-PUBN01-ACCT')
	
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'PUBR01-SUBR01-PUBN01-ACCT'		
				,@pPostingGroupName			= 'Test Publisher 01 Sending Data to Subscriber 01. Publication 01 Account'
				,@pPostingGroupDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategoryCode	= 'UNK'				
				,@pInterval		= 'DY'				
				,@pLength		= 1
				,@pProcessingMethodCode		= 'SSIS'
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN01-ACCT.dtsx'	
				,@pIsActive		= 1
			--	,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR01-SUBR01-PUBN01-ACCT'	

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR01-SUBR01-PUBN02-ASSG')
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'PUBR01-SUBR01-PUBN02-ASSG'		
				,@pPostingGroupName			= 'Test Publisher 01 Sending Data to Subscriber 01. Publication 02 Assignment'
				,@pPostingGroupDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategoryCode	= 'UNK'								
				,@pInterval		= 'WK'				
				,@pLength		= 1
				,@pProcessingMethodCode		= 'SSIS'
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN02-ASSG.dtsx'	
				,@pIsActive		= 1
			--	,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR01-SUBR01-PUBN02-ASSG'

--	@SubscriptionCode":"PUBR01-SUBR02-PUBN02-ASSG"
		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR01-SUBR02-PUBN02-ASSG')
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'PUBR01-SUBR02-PUBN02-ASSG'		
				,@pPostingGroupName			= 'Test Publisher 01 Sending Data to Subscriber 02. Publication 02 Assignment'
				,@pPostingGroupDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategoryCode	= 'UNK'							
				,@pInterval		= 'WK'				
				,@pLength		= 1
				,@pProcessingMethodCode		= 'SSIS'
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN02-ASSG.dtsx'	
				,@pIsActive		= 1
				--,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR01-SUBR02-PUBN02-ASSG'

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR02-SUBR01-PUBN03-COUR')
	
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'PUBR02-SUBR01-PUBN03-COUR'		
				,@pPostingGroupName			= 'Test Publisher 02 Sending Data to Subscriber 01. Publication 03 Course'
				,@pPostingGroupDesc			= 'Regression testing the hand off from DataHub to PostingGroup. This is a fact.'
				,@pCategoryCode	= 'UNK'						
				,@pInterval		= 'DY'				
				,@pLength		= 1
				,@pProcessingMethodCode		= 'SSIS'
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN01-COUR.dtsx'	
				,@pIsActive		= 1
				--,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR02-SUBR01-PUBN03-COUR'	

-------------------------------------------------------------------------------
-- Create domain data specific to posting groups.
-- Building a Dim load posting group that will be triggered after data is staged.
-------------------------------------------------------------------------------

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'TST-ACCT-ASSG-DIM-LOAD')
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'TST-ACCT-ASSG-DIM-LOAD'		
				,@pPostingGroupName			= 'Test the account and assignment dimension load'
				,@pPostingGroupDesc			= 'This is the parent posting group to the Account and Assignment data hub staging load.'
				,@pCategoryCode	= 'UNK'						
				,@pInterval		= 'DY'				
				,@pLength		= 1
				,@pProcessingMethodCode		= 'SSIS'
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'ACCT-ASSG-DIM-LOAD.dtsx'	
				,@pIsActive		= 1
			--	,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'TST-ACCT-ASSG-DIM-LOAD'	

-------------------------------------------------------------------------------
-- Create domain data specific to posting groups.
-- Building a fact load posting group that will be triggered after dim and staged data is run.
-------------------------------------------------------------------------------

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD')
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'TST-ACCT-ASSG-FACT-LOAD'		
				,@pPostingGroupName			= 'Test the account and assignment fact load'
				,@pPostingGroupDesc			= 'This is the parent posting group to the Account and Assignment Dim load.'
				,@pCategoryCode	= 'UNK'				
				,@pProcessingMethodCode			= 'ADFP'
				,@pProcessingModeCode			= 'INIT'
				,@pInterval		= 'DY'				
				,@pLength		= 1
				,@pSSISFolder	= 'N/A'	
				,@pSSISProject	= 'N/A'		
				,@pSSISPackage	= 'N/A'
				,@pDataFactoryName     = 'PostingGroup'		
				,@pDataFactoryPipeline = 'PL-AccountAssgnmentFactLoad'
				,@pIsActive		= 1
				--,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'TST-ACCT-ASSG-FACT-LOAD'		

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'TST-COUR-FACT-LOAD')
			
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'TST-COUR-FACT-LOAD'		
				,@pPostingGroupName			= 'Test the course fact load'
				,@pPostingGroupDesc			= 'This is the parent posting group to the Course staging process.'
			,@pCategoryCode	= 'UNK'						
				,@pInterval		= 'DY'				
				,@pLength		= 1
				,@pProcessingMethodCode		= 'SSIS'
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'		
				,@pSSISPackage	= 'COUR-FACT-LOAD.dtsx'	
				,@pIsActive		= 1
				--,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'TST-COUR-FACT-LOAD'	

	end

	-- New Posting group to test sql job execution.
	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'TST-SQL-JOB-EXEC')
	begin		
			EXEC pg.InsertPostingGroup 	
				 @pPostingGroupCode			= 'TST-SQL-JOB-EXEC'		
				,@pPostingGroupName			= 'Test Posting Group SQL Job Execution'
				,@pPostingGroupDesc			= 'See if we can get a sql server job to run.'
			,@pCategoryCode	= 'UNK'				
				,@pProcessingMethodCode			= 'SQLJ'
				,@pProcessingModeCode			= 'NORM'
				,@pInterval		= 'DY'				
				,@pLength		= 1
				,@pSSISFolder	= 'N/A'
				,@pSSISProject	= 'N/A'
				,@pSSISPackage	= 'N/A'
				,@pJobName		= 'Test Posting Group SQL Job Execution'
				,@pIsActive		= 1
				--,@pTriggerType			= 'Immediate'
				,@pNextExecutionDtm		= '01-Jan-1900'
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0
		end

-- Meh add the actual codes to the scripts later.
update pg.PostingGroup
set ProcessingMethodCode = 'SSIS'
where ProcessingMethodCode = 'DFP'

print '----------------------------------------------------------'
print 'Posting Groups Created.'
print '----------------------------------------------------------'


--select * from pg.PostingGroup
--select * from pg.PostingGroupdependency


-------------------------------------------------------------------------------
-- 20) Build posting group dependencies.
-- PUBR01-SUBR01-PUBN01-ACCT --To-- TST-ACCT-ASSG-DIM-LOAD
-- PUBR01-SUBR01-PUBN02-ASSG --To-- TST-ACCT-ASSG-DIM-LOAD
-- PUBR02-SUBR01-PUBN03-COUR --To-- TST-ACCT-ASSG-FACT-LOAD
-- PUBR02-SUBR01-PUBN03-COUR --To-- TST-COUR-FACT-LOAD
-- TST-ACCT-ASSG-DIM-LOAD    --To-- TST-ACCT-ASSG-FACT-LOAD
-- TST-ACCT-ASSG-FACT-LOAD   --To-- TST-SQL-JOB-EXEC
-------------------------------------------------------------------------------


	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE DependencyCode = 'PUBR01-SUBR01-PUBN01-ACCT--To--TST-ACCT-ASSG-DIM-LOAD')
	begin

--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'PUBR01-SUBR01-PUBN01-ACCT'
--		select @PGParentId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'

-------------------------------------------------------------------------------
-- Building Dependency
-- Acct --> Account Dim
-------------------------------------------------------------------------------


		exec pg.[InsertPostingGroupDependency] 
-- 			 @pParentId				=	@PGParentId
--			,@pChildId				=	@PGChildId
			 @pParentCode			=	'TST-ACCT-ASSG-DIM-LOAD'
			,@pChildCode			=	'PUBR01-SUBR01-PUBN01-ACCT'
--			,@pParentName			=	'Test the account and assignment dimension load'
--			,@pChildName			=	'Test Publisher 01 Sending Data to Subscriber 01. Publication 01 Account'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] where DependencyCode = 'PUBR01-SUBR01-PUBN02-ASSG--To--TST-ACCT-ASSG-DIM-LOAD')
	begin

--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'PUBR01-SUBR01-PUBN02-ASSG'
--		select @PGParentId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'

-------------------------------------------------------------------------------
-- Building Dependency
-- Assg --> Assignment Dim (same dim load)
-------------------------------------------------------------------------------


		exec pg.[InsertPostingGroupDependency] 
-- 			 @pParentId				=	3
--			,@pChildId				=	2
			 @pParentCode			=	'TST-ACCT-ASSG-DIM-LOAD'
			,@pChildCode			=	'PUBR01-SUBR01-PUBN02-ASSG'
--			,@pParentName			=	'Test the account and assignment dimension load'
--			,@pChildName			=	'Test Publisher 01 Sending Data to Subscriber 01. Publication 02 Assignment'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE  DependencyCode = 'TST-ACCT-ASSG-DIM-LOAD--To--TST-ACCT-ASSG-FACT-LOAD')
	begin

--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'
--		select @PGParentId = postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-FACT-LOAD'

-------------------------------------------------------------------------------
-- Building Dependency
-- ASSG-DIM --> ASSG-FACT
-------------------------------------------------------------------------------


		exec pg.[InsertPostingGroupDependency] 
-- 			 @pParentId				=	@PGParentId
--			,@pChildId				=	@PGChildId
			 @pParentCode			=	'TST-ACCT-ASSG-FACT-LOAD'
			,@pChildCode			=	'TST-ACCT-ASSG-DIM-LOAD'
--			,@pParentName			=	'Test the account and assignment fact load'
--			,@pChildName			=	'Test the account and assignment dim load'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end
-- Take a look to see that data propogated correctly.

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency]  WHERE  DependencyCode = 'PUBR02-SUBR01-PUBN03-COUR--To--TST-ACCT-ASSG-FACT-LOAD')
	begin

-------------------------------------------------------------------------------
-- Building Dependency
-- COURSE --> ASSG-FACT
-------------------------------------------------------------------------------

--		table need to stage for fact to work
		exec pg.[InsertPostingGroupDependency] 
			 @pParentCode			=	'TST-ACCT-ASSG-FACT-LOAD'
			,@pChildCode			=	'PUBR02-SUBR01-PUBN03-COUR'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE  DependencyCode = 'PUBR02-SUBR01-PUBN03-COUR--To--TST-ACCT-ASSG-FACT-LOAD')
	begin

-------------------------------------------------------------------------------
-- Building Dependency
-- COURSE --> ASSG-FACT
-------------------------------------------------------------------------------

--		table need to stage for fact to work
		exec pg.[InsertPostingGroupDependency] 
			 @pParentCode			=	'TST-COUR-FACT-LOAD'
			,@pChildCode			=	'PUBR02-SUBR01-PUBN03-COUR'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end

/*Skip SQL Agent Job trigger.
	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE  DependencyCode = 'TST-ACCT-FACT-LOAD--To--TST-SQL-JOB-EXEC')
	begin
-------------------------------------------------------------------------------
-- Building Dependency
-- ASSG-FACT --> TST-SQL-JOB-EXEC
-------------------------------------------------------------------------------
 
--		table need to stage for fact to work
		exec pg.[InsertPostingGroupDependency] 
			 @pParentCode			=	'TST-SQL-JOB-EXEC'
			,@pChildCode			=	'TST-ACCT-ASSG-FACT-LOAD'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end
*/
-- Take a look to see that data propogated correctly.
print '----------------------------------------------------------'
print 'Posting Group Dependencies Created.'
print '----------------------------------------------------------'

if @Verbose in (1,3) begin
	 select 'Initial State PostingGroup' AS TestingStep, * from pg.PostingGroup
	 select 'Initial State PostingGroupDependency' AS TestingStep, * from pg.[PostingGroupDependency]
end 

-------------------------------------------------------------------------------
-- Test Case: Generate Notification
-- 40) Kicking off the first round of posting groups.
-- Mimic a datahub notification for new isues comming across.
-- Mimic the processing for checking for downstream dependencies.
-- Mimic processing for packacges that have their dependencies met.
-- This process would normally be fired by the data hub notification process
-- or the function app (future)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Pre Condition:
-- * Assumes the tst_DataHub.sql has been run.
-- All staging processes for Data Hub are complete.
-- Issues and Distributions have been created
-- Seq (1) Issue records are 'IL' Issue Loaded
-- Seq (2) Issue records are 'IP' Issue Prepared
-- All Distribution records are 'DN' Distribution Awaiting Notification
-------------------------------------------------------------------------------

/*
 select top 100 * from ctl.issue order by 1 desc 
 select top 100 * from ctl.distribution
 select top 100 * from audit.steplog order by 1 desc
 select top 100 * from audit.steplog order by 1 desc
 	select top 100 'Initial State PostingGroupProcessing' AS TestingStep, * from pg.PostingGroupProcessing order by 2 desc
	select * from pg.PostingGroup where postinggroupid = 337
*/

declare @IssueID int = -1


--select * from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN01-ACCT_20070112_01.txt'

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN01-ACCT_20070112_01.txt
--		,@pStageStart							= '2020-11-24 02:24:13.483'
--		,@pStageEnd								= '2020-11-24 08:24:13.483'
--		,@pIsDataHub							= 1
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0



select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN02-ASSG_20070112_01.txt'

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN02-ASSG_20070112_01.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0

--declare @IssueId  int = -1

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN03-COUR_20070112_01.txt'

--select * from pg.postinggroup
--select * from pg.vw_PostingGroupProcessingStatus
--PUBR02-SUBR01-PUBN03-COUR

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN03-COUR_20070112_01.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0

print '----------------------------------------------------------'
print 'Seq (1) notify complete.'
print '----------------------------------------------------------'



if @Verbose in (1,3) begin
	select 'Fun Stuff' AS TestingStep, * from pg.vw_PostingGroupProcessingStatus
	select * from audit.StepLog order by 1 desc
	select top 100 * from ctl.issue order by 1 desc 

end

-------------------------------------------------------------------------------
-- Post Condition:
-- New staging processes for Data Hub are complete.
-- Results
-- PUBR01-SUBR01-PUBN01-ACCT	PC
-- PUBR01-SUBR01-PUBN02-ASSG	PC
-- TST-ACCT-ASSG-DIM-LOAD		PQ
-- PUBR01-SUBR02-PUBN02-ASSG	PC
-------------------------------------------------------------------------------



if @Verbose in (1,3) begin
	select 'Initial State PostingGroupBatch     ' AS TestingStep, * from pg.PostingGroupBatch 
	select 'Initial State PostingGroupProcessing' AS TestingStep, pg.PostingGroupCode, rs.StatusCode, * 
			from pg.PostingGroupProcessing pgp
			join pg.RefStatus rs  on  pgp.PostingGroupStatusId = rs.StatusId
			join pg.PostingGroup pg on pg.PostingGroupId = pgp.PostingGroupId
			where pgp.PostingGroupId in (
				select PostingGroupId from pg.PostingGroup 
				where PostingGroupCode in ('PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR01-PUBN03-COUR','TST-ACCT-ASSG-DIM-LOAD','TST-ACCT-ASSG-FACT-LOAD','TST-COUR-FACT-LOAD'))
	select top 100 * from audit.steplog order by 1 desc
end

-------------------------------------------------------------------------------
-- Test Case: Simulate  Running of packages that were Queued earlier in this 
-- regression. Complete the execution of 'TST-ACCT-ASSG-DIM-LOAD'
-- Execute processes that can run.
-- Here we mimic what the SSIS /data facotry package should do.
-------------------------------------------------------------------------------

/*
declare @BatchId int 
       ,@PostingGroup int
	   ,@PGBatchSeq int
	   ,@PGChildId int = -1
	   ,@Verbose int = 0
	
*/


-- Waiting for 5 seconds to ensure logging in postingGropuProcessing works.
-- Process is queued from previous step. Gathering associated processing data then mimicing the run of an ETL package moving the process from PP to PC
WAITFOR DELAY '00:00:01'

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-ACCT-ASSG-DIM-LOAD'

select	 @PGBatchSeq				= max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId
where	 PostingGroupCode			= 'TST-ACCT-ASSG-DIM-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...
and		 pgp.PostingGroupBatchId	= @BatchId   --696 


if @Verbose in (1,3) begin
	--select 		isnull(@BatchId,-1) as batchId,isnull(@PostingGroup,-1) as PostingGroup ,isnull( @PGBatchSeq,-1) as BatchSeq
	print '@BatchId: ' + cast(isnull(@BatchId,-1)as varchar(20))
	print '@PostingGroup: ' + cast(isnull(@PostingGroup,-1)as varchar(20))
	print '@PGBatchSeq: ' + cast(isnull(@PGBatchSeq,-1)as varchar(20))

	select top 100 * from pg.PostingGroupProcessing 
	where PostingGroupBatchId=@BatchId
	and PostingGroupId=@PostingGroup
	and PGPBatchSeq=@PGBatchSeq
	order by 1 desc
end


exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode ='PP'

	
WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode ='PC'

print '----------------------------------------------------------'
print 'TST-ACCT-ASSG-DIM-LOAD run to completion.'
print '----------------------------------------------------------'

-------------------------------------------------------------------------------
-- Post Condition:
-- All standalone staging jobs are set to Queued.
-- Results
-- Posting Groups 'TST-ACCT-ASSG-DIM-LOAD' = status: 'PC'
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Test Case: Run Process with met Dependicies.
-- Execute processes that can run after 'TST-ACCT-ASSG-DIM-LOAD'
-- During this pass it should be all the unpack steps.
-------------------------------------------------------------------------------

print '----------------------------------------------------------'
print 'Test Case: TST-ACCT-ASSG-DIM-LOAD Run Process with met Dependicies.'
print '----------------------------------------------------------'


/*
declare @BatchId int 
       ,@PostingGroup int
	   ,@PGBatchSeq int
	   ,@PGChildId int = -1
	   ,@Verbose int = 0
*/

select @BatchId		 = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PGChildId	 = PostingGroupId from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'
select @PGBatchSeq   = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing  pgp
join	 pg.PostingGroup pg
on		 pgp.PostingGroupId = pg.PostingGroupId
where	 pg.PostingGroupCode = 'TST-ACCT-ASSG-DIM-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...

exec pg.ExecutePostingGroupProcessing 
		 @pPGBId				= @BatchId
		,@pPGId					= @PGChildId -- 2 -- one of the child PGIds
		,@pPGBatchSeq			= @PGBatchSeq
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0


print '----------------------------------------------------------'
print 'Round 1 ExecutePostingGroupProcessing.'
print '----------------------------------------------------------'

if @Verbose in (1,3) begin
	select 'Fun Stuff' AS TestingStep, * from pg.vw_PostingGroupProcessingStatus

end


if @Verbose in (1,3) begin
	select 'Initial State PostingGroupProcessing' AS TestingStep, pg.PostingGroupCode, rs.StatusCode, * 
			from pg.PostingGroupProcessing pgp
			join pg.RefStatus rs  on  pgp.PostingGroupStatusId = rs.StatusId
			join pg.PostingGroup pg on pg.PostingGroupId = pgp.PostingGroupId
			where pgp.PostingGroupId in (select PostingGroupId from pg.PostingGroup 
				where PostingGroupCode in ('PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR01-PUBN03-COUR','TST-ACCT-ASSG-DIM-LOAD','TST-ACCT-ASSG-FACT-LOAD','TST-COUR-FACT-LOAD'))
end

-------------------------------------------------------------------------------
-- Post Condition:
-- All standalone staging jobs are set to Queued. TST-ACCT-ASSG-FACT-LOAD 
-- Results
-- Posting Groups 'TST-ACCT-ASSG-FACT-LOAD' = status: 'PQ'
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Test Case: Mimic the run of TST-ACCT-ASSG-FACT-LOAD
-- Update statuses for TST-ACCT-ASSG-FACT-LOAD accordingly
-------------------------------------------------------------------------------

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD'


select @PGBatchSeq = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp 
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId 
where	 PostingGroupCode			= 'TST-ACCT-ASSG-FACT-LOAD' 
and		 pgp.PostingGroupBatchId	= @BatchId


select @Verbose = 3

if @Verbose in (1,3) begin
	print 'UpdatePostingGroupProcessingStatus'
	print '@BatchId: ' + cast(isnull(@BatchId,-1)as varchar(20))
	print '@PostingGroup: ' + cast(isnull(@PostingGroup,-1)as varchar(20))
	print '@PGBatchSeq: ' + cast(isnull(@PGBatchSeq,-1)as varchar(20))
	print '... for TST-ACCT-ASSG-FACT-LOAD'
end

select @Verbose = 0

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'

print '----------------------------------------------------------------'
print 'Round 1 TST-ACCT-ASSG-FACT-LOAD PostingGroupProcessing complete.'
print '----------------------------------------------------------------'

-------------------------------------------------------------------------------
-- Post Condition:
-- All standalone staging jobs are set to Queued. TST-ACCT-ASSG-FACT-LOAD 
-- Results:
-- Posting Groups 'TST-ACCT-ASSG-FACT-LOAD' status = 'PC'
-------------------------------------------------------------------------------

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD'

-- Getting TST-COUR-FACT-LOAD kicked off. $$$$

select @PGBatchSeq = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp 
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId 
where	 PostingGroupCode			= 'TST-COUR-FACT-LOAD' 
and		 pgp.PostingGroupBatchId	= @BatchId


select @Verbose = 3

if @Verbose in (1,3) begin
	print 'UpdatePostingGroupProcessingStatus for: TST-COUR-FACT-LOAD'
	print '@BatchId: ' + cast(isnull(@BatchId,-1)as varchar(20))
	print '@PostingGroup: ' + cast(isnull(@PostingGroup,-1)as varchar(20))
	print '@PGBatchSeq: ' + cast(isnull(@PGBatchSeq,-1)as varchar(20))
	print '... for TST-COUR-FACT-LOAD'
end

select @Verbose = 0

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'

print '----------------------------------------------------------'
print 'Round 1 TST-COUR-FACT-LOAD status update complete.'
print '----------------------------------------------------------'

-------------------------------------------------------------------------------
-- Post Condition:
-- All standalone staging jobs are set to Queued. TST-ACCT-ASSG-FACT-LOAD 
-- Results
-- Posting Groups 'TST-ACCT-ASSG-FACT-LOAD' = status: 'PC'
-------------------------------------------------------------------------------

--$$$$ HERERE

print '----------------------------------------------------------'
print 'Test Case: TST-SQL-JOB-EXEC Run Process with met Dependicies.'
print '----------------------------------------------------------'


/*
declare @BatchId int 
       ,@PostingGroup int
	   ,@PGBatchSeq int
	   ,@PGChildId int = -1
	   ,@Verbose int = 0
*/

-- simulate the previous job executing to completion and calling to see if the next job should run.

select @BatchId		 = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PGChildId	 = PostingGroupId from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-FACT-LOAD'
select @PGBatchSeq   = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing  pgp
join	 pg.PostingGroup pg
on		 pgp.PostingGroupId = pg.PostingGroupId
where	 pg.PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...

exec pg.ExecutePostingGroupProcessing 
		 @pPGBId				= @BatchId
		,@pPGId					= @PGChildId -- 2 -- one of the child PGIds
		,@pPGBatchSeq			= @PGBatchSeq
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0

-- now im queued. ill pretend to run the job.
-- Getting TST-COUR-FACT-LOAD kicked off. $$$$
/* Doing this directly in the job instead


select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-SQL-JOB-EXEC'


select @PGBatchSeq = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp 
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId 
where	 PostingGroupCode			= 'TST-SQL-JOB-EXEC' 
and		 pgp.PostingGroupBatchId	= @BatchId


select @Verbose = 3

if @Verbose in (1,3) begin
	print 'UpdatePostingGroupProcessingStatus for: TST-SQL-JOB-EXEC'
	print '@BatchId: ' + cast(isnull(@BatchId,-1)as varchar(20))
	print '@PostingGroup: ' + cast(isnull(@PostingGroup,-1)as varchar(20))
	print '@PGBatchSeq: ' + cast(isnull(@PGBatchSeq,-1)as varchar(20))
	print '... for TST-SQL-JOB-EXEC'
end

select @Verbose = 0

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'
*/
print '----------------------------------------------------------'
print 'Round 1 Execute TST-ACCT-ASSG-FACT-LOAD PostingGroupProcessing.'
print '----------------------------------------------------------'

-- ENDING HERE
--return


-------------------------------------------------------------------------------
-- Test Case: Mark Distributions as complete.
-------------------------------------------------------------------------------
--declare @issueid int = -1
select @IssueId =  IssueId from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'

--was comment start
 exec ctl.usp_UpdateDistributionStatus
 	 @pIssueId					= @IssueId
	,@pSubscriptionCode			= 'PUBR01-SUBR01-PUBN01-ACCT'
	,@pStatus					= 'DC'


select @IssueId =  IssueId from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'

  exec ctl.usp_UpdateDistributionStatus
 	 @pIssueId					= @IssueId
	,@pSubscriptionCode			= 'PUBR01-SUBR01-PUBN02-ASSG'
	,@pStatus					= 'DC'
-- was comment end

print '----------------------------------------------------------'
print 'Distribution set to complete.'
print '----------------------------------------------------------'

if @Verbose in (1,3) begin
	select top 100 'DistResponse' AS TestingStep, * from pg.[vw_PostingGroupProcessingStatus] order by 2 desc 
		select * from ctl.distributionstatus 
end



-------------------------------------------------------------------------------
-- Post Condition:
-- Distributions are marked as complete.
-- Results
-- Distribution status: 'DC'
-------------------------------------------------------------------------------

if @Verbose in (1,3) begin
	select 'Watcher' As TestStep, * from pg.PostingGroupProcessing
	select 'StatusCodes' As TestStep, * from pg.RefStatus
end



-------------------------------------------------------------------------------
-- Test Case: Run Second set of Notifications (withinin same batch)
-- Execute processes that can run.
-- During this pass it should be all the unpack steps.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Pre Condition:
-- All previous testcases have executed correctly./
-- tst_DataHub.sql has been run.
-------------------------------------------------------------------------------

/*
 select top 100 * from ctl.issue
 select top 100 * from ctl.distribution
 select top 100 * from audit.steplog order by 1 desc
 select top 100 * from audit.steplog order by 1 desc
*/


-- declare @IssueId int = -1
select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100))
print 'IssueName: PUBN01-ACCT_20070112_02.txt'


update ctl.distribution
set StatusId = (select statusid from ctl.refstatus where statuscode ='DN')
where IssueId = @IssueId


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN01-ACCT_20070112_02.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0
/*
		print'break'
return



 select top 100  * from audit.steplog order by 1 desc
 	select top 100 'Initial State PostingGroupProcessing' AS TestingStep, * from pg.vw_PostingGroupProcessingStatus order by 2 
*/
-- declare @IssueId int = -1

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100))
print 'IssueName: PUBN02-ASSG_20070112_02.txt'

update ctl.distribution
set StatusId = (select statusId from ctl.refstatus where statuscode ='DN')
where IssueId = @IssueId

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- @IssueId -- PUBN02-ASSG_20070112_02.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100))
print 'IssueName: PUBN03-COUR_20070112_02.txt'

update ctl.distribution
set StatusId = (select statusId from ctl.refstatus where statuscode ='DN')
where IssueId = @IssueId

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- @IssueId -- 'PUBN02-COUR_20070112_02.txt'
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0

-------------------------------------------------------------------------------
-- Post Condition:
-- Second Dim Load is Queued
-- Results
-- 2	TST-ACCT-ASSG-DIM-LOAD	PQ
-- 2   PUBN02-COUR_20070112_02.txt 'IL'
-------------------------------------------------------------------------------


if @Verbose in (1,3) begin
	select top 100 'Initial State PostingGroupBatch     ' AS TestingStep, * from pg.PostingGroupBatch order by 2 desc
	select top 100 'Initial State PostingGroupProcessing' AS TestingStep, * from pg.vw_PostingGroupProcessingStatus order by 2 
	select top 100 * from audit.steplog where processname in ('NotifySubscriberOfDistribution','ExecutePostingGroupProcessing')order by 1 desc 
end


-------------------------------------------------------------------------------
-- Test Case: Simulate  Running of packages that were Queued earlier in this 
-- regression. Complete the execution of 'TST-ACCT-ASSG-DIM-LOAD' Run 2
-- Execute processes that can run.
-------------------------------------------------------------------------------

/*
declare @BatchId int 
       ,@PostingGroup int
*/


print '----------------------------------------------------------'
print 'Test Case: Simulate  Running of packages that were Queued earlier in this test.'
print '----------------------------------------------------------'

-- Waiting for 5 seconds to ensure logging in postingGropuProcessing works.
WAITFOR DELAY '00:00:01'

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-ACCT-ASSG-DIM-LOAD'

select	 @PGBatchSeq				= max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId
where	 PostingGroupCode			= 'TST-ACCT-ASSG-DIM-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...
and		 pgp.PostingGroupBatchId	= @BatchId

--print 'SHOULD BE SENDING DATA TO GRID'
--select 		isnull(@BatchId,-1),isnull(@PostingGroup,-1),isnull( @PGBatchSeq,-1)

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'


-------------------------------------------------------------------------------
-- Post Condition:
-- Second Dim Load is Queued
-- Results
-- 2	TST-ACCT-ASSG-DIM-LOAD	PC
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Test Case: Run Process with met Dependicies for next level parent (2nd run / seq).
-- Execute processes that can run.  TST-ACCT-ASSG-FACT-LOAD
-- During this pass it should be all the unpack steps.
-------------------------------------------------------------------------------
print '----------------------------------------------------------'
print 'Test Case: TST-ACCT-ASSG-FACT-LOAD Run Process with met Dependicies for next level parent (2nd run / seq).'
print '----------------------------------------------------------'



select @PGChildId =  PostingGroupId from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'
select @PGBatchSeq   = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing  pgp
join	 pg.PostingGroup pg
on		 pgp.PostingGroupId = pg.PostingGroupId
where	 pg.PostingGroupCode = 'TST-ACCT-ASSG-DIM-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...


exec pg.ExecutePostingGroupProcessing 
		 @pPGBId				= @BatchId
		,@pPGId					= @PGChildId -- 2 -- one of the child PGIds
		,@pPGBatchSeq			= @PGBatchSeq
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0

if @Verbose in (1,3) begin
	select 'Fun Stuff' AS TestingStep, * from pg.vw_PostingGroupProcessingStatus

	select * from audit.StepLog order by 1 desc
	select * from ctl.distributionstatus 
	select 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessing
end

-------------------------------------------------------------------------------
-- Post Condition:
-- Second Fact Load is Queued
-- Results
-- 2	TST-ACCT-ASSG-FACT-LOAD	PQ
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Test Case: Simulate  Running of packages that were Queued earlier in this 
-- regression. Complete the execution of 'TST-ACCT-ASSG-DIM-LOAD' Run 2
-- Execute processes that can run.
-------------------------------------------------------------------------------
print '----------------------------------------------------------'
print ' Test Case: TST-ACCT-ASSG-DIM-LOAD Simulate  Running of packages that were Queued earlier in this regression'
print '----------------------------------------------------------'

/*
declare @BatchId int 
       ,@PostingGroup int
*/
-- Waiting for 5 seconds to ensure logging in postingGropuProcessing works.
WAITFOR DELAY '00:00:01'

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD'

select	 @PGBatchSeq				= max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId
where	 PostingGroupCode			= 'TST-ACCT-ASSG-FACT-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...
and		 pgp.PostingGroupBatchId	= @BatchId

--print 'SHOULD BE SENDING DATA TO GRID'
--select 		isnull(@BatchId,-1),isnull(@PostingGroup,-1),isnull( @PGBatchSeq,-1)

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'


print 'TST-ACCT-ASSG-FACT-LOAD is complete'

		

WAITFOR DELAY '00:00:01'

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-COUR-FACT-LOAD'

select	 @PGBatchSeq				= max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId
where	 PostingGroupCode			= 'TST-COUR-FACT-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...
and		 pgp.PostingGroupBatchId	= @BatchId

--print 'SHOULD BE SENDING DATA TO GRID'
--select 		isnull(@BatchId,-1),isnull(@PostingGroup,-1),isnull( @PGBatchSeq,-1)

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'

print 'TST-COUR-FACT-LOAD is complete'

WAITFOR DELAY '00:00:01'
-- NEED THE EXECUTE HERE $$$$$
select @PGChildId =  PostingGroupId from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-FACT-LOAD'
select @PGBatchSeq   = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing  pgp
join	 pg.PostingGroup pg
on		 pgp.PostingGroupId = pg.PostingGroupId
where	 pg.PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD'  --= 1 -- SHOULD GET THIS DYNAMIC...


exec pg.ExecutePostingGroupProcessing 
		 @pPGBId				= @BatchId
		,@pPGId					= @PGChildId -- 2 -- one of the child PGIds
		,@pPGBatchSeq			= @PGBatchSeq
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0

/*
We dont want to test the Execution of the SQL Job.

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-SQL-JOB-EXEC'

select	 @PGBatchSeq				= max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId
where	 PostingGroupCode			= 'TST-SQL-JOB-EXEC'  --= 1 -- SHOULD GET THIS DYNAMIC...
and		 pgp.PostingGroupBatchId	= @BatchId

--print 'SHOULD BE SENDING DATA TO GRID'
--select 		isnull(@BatchId,-1),isnull(@PostingGroup,-1),isnull( @PGBatchSeq,-1)

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pPostingGroupStatusCode			='PC'

print 'TST-SQL-JOB-EXEC is complete'
*/
-------------------------------------------------------------------------------
-- Post Condition:
-- Second Fact Load is Complete
-- Results
-- 2	TST-ACCT-ASSG-FACT-LOAD	PC
-------------------------------------------------------------------------------



if @Verbose in (1,3) begin
	select 'Fun Stuff' AS TestingStep, * from pg.vw_PostingGroupProcessingStatus

	select * from audit.StepLog order by 1 desc
	select * from ctl.distributionstatus 
	select top 100 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessing order by 2 desc 
end



Print 'Dunzo'
