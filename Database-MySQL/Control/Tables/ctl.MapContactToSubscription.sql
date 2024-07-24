CREATE TABLE [ctl].[MapContactToSubscription](
	[ContactToSubscriptionId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NOT NULL,
	[SubscriptionId] [int] NOT NULL,
	[ContactToSubscriptionDesc] [varchar](max) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_ContactToSubscriptionId] PRIMARY KEY CLUSTERED 
(
	[ContactToSubscriptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_MapContactToSubscription__ContactId_SubscriptionId]
    ON [ctl].[MapContactToSubscription]([ContactId] ASC, [SubscriptionId] ASC) WITH (FILLFACTOR = 90);
GO

ALTER TABLE [ctl].[MapContactToSubscription]  ADD  CONSTRAINT [FK_MapContactToSubscription_Subscription__SubscriptionId] FOREIGN KEY([SubscriptionId])
REFERENCES [ctl].[Subscription] ([SubscriptionId])
GO

ALTER TABLE [ctl].[MapContactToSubscription] CHECK CONSTRAINT [FK_MapContactToSubscription_Subscription__SubscriptionId]
GO

ALTER TABLE [ctl].[MapContactToSubscription]  ADD  CONSTRAINT [FK_MapContactToSubscription_Contact__ContactId] FOREIGN KEY([ContactId])
REFERENCES [ctl].[Contact] ([ContactId])
GO