CREATE VIEW [ctl].[vw_DelayedPublicationsList] AS
	SELECT p.PublicationId
		,p.PublicationCode
		,p.PublicationName
		,i.LastIssueDtm
		,p.IntervalCode
		,p.IntervalLength
		,p.SLATime
		,p.NextExecutionDtm
		,ElapsedTimePercent = ETP.ElapsedTimePercent
	FROM ctl.Publication AS p
	INNER JOIN (SELECT PublicationId
					  ,max(CreatedDtm) AS LastIssueDtm
				FROM ctl.Issue
				GROUP BY PublicationId) AS i ON i.PublicationId = p.PublicationId
	OUTER APPLY (SELECT ElapsedTimePercent = CASE p.IntervalCode
			WHEN 'MIN'	 THEN ((DATEDIFF(ss, p.NextExecutionDtm, GETDATE()) * 100) / (p.IntervalLength * 60))
			WHEN 'HRLY'	 THEN ((DATEDIFF(mi, p.NextExecutionDtm, GETDATE()) * 100) / (p.IntervalLength * 60))
			WHEN 'DLY'	 THEN ((DATEDIFF(hh, p.NextExecutionDtm, GETDATE()) * 100) / (p.IntervalLength * 24))
			WHEN 'WKLY'	 THEN ((DATEDIFF(hh, p.NextExecutionDtm, GETDATE()) * 100) / (p.IntervalLength * 168))
			WHEN 'MTHLY' THEN ((DATEDIFF(dd, p.NextExecutionDtm, GETDATE()) * 100) / (p.IntervalLength * (DATEDIFF(dd, p.NextExecutionDtm, DATEADD(mm, p.IntervalLength, p.NextExecutionDtm)))))
			WHEN 'YRLY'  THEN ((DATEDIFF(mm, p.NextExecutionDtm, GETDATE()) * 100) / (p.IntervalLength * 12))
			END) ETP
	WHERE IsDataHub = 1
	AND IsActive = 1
	AND ElapsedTimePercent > 50


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180518	omkar		Initial Iteration
20192002	ochowkwale	Modifying the view to display only records with Elapsed 
						Time greater than 50%
20190624	ochowkwale	Updating view to use IsActive field
******************************************************************************/
GO