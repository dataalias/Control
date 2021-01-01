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

******************************************************************************/

use control
GO

DECLARE @CurDt DATETIME = GETDATE()
DECLARE @CurDtInt INT = CAST(CONVERT(VARCHAR(20),@CurDt,112) AS VARCHAR(20))

IF NOT EXISTS (SELECT TOP 1 1 FROM  [pg].[PostingGroupBatch] WHERE dateid = @CurDtInt)
BEGIN

	INSERT INTO [pg].[PostingGroupBatch](
	dateid,createdby,createddtm) VALUES(
	CAST(CONVERT(VARCHAR(20),@CurDt,112) AS INT),'ffortunato',@CurDt)
end

go


IF NOT EXISTS (SELECT TOP 1 1 FROM pg.RefStatus WHERE StatusCode IN ('PR','PS','PC','PF','N/A'))
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

	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PI','Posting Group Initialized'
	,'Posting group has had at least on child process completed and is getting the initial entry in the PostingGroupProcessing table.','PostingGroup'
	,GETDATE(),'ffortunato')

	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PQ','Posting Group Queued'
	,'The posting group is now being called for execution.','PostingGroup'
	,GETDATE(),'ffortunato')


	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PP','Posting Group Processing'
	,'The package for laoding the posting group is running.','PostingGroup'
	,GETDATE(),'ffortunato')


	INSERT INTO pg.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PR','Posting Group Retrying'
	,'Posting Group Processing is being retried.','PostingGroup'
	,GETDATE(),'ffortunato')

	INSERT INTO pg.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PC','Posting Group Complete'
	,'Posting Group has completed.','PostingGroup'
	,GETDATE(),'ffortunato')
	INSERT INTO pg.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('PF','Posting Group Failed'
	,'Posting Group has failed to complete.','PostingGroup'
	,GETDATE(),'ffortunato')
END


if not exists (select top 1 1 from pg.RefProcessingMethod where [ProcessingMethodCode] in ('NORM','RTRY','INIT','REST'))
begin
	
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('NORM','Normal','A standard execution of the posting group process.','ffortunato',getdate())
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('RTRY','Retry','A restarted execution of the posting group process.','ffortunato',getdate())
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('INIT','Initial Load','An execution that is meant to load a large amount of historical information. Typically the first run of a posting group.','ffortunato',getdate())
	insert into pg.RefProcessingMethod (	[ProcessingMethodCode],    [ProcessingMethodName],    [ProcessingMethodDesc],    [CreatedBy],    [CreatedDtm])
	values ('REST','Restatement','','ffortunato',getdate())

end
