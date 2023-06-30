/******************************************************************************
file:           Issue.sql
name:           Issue

purpose:        Provides a list of feeds produced by publishers.

called by:      
calls:          

author:         ffortunato
date:           20181011

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 
							naming default constraints
							renaming indixes to conform to standards
20210316	ffortunato		adding SrcIssueName
20210316	ffortunato		PeriodEndTime Can be NULL during initial insert.
******************************************************************************/

CREATE TABLE [ctl].[Issue](
	[IssueId] [int] IDENTITY(1,1) NOT NULL,
	[PublicationId] [int] NOT NULL,
	[StatusId] [int] NOT NULL,
	[ReportDate] [datetime] NOT NULL,
	[SrcDFPublisherId] [varchar](40) NULL,
	[SrcDFPublicationId] [varchar](40) NULL,
	[SrcDFIssueId] [varchar](100) NULL,
	[SrcIssueName] [nvarchar](255) NULL,
	[SrcDFCreatedDate] [datetime] NULL,
	DataLakePath [varchar](1000) NOT NULL,
	[IssueName] [varchar](255) NOT NULL,
	[PublicationSeq] [int] NOT NULL,
	[DailyPublicationSeq] [int] NOT NULL,
	[FirstRecordSeq] [int] NULL,
	[LastRecordSeq] [int] NULL,
	[FirstRecordChecksum] [varchar](2048) NULL,
	[LastRecordChecksum] [varchar](2048) NULL,
	[PeriodStartTime] [datetime] NOT NULL,
	[PeriodEndTime] [datetime] NULL,
	[PeriodStartTimeUTC] [datetimeoffset]  NULL,
	[PeriodEndTimeUTC] [datetimeoffset]  NULL,
	[IssueConsumedDate] [datetime] NULL,
	[RecordCount] [int] NOT NULL,
	[RetryCount] [int] NOT NULL,
	[ETLExecutionId] nvarchar(1000) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [Pk_IssueIssueId] PRIMARY KEY CLUSTERED 
(
	[IssueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
)
GO

ALTER TABLE [ctl].[Issue] ADD  CONSTRAINT [DF__Issue__PublicationSeq_-1]  DEFAULT -1 FOR [PublicationSeq]
GO

ALTER TABLE [ctl].[Issue] ADD  CONSTRAINT [DF__Issue__DailyPublicationSeq_-1]  DEFAULT -1 FOR [DailyPublicationSeq]
GO

ALTER TABLE [ctl].[Issue] ADD  CONSTRAINT [DF__Issue__RetryCount__0]  DEFAULT 0 FOR [RetryCount]
GO

ALTER TABLE [ctl].[Issue] ADD  CONSTRAINT [DF__Issue__DataLakePath__Raw]  DEFAULT '/Raw Data Zone/...' FOR [DataLakePath]
go

ALTER TABLE [ctl].[Issue]  ADD  CONSTRAINT [FK_Issue__Publication__PublicationId] FOREIGN KEY([PublicationId])
REFERENCES [ctl].[Publication] ([PublicationId])
GO

--ALTER TABLE [ctl].[Issue] CHECK CONSTRAINT [FK_IssuePublicationId]
--GO

ALTER TABLE [ctl].[Issue]  ADD  CONSTRAINT [FK_Issue__RefStatus__StatusId] FOREIGN KEY([StatusId])
REFERENCES [ctl].[RefStatus] ([StatusId])
GO

--ALTER TABLE [ctl].[Issue] CHECK CONSTRAINT [FK_IssueStatusId]
--GO

CREATE NONCLUSTERED INDEX [IDX_Issue__IssueName]
    ON [ctl].[Issue]([IssueName] ASC) WITH (FILLFACTOR = 100);
GO

CREATE NONCLUSTERED INDEX [IDX_Issue__ReportDate]
    ON [ctl].[Issue]([ReportDate] ASC)
    INCLUDE([PublicationId], [RecordCount]) WITH (FILLFACTOR = 100);
GO

CREATE NONCLUSTERED INDEX [IDX_Issue__StatusId]
    ON [ctl].[Issue]([StatusId] ASC) WITH (FILLFACTOR = 100);
GO

CREATE NONCLUSTERED INDEX [IDX_Issue__PublicationId_StatusId]
    ON [ctl].[Issue]([PublicationId] ASC)
    INCLUDE([PublicationSeq], [StatusId]) WITH (FILLFACTOR = 100);
GO

create trigger ctl.trg_InsertIssueDistribution on ctl.Issue for insert as

/******************************************************************************
file:           trg_InsertIssueDistribution.sql
name:           trg_InsertIssueDistribution
object:			Trigger
purpose:        

parameters:     

called by:      insert on issue table
calls:          

author:         ffortunato
date:           20091104

description:    this trigger sits on the issue table. when an new issue
                 is created the assoicated distributions are added as well.

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20161206	ffortunato		improved error handling.
20161215	ffortunato		fixing up the insert query to improve the join. 
20161215	ffortunato		fixing up the insert query to improve the join. 
20180411	ffortunato		change from start date to is active. 
20180906	ffortunato		cleaning up the trigger for a more straight forward
							join. 
******************************************************************************/

declare 
     @err						int				= 0
    ,@errmsg					varchar(255)	= 'trigger trg_InsertIssueDistribution failed.' + Char(13)
    ,@Start						datetime		= GETDATE()
    ,@PublisherId				int				= -1
    ,@PublicationId				int				= -1
    ,@IssueId					int				= -1
	,@RefStatsType				varchar(100)	= 'Distribution'
    ,@DistributionStatusCode	varchar(20)		= 'DN'
	,@DistributionStatusId		int				= -1
    ,@CreatedBy					varchar(30)		= SYSTEM_USER
	,@Verbose					bit				= 0

begin try

select	 @PublisherId			= pub.PublisherId
		,@PublicationId			= ins.PublicationId
		,@IssueId				= ins.IssueId
from	 inserted				  ins               -- this is the issue table.
join	 ctl.Publication		  pub
on		 ins.PublicationId		= pub.PublicationId

select	 @DistributionStatusId	= StatusId
from	 ctl.RefStatus
where	 StatusCode				= @DistributionStatusCode
and		 StatusType				= @RefStatsType

end try

begin catch
	select @ErrMsg = @ErrMsg + char(13)  + ERROR_MESSAGE()
	raiserror (@ErrMsg,-1,-1)
end catch

if @Verbose = 1 begin 
	print 'publisherid:    ' + cast(@PublisherId as varchar(20))
	print 'publicationid:  ' + cast(@PublicationId as varchar(20))
	print 'issueid:        ' + cast(@IssueId as varchar(20))
	print 'start:          ' + cast(@start as varchar(20))
	print 'DistStatusCode: ' + cast(@DistributionStatusCode as varchar(20))
	print 'DistStatusId:   ' + cast(@DistributionStatusId as varchar(20))
	
end
	
begin try

    insert into ctl.[Distribution] (
         IssueId
        ,SubscriptionId
        ,StatusId
        ,CreatedBy
		,CreatedDtm
    )
    select 
         @IssueId
        ,SubscriptionId
        ,@DistributionStatusId
        ,@CreatedBy
		,@Start
    from	ctl.Subscription	  sub
    where	PublicationId		= @PublicationId
	and		sub.IsActive		= 1
--    and    @start                  between sub.StartDate AND ISNULL(sub.EndDate,@start+1)

end try

begin catch
	select @ErrMsg = @ErrMsg + char(13)  + ERROR_MESSAGE()
	raiserror (@ErrMsg,-1,-1)
end catch
GO

ALTER TABLE [ctl].[Issue] ENABLE TRIGGER [trg_InsertIssueDistribution]
GO


CREATE TRIGGER [ctl].[trg_IssueStatusUpdateFail] ON [ctl].[Issue] FOR  UPDATE AS
/******************************************************************************
file:           trg_IssueStatusUpdateFail.sql
name:           trg_IssueStatusUpdateFail

purpose:        this trigger sits on the Issue table. when a 
				issue status is updated to failed, the trigger updates the IssueName
				in issue table, updates distribution status to Fail, updates posting 
				group status to Fail.

called by:      update on ctl.issue
calls:          

author:         ochowkwale
date:           20200708

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20200708	ochowkwale		initial iteration
******************************************************************************/

declare 
     @err						int				= 0
    ,@ErrMsg					varchar(255)	= 'trigger trg_IssueStatusUpdateFail (trigger) failed.' + Char(13)
    ,@Start						datetime		= GETDATE()
    ,@CreatedBy					varchar(30)		= SYSTEM_USER
	,@Verbose					bit				= 0


begin try
	
	select	 ins.IssueId
	INTO #IssueId
	from	 inserted				  ins
	join	 ctl.RefStatus			  rs
	on		 ins.StatusId			= rs.StatusId
	WHERE rs.StatusCode = 'IF'
	AND ins.IssueName NOT LIKE 'IF_%'

	--Update the Issuename to inlcude status and IssueId
	UPDATE i
	SET IssueName = CONCAT('IF_',i.IssueId,'_',i.IssueName)
		,ModifiedBy = SYSTEM_USER
		,ModifiedDtm = GETDATE()
	FROM ctl.Issue as i
	INNER JOIN #IssueId on #IssueId.IssueId = i.IssueId

end try

begin catch
	select @ErrMsg	= @ErrMsg + char(13)  + 	
					' @IssueId = ' + isnull(cast((select top 1 IssueId from #IssueId) as varchar(100)),'NULL') + ' ' + 
					' @IssueStatusCode = IF'
	select @ErrMsg = @ErrMsg + char(13)  + ERROR_MESSAGE()
	raiserror (@ErrMsg,-1,-1)

end catch
GO

ALTER TABLE [ctl].[Issue] ENABLE TRIGGER [trg_IssueStatusUpdateFail]
GO