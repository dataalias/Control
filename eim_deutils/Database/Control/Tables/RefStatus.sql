-- ************************************** DATA_HUB.REF_Status
CREATE OR REPLACE TABLE DATA_HUB.REF_Status
(
 StatusId    integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 StatusCode  varchar(25) NOT NULL,
 StatusName  varchar(255) NOT NULL,
 StatusDesc  varchar(255) NOT NULL,
 StatusType  varchar(255) NOT NULL,
 CreatedBy   varchar(255) NOT NULL,
 CreatedDtm  date NOT NULL,
 ModifiedBy  varchar(255),
 ModifiedDtm date,

 CONSTRAINT PK_RefStatus__StatusCode PRIMARY KEY ( StatusCode )
 --CONSTRAINT UNQ_RefStatus__StatusCode UNIQUE ( StatusCode )
);