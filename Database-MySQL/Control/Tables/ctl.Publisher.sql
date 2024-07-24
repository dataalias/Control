/* SQLINES DEMO *** ***********************************************************
file:           Publisher.sql
name:           Publisher

purpose:        Provider of publications (feeds).

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE TABLE `ctl`.`Publisher`(
	`PublisherId` int AUTO_INCREMENT NOT NULL,
	`ContactId` int NOT NULL,
	`PublisherCode` varchar(20) NOT NULL,
	`PublisherName` varchar(50) NOT NULL,
	`PublisherDesc` varchar(1000) NULL,
	`InterfaceCode` varchar(20) NOT NULL DEFAULT 'N/A',
	`SiteURL` varchar(256) NULL,
	`SiteUser` varchar(256) NULL,
	`SitePassword` varbinary(8000) NULL,
	`SiteHostKeyFingerprint` varbinary(8000) NULL,
	`SitePort` varchar(10) NULL,
	`SiteProtocol` varchar(100) NULL,
	`PrivateKeyPassPhrase` varbinary(8000) NULL,
	`PrivateKeyFile` varbinary(8000) NULL,
	`CreatedBy` varchar(50) NOT NULL,
	`CreatedDtm` datetime(3) NOT NULL,
	`ModifiedBy` varchar(50) NULL,
	`ModifiedDtm` datetime(3) NULL,
 CONSTRAINT `PK_PubrPublisherId` PRIMARY KEY 
(
	`PublisherId` ASC
) ,
 CONSTRAINT `UNQ_Publisher__PublisherCode` UNIQUE 
(
	`PublisherCode` ASC
) 
);

--  SQLINES DEMO *** [Publisher] ADD  DEFAULT ('N/A') FOR [InterfaceCode]
-- GO

/* Moved to CREATE TABLE
ALTER TABLE `ctl`.`Publisher` ADD  CONSTRAINT `DF__Publisher__InterfaceCode__NA`  DEFAULT (('N/A')) FOR `InterfaceCode`
GO */

ALTER TABLE `ctl`.`Publisher`   ADD  CONSTRAINT `FK_Publisher_RefInterface__InterfaceCode` FOREIGN KEY(`InterfaceCode`)
REFERENCES `ctl`.`RefInterface` (`InterfaceCode`);
 

--  SQLINES DEMO *** [Publisher] CHECK CONSTRAINT [FK_Publisher_RefInterface__InterfaceCode]
-- GO

ALTER TABLE `ctl`.`Publisher`   ADD  CONSTRAINT `FK_RefContact__ContactId` FOREIGN KEY(`ContactId`)
REFERENCES `ctl`.`Contact` (`ContactId`);
 

--  SQLINES DEMO *** [Publisher] CHECK CONSTRAINT [FK_RefContact__ContactId]
-- GO

-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE INDEX `IDX_Publisher__InterfaceCode`
    ON `ctl`.`Publisher`(`InterfaceCode` ASC) ;
 

/* SQLINES DEMO *** ***********************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 
20211007	ffortunato		o PublisherCode 10 --> 20
							+ PublicationDesc
							o DataHube int --> bit
							- MethodCode
******************************************************************************/