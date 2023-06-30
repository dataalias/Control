/******************************************************************************
file:           PostingGroupProcessing.sql
name:           PostingGroupProcessing

purpose:        Provides a list of postings groups that have run.

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

******************************************************************************/
CREATE TABLE [pg].[PostingGroupProcessing](
	[PostingGroupProcessingId] [bigint] IDENTITY(1,1) NOT NULL,
	[PostingGroupBatchId] [int] NOT NULL,
	[PostingGroupId] [int] NOT NULL,
	[PostingGroupStatusId] [int] NOT NULL,
	[PGPBatchSeq] [bigint] NOT NULL,
	[SrcBatchSeq] [bigint] NOT NULL,
	[ProcessingModeCode] varchar(20) NOT NULL,
	[DateId] [int] NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[DurationChar] [varchar](20) NOT NULL,
	[DurationSec] [int] NOT NULL,
	[RecordCount] [int] NOT NULL,
	[RetryCount] [int] NOT NULL,
	[IssueId] [bigint] NOT NULL,
	[DistributionId] [bigint] NOT NULL,
	[ETLExecutionId] [int] NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_PGP_PostingGroupProcessingId] PRIMARY KEY CLUSTERED 
(
	[PostingGroupProcessingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__PostingGroupStatusId_-1]  DEFAULT ((-1)) FOR [PostingGroupStatusId]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__PGPBatchSeq__1]  DEFAULT ((1)) FOR [PGPBatchSeq]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__SrcBatchSeq__1]  DEFAULT ((1)) FOR [SrcBatchSeq]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__ProcessingModeCode__NORM]  DEFAULT (('NORM')) FOR [ProcessingModeCode]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__DurationChar__0]  DEFAULT ('00:00:00') FOR [DurationChar]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__DurationSec__-1]  DEFAULT ((-1)) FOR [DurationSec]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__RecordCount__-1]  DEFAULT ((-1)) FOR [RecordCount]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__RetryCount__0]  DEFAULT ((0)) FOR [RetryCount]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__IssueId__-1]  DEFAULT ((-1)) FOR [IssueId]
GO

ALTER TABLE [pg].[PostingGroupProcessing] ADD  CONSTRAINT [DF__PostingGroupProcessing__DistributionId__-1]  DEFAULT ((-1)) FOR [DistributionId]
GO

ALTER TABLE [pg].[PostingGroupProcessing]  ADD  CONSTRAINT [FK_PGP_PostingGroupBatchId] FOREIGN KEY([PostingGroupBatchId])
REFERENCES [pg].[PostingGroupBatch] ([PostingGroupBatchId])
GO

--ALTER TABLE [pg].[PostingGroupProcessing] CHECK CONSTRAINT [FK_PGP_PostingGroupBatchId]
--GO

ALTER TABLE [pg].[PostingGroupProcessing]  ADD  CONSTRAINT [FK_PGP_PostingGroupId] FOREIGN KEY([PostingGroupId])
REFERENCES [pg].[PostingGroup] ([PostingGroupId])
GO

--ALTER TABLE [pg].[PostingGroupProcessing] CHECK CONSTRAINT [FK_PGP_PostingGroupId]
--GO

ALTER TABLE [pg].[PostingGroupProcessing]  ADD  CONSTRAINT [FK_PGP_PostingGroupStatusId] FOREIGN KEY([PostingGroupStatusId])
REFERENCES [pg].[RefStatus] ([StatusId])
GO

--ALTER TABLE [pg].[PostingGroupProcessing] CHECK CONSTRAINT [FK_PGP_PostingGroupStatusId]
--GO
ALTER TABLE [pg].[PostingGroupProcessing]   ADD  CONSTRAINT [FK_ProcessingMode_PostingGroupProcessing__ProcessingModeCode] FOREIGN KEY([ProcessingModeCode])
REFERENCES [pg].[RefProcessingMode] ([ProcessingModeCode]) 
GO

CREATE NONCLUSTERED INDEX [idx_PGP_PGID]
    ON [pg].[PostingGroupProcessing]([PostingGroupId] ASC)
    INCLUDE([PostingGroupBatchId], [PostingGroupStatusId]) WITH (FILLFACTOR = 90);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_PGP__ProcessingId_BatchId_BatchSeq]
    ON [pg].[PostingGroupProcessing]([PostingGroupBatchId] ASC, [PostingGroupId] ASC, [PGPBatchSeq] ASC) WITH (FILLFACTOR = 90);
GO

CREATE TRIGGER pg.trg_NotifyCompleteDistribution ON [pg].[PostingGroupProcessing] FOR  UPDATE AS
/******************************************************************************
file:           trg_NotifyCompleteDistribution.sql
name:           trg_NotifyCompleteDistribution

purpose:        this trigger sits on the PostingGroupProcessing table. when a 
				PostingGroupProcessing status is updated the trigger determines if the 
				associated distribtuion status can be updated.

called by:      update on pg.PostingGroupProcessing
calls:          

author:         ffortunato
date:           20181011

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20210413	ffortunato		lots of ints here should be bigints...

******************************************************************************/

declare 
     @err						int				= 0
    ,@ErrMsg					varchar(255)	= 'trg_NotifyCompleteDistribution (trigger) failed.' + Char(13)
    ,@Start						datetime		= GETDATE()
    ,@PublisherId				int				= -1
    ,@PublicationId				int				= -1
    ,@IssueId					int				= -1
	,@RefStatsType				varchar(100)	= 'Distribution'
	,@DistributionId			bigint			= -1
	,@DistributionStatusId		int				= -1
    ,@DistributionStatusCode	varchar(20)		= 'DN'
	,@ChildPostingGroupId		bigint				= -1
	,@PostingGroupProcessingId	bigint			= -1
	,@PostingGroupId			int				= -1
	,@PostingGroupBatchId		bigint			= -1
	,@PGPBatchSeq				bigint			= -1
	,@PostingGroupProcessingStatusId	int		= -1
	,@PostingGroupProcessingStatusCode	varchar(20) = 'N/A'
    ,@CreatedBy					varchar(30)		= SYSTEM_USER
	,@Verbose					bit				= 0
	,@TotalCount				int				= -1
	,@MetCount					int				= -2
	,@LoopCount					int				= 1
	,@MaxLoopCount				int				= -2
	,@ChildLoopCount			int				= 1
	,@ChildMaxLoopCount			int				= -2

declare @Inserted table (
	 InsertedId							int identity (1,1)		not null
	,PostingGroupProcessingId			bigint		not null
	,PostingGroupId						int			not null
	,PostingGroupBatchId				int			not null
	,PGPBatchSeq						bigint		not null
	,PostingGroupProcessingStatusId		int			not null
	,PostingGroupProcessingStatusCode	varchar(20) not null
)

declare @AllMyChildren table (
	 AllMyChildrenId					int identity (1,1)		not null
	,ChildPostingGroupId				bigint		not null
	,PostingGroupBatchId				bigint		not null
	,PGPBatchSeq						bigint		not null
	,PostingGroupProcessingStatusId		int			not null
	,DistributionId						bigint		not null
)

begin try

	insert into @Inserted (
			 PostingGroupProcessingId
			,PostingGroupId
			,PostingGroupBatchId
			,PGPBatchSeq
			,PostingGroupProcessingStatusId
			,PostingGroupProcessingStatusCode	
	)
	select	 ins.PostingGroupProcessingId
			,ins.PostingGroupId
			,ins.PostingGroupBatchId
			,ins.PGPBatchSeq
			,ins.PostingGroupStatusId
			,rs.StatusCode
	from	 inserted					  ins
	join	 pg.RefStatus				  rs
	on		 ins.PostingGroupStatusId	= rs.StatusId
	where	 rs.StatusCode				in ('PC','PF')

	-- Technically there should never be more than one records inserted at a time.
	-- Just incase we are loading this into a while loop.

	select	 @MaxLoopCount = max(InsertedId)
	from	 @Inserted

	while	 @LoopCount <= @MaxLoopCount
	begin

		select	 @PostingGroupProcessingId			= ins.PostingGroupProcessingId
				,@PostingGroupId					= ins.PostingGroupId
				,@PostingGroupBatchId				= ins.PostingGroupBatchId
				,@PGPBatchSeq						= ins.PGPBatchSeq
				,@PostingGroupProcessingStatusCode	= ins.PostingGroupProcessingStatusCode
				,@PostingGroupProcessingStatusId    = ins.PostingGroupProcessingStatusId
		from	 @Inserted							  ins
		where	 InsertedId							= @LoopCount

		-- base line the Parent process that just completed.
		-- Find that parents children
		-- Find those children's parents
		-- Count the total number of parents.

		insert into @AllMyChildren (
				 ChildPostingGroupId
				,PostingGroupBatchId
				,PGPBatchSeq
				,PostingGroupProcessingStatusId
				,DistributionId)
		select	 pgd.ChildId
				,@PostingGroupBatchId
				,@PGPBatchSeq
				,@PostingGroupProcessingStatusId
				,-3
		from	pg.PostingGroupDependency			  pgd
		where	pgd.ParentId						= @PostingGroupId  -- this is the parent that fired the trigger
		group by pgd.ChildId

		update										  amc
		set		 DistributionId						= isnull(pgp.DistributionId, -2)
		from	 @AllMyChildren						  amc
		join	 pg.PostingGroupProcessing			  pgp
		on		pgp.PostingGroupId					= ChildPostingGroupId
		where	pgp.PostingGroupBatchId				= @PostingGroupBatchId
		and		pgp.PGPBatchSeq						= @PGPBatchSeq
		and		pgp.PostingGroupStatusId			= @PostingGroupProcessingStatusId

		-- Now check the indiivdual children's parents for completion. 
		-- If all parents are complete notify datahub.

		select	 @ChildMaxLoopCount = max(AllMyChildrenId)
		from	 @AllMyChildren

		while	 @ChildLoopCount <= @ChildMaxLoopCount
		begin

			select	 @ChildPostingGroupId				= amc.ChildPostingGroupId
					,@PostingGroupBatchId				= amc.PostingGroupBatchId
					,@PGPBatchSeq						= amc.PGPBatchSeq
					,@PostingGroupProcessingStatusId    = amc.PostingGroupProcessingStatusId
					,@DistributionId					= amc.DistributionId
			from	 @AllMyChildren						  amc
			where	 AllMyChildrenId					= @ChildLoopCount

			select	 @TotalCount						= count(1)
			from	 @AllMyChildren						  amc
			join	 pg.PostingGroupDependency			  pgd
			on		amc.ChildPostingGroupId				= pgd.ChildId
			where	 AllMyChildrenId					= @ChildLoopCount

			select	 @MetCount							= count(1)
			from	 @AllMyChildren						  amc
			join	  pg.PostingGroupDependency			  pgdC
			on		amc.ChildPostingGroupId				= pgdC.ChildId
			join	  pg.PostingGroupProcessing			  pgpP
			on		pgdC.ParentId						= pgpP.PostingGroupId
			and		pgpP.PostingGroupBatchId			= amc.PostingGroupBatchId
			and		pgpP.PostingGroupStatusId			= amc.PostingGroupProcessingStatusId
			and		pgpP.PGPBatchSeq					= amc.PGPBatchSeq
			where	 AllMyChildrenId					= @ChildLoopCount

			if	(@PostingGroupProcessingStatusCode = 'PF')
			begin
				update	 dis
				set		 StatusId			= (select StatusId from ctl.RefStatus where StatusCode = 'DF')
						,ModifiedBy			= @CreatedBy
						,ModifiedDtm		= @Start
				from	 ctl.Distribution	  dis
				where	 dis.DistributionId	= @DistributionId

			end -- (@@PostingGroupProcessingStatusCode = 'PF')

			else if	((@MetCount = @TotalCount) and (@PostingGroupProcessingStatusCode = 'PC'))
			begin
					update	 dis
					set		 StatusId			= (select StatusId from ctl.RefStatus where StatusCode = 'DC')
							,ModifiedBy			= @CreatedBy
							,ModifiedDtm		= @Start
					from	 ctl.Distribution	  dis
					where	 dis.DistributionId	= @DistributionId
			end  -- (@MetCount =@TotalCount)

			select	 @ChildLoopCount					= @ChildLoopCount + 1	
					,@ChildPostingGroupId				= -1
					,@PostingGroupBatchId				= -1
					,@PGPBatchSeq						= -1
					,@DistributionId					= -3

		end -- while for the children
		select	 @LoopCount							= @LoopCount + 1	
				,@PostingGroupProcessingId			= -1
				,@PostingGroupBatchId				= -1
				,@PGPBatchSeq						= -1
				,@PostingGroupProcessingStatusCode	= 'PF'
				,@PostingGroupProcessingStatusId    = -1

	end -- While loop for _all_ updated records.
end try

	begin catch
		select @ErrMsg	= @ErrMsg + char(13)  + 	
						' @DistributionId = ' + isnull(cast(@DistributionId as varchar(100)),'NULL') + ' ' 
		select @ErrMsg = @ErrMsg + char(13)  + ERROR_MESSAGE()
		raiserror (@ErrMsg,-1,-1)

	end catch


GO

ALTER TABLE [pg].[PostingGroupProcessing] ENABLE TRIGGER [trg_NotifyCompleteDistribution]
GO