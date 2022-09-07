/******************************************************************************
File:           ctlDomainData.sql
Name:           Control Domain Data 

Purpose:        This file is used to manage the meta data needed by pubsub.

Parameters:     

  ,@Verbose     

  ,@PassVerbose 


Execution:      N/A

Called By:      QA

Author:         ffortunato
Date:           20161206

*******************************************************************************
       Change History
*******************************************************************************
Date		Author		Description
--------	-----------	---------------------------------------------------

20161206	ffortunato	initial iteration
20170126	ffortunato	making changes to service now inserts as well.
20170126	GopiKadambari	Added a statement to insert record into Publication
						Table
20210105	ffortunato	more if statements
20210312	ffortunato	reffileformat added.
20220809	ffortunato	cleaning up issue statuses.

******************************************************************************/


print 'Start DataHub Reference data inserts'

use [$(DatabaseName)]
go

-- Column and table definitions
/*
SELECT
   SCHEMA_NAME(tbl.schema_id) AS SchemaName,	
   tbl.name AS TableName, 
   clmns.name AS ColumnName,
   p.name AS ExtendedPropertyName,
   CAST(p.value AS sql_variant) AS ExtendedPropertyValue
FROM
   sys.tables AS tbl
   INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id
   INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1
WHERE
   SCHEMA_NAME(tbl.schema_id)='ctl'
   and tbl.name='Publication' 
   and clmns.name='sno'
   and p.name='SNO'
*/



--------------------------------------------------------------------------------
-- Domain data for RefFileFormat
-- Ref Table manages the different file types that are inbound or stored in the lake.
--------------------------------------------------------------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('N/A'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('N/A','Not Applicable','A file format is not expected for this specific record.','na','.na',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('UNK'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('UNK','Unknown','The file format for this record is unknown.','unk','.unk',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('DAT'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('DAT','Data File','The file format for this record is ASCII with a given delimiter.','dat','.dat',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('CSV'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('CSV','Comma Seperated Values','The file is standard ASCII csv file.','csv','.csv',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('PARQ'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('PARQ','Parquet','The file is column store Parquet file.','parquet','.parquet',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('XLS'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('XLS','Microsoft Excel Legacy','This is an excel file saved in prior 2008 version of excel.','xls','.xls',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('XLSX'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('XLSX','Microsoft Excel Current','This is an excel files saved after 2015.','xlsx','.xlsx',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('TXT'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('TXT','Standard ASCII file.','Fixedwidth or delimited file normally human readable.','txt','.txt',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('JSON'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('JSON','JavaScript Object Notation','Named value pair file .','json','.json',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('AU'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('AU','Audacity Audio File','An AU file is an audio file created by Audacity, a free, cross-platform audio editor. It is saved in a proprietary audio format used only by Audacity.','au','.au',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefFileFormat] WHERE [FileFormatCode] IN ('MP3'))
BEGIN

	INSERT INTO [ctl].[RefFileFormat]     ([FileFormatCode]           ,[FileFormatName]          ,[FileFormatDesc], [FileExtension],[DotFileExtension]  ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('MP3','MPEG Audio File','The MP3 lossy audio-data compression algorithm takes advantage of a perceptual limitation of human hearing called auditory masking.','mp3','.mp3',system_user,getdate())
END
go

-- REf Transfer Method
-- Defines how the information moves in transit.
-- Used to derive what merge functions we should used to load data into the target.
print 'Start Loading Transfer Method.'

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTransferMethod] WHERE [TransferMethodCode] IN ('UNK'))
BEGIN

	INSERT INTO [ctl].[RefTransferMethod]     ([TransferMethodCode]           ,[TransferMethodName]           ,[TransferMethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('UNK','Unknown','The method of transfer is unknown for this feed.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTransferMethod] WHERE [TransferMethodCode] IN ('SS'))
BEGIN

	INSERT INTO [ctl].[RefTransferMethod]     ([TransferMethodCode]           ,[TransferMethodName]           ,[TransferMethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('SS','Snap Shot','Feed generated using a snaphot method. Staging will require delta processing.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTransferMethod] WHERE [TransferMethodCode] IN ('DLT'))
BEGIN

	INSERT INTO [ctl].[RefTransferMethod]     ([TransferMethodCode]           ,[TransferMethodName]           ,[TransferMethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('DLT','Delta','Feed generated using a delta method. Only new and updated records are generated.',system_user,getdate())
END
go

print 'Complete Loading Transfer Method.'
-- REf Storage Method
-- Defines how the information resides at rest.
-- Used to derive what merge functions we should used to load data into the target.

print 'Start Loading Storage Method.'

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefStorageMethod] WHERE [StorageMethodCode] IN ('UNK'))
BEGIN

	INSERT INTO [ctl].[RefStorageMethod]     ([StorageMethodCode]           ,[StorageMethodName]           ,[StorageMethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('UNK','Unknown','The method of transfer is unknown for this feed.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefStorageMethod] WHERE [StorageMethodCode] IN ('TXN'))
BEGIN

	INSERT INTO [ctl].[RefStorageMethod]     ([StorageMethodCode]           ,[StorageMethodName]           ,[StorageMethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('TXN','Transaction','Transactional data.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefStorageMethod] WHERE [StorageMethodCode] IN ('SS'))
BEGIN

	INSERT INTO [ctl].[RefStorageMethod]     ([StorageMethodCode]           ,[StorageMethodName]           ,[StorageMethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('SS','Snapshot','At rest the data is stored with the data in the current state.',system_user,getdate())
END
go

print 'Complete Loading Storage Method.'

-- REf Method
-- Deprecated
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefMethod] WHERE [MethodCode] IN ('SS'))
BEGIN

	INSERT INTO [ctl].[RefMethod]     ([MethodCode]           ,[MethodName]           ,[MethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('SS','Snap Shot','Feed generated using a snaphot method. Staging will require delta processing.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefMethod] WHERE [MethodCode] IN ('DLT'))
BEGIN

	INSERT INTO [ctl].[RefMethod]     ([MethodCode]           ,[MethodName]           ,[MethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('DLT','Delta','Feed generated using a delta method. Only new and updated records are generated.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefMethod] WHERE [MethodCode] IN ('TXN'))
BEGIN

	INSERT INTO [ctl].[RefMethod]     ([MethodCode]           ,[MethodName]           ,[MethodDesc]           ,[CreatedBy]  ,[CreatedDtm] )
	VALUES ('TXN','Transaction','Feed generated by delivering all transactions encoutnerd by the source system. Only new records are generated.',system_user,getdate())
END

/* OLD
--REF INTERVAL
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('N/A'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('N/A','Not Applicable','The data feed interval is not applicable for this record.','N/A','N/A',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('UNK'))
BEGIN

	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('UNK','Unknown','The interval is absent for this record.','UNK','UNK',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('MIN'))
BEGIN

	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('MIN','Minute','The data feed interval is measured in minutes.','ss','[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('HRLY'))
BEGIN

	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('HRLY','Hourly','The data feed interval is measured in hours.','mm:ss','[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('DLY'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('DLY','Daily','The data feed interval is measured in days.','hh:mm:ss','([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('MTHLY'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('MTHLY','Monthly','The data feed interval is measured in months.','ddThh:mm','[0-3][0-9]T[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('YRLY'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('YRLY','Yearly','The data feed interval is measured in years.','mm-ddThh:mm','(?:0[1-9]|1[012])-[0-3][0-9]T[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('WKLY'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('WKLY','Weekly','The data feed interval is measured in weeks.','??','??',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('IMM'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('IMM','Immediately','The data feed interval is executed Immediately.','UNK','UNK',SYSTEM_USER,GETDATE())
END
*/
--  These are the values to use in the future. Makes all intervals the same context (drop the 'ly')
--REF INTERVAL
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('N/A'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('N/A','Not Applicable','The data feed interval is not applicable for this record.','N/A','N/A',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('UNK'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('UNK','Unknown','The interval is absent for this record.','UNK','UNK',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('MN'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('MN','Minute','The data feed interval is measured in minutes.','ss','[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('HR'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('HR','Hour','The data feed interval is measured in hours.','mm:ss','[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('DY'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('DY','Day','The data feed interval is measured in days.','hh:mm:ss','([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('MT'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('MT','Monthly','The data feed interval is measured in months.','ddThh:mm','[0-3][0-9]T[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('YR'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('YR','Yearly','The data feed interval is measured in years.','mm-ddThh:mm','(?:0[1-9]|1[012])-[0-3][0-9]T[0-5][0-9]:[0-5][0-9]',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('WK'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('WK','Weekly','The data feed interval is measured in weeks.','??','??',SYSTEM_USER,GETDATE())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterval] WHERE [IntervalCode] IN ('IMM'))
BEGIN
	INSERT INTO [ctl].[RefInterval] ([IntervalCode] ,[IntervalName],[IntervalDesc],[SLAFormat],[SLARegEx],[CreatedBy],[CreatedDtm])     VALUES 
	('IMM','Immediately','The data feed interval is executed immediately.','UNK','UNK',SYSTEM_USER,GETDATE())
END
GO


-- REF INTERFACE
print 'Start Ref Interface Inserts'

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('N/A'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('N/A','Not Applicable','If an interface code is not needed set the value to N/A. ',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('UNK'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('UNK','Unknown','The user did not provide an interface.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('API'))
BEGIN
	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
           ('API','Application Programming Interface','The system will connect to an API to facilitate data transfer.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('SHARE'))
BEGIN
	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('SHARE','File Share','',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN (/*'FILE','API','TBL',*/'FTP'))
BEGIN
	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
           ('FTP','File Transfer Protocol','',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('SFTP'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('SFTP','Secure File Transfer Protocol','',system_user,getdate())
END
/*
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('CANVAS'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('CANVAS','Canvas Sync Command Line Utility','',system_user,getdate())
END
*/
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('TBL'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('TBL','Table','System directly interfaces with a relational database table.',system_user,getdate())

END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('EMAIL'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('EMAIL','e-Mail','System interfaces with a mailbox and retrieves or sends attachements.',system_user,getdate())

END

print 'Complete Ref Interface Inserts'


-- ISSUE STATUSES
print 'Start Ref Status Inserts'
print 'Loading Issue Statuses'

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IP'))
BEGIN
	
	INSERT INTO ctl.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IP','Issue Prepared'
	,'Issue is prepared on the publishing system. The file is ready or table populated.' ,'Issue'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IS'))
BEGIN
	INSERT INTO ctl.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IS','Issue Staging'
	,'Issue is currently being loaded onto local staging area.' ,'Issue'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IL'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IL','Issue Loaded'
	,'The Load of the issues to staging/ods area complete. Subscribers can now access the information based on distribution.'   ,'Issue'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IN'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IN','Issue Ready for Notification'
	,'All of the Issues Distributions are ready for notifcation.'   ,'Issue'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IC'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IC','Issue Complete'
	,'Issue has been consumed by subscribing systems.'   ,'Issue'
	,GETDATE(),'ffortunato')
END

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IA'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IA','Issue Archived'
	,'The stage table has been consumed by all subscribers and has been archived and lastly removed from the staging table. The issue, if a file, has been moved to an archive directory.'   ,'Issue'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IR'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IR','Issue Retry'
	,'The stage table has to be rerun from the begining.'   ,'Issue'
	,GETDATE(),'ffortunato')
END

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IF'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IF','Issue Failed'
	,'Issue has failed to be consumed by ALL subscribing systems.'   ,'Issue'
	,GETDATE(),'ffortunato')
END

print 'Loading Distribution Statuses'

-- Distribution STATUSES
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('DN'))
BEGIN
	INSERT INTO ctl.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('DN','Distribution Awaiting Notification'
	,'Issue record was created and the trigger created a distribution record as well.' ,'Distribution'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('DT'))
BEGIN
	INSERT INTO ctl.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('DT','Distribution Notification Sent to Subscriber'
	,'Distribution has been notified to the subscribing systems posting group controls.'             ,'Distribution'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('DC'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('DC','Distribution Complete'
	,'Distribution has been consumed by subscribing systems.'   ,'Distribution'
	,GETDATE(),'ffortunato')
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('DF'))
BEGIN
	INSERT INTO ctl.REFSTATUS ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('DF','Distribution Failed'
	,'Distribution has failed to be consumed by subscribing system.'   ,'Distribution'
	,GETDATE(),'ffortunato')
END

-- select * from ctl.refstatus

-- unknown contact./
if not exists (select top 1 1 from ctl.Contact where @pContactName = 'Unknown')
EXEC [ctl].usp_InsertNewContact 
		 @pCompanyName				= 'Unknown'
		,@pContactName				= 'Unknown'
		,@pTier						= '1'
		,@pEmail					= 'Unknown@Unknown.Unknown'
		,@pPhone					= 'Unknown'
		,@pAddress01				= 'Unknown'
		,@pAddress02				= ''
		,@pCity						= 'Unknown'
		,@pState					= ''
		,@pZipCode					= 'Unknown'


print 'Complete DataHub Reference data inserts'

