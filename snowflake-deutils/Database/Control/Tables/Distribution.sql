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

-- SQLINES LICENSE FOR EVALUATION USE ONLY

CREATE OR REPLACE TABLE DATA_HUB.Distribution
(
 DistributionId bigint NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 IssueId        bigint NOT NULL,
 SubscriptionId integer NOT NULL,
 StatusId       integer NOT NULL,
 RetryCount     integer NOT NULL DEFAULT ((1)),
 CreatedBy      varchar(255) NOT NULL,
 CreatedDtm     date,
 ModifiedBy     varchar(255),
 ModifiedDtm    date,

 CONSTRAINT PK_Dist__IssueId_SubnId PRIMARY KEY ( IssueId, SubscriptionId ),
 CONSTRAINT UNQ_Dist_DistributionId UNIQUE ( DistributionId ),
 CONSTRAINT FK_Dist__IssueId FOREIGN KEY ( IssueId ) REFERENCES DATA_HUB."Issue" ( IssueId ),
 CONSTRAINT FK_Dist__StatusId FOREIGN KEY ( StatusId ) REFERENCES DATA_HUB.REF_Status ( StatusId ),
 CONSTRAINT FK_Dist__SubscriptionId FOREIGN KEY ( SubscriptionId ) REFERENCES DATA_HUB.Subscription ( SubscriptionId )
);

/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 
							naming default constraints
20240724	ffortunato		converting to my sql 
******************************************************************************/