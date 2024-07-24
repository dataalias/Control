/* SQLINES DEMO *** ***********************************************************
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

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE TABLE `ctl`.`Issue`(
	`IssueId` int AUTO_INCREMENT NOT NULL,
	`PublicationId` int NOT NULL,
	`StatusId` int NOT NULL,
	`ReportDate` datetime(3) NOT NULL,
	`SrcDFPublisherId` varchar(40) NULL,
	`SrcDFPublicationId` varchar(40) NULL,
	`SrcDFIssueId` varchar(100) NULL,
	`SrcIssueName` nvarchar(255) NULL,
	`SrcDFCreatedDate` datetime(3) NULL,
	DataLakePath varchar(1000) NOT NULL,
	`IssueName` varchar(255) NOT NULL,
	`PublicationSeq` int NOT NULL ,
	`DailyPublicationSeq` int NOT NULL ,
	`FirstRecordSeq` int NULL,
	`LastRecordSeq` int NULL,
	`FirstRecordChecksum` varchar(2048) NULL,
	`LastRecordChecksum` varchar(2048) NULL,
	`PeriodStartTime` datetime(3) NOT NULL,
	`PeriodEndTime` datetime(3) NULL,
	`PeriodStartTimeUTC` Datetime(6)  NULL,
	`PeriodEndTimeUTC` Datetime(6)  NULL,
	`IssueConsumedDate` datetime(3) NULL,
	`RecordCount` int NOT NULL,
	`RetryCount` int NOT NULL ,
	`ETLExecutionId` nvarchar(1000) NULL,
	`CreatedBy` varchar(50) NOT NULL,
	`CreatedDtm` datetime(3) NOT NULL,
	`ModifiedBy` varchar(50) NULL,
	`ModifiedDtm` datetime(3) NULL,
 CONSTRAINT `Pk_IssueIssueId` PRIMARY KEY 
(
	`IssueId` ASC
) 
);


ALTER TABLE `ctl`.`Issue` ADD  CONSTRAINT `DF__Issue__PublicationSeq_-1`  DEFAULT -1 FOR `PublicationSeq`
GO

ALTER TABLE `ctl`.`Issue` ADD  CONSTRAINT `DF__Issue__DailyPublicationSeq_-1`  DEFAULT -1 FOR `DailyPublicationSeq`
GO 

ALTER TABLE `ctl`.`Issue` ADD  CONSTRAINT `DF__Issue__RetryCount__0`  DEFAULT 0 FOR `RetryCount`
GO 


ALTER TABLE `ctl`.`Issue` ADD  CONSTRAINT `DF__Issue__DataLakePath__Raw`  DEFAULT '/Raw Data Zone/...' FOR `DataLakePath`
go

ALTER TABLE `ctl`.`Issue`  ADD  CONSTRAINT `FK_Issue__Publication__PublicationId` FOREIGN KEY(`PublicationId`)
REFERENCES `ctl`.`Publication` (`PublicationId`);
 


-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_Issue__IssueName`
    ON `ctl`.`Issue`(`IssueName` ASC) ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_Issue__ReportDate`
    ON `ctl`.`Issue`(`ReportDate` ASC)
    /* INCLUDE(`PublicationId`, `RecordCount`) */ ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_Issue__StatusId`
    ON `ctl`.`Issue`(`StatusId` ASC) ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_Issue__PublicationId_StatusId`
    ON `ctl`.`Issue`(`PublicationId` ASC)
    /* INCLUDE(`PublicationSeq`, `StatusId`) */ ;
 


create trigger ctl.trg_InsertIssueDistribution on ctl.Issue for -- SQLINES LICENSE FOR EVALUATION USE ONLY
 insert as

/* SQLINES DEMO *** ***********************************************************
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
     v_err						int				default 0
    ; declare v_errmsg					varchar(255)	default CONCAT('trigger trg_InsertIssueDistribution failed.' , Cast(Char(13) As char))
    ; declare v_Start						datetime(3)		default NOW(3)
    ; declare v_PublisherId				int				default -1
    ; declare v_PublicationId				int				default -1
    ; declare v_IssueId					int				default -1
	; declare v_RefStatsType				varchar(100)	default 'Distribution'
    ; declare v_DistributionStatusCode	varchar(20)		default 'DN'
	; declare v_DistributionStatusId		int				default -1
    ; declare v_CreatedBy					varchar(30)		default SYSTEM_USER
	; declare v_Verbose					tinyint				default 0;

begin

select pub.PublisherId
		, ins.PublicationId
		, ins.IssueId into v_PublisherId, v_PublicationId, v_IssueId
from	 inserted				  ins               -- SQLINES DEMO ***  table.
join	 ctl.Publication		  pub
on		 ins.PublicationId		= pub.PublicationId;

select StatusId into v_DistributionStatusId
from	 ctl.RefStatus
where	 StatusCode				= v_DistributionStatusCode
and		 StatusType				= v_RefStatsType;

end

declare continue handler for sqlexception
begin
	set v_errmsg = v_errmsg + cast(char(13) as char)  + ERROR_MESSAGE();
	signal SQLSTATE '02000' SET MESSAGE_TEXT = v_errmsg;
end

if v_Verbose = 1 then 
	/* print Concat('publisherid:    ' , cast(v_PublisherId as char(20))) */
	/* print Concat('publicationid:  ' , cast(v_PublicationId as char(20))) */
	/* print Concat('issueid:        ' , cast(v_IssueId as char(20))) */
	/* print Concat('start:          ' , cast(v_Start as char(20))) */
	/* print CONCAT('DistStatusCode: ' , cast(v_DistributionStatusCode as char(20))) */
	/* print CONCAT('DistStatusId:   ' , cast(v_DistributionStatusId as char(20))) */
	
end if;
	
begin

    -- SQLINES LICENSE FOR EVALUATION USE ONLY
    insert into ctl.`Distribution` (
         IssueId
        ,SubscriptionId
        ,StatusId
        ,CreatedBy
		,CreatedDtm
    )
    select 
         v_IssueId
        ,SubscriptionId
        ,v_DistributionStatusId
        ,v_CreatedBy
		,v_Start
    from	ctl.Subscription	  sub
    where	PublicationId		= v_PublicationId
	and		sub.IsActive		= 1;
-- SQLINES DEMO ***                  between sub.StartDate AND ISNULL(sub.EndDate,@start+1)

end

declare continue handler for sqlexception
begin
	set v_errmsg = v_errmsg + cast(char(13) as char)  + ERROR_MESSAGE();
	signal SQLSTATE '02000' SET MESSAGE_TEXT = v_errmsg;
end
 

ALTER TABLE `ctl`.`Issue` ENABLE TRIGGER `trg_InsertIssueDistribution`
GO


-- SQLINES LICENSE FOR EVALUATION USE ONLY
DELIMITER //

CREATE TRIGGER `ctl`.`trg_IssueStatusUpdateFail` ON `ctl`.`Issue` FOR  UPDATE AS
/* SQLINES DEMO *** ***********************************************************
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
    ,@ErrMsg;					varchar(255)	= CONCAT('trigger trg_IssueStatusUpdateFail (trigger) failed.' , Cast(Char(13) As char))
    ,@Start						datetime		= NOW(3)
    ,@CreatedBy					varchar(30)		= SYSTEM_USER
	,@Verbose					bit				= 0


begin
	
	create temporary table tmp_IssueId as
select	 ins.IssueId
	from	 inserted				  ins
	join	 ctl.RefStatus			  rs
	on		 ins.StatusId			= rs.StatusId
	WHERE rs.StatusCode = 'IF'
	AND ins.IssueName NOT LIKE 'IF_%';

	--  SQLINES DEMO *** me to inlcude status and IssueId
	UPDATE ctl.Issue as i
	INNER JOIN tmp_IssueId on tmp_IssueId.IssueId = i.IssueId
	SET IssueName = CONCAT('IF_',i.IssueId,'_',i.IssueName)
		,ModifiedBy = SYSTEM_USER
		,ModifiedDtm = NOW(3)
;

end

declare continue handler for sqlexception
begin
	set @ErrMsg	= @ErrMsg + cast(char(13) as char)  , 	
					' @IssueId = ' , ifnull(cast((select IssueId from tmp_IssueId
limit 1) as char(100)),'NULL') , ' ' , 
					' @IssueStatusCode = IF';
	set @ErrMsg = @ErrMsg + cast(char(13) as char)  + ERROR_MESSAGE();
	signal SQLSTATE '02000' SET MESSAGE_TEXT = @ErrMsg;

end
 

ALTER TABLE `ctl`.`Issue` ENABLE TRIGGER `trg_IssueStatusUpdateFail`
GO