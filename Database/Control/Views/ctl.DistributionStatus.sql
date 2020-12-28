CREATE VIEW [ctl].[DistributionStatus] AS
SELECT 
		 dis.DistributionId
		,std.StatusCode			  DistributionStatusCode
		,iss.RecordCount
		,iss.IssueId
		,iss.IssueName
		,sti.StatusCode			  IssueStatusCode
		,pbr.PublisherId
		,pbr.PublisherCode
		,pbn.PublicationId
		,pbn.PublicationCode
		,sbr.SubscriberId
		,sbr.SubscriberCode
		,sbn.SubscriptionId
		,sbn.SubscriptionCode
		,pbr.ContactId			  PublisherContactId
		,sbr.ContactId			  SubscriberContactId  
		,sbr.NotificationDatabase
		,sbr.NotificationProcedure
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
GO