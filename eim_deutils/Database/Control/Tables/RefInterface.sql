-- ************************************** DATA_HUB.REF_Interface
CREATE OR REPLACE TABLE DATA_HUB.REF_Interface
(
 InterfaceCode varchar(25) NOT NULL,
 InterfaceId   integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 InterfaceName varchar(255),
 InterfaceDesc varchar(255) NOT NULL,
 CreatedBy     varchar(255) NOT NULL,
 CreatedDtm    date NOT NULL,
 ModifiedBy    varchar(255),
 ModifiedDtm   date,

 CONSTRAINT PK_RefInterface__InterfaceCode PRIMARY KEY ( InterfaceCode )
);