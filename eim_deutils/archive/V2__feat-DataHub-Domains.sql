
delete from DATA_HUB.Ref_Trigger_Type;
delete from DATA_HUB.REF_FILE_FORMAT;
delete from DATA_HUB.REF_STORAGE_METHOD;
delete from DATA_HUB.REF_METHOD ;
delete from DATA_HUB.REF_METHOD;
delete from DATA_HUB.REF_INTERVAL;
delete from DATA_HUB.REF_INTERFACE;
delete from DATA_HUB.REF_STATUS;

	INSERT INTO DATA_HUB.Ref_Trigger_Type     (TriggerTypeCode           ,TriggerTypeName          ,TriggerTypeDesc,CreatedBy  ,CreatedDtm )
	VALUES ('N/A','Not Applicable','A trigger type is not expected for this specific record.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.Ref_Trigger_Type     (TriggerTypeCode           ,TriggerTypeName          ,TriggerTypeDesc, CreatedBy  ,CreatedDtm )
	VALUES ('UNK','Unknown','The trigger type is unknown.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.Ref_Trigger_Type     (TriggerTypeCode           ,TriggerTypeName          ,TriggerTypeDesc, CreatedBy  ,CreatedDtm )
	VALUES ('S3','S3 File Put','A file arrived in a S3 bucket that will trigger a datahub load.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.Ref_Trigger_Type     (TriggerTypeCode           ,TriggerTypeName          ,TriggerTypeDesc, CreatedBy  ,CreatedDtm )
	VALUES ('SCH','Scheduled','Publication will be pulled by DataHub based on the interval and next execution for the feed.',CURRENT_USER,CURRENT_DATE);


--------------------------------------------------------------------------------
-- Domain data for RefFileFormat
-- Ref Table manages the different file types that are inbound or stored in the lake.
--------------------------------------------------------------------------------


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('N/A','Not Applicable','A file format is not expected for this specific record.','na','.na',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('UNK','Unknown','The file format for this record is unknown.','unk','.unk',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('DAT','Data File','The file format for this record is ASCII with a given delimiter.','dat','.dat',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('CSV','Comma Seperated Values','The file is standard ASCII csv file.','csv','.csv',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('PARQ','Parquet','The file is column store Parquet file.','parquet','.parquet',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('XLS','Microsoft Excel Legacy','This is an excel file saved in prior 2008 version of excel.','xls','.xls',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('XLSX','Microsoft Excel Current','This is an excel files saved after 2015.','xlsx','.xlsx',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('TXT','Standard ASCII file.','Fixedwidth or delimited file normally human readable.','txt','.txt',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('JSON','JavaScript Object Notation','Named value pair file .','json','.json',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('AU','Audacity Audio File','An AU file is an audio file created by Audacity, a free, cross-platform audio editor. It is saved in a proprietary audio format used only by Audacity.','au','.au',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('MP3','MPEG Audio File','The MP3 lossy audio-data compression algorithm takes advantage of a perceptual limitation of human hearing called auditory masking.','mp3','.mp3',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('ZIP','ZIP Compressed File','ZIP Compressed','zip','.zip',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_FILE_FORMAT     (FileFormatCode           ,FileFormatName          ,FileFormatDesc, FileExtension,DotFileExtension  ,CreatedBy  ,CreatedDtm )
	VALUES ('GZ','gz Compressed File','gz Compressed','gz','.gz',CURRENT_USER,CURRENT_DATE);


-- REf Transfer Method
-- Defines how the information moves in transit.
-- Used to derive what merge functions we should used to load data into the target.




	INSERT INTO DATA_HUB.REF_TRANSFER_METHOD    (TransferMethodCode           ,TransferMethodName           ,TransferMethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('UNK','Unknown','The method of transfer is unknown for this feed.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_TRANSFER_METHOD     (TransferMethodCode           ,TransferMethodName           ,TransferMethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('SS','Snap Shot','Feed generated using a snaphot method. Staging will require delta processing.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_TRANSFER_METHOD     (TransferMethodCode           ,TransferMethodName           ,TransferMethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('DLT','Delta','Feed generated using a delta method. Only new and updated records are generated.',CURRENT_USER,CURRENT_DATE);






	INSERT INTO DATA_HUB.REF_STORAGE_METHOD     (StorageMethodCode           ,StorageMethodName           ,StorageMethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('UNK','Unknown','The method of transfer is unknown for this feed.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_STORAGE_METHOD     (StorageMethodCode           ,StorageMethodName           ,StorageMethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('TXN','Transaction','Transactional data.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_STORAGE_METHOD     (StorageMethodCode           ,StorageMethodName           ,StorageMethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('SS','Snapshot','At rest the data is stored with the data in the current state.',CURRENT_USER,CURRENT_DATE);




	INSERT INTO DATA_HUB.REF_METHOD     (MethodCode           ,MethodName           ,MethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('SS','Snap Shot','Feed generated using a snaphot method. Staging will require delta processing.',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_METHOD     (MethodCode           ,MethodName           ,MethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('DLT','Delta','Feed generated using a delta method. Only new and updated records are generated.',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_METHOD     (MethodCode           ,MethodName           ,MethodDesc           ,CreatedBy  ,CreatedDtm )
	VALUES ('TXN','Transaction','Feed generated by delivering all transactions encoutnerd by the source system. Only new records are generated.',CURRENT_USER,CURRENT_DATE);

--REF INTERVAL

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('N/A','Not Applicable','The data feed interval is not applicable for this record.','N/A','N/A',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('UNK','Unknown','The interval is absent for this record.','UNK','UNK',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('MN','Minute','The data feed interval is measured in minutes.','ss','0-50-9',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('HR','Hour','The data feed interval is measured in hours.','mm:ss','0-50-9:0-50-9',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('DY','Day','The data feed interval is measured in days.','hh:mm:ss','(01?0-9|20-3):0-50-9:0-50-9',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('MT','Monthly','The data feed interval is measured in months.','ddThh:mm','0-30-9T0-50-9:0-50-9',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('YR','Yearly','The data feed interval is measured in years.','mm-ddThh:mm','(?:01-9|1012)-0-30-9T0-50-9:0-50-9',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('WK','Weekly','The data feed interval is measured in weeks.','??','??',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERVAL (IntervalCode ,IntervalName,IntervalDesc,SLAFormat,SLARegEx,CreatedBy,CreatedDtm)     VALUES 
	('IMM','Immediately','The data feed interval is executed immediately.','UNK','UNK',CURRENT_USER,CURRENT_DATE);






	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('N/A','Not Applicable','If an interface code is not needed set the value to N/A. ',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('UNK','Unknown','The user did not provide an interface.',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
           ('API','Application Programming Interface','The system will connect to an API to facilitate data transfer.',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('SHARE','File Share','',CURRENT_USER,CURRENT_DATE);

	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
           ('FTP','File Transfer Protocol','',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('SFTP','Secure File Transfer Protocol','',CURRENT_USER,CURRENT_DATE);


	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('S3','S3 Bucket','The system will connect with an S3 bucket to faclitate data transfer.',CURRENT_USER,CURRENT_DATE);



	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('TBL','Table','System directly interfaces with a relational database table.',CURRENT_USER,CURRENT_DATE);



	INSERT INTO DATA_HUB.REF_INTERFACE(InterfaceCode,InterfaceName,InterfaceDesc,CreatedBy,CreatedDtm)  VALUES
			   ('EMAIL','e-Mail','System interfaces with a mailbox and retrieves or sends attachements.',CURRENT_USER,CURRENT_DATE);





	
	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IX','Issue External'
	,'Issue is ready on an external system. The data set can be retrieved based on scheduler.' ,'Issue'
	,CURRENT_DATE,'ffortunato');

	
	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IP','Issue Prepared'
	,'Issue is prepared on the publishing system. The file is ready or table populated.' ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IS','Issue Staging'
	,'Issue is currently being loaded onto local staging area.' ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IL','Issue Loaded'
	,'The Load of the issues to staging/ods area complete. Subscribers can now access the information based on distribution.'   ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IN','Issue Ready for Notification'
	,'All of the Issues Distributions are ready for notifcation.'   ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IC','Issue Complete'
	,'Issue has been consumed by subscribing systems.'   ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IA','Issue Archived'
	,'The stage table has been consumed by all subscribers and has been archived and lastly removed from the staging table. The issue, if a file, has been moved to an archive directory.'   ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IR','Issue Retry'
	,'The stage table has to be rerun from the begining.'   ,'Issue'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('IF','Issue Failed'
	,'Issue has failed to be consumed by ALL subscribing systems.'   ,'Issue'
	,CURRENT_DATE,'ffortunato');


-- Distribution STATUSES

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('DN','Distribution Awaiting Notification'
	,'Issue record was created and the trigger created a distribution record as well.' ,'Distribution'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('DT','Distribution Notification Sent to Subscriber'
	,'Distribution has been notified to the subscribing systems posting group controls.'             ,'Distribution'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('DC','Distribution Complete'
	,'Distribution has been consumed by subscribing systems.'   ,'Distribution'
	,CURRENT_DATE,'ffortunato');

	INSERT INTO DATA_HUB.REF_STATUS (STATUSCODE,STATUSNAME
	,STATUSDESC,STATUSTYPE
	,CreatedDtm,CREATEDBY)
	VALUES ('DF','Distribution Failed'
	,'Distribution has failed to be consumed by subscribing system.'   ,'Distribution'
	,CURRENT_DATE,'ffortunato');
