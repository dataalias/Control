USE [$(DatabaseName)]
GO



print 'Start Predeployment Script'

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.RefStatus WHERE StatusCode IN ('IX'))
BEGIN
	
	INSERT INTO ctl.RefStatus ([STATUSCODE],[STATUSNAME]
	,[STATUSDESC],[STATUSTYPE]
	,CreatedDtm,CREATEDBY)
	VALUES ('IX','Issue Extract'
	,'Issue is ready to be extracted from source.' ,'Issue'
	,GETDATE(),'ffortunato')
END

IF NOT EXISTS (SELECT TOP 1 1 FROM ctl.[RefInterface] WHERE [InterfaceCode] IN ('S3'))
BEGIN

	INSERT INTO [ctl].[RefInterface]([InterfaceCode],[InterfaceName],[InterfaceDesc],[CreatedBy],[CreatedDtm])  VALUES
			   ('S3','S3 Bucket','The system will connect with an S3 bucket to faclitate data transfer.',system_user,getdate())
END



print 'Complete Predeployment Script'