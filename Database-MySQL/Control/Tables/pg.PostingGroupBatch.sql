CREATE TABLE [pg].[PostingGroupBatch](
	[PostingGroupBatchId] [int] IDENTITY(1,1) NOT NULL,
	[DateId] [int] NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_PGB_PostingGroupBatchId] PRIMARY KEY CLUSTERED 
(
	[PostingGroupBatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_PostingGroupBatch__DateId]
    ON [pg].[PostingGroupBatch]([DateId] ASC) WITH (FILLFACTOR = 90);
GO