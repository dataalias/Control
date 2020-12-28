USE Control
GO

IF (SELECT 1 FROM ctl.RefStatus where StatusCode = 'IR') IS NULL
BEGIN
	INSERT INTO ctl.RefStatus (StatusCode,StatusName,StatusDesc,StatusType,CreatedBy,CreatedDtm)
	VALUES ('IR','Issue Retry','Issue needs to be retried','Issue','ochowkwale',GETDATE())
END

IF (SELECT 1 FROM pg.RefStatus where StatusCode = 'PR') IS NULL
BEGIN
	INSERT INTO pg.RefStatus (StatusCode,StatusName,StatusDesc,StatusType,CreatedBy,CreatedDtm)
	VALUES ('PR','PostingGroupProcessing Retry','Posting Group Processing record needs to be retried','PostingGroupProcessing','ochowkwale',GETDATE())
END