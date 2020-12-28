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
******************************************************************************/


-------------------------------------------------------------------------------
-- Declarations
-------------------------------------------------------------------------------
-- Verbose Helps dtermin how much output you want to see from the 
-- test process.

use Control

-- Cleanup

/*

select top 1000 * from   [pg].[PostingGroupProcessing]
select top 1000 * from    [pg].[PostingGroupProcessingStatus]
select top 1000 * from    [pg].[PostingGroupDependency]
select top 1000 * from     [pg].[PostingGroupBatch] 
select top 1000 * from     [pg].[PostingGroup] 
select top 1000 * from     [pg].refstatus


truncate table   [pg].[PostingGroupProcessing]
truncate table    [pg].[PostingGroupDependency]
truncate table     [pg].[PostingGroupBatch] 
truncate table     [pg].[PostingGroup] 
select top 1000 * from     [pg].refstatus



*/

delete PGP
from  [pg].[PostingGroupProcessing] PGP
join pg.PostingGroup PG
on PGP.PostingGroupId = PG.PostingGroupId
where PG.PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD')


delete PGD
from [pg].[PostingGroupDependency]PGD
join pg.PostingGroup PG
on PGD.ParentId = PG.PostingGroupId
where PG.PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD')

delete PGD
from [pg].[PostingGroupDependency]PGD
join pg.PostingGroup PG
on PGD.ChildId = PG.PostingGroupId
where PG.PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD')


delete pg.PostingGroup 
where PostingGroupCode in (
'PUBR01-SUBR01-PUBN01-ACCT'
,'PUBR01-SUBR01-PUBN02-ASSG'
,'PUBR01-SUBR02-PUBN02-ASSG'
,'TST-ACCT-ASSG-DIM-LOAD'
,'TST-ACCT-ASSG-FACT-LOAD')


--delete [pg].[PostingGroupBatch] 
--where PostingGroupBatchId = (select max(PostingGroupBatchId) from pg.[PostingGroupBatch])

--delete [pg].[PostingGroup] 
--delete [audit].StepLog


-- Reset Key Values.
/*
DBCC CHECKIDENT ('audit.[StepLog]', RESEED, 11000);
GO
*/
--select max(PostingGroupProcessingId) + 10 from pg.PostingGroupProcessing
/*
declare @PGPReSeed int = -1
--select @PGPReSeed = max(PostingGroupProcessingId) + 10 from pg.PostingGroupProcessing
select @PGPReSeed = 4100


DBCC CHECKIDENT ('pg.[PostingGroupProcessing]', RESEED)
--DBCC CHECKIDENT ('pg.[PostingGroupProcessing]', RESEED, @PGPReSeed);

GO
*/
/*
DBCC CHECKIDENT ('pg.[PostingGroupBatch]', RESEED, 0);
GO

DBCC CHECKIDENT ('pg.[PostingGroup]', RESEED, 100);
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
-- Create domain data specific to posting groups.
-------------------------------------------------------------------------------

-- execute the scripts to create test domain data. It must pair to the datahub test scripts
	IF EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='PostingGroup') 
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR01-SUBR01-PUBN01-ACCT')
	
			
			EXEC pg.InsertPostingGroup 	
				 @pCode			= 'PUBR01-SUBR01-PUBN01-ACCT'		
				,@pName			= 'Test Publisher 01 Sending Data to Subscriber 01. Publication 01 Account'
				,@pDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategory		= 'N/A'				
				,@pInterval		= 'HR'				
				,@pLength		= 1
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN01-ACCT.dtsx'	
				,@pIsActive		= 1
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR01-SUBR01-PUBN01-ACCT'	

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR01-SUBR01-PUBN02-ASSG')
			
			EXEC pg.InsertPostingGroup 	
				 @pCode			= 'PUBR01-SUBR01-PUBN02-ASSG'		
				,@pName			= 'Test Publisher 01 Sending Data to Subscriber 01. Publication 02 Assignment'
				,@pDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategory		= 'N/A'				
				,@pInterval		= 'HR'				
				,@pLength		= 1
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN02-ASSG.dtsx'	
				,@pIsActive		= 1
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR01-SUBR01-PUBN02-ASSG'

--	@SubscriptionCode":"PUBR01-SUBR02-PUBN02-ASSG"
		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR01-SUBR02-PUBN02-ASSG')
			
			EXEC pg.InsertPostingGroup 	
				 @pCode			= 'PUBR01-SUBR02-PUBN02-ASSG'		
				,@pName			= 'Test Publisher 01 Sending Data to Subscriber 02. Publication 02 Assignment'
				,@pDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategory		= 'N/A'				
				,@pInterval		= 'HR'				
				,@pLength		= 1
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN02-ASSG.dtsx'	
				,@pIsActive		= 1
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR01-SUBR02-PUBN02-ASSG'

--	@SubscriptionCode":"PUBR02-SUBR01-PUBN03-COUR"
		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'PUBR02-SUBR01-PUBN03-COUR')
			
			EXEC pg.InsertPostingGroup 	
				 @pCode			= 'PUBR02-SUBR01-PUBN03-COUR'		
				,@pName			= 'Test Publisher 02 Sending Data to Subscriber 01. Publication 03 Course'
				,@pDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
				,@pCategory		= 'N/A'				
				,@pInterval		= 'HR'				
				,@pLength		= 1
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'TSTPUBN03-COUR.dtsx'	
				,@pIsActive		= 1
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'PUBR02-SUBR01-PUBN03-COUR'

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'TST-ACCT-ASSG-DIM-LOAD')
			
			EXEC pg.InsertPostingGroup 	
				 @pCode			= 'TST-ACCT-ASSG-DIM-LOAD'		
				,@pName			= 'Test the account and assignment dimension load'
				,@pDesc			= 'This is the parent posting group to the Account and Assignment data hub staging load.'
				,@pCategory		= 'N/A'				
				,@pInterval		= 'HR'				
				,@pLength		= 1
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'	
				,@pSSISPackage	= 'ACCT-ASSG-DIM-LOAD.dtsx'	
				,@pIsActive		= 1
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'TST-ACCT-ASSG-DIM-LOAD'	

		IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD')
			
			EXEC pg.InsertPostingGroup 	
				 @pCode			= 'TST-ACCT-ASSG-FACT-LOAD'		
				,@pName			= 'Test the account and assignment fact load'
				,@pDesc			= 'This is the parent posting group to the Account and Assignment Dim load.'
				,@pCategory		= 'N/A'				
				,@pInterval		= 'HR'				
				,@pLength		= 1
				,@pSSISFolder	= 'RegressionTesting'	
				,@pSSISProject	= 'PostingGroup'		
				,@pSSISPackage	= 'ACCT-ASSG-FACT-LOAD.dtsx'	
				,@pIsActive		= 1
				,@pCreatedBy	= 'ffortunato'
				,@pETLExecutionId	= -1
				,@pPathId		= -1
				,@pVerbose		= 0

		print 'TST-ACCT-ASSG-FACT-LOAD'		

	end

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE childId =1 and parentid = 3)
	begin

--		select @PGParentId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'
--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'PUBR01-SUBR01-PUBN01-ACCT'

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

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE childId =2 and parentid = 3)
	begin

--		select @PGParentId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'
--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'PUBR01-SUBR01-PUBN02-ASSG'

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

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE childId =3 and parentid = 4)
	begin

--		select @PGParentId = postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-FACT-LOAD'
--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'

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

	IF NOT EXISTS (SELECT TOP 1 1 FROM pg.[PostingGroupDependency] WHERE childId =3 and parentid = 4)
	begin

--		select @PGParentId = postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-FACT-LOAD'
--		select @PGChildId =  postinggroupid from pg.PostingGroup where [PostingGroupCode] = 'TST-ACCT-ASSG-DIM-LOAD'

		exec pg.[InsertPostingGroupDependency] 
-- 			 @pParentId				=	@PGParentId
--			,@pChildId				=	@PGChildId
			 @pParentCode			=	'TST-ACCT-ASSG-FACT-LOAD'
			,@pChildCode			=	'PUBR02-SUBR01-PUBN03-COUR'
--			,@pParentName			=	'Test the account and assignment fact load'
--			,@pChildName			=	'Test the account and assignment dim load'
			,@pCreatedBy			=	'ffortunato'
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0
	end

-- Take a look to see that data propogated correctly.

if @Verbose in (1,3) begin
	 select 'Initial State PostingGroup' AS TestingStep, * from pg.PostingGroup
	 select 'Initial State PostingGroupDependency' AS TestingStep, * from pg.[PostingGroupDependency]
end 

-------------------------------------------------------------------------------
-- Test Case: Generate Notification
--
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
-- All Issue records are 'IC'
-- All Distribution records are 'DN' Distribution Awaiting Notification
-------------------------------------------------------------------------------

/*
 select top 100 * from Control.ctl.issue order by 1 desc 
 select top 100 * from Control.ctl.distribution
 select top 100 * from audit.steplog order by 1 desc
 select top 100 * from Control.audit.steplog order by 1 desc
*/
print 'break'
return

declare @IssueID int = -1

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN01-ACCT_20070112_01.txt'

exec Control.ctl.NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN01-ACCT_20070112_01.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0



select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN02-ASSG_20070112_01.txt'

exec Control.ctl.NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN02-ASSG_20070112_01.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0


if @Verbose in (1,3) begin
	select 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessingStatus
	select * from audit.StepLog order by 1 desc

end

-------------------------------------------------------------------------------
-- Post Condition:
-- New staging processes for Data Hub are complete.
-- Results
-- PUBR01-SUBR01-PUBN01-ACCT	PC
-- PUBR01-SUBR01-PUBN02-ASSG	PC
-- TST-ACCT-ASSG-DIM-LOAD		PC
-- PUBR01-SUBR02-PUBN02-ASSG	PC
-- TST-ACCT-ASSG-FACT-LOAD		PC
-------------------------------------------------------------------------------

if @Verbose in (1,3) begin
	select 'Initial State PostingGroupBatch     ' AS TestingStep, * from pg.PostingGroupBatch
	select 'Initial State PostingGroupProcessing' AS TestingStep, * from pg.PostingGroupProcessing
	select 'Initial State PostingGroupProcessingStatus' AS TestingStep, * from pg.PostingGroupProcessingstatus
	select top 100 * from audit.steplog order by 1 desc
end

-------------------------------------------------------------------------------
-- Test Case: Simulate  Running of packages that were Queued earlier in this 
-- regression. Complete the execution of 'TST-ACCT-ASSG-DIM-LOAD'
-- Execute processes that can run.
-------------------------------------------------------------------------------

/*
declare @BatchId int 
       ,@PostingGroup int
*/



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
		,@pStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pStatusCode			='PC'

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
	select 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessingStatus

end

-------------------------------------------------------------------------------
-- Post Condition:
-- All standalone staging jobs are set to Queued. TST-ACCT-ASSG-FACT-LOAD 
-- Results
-- Posting Groups 'TST-ACCT-ASSG-FACT-LOAD' = status: 'PQ'
-------------------------------------------------------------------------------

select @BatchId = max(PostingGroupBatchId) from pg.postinggroupbatch
select @PostingGroup = PostingGroupId from pg.postinggroup where PostingGroupCode = 'TST-ACCT-ASSG-FACT-LOAD'
select @PGBatchSeq = max(PGPBatchSeq) 
from	 pg.PostingGroupProcessing	  pgp 
join	 pg.PostingGroup			  pg
on		 pgp.PostingGroupId			= pg.PostingGroupId 
where	 PostingGroupCode			= 'TST-ACCT-ASSG-FACT-LOAD' 
and		 pgp.PostingGroupBatchId	= @BatchId

--print 'SHOULD BE SENDING DATA TO GRID'
--select 		isnull(@BatchId,-1),isnull(@PostingGroup,-1),isnull( @PGBatchSeq,-1)

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pStatusCode			='PC'

-------------------------------------------------------------------------------
-- Post Condition:
-- All standalone staging jobs are set to Queued. TST-ACCT-ASSG-FACT-LOAD 
-- Results
-- Posting Groups 'TST-ACCT-ASSG-FACT-LOAD' = status: 'PC'
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Test Case: Mark Distributions as complet.
-------------------------------------------------------------------------------
--declare @issueid int = -1
select @IssueId =  IssueId from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'


 exec Control.ctl.usp_UpdateDistributionStatus
 	 @pIssueId					= @IssueId
	,@pSubscriptionCode			= 'PUBR01-SUBR01-PUBN01-ACCT'
	,@pStatus					= 'DC'


select @IssueId =  IssueId from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'

  exec Control.ctl.usp_UpdateDistributionStatus
 	 @pIssueId					= @IssueId
	,@pSubscriptionCode			= 'PUBR01-SUBR01-PUBN02-ASSG'
	,@pStatus					= 'DC'

if @Verbose in (1,3) begin
	select 'DistResponse' AS TestingStep, * from pg.[PostingGroupProcessingStatus]
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
 select top 100 * from Control.ctl.issue
 select top 100 * from Control.ctl.distribution
 select top 100 * from audit.steplog order by 1 desc
 select top 100 * from Control.audit.steplog order by 1 desc
*/


-- declare @IssueId int = -1
select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100))
print 'IssueName: PUBN01-ACCT_20070112_02.txt'

delete pgp
from pg.postinggroupprocessing pgp
join pg.postinggroup pg
on pgp.PostingGroupId = pgp.PostingGroupId
where pg.PostingGroupCode in (
	'PUBR01-SUBR01-PUBN01-ACCT'
,	'PUBR01-SUBR01-PUBN02-ASSG'
	,'PUBR01-SUBR02-PUBN02-ASSG'
)
and pgp.[PGPBatchSeq] > 1

update ctl.distribution
set StatusId = (select statusid from ctl.refstatus where statuscode ='DN')
where IssueId = @IssueId


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'

exec Control.ctl.NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- PUBN01-ACCT_20070112_02.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0
/*
		print'break'
return
*/


 select top 100  * from audit.steplog order by 1 desc
 	select top 100 'Initial State PostingGroupProcessing' AS TestingStep, * from pg.PostingGroupProcessingStatus order by 2 

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

exec Control.ctl.NotifySubscriberOfDistribution
		 @pIssueId								= @IssueId -- @IssueId -- PUBN02-ASSG_20070112_02.txt
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0

-------------------------------------------------------------------------------
-- Post Condition:
-- Second Dim Load is Queued
-- Results
-- 2	TST-ACCT-ASSG-DIM-LOAD	PQ
-------------------------------------------------------------------------------


if @Verbose in (1,3) begin
	select top 100 'Initial State PostingGroupBatch     ' AS TestingStep, * from pg.PostingGroupBatch order by 2 desc
	select top 100 'Initial State PostingGroupProcessing' AS TestingStep, * from pg.PostingGroupProcessingStatus order by 2 
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

	   select * from pg.postinggroup

*/



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
		,@pStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pStatusCode			='PC'


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
	select 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessingStatus

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
		,@pStatusCode			='PP'

WAITFOR DELAY '00:00:01'

exec pg.UpdatePostingGroupProcessingStatus
		 @pPostingGroupBatchId	= @BatchId
		,@pPostingGroupId		= @PostingGroup
		,@pPostingGroupBatchSeq	= @PGBatchSeq
		,@pStatusCode			='PC'


-------------------------------------------------------------------------------
-- Post Condition:
-- Second Fact Load is Complete
-- Results
-- 2	TST-ACCT-ASSG-FACT-LOAD	PC
-------------------------------------------------------------------------------



if @Verbose in (1,3) begin
	select 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessingStatus

	select * from audit.StepLog order by 1 desc
	select * from ctl.distributionstatus 
	select 'Fun Stuff' AS TestingStep, * from pg.PostingGroupProcessing

	select * from ctl.PostingGroupDependencyDetails

end

