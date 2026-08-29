/******************************************************************************
File:           pgDomainData.sql
Name:           Posting Group Domain Data

Purpose:        This file is used to manage the meta data needed by pubsub.

Execution:      N/A

Called By:      Deployment / Release Process

Author:         ffortunato
Date:           20180412

*******************************************************************************
       Change History
*******************************************************************************
Date      Author         Description
--------  -------------  ------------------------------------------------------

20180412  ffortunato     initial iteration
20210105  ffortunato     more if statements

******************************************************************************/

print 'Start PostingGroup Reference data inserts'

use [$(DatabaseName)]
go

DECLARE @CurDt DATETIME = GETDATE()
DECLARE @CurDtInt INT = CAST(CONVERT(VARCHAR(20),@CurDt,112) AS VARCHAR(20))

IF NOT EXISTS (SELECT TOP 1 1 FROM  [pg].[PostingGroupBatch] WHERE dateid = @CurDtInt)
BEGIN

	INSERT INTO [pg].[PostingGroupBatch](
	dateid,createdby,createddtm) VALUES(
	CAST(CONVERT(VARCHAR(20),@CurDt,112) AS INT),'ffortunato',@CurDt)
end

go


IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('N/A'))
BEGIN
	-- ISSUE STATUSES
	SET Identity_Insert pg.RefStatus On

	INSERT INTO pg.RefStatus ([StatusId],[STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES (-1, 'N/A','Not Applicable'
	,'No Record sould ever be in this state.','PostingGroup'
	,GETDATE(),'ffortunato')

	SET Identity_Insert pg.RefStatus Off

END

IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PI'))
BEGIN

	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PI','Posting Group Initialized'
	,'Posting group has had at least on child process completed and is getting the initial entry in the PostingGroupProcessing table.','PostingGroup'
	,GETDATE(),'ffortunato')

END


IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PQ'))
BEGIN

	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PQ','Posting Group Queued'
	,'The posting group is now being called for execution.','PostingGroup'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PP'))
BEGIN


	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PP','Posting Group Processing'
	,'The package for laoding the posting group is running.','PostingGroup'
	,GETDATE(),'ffortunato')

END
IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PR'))
BEGIN

	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PR','Posting Group Retrying'
	,'Posting Group Processing is being retried.','PostingGroup'
	,GETDATE(),'ffortunato')

	END
IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PC'))
BEGIN

	INSERT INTO pg.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PC','Posting Group Complete'
	,'Posting Group has completed.','PostingGroup'
	,GETDATE(),'ffortunato')

END
IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PF'))
BEGIN

	INSERT INTO pg.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PF','Posting Group Failed'
	,'Posting Group has failed to complete.','PostingGroup'
	,GETDATE(),'ffortunato')
END



--------------------------------------------------------------------------------
-- Domain data for RefProcessingMode
-- Ref Table manages the different modes processes can run in.
--------------------------------------------------------------------------------

if not exists (select top 1 1 from pg.RefProcessingMode where [ProcessingModeCode] in ('UNK'))
begin
	insert into pg.RefProcessingMode (	[ProcessingModeCode],    [ProcessingModeName],    [ProcessingModeDesc],    [CreatedBy],    [CreatedDtm])
	values ('UNK','Unknown','This code should never be assigned.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMode where [ProcessingModeCode] in ('NORM'))
begin
	insert into pg.RefProcessingMode (	[ProcessingModeCode],    [ProcessingModeName],    [ProcessingModeDesc],    [CreatedBy],    [CreatedDtm])
	values ('NORM','Normal','A standard execution of the posting group process.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMode where [ProcessingModeCode] in ('RTRY'))
begin
	insert into pg.RefProcessingMode (	[ProcessingModeCode],    [ProcessingModeName],    [ProcessingModeDesc],    [CreatedBy],    [CreatedDtm])
	values ('RTRY','Retry','A restarted execution of the posting group process.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMode where [ProcessingModeCode] in ('INIT'))
begin
	insert into pg.RefProcessingMode (	[ProcessingModeCode],    [ProcessingModeName],    [ProcessingModeDesc],    [CreatedBy],    [CreatedDtm])
	values ('INIT','Initial Load','An execution that is meant to load a large amount of historical information. Typically the first run of a posting group.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMode where [ProcessingModeCode] in ('REST'))
begin
	insert into pg.RefProcessingMode (	[ProcessingModeCode],    [ProcessingModeName],    [ProcessingModeDesc],    [CreatedBy],    [CreatedDtm])
	values ('REST','Restatement','Rebuilding a dataset over a given period of time with new input or new logic.','ffortunato',getdate())
end

--------------------------------------------------------------------------------
-- Domain data for RefProcessingMethod
-- Ref Table manages the different Methods for executing code within the system.
--------------------------------------------------------------------------------

if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('UNK'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('UNK','Unknown','This code should never be assigned.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('ADFP'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('ADFP','Azure Data Factory Pipeline','Posting group will call a Data Factory Pipeline to execute the queued posting group.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('SSIS'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('SSIS','SQL Server Integration Services','Posting group will call a SQL Server Integration Service to execute the queued posting group.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('SQLJ'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('SQLJ','SQL Server Job','Posting group will call a SQL Server Agent Job to execute the queued posting group.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('SQLP'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('SQLP','SQL Server Stored Procedure','Posting group will call a SQL Server Stored Procedure Job to execute the queued posting group.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('GLUE'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('GLUE','AWS Glue','Posting group will call a AWS Glue Pipeline to execute the queued posting group.','ffortunato',getdate())
end
if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('AWSP'))
begin
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('AWSP','AWS Pipeline','Posting group will call a AWS Pipeline to execute the queued posting group.','ffortunato',getdate())
end
print 'End PostingGroup Reference data inserts'