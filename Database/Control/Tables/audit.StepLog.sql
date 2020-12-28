CREATE TABLE [audit].[StepLog](
	[StepLogId] [int] IDENTITY(1,1) NOT NULL,
	[ParentLogId] [int] NOT NULL,
	[ProcessName] [varchar](256) NULL,
	[ProcessType] [varchar](256) NULL,
	[StepName] [varchar](256) NULL,
	[StepDesc] [nvarchar](max) NULL,
	[StepStatus] [varchar](10) NULL,
	[StartDtm] [datetime] NOT NULL,
	[DurationInSeconds] [int] NULL,
	[DbName] [varchar](50) NULL,
	[RecordCount] [int] NULL,
	[ETLExecutionId] [int] NOT NULL,
	[PathId] [int] NOT NULL,
 CONSTRAINT [Pk_StepLog__LogId] PRIMARY KEY CLUSTERED 
(
	[StepLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

ALTER TABLE [audit].[StepLog] ADD  DEFAULT ((0)) FOR [ParentLogId]
GO

CREATE NONCLUSTERED INDEX [IDX_NCI_StepLog_Index1]
    ON [audit].[StepLog]([StepStatus] ASC, [StepName] ASC)
    INCLUDE([ETLExecutionId]) WITH (FILLFACTOR = 95);
GO

CREATE NONCLUSTERED INDEX [IDX_StepLog_ProcessName]
    ON [audit].[StepLog]([ProcessName] ASC) WITH (FILLFACTOR = 95);
GO