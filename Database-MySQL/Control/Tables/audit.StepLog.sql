-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE TABLE `audit`.`StepLog`(
	`StepLogId` int AUTO_INCREMENT NOT NULL,
	`ParentLogId` int NOT NULL DEFAULT 0,
	`ProcessName` varchar(256) NULL,
	`ProcessType` varchar(256) NULL,
	`StepName` varchar(256) NULL,
	`StepDesc` Longtext NULL,
	`StepStatus` varchar(10) NULL,
	`StartDtm` datetime(3) NOT NULL,
	`DurationInSeconds` int NULL,
	`DbName` varchar(50) NULL,
	`RecordCount` int NULL,
	`ETLExecutionId` int NOT NULL,
	`PathId` int NOT NULL,
 CONSTRAINT `Pk_StepLog__LogId` PRIMARY KEY 
(
	`StepLogId` ASC
) 
);

/* Moved to CREATE TABLE
ALTER TABLE `audit`.`StepLog` ADD  DEFAULT ((0)) FOR `ParentLogId`
GO */

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_NCI_StepLog_Index1`
    ON `audit`.`StepLog`(`StepStatus` ASC, `StepName` ASC)
    /* INCLUDE(`ETLExecutionId`) */ ;
 

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_StepLog_ProcessName`
    ON `audit`.`StepLog`(`ProcessName` ASC) ;
 