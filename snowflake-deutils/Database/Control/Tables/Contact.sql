
-- ----------------------------------------------------------------------------
-- Table ctl.Contact
-- ----------------------------------------------------------------------------
-- ************************************** DATA_HUB.Contact
CREATE TABLE DATA_HUB.Contact
(
 ContactId   integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 CompanyName varchar(255) NOT NULL,
 ContactName varchar(255) NOT NULL DEFAULT 'N/A',
 Tier        varchar(255),
 Email       varchar(255),
 Phone       varchar(255),
 SupportURL  varchar(255),
 Address01   varchar(255),
 Address02   varchar(255),
 City        varchar(255),
 State       varchar(255),
 ZipCode     varchar(255),
 CreatedBy   varchar(255) NOT NULL,
 CreatedDtm  date NOT NULL,
 ModifiedBy  varchar(255),
 ModifiedDtm date,

 CONSTRAINT PK_ContactContactId PRIMARY KEY ( ContactId ),
 CONSTRAINT UNQ_Contact__Name UNIQUE ( ContactName )
);

-- ALTER TABLE `dh`.`Contact` ADD  CONSTRAINT `DF__Contact__Name__NA`  DEFAULT ('N/A') FOR `ContactName`;
