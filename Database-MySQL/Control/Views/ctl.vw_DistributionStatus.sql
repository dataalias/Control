CREATE VIEW [ctl].[vw_DistributionStatus] AS
SELECT 
		 dis.DistributionId
		,pbn.Bound
		,dis.StatusId			  DistributionStatusId
		,std.StatusCode			  DistributionStatusCode
		,iss.IssueId
		,sti.StatusId			  IssueStatusId
		,sti.StatusCode			  IssueStatusCode
		,iss.IssueName
		,iss.RecordCount
		,pbr.PublisherId
		,pbr.PublisherCode
		,pbn.PublicationId
		,pbn.PublicationCode
		,sbr.SubscriberId
		,sbr.SubscriberCode
		,sbn.SubscriptionId
		,sbn.SubscriptionCode     SubscriptionCode
		,iss.PublicationSeq       TotalPublicationSeq
		,iss.DailyPublicationSeq
		,pbr.ContactId			  PublisherContactId
		,sbr.ContactId			  SubscriberContactId  
		,sbr.NotificationDatabase
		,sbr.NotificationProcedure
		,pbn.IsDataHub
		,pbn.IsActive
		,dis.CreatedDtm			  DistributionCreatedDtm
FROM	 ctl.[Distribution]		  dis
JOIN	 ctl.Issue				  iss
ON		 dis.IssueId			= iss.IssueId
JOIN	 ctl.Subscription		  sbn
ON		 dis.SubscriptionId		= sbn.SubscriptionId
JOIN	 ctl.Publication		  pbn
ON		 iss.PublicationId		= pbn.PublicationId
JOIN	 ctl.Publisher			  pbr
ON		 pbn.PublisherId		= pbr.PublisherId
JOIN	 ctl.Subscriber			  sbr
ON		 sbn.SubscriberId		= sbr.SubscriberId
JOIN	 ctl.RefStatus			  sti
ON		 iss.StatusId			= sti.StatusId
JOIN	 ctl.RefStatus			  std
ON		 dis.StatusId			= std.StatusId
--WHERE	 dis.CreatedDtm			> getdate() -30
GO