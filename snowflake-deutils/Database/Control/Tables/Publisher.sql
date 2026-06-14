/****************************************************************************
file:           Publisher.sql
name:           Publisher

purpose:        Provider of publications (feeds).

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.Publisher
-- ----------------------------------------------------------------------------

-- ************************************** DATA_HUB.PUBLISHER
-- ************************************** DATA_HUB.Publisher
CREATE OR REPLACE TABLE DATA_HUB.Publisher
(
 PublisherId            integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1 order,
 --ContactId              integer NOT NULL,
 ContactName            varchar(255) NOT NULL,
 PublisherCode          varchar(25) NOT NULL,
 PublisherName          varchar(255) NOT NULL,
 PublisherDesc          varchar(255),
 InterfaceCode          varchar(25) NOT NULL DEFAULT (('N/A')),
 SecretKey              varchar(255),
 CreatedBy              varchar(255) NOT NULL,
 CreatedDtm             date NOT NULL,
 ModifiedBy             varchar(255),
 ModifiedDtm            date,

 CONSTRAINT PK_PubrPublisherId PRIMARY KEY ( PublisherId ),
 CONSTRAINT UNQ_Publisher__PublisherCode UNIQUE ( PublisherCode ),
 CONSTRAINT FK_Publisher_RefInterface__InterfaceCode FOREIGN KEY ( InterfaceCode ) REFERENCES DATA_HUB.REF_Interface ( InterfaceCode ),
 CONSTRAINT FK_RefContact__ContactId FOREIGN KEY ( ContactId ) REFERENCES DATA_HUB.Contact ( ContactId )
);
  /*
  UNIQUE INDEX UNQ_Publisher__PublisherCode (Publisher_Code ASC) VISIBLE,
  INDEX IDX_Publisher__InterfaceCode (Interface_Code ASC) VISIBLE,
  CONSTRAINT FK_Publisher_RefInterface__Interface_Code
    FOREIGN KEY (Interface_Code)
    REFERENCES ctl.RefInterface (Interface_Code)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_RefContact__ContactId
    FOREIGN KEY (ContactId)
    REFERENCES ctl.Contact (Contact_Id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    */
/*
-- ALTER TABLE ctl.Publisher ADD  CONSTRAINT DF__Publisher__InterfaceCode__NA  SET DEFAULT (('N/A')) FOR InterfaceCode;
ALTER TABLE ctl.Publisher  ALTER COLUMN  InterfaceCode SET DEFAULT 'N/A';

ALTER TABLE ctl.Publisher   ADD  CONSTRAINT FK_RefContact__ContactId FOREIGN KEY(ContactId)
REFERENCES ctl.Contact (ContactId);
 
CREATE INDEX IDX_Publisher__InterfaceCode
    ON ctl.Publisher(InterfaceCode ASC) ;
 */

/******************************************************************************
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
20240724	ffortunato		o Convert to MySQL
20241031	ffortunato		o ContactId --> Contact Name varchar(255)
******************************************************************************/