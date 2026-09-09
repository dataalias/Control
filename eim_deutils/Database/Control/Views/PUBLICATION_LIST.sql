create or replace view ULTRA_@ENV@_RAW.DATA_HUB.PUBLICATION_LIST_VW AS
select	 pr.PublisherId
			,pr.PublisherCode
			,pr.PublisherName
			,pn.PublicationId
			,pn.PublicationName
			,pn.PublicationCode
			,pr.InterfaceCode
			,pn.SrcFileRegEx
			,pn.IntervalCode
			,pn.IntervalLength
			,pn.RetryIntervalCode
			,pn.RetryIntervalLength
			,pn.RetryMax
			,pn.ProcessingMethodCode
			,pn.TransferMethodCode
			,pn.NextExecutionDtm
			,pn.SLATime
			,ri.SLAFormat
			,ri.SLARegEx
			,pn.Bound
			,pn.SrcFileFormatCode  -- As FeedFormat
			,pn.StandardFileFormatCode
			,pn.GlueWorkflow
			,pn.SrcPublicationName		
			,pn.SrcFilePath
			,pn.PublicationFilePath
			,pn.PublicationArchivePath
			,pn.PublicationGroupSequence
			,id.IssueId					    LastIssueId
			,IFNULL(id.IssueName, 'Unknown')	IssueName
			,id.PeriodStartTime				LastHighWaterMarkDatetime
			,id.PeriodStartTimeUTC			LastHighWaterMarkDatetimeUTC
			,id.PeriodEndTime				HighWaterMarkDatetime
			,id.PeriodEndTimeUTC			HighWaterMarkDatetimeUTC
			,LastRecordSeq					HighWaterMarkRecordSeq
			,id.PublicationSeq
	from 	DATA_HUB.Publication		  pn
	left join (
        select	 
             iss.IssueId                                    IssueId
            ,issd.PublicationCode                           PublicationCode
            ,ifnull(iss.PeriodStartTime   ,'1900-01-01')    PeriodStartTime
            ,iss.PeriodEndTime                              PeriodEndTime
            ,ifnull(iss.PeriodStartTimeUTC,'1900-01-01')    PeriodStartTimeUTC
            ,iss.PeriodEndTimeUTC                           PeriodEndTimeUTC
            ,iss.FirstRecordSeq                             FirstRecordSeq
            ,iss.LastRecordSeq                              LastRecordSeq
            ,iss.FirstRecordChecksum                        FirstRecordChecksum
            ,iss.LastRecordChecksum                         LastRecordChecksum
            ,iss.PublicationSeq                             PublicationSeq
        from	 (
            select	 pbn.PublicationCode      PublicationCode
                    ,max(IssueId)             IssueId
            from	 DATA_HUB.Issue			  iss
            join	 DATA_HUB.Publication	  pbn
            on		 iss.PublicationCode	= pbn.PublicationCode
            join	 DATA_HUB.Publisher		  pbr
            on		 pbn.PublisherCode		= pbr.PublisherCode
            join	 DATA_HUB.Ref_Status	  rs
            on		 iss.StatusCode			= rs.StatusCode
            --where	 pbr.PublisherCode		= '{params['PublisherCode']}'
            where		 rs.StatusCode		in ('IL','IC','IA') -- We dont want values from failed issues.
            group by pbn.PublicationCode
        )			  issd
        join	 DATA_HUB.Issue			  iss
        on		 iss.IssueId		    = issd.IssueId
    )                                     id
	on		id.PublicationCode			= pn.PublicationCode
	join	DATA_HUB.Publisher			  pr 
	on		pr.PublisherCode			= pn.PublisherCode
	join	DATA_HUB.Ref_Interval		  ri
	on		pn.IntervalCode				= ri.IntervalCode
	where	pn.IsActive					= 1 
	and		pn.Bound					= 'In'
	--and		pn.NextExecutionDtm			<= '{params['CurrentDate']}'
	--and		pr.PublisherCode			=  '{params['PublisherCode']}'
    order   by pn.PublicationGroupSequence ASC;