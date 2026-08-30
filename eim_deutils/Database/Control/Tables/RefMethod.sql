
-- ************************************** DATA_HUB.REF_Method
CREATE OR REPLACE TABLE DATA_HUB.REF_Method
(
 MethodCode  varchar(25) NOT NULL,
 MethodId    integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 MethodName  varchar(255),
 MethodDesc  varchar(255),
 CreatedBy   varchar(255) NOT NULL,
 CreatedDtm  date NOT NULL,
 ModifiedBy  varchar(255),
 ModifiedDtm date,

 CONSTRAINT PK_RefMethod_MethodCode PRIMARY KEY ( MethodCode )
);
