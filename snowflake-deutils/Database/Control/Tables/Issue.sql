/**********************************************************************************************************************
file:           Issue.sql
name:           Issue

purpose:        Provides a list of feeds produced by publishers.

called by:      
calls:          

author:         ffortunato
date:           20181011

**********************************************************************************************************************/
CREATE OR REPLACE TABLE DATA_HUB.ISSUE
(
 IssueId             bigint NOT NULL DEFAULT DATA_HUB.SEQ_ISSUE_ID.NEXTVAL,
-- PublicationId       integer NOT NULL,
 PublicationCode     varchar(25) NOT NULL,
 StatusCode          varchar(25) NOT NULL,
 ReportDate          date NOT NULL,
 SrcDFPublisherId    varchar(255),
 SrcDFPublicationId  varchar(255),
 SrcDFIssueId        varchar(255),
 SrcIssueName        varchar(255),
 SrcDFCreatedDate    TIMESTAMP_TZ ,
 DataLakePath        varchar(255) NOT NULL DEFAULT '/Raw Data Zone/...',
 IssueName           varchar(255) NOT NULL,
 PublicationSeq      integer NOT NULL DEFAULT -1,
 DailyPublicationSeq integer NOT NULL DEFAULT -1,
 FirstRecordSeq      bigint,
 LastRecordSeq       bigint,
 FirstRecordChecksum varchar(255),
 LastRecordChecksum  varchar(255),
 PeriodStartTime     TIMESTAMP_TZ  NOT NULL,
 PeriodEndTime       TIMESTAMP_TZ ,
 PeriodStartTimeUTC  TIMESTAMP_TZ ,
 PeriodEndTimeUTC    TIMESTAMP_TZ ,
 IssueConsumedDate   TIMESTAMP_TZ,
 RecordCount         integer NOT NULL,
 RetryCount          integer NOT NULL DEFAULT 0,
 ETLExecutionId      varchar(255),
 CreatedBy           varchar(255) NOT NULL,
 CreatedDtm          TIMESTAMP_TZ NOT NULL,
 ModifiedBy          varchar(255),
 ModifiedDtm         TIMESTAMP_TZ,

 CONSTRAINT Pk_IssueIssueId PRIMARY KEY ( IssueId ),
 CONSTRAINT FK_Issue__Publication__PublicationCode FOREIGN KEY ( PublicationCode ) REFERENCES DATA_HUB.Publication ( PublicationCode ),
 CONSTRAINT FK_Issue__RefStatus__StatusCode FOREIGN KEY ( StatusCode ) REFERENCES DATA_HUB.REF_Status ( StatusCode )
);
  /*
  INDEX IDX_Issue__IssueName (Issue_Name ASC) VISIBLE,
  INDEX IDX_Issue__ReportDate (Report_Date ASC, PublicationId ASC, RecordCount ASC) VISIBLE,
  INDEX IDX_Issue__StatusId (Status_Id ASC) VISIBLE,
  INDEX IDX_Issue__PublicationId_StatusId (Publication_Id ASC, PublicationSeq ASC, StatusId ASC) VISIBLE,
  CONSTRAINT FK_Issue__RefStatus__StatusId
    FOREIGN KEY (StatusId)
    REFERENCES ctl.RefStatus (StatusId)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_Issue__Publication__PublicationId
    FOREIGN KEY (PublicationId)
    REFERENCES ctl.Publication (PublicationId)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
*/

/*
ALTER TABLE ctl.Issue ADD  CONSTRAINT DF__Issue__PublicationSeq_-1  DEFAULT -1 FOR PublicationSeq
GO

ALTER TABLE ctl.Issue ADD  CONSTRAINT DF__Issue__DailyPublicationSeq_-1  DEFAULT -1 FOR DailyPublicationSeq
GO 

ALTER TABLE ctl.Issue ADD  CONSTRAINT DF__Issue__RetryCount__0  DEFAULT 0 FOR RetryCount
GO 


ALTER TABLE ctl.Issue ADD  CONSTRAINT DF__Issue__DataLakePath__Raw  DEFAULT '/Raw Data Zone/...' FOR DataLakePath
go

ALTER TABLE ctl.Issue  ADD  CONSTRAINT FK_Issue__Publication__PublicationId FOREIGN KEY(PublicationId)
REFERENCES ctl.Publication (PublicationId);
 


-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX IDX_Issue__IssueName
    ON ctl.Issue(IssueName ASC) ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX IDX_Issue__ReportDate
    ON ctl.Issue(ReportDate ASC)
    /* INCLUDE(PublicationId, RecordCount) */ ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
/*
CREATE INDEX IDX_Issue__StatusCode
    ON ctl.Issue(StatusCode ASC) ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX IDX_Issue__PublicationCode
    ON ctl.Issue(PublicationCode ASC)
*/

/**********************************************************************************************************************
       change history
***********************************************************************************************************************
date		author			description
--------	-------------	-------------------------------------------------------------------------------------------
20181011	ffortunato		initial iteration
20240901	ffortunato		o ready for snowflake
20240919	ffortunato		o timestamp_tz
                            o issue_id bigint
20260420	ffortunato		o IssueId AUTOINCREMENT -> DEFAULT DATA_HUB.SEQ_ISSUE_ID.NEXTVAL
**********************************************************************************************************************/

