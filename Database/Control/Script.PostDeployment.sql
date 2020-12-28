﻿/*

USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'IntraDay_RetryPostingGroup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'Run Posting Groups based', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'BRIDGEPOINT\sql_server', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trigger PostingGroup Processing stored procedure', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=5, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N' EXEC Control.pg.usp_TriggerPostingGroupProcessing -1,-1,0
					GO', 
		@database_name=N'Control', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'5 min schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20201008, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


*/

use Control
go



if not exists (select top 1 1 from ctl.Passphrase
	where	DatabaseName='Control'
	and		[SchemaName]='ctl'
	and		TableName='Publisher'
	and		[Passphrase]='Publisher')

insert into ctl.Passphrase (
	 [DatabaseName]
	,[SchemaName]
	,TableName
	,[Passphrase])
values( 
'Control',	'ctl',	'Publisher',	'Publisher');

go

if not exists (select top 1 1 from ctl.Passphrase
	where	DatabaseName='Control'
	and		[SchemaName]='ctl'
	and		TableName='Subscriber'
	and		[Passphrase]='Subscriber')

insert into ctl.Passphrase (
	 [DatabaseName]
	,[SchemaName]
	,TableName
	,[Passphrase])
values( 
'Control',	'ctl',	'Subscriber',	'Subscriber');

go



if not exists (select top 1 1 from ctl.Passphrase
	where	DatabaseName='BPI_DW'
	and		[SchemaName]='dbo'
	and		TableName='DimVendor'
	and		[Passphrase]='Vendor')

insert into ctl.Passphrase (
	 [DatabaseName]
	,[SchemaName]
	,TableName
	,[Passphrase])
values(
'BPI_DW',	'dbo',	'DimVendor',	'Vendor');


update   pgd
set		 pgd.DependencyName = pgC.PostingGroupName + '--To--' + pgP.PostingGroupName
		,pgd.DependencyCode = pgC.PostingGroupCode + ' --To-- ' + pgP.PostingGroupCode
from	 pg.PostingGroupDependency	  pgd
join	 pg.PostingGroup			  pgC
on		 pgC.PostingGroupId			= pgd.ChildId
join	 pg.PostingGroup			  pgP
on		 pgP.PostingGroupId			= pgd.ParentId