-- ************************************** DATA_HUB.REF_Interval
CREATE OR REPLACE TABLE DATA_HUB.REF_Interval
(
 IntervalCode varchar(25) NOT NULL,
 IntervalId   integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 IntervalName varchar(255),
 IntervalDesc varchar(255),
 SLAFormat    varchar(255),
 SLARegEx     varchar(255),
 CreatedBy    varchar(255) NOT NULL,
 CreatedDtm   date NOT NULL,
 ModifiedBy   varchar(255),
 ModifiedDtm  date,

 CONSTRAINT PK_RefInterval_IntervalCode PRIMARY KEY ( IntervalCode )
);