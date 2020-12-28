/******************************************************************************
file:           Distribution.sql
name:           Distribution

purpose:        The specific issue that a subscriber will get.

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
******************************************************************************/

CREATE TABLE [ctl].[Distribution](
	[IssueId] [int] NOT NULL,
	[SubscriptionId] [int] NOT NULL,
	[DistributionId] [bigint] IDENTITY(1,1) NOT NULL,
	[StatusId] [int] NOT NULL,
	[RetryCount] [int] NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_Dist__IssueId_SubnId] PRIMARY KEY CLUSTERED 
(
	[IssueId] ASC,
	[SubscriptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
)
GO

ALTER TABLE [ctl].[Distribution] ADD  CONSTRAINT [DF__Distribution__RetryCount__1]  DEFAULT ((1)) FOR [RetryCount]
GO

ALTER TABLE [ctl].[Distribution]  ADD  CONSTRAINT [FK_Dist__IssueId] FOREIGN KEY([IssueId])
REFERENCES [ctl].[Issue] ([IssueId])
GO

--ALTER TABLE [ctl].[Distribution] CHECK CONSTRAINT [FK_Dist__IssueId]
--GO

ALTER TABLE [ctl].[Distribution]  ADD  CONSTRAINT [FK_Dist__StatusId] FOREIGN KEY([StatusId])
REFERENCES [ctl].[RefStatus] ([StatusId])
GO

--ALTER TABLE [ctl].[Distribution] CHECK CONSTRAINT [FK_Dist__StatusId]
--GO

ALTER TABLE [ctl].[Distribution]  ADD  CONSTRAINT [FK_Dist__SubscriptionId] FOREIGN KEY([SubscriptionId])
REFERENCES [ctl].[Subscription] ([SubscriptionId])
GO

--ALTER TABLE [ctl].[Distribution] CHECK CONSTRAINT [FK_Dist__SubscriptionId]
--GO

CREATE UNIQUE NONCLUSTERED INDEX [UNQ_Dist_DistributionId]
    ON [ctl].[Distribution]([DistributionId] ASC) WITH (FILLFACTOR = 90);
GO

CREATE TRIGGER ctl.[trg_DistributionStatusIssueStatusUpdate] ON [ctl].[Distribution] FOR  UPDATE AS
/******************************************************************************
file:           trg_DistributionStatusIssueStatusUpdate.sql
name:           trg_DistributionStatusIssueStatusUpdate

purpose:        this trigger sits on the distribution table. when a 
				distribution status is updated the trigger determines if the 
				associated issue status can be updated.

called by:      update on ctl.distribution
calls:          

author:         ffortunato
date:           20180928

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20180928	ffortunato		initial iteration
20181002	ffortunato		inserted table (not updated)
******************************************************************************/

declare 
     @err						int				= 0
    ,@ErrMsg					varchar(255)	= 'trigger trg_DistributionStatusIssueStatusUpdate (trigger) failed.' + Char(13)
    ,@Start						datetime		= GETDATE()
    ,@PublisherId				int				= -1
    ,@PublicationId				int				= -1
    ,@IssueId					int				= -1
	,@RefStatsType				varchar(100)	= 'Distribution'
	,@DistributionId			bigint			= -1
	,@DistributionStatusId		int				= -1
    ,@DistributionStatusCode	varchar(20)		= 'DN'
    ,@CreatedBy					varchar(30)		= SYSTEM_USER
	,@Verbose					bit				= 0
	,@TotalCount				int				= -1
	,@MetCount					int				= -2
	,@LoopCount					int				= 1
	,@MaxLoopCount				int				= -2

declare @Inserted table (
		 InsertedId				int identity (1,1) not null
		,DistributionId			bigint		 not null
		,DistributionStatusId	int			 not null
		,DistributionStatusCode	varchar(20)	 not null
		,IssueId				int			 not null
)

begin try

	insert into @Inserted (
			 DistributionId
			,DistributionStatusId
			,DistributionStatusCode
			,IssueId
	)
	select	 ins.DistributionId
			,ins.StatusId
			,rs.StatusCode
			,ins.IssueId
	from	 inserted				  ins
	join	 ctl.RefStatus			  rs
	on		 ins.StatusId			= rs.StatusId

	select	 @MaxLoopCount = max(InsertedId)
	from	 @Inserted

	while	 @LoopCount <= @MaxLoopCount
	begin

		select	 @DistributionId		= ins.DistributionId
				,@DistributionStatusId	= ins.DistributionStatusId
				,@DistributionStatusCode= rs.StatusCode
				,@IssueId				= ins.IssueId
		from	 @Inserted				  ins
		join	 ctl.RefStatus			  rs
		on		 ins.DistributionStatusId	= rs.StatusId
		and		 InsertedId				= @LoopCount

		select	 @TotalCount			= count(1)
		from	 ctl.Distribution		  dist
		where	 dist.IssueId			= @IssueId

		select	 @MetCount				= count(1)
		from	 ctl.Distribution		  dist
		where	 dist.StatusId			= @DistributionStatusId
		and		 dist.IssueId			= @IssueId

		if	(@DistributionStatusCode = 'DF')
		begin
			update	 iss
			set		 StatusId		= (select StatusId from ctl.RefStatus where StatusCode = 'IF')
					,ModifiedBy		= @CreatedBy
					,ModifiedDtm	= @Start
			from	 ctl.Issue		  iss
			where	 iss.IssueId	= @IssueId

		end -- (@DistributionStatusCode = 'DF')

		else if	(@MetCount = @TotalCount)

		begin

			if			 (@DistributionStatusCode = 'DT')
			begin
				update	 iss
				set		 StatusId		= (select StatusId from ctl.RefStatus where StatusCode = 'IN')
						,ModifiedBy		= @CreatedBy
						,ModifiedDtm	= @Start
				from	 ctl.Issue		  iss
				where	 iss.IssueId	= @IssueId

			end
			else if		 (@DistributionStatusCode = 'DC')
			begin
				update	 iss
				set		 StatusId		= (select StatusId from ctl.RefStatus where StatusCode = 'IC')
						,ModifiedBy		= @CreatedBy
						,ModifiedDtm	= @Start
				from	 ctl.Issue		  iss
				where	 iss.IssueId	= @IssueId

			end
		end  -- (@MetCount =@TotalCount)

		select	 @LoopCount		= @LoopCount + 1		

	end -- While loop
end try

	begin catch
		select @ErrMsg	= @ErrMsg + char(13)  + 	
						' @DistributionId = ' + isnull(cast(@DistributionId as varchar(100)),'NULL') + ' ' + 
						' @DistributionStatusId = ' + isnull(cast(@DistributionStatusId as varchar(100)),'NULL') + ' ' + 
						' @DistributionStatusCode = ' + isnull(@DistributionStatusCode,'NULL') 
		select @ErrMsg = @ErrMsg + char(13)  + ERROR_MESSAGE()
		raiserror (@ErrMsg,-1,-1)

	end catch
GO

ALTER TABLE [ctl].[Distribution] ENABLE TRIGGER [trg_DistributionStatusIssueStatusUpdate]
GO