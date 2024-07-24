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
CREATE TABLE `ctl`.`Distribution`(
	`IssueId` int NOT NULL,
	`SubscriptionId` int NOT NULL,
	`DistributionId` bigint AUTO_INCREMENT NOT NULL,
	`StatusId` int NOT NULL,
	`RetryCount` int NOT NULL,
	`CreatedBy` varchar(50) NOT NULL,
	`CreatedDtm` datetime(3) NULL,
	`ModifiedBy` varchar(50) NULL,
	`ModifiedDtm` datetime(3) NULL,
 CONSTRAINT `PK_Dist__IssueId_SubnId` PRIMARY KEY 
(
	`IssueId` ASC,
	`SubscriptionId` ASC
) 
);

ALTER TABLE `ctl`.`Distribution` ADD  CONSTRAINT `DF__Distribution__RetryCount__1`  DEFAULT ((1)) FOR `RetryCount`;


ALTER TABLE `ctl`.`Distribution`  ADD  CONSTRAINT `FK_Dist__IssueId` FOREIGN KEY(`IssueId`)
REFERENCES `ctl`.`Issue` (`IssueId`);
 


ALTER TABLE `ctl`.`Distribution`  ADD  CONSTRAINT `FK_Dist__StatusId` FOREIGN KEY(`StatusId`)
REFERENCES `ctl`.`RefStatus` (`StatusId`);
 

ALTER TABLE `ctl`.`Distribution`  ADD  CONSTRAINT `FK_Dist__SubscriptionId` FOREIGN KEY(`SubscriptionId`)
REFERENCES `ctl`.`Subscription` (`SubscriptionId`);
 


CREATE TRIGGER ctl.`trg_DistributionStatusIssueStatusUpdate` ON `ctl`.`Distribution` FOR  UPDATE AS
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
20211006	ffortunato		updating error handling section of trigger.
							throw rather than raiseerror.
******************************************************************************/

declare 
     @ErrNum					int				= 0
    ,@ErrMsg;					varchar(255)	= CONCAT('trigger trg_DistributionStatusIssueStatusUpdate (trigger) failed.' , Cast(Char(13) As char))
    ,@Start						datetime		= NOW(3)
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

drop temporary table if exists tmp_Inserted;
create temporary table tmp_Inserted (
		 InsertedId				int auto_increment not null
		,DistributionId			bigint		 not null
		,DistributionStatusId	int			 not null
		,DistributionStatusCode	varchar(20)	 not null
		,IssueId				int			 not null
);

begin

	-- SQLINES LICENSE FOR EVALUATION USE ONLY
	insert into tmp_Inserted (
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
	on		 ins.StatusId			= rs.StatusId;

	select max(InsertedId) into @MaxLoopCount
	from	 tmp_Inserted

	while;	 @LoopCount <= @MaxLoopCount
	begin

		select ins.DistributionId
				, ins.DistributionStatusId
				, rs.StatusCode
				, ins.IssueId into @DistributionId, @DistributionStatusId, @DistributionStatusCode, @IssueId
		from	 tmp_Inserted				  ins
		join	 ctl.RefStatus			  rs
		on		 ins.DistributionStatusId	= rs.StatusId
		and		 InsertedId				= @LoopCount;

		select count(1) into @TotalCount
		from	 ctl.Distribution		  dist
		where	 dist.IssueId			= @IssueId;

		select count(1) into @MetCount
		from	 ctl.Distribution		  dist
		where	 dist.StatusId			= @DistributionStatusId
		and		 dist.IssueId			= @IssueId;

		if	(@DistributionStatusCode = 'DF')
		then
			update		 ctl.Issue		  iss
			set		 StatusId		= (select StatusId from ctl.RefStatus where StatusCode = 'IF')
					,ModifiedBy		= @CreatedBy
					,ModifiedDtm	= @Start
			where	 iss.IssueId	= @IssueId;

	 -- SQLINES DEMO *** tusCode = 'DF')

		elseif 	(@MetCount = @TotalCount)

		then

			if			 (@DistributionStatusCode = 'DT')
			then
				update		 ctl.Issue		  iss
				set		 StatusId		= (select StatusId from ctl.RefStatus where StatusCode = 'IN')
						,ModifiedBy		= @CreatedBy
						,ModifiedDtm	= @Start
				where	 iss.IssueId	= @IssueId;

			elseif 		 (@DistributionStatusCode = 'DC')
			then
				update		 ctl.Issue		  iss
				set		 StatusId		= (select StatusId from ctl.RefStatus where StatusCode = 'IC')
						,ModifiedBy		= @CreatedBy
						,ModifiedDtm	= @Start
				where	 iss.IssueId	= @IssueId;

			end if;
		end if;  -- SQLINES DEMO *** lCount)

		set	 @LoopCount		= @LoopCount + 1;		

	end; -- Wh... SQLINES DEMO ***
end

	declare continue handler for sqlexception
	begin
		
		set @ErrNum  = @@ERROR;

		if @ErrNum < 50000 then
			set @ErrNum = @ErrNum + 100000;
		end if;

		set @ErrMsg	= @ErrMsg + cast(char(13) as char)  , 	
						' @DistributionId = ' , ifnull(cast(@DistributionId as char(100)),'NULL') , ' ' , 
						' @DistributionStatusId = ' , ifnull(cast(@DistributionStatusId as char(100)),'NULL') , ' ' , 
						' @DistributionStatusCode = ' , ifnull(@DistributionStatusCode,'NULL'); 
		set @ErrMsg = @ErrMsg + cast(char(13) as char)  + ERROR_MESSAGE();
		
		/* print @ErrMsg
		; */throw	 @ErrNum, @ErrMsg, 1

	end
 

ALTER TABLE `ctl`.`Distribution` ENABLE TRIGGER `trg_DistributionStatusIssueStatusUpdate`
GO


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