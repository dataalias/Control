
print 'Start Post Deployment Script'


--------------------------------------------------------------------------------
-- Domain data for RefTriggerType
-- Ref Table manages the different file types that are inbound or stored in the lake.
print 'Insert domain data for RefTriggerType'
--------------------------------------------------------------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTriggerType] WHERE [TriggerTypeCode] IN ('N/A'))
BEGIN

	INSERT INTO [ctl].[RefTriggerType]     ([TriggerTypeCode]           ,[TriggerTypeName]          ,[TriggerTypeDesc],[CreatedBy]  ,[CreatedDtm] )
	VALUES ('N/A','Not Applicable','A trigger type is not expected for this specific record.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTriggerType] WHERE [TriggerTypeCode] IN ('UNK'))
BEGIN

	INSERT INTO [ctl].[RefTriggerType]     ([TriggerTypeCode]           ,[TriggerTypeName]          ,[TriggerTypeDesc], [CreatedBy]  ,[CreatedDtm] )
	VALUES ('UNK','Unknown','The trigger type is unknown.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTriggerType] WHERE [TriggerTypeCode] IN ('S3'))
BEGIN

	INSERT INTO [ctl].[RefTriggerType]     ([TriggerTypeCode]           ,[TriggerTypeName]          ,[TriggerTypeDesc], [CreatedBy]  ,[CreatedDtm] )
	VALUES ('S3','S3 File Put','A file arrived in a S3 bucket that will trigger a datahub load.',system_user,getdate())
END
IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefTriggerType] WHERE [TriggerTypeCode] IN ('SCH'))
BEGIN

	INSERT INTO [ctl].[RefTriggerType]     ([TriggerTypeCode]           ,[TriggerTypeName]          ,[TriggerTypeDesc], [CreatedBy]  ,[CreatedDtm] )
	VALUES ('SCH','Scheduled','Publication will be pulled by DataHub based on the interval and next execution for the feed.',system_user,getdate())
END

print 'Complete Post Deployment Script'
