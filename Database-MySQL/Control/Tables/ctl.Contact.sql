
CREATE TABLE `ctl`.`Contact`(
	`ContactId` int AUTO_INCREMENT NOT NULL,
	`CompanyName` varchar(250) NOT NULL DEFAULT 'N/A',
	`ContactName` varchar(250) NOT NULL,
	`Tier` varchar(20) NULL,
	`Email` varchar(100) NULL,
	`Phone` varchar(20) NULL,
	`SupportURL` varchar(1000) NULL,
	`Address01` varchar(100) NULL,
	`Address02` varchar(100) NULL,
	`City` varchar(30) NULL,
	`State` varchar(10) NULL,
	`ZipCode` varchar(10) NULL,
	`CreatedBy` varchar(50) NOT NULL,
	`CreatedDtm` datetime(3) NOT NULL,
	`ModifiedBy` varchar(50) NULL,
	`ModifiedDtm` datetime(3) NULL,
 CONSTRAINT `PK_ContactContactId` PRIMARY KEY 
(
	`ContactId` ASC
) 
);

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE UNIQUE INDEX `UNQ_Contact__Name` ON ctl.Contact(`ContactName`)
 ;
 

-- ALTER TABLE `dh`.`Contact` ADD  CONSTRAINT `DF__Contact__Name__NA`  DEFAULT ('N/A') FOR `ContactName`;
