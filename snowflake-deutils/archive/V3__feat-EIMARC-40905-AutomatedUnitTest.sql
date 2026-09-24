ALTER TABLE MYDB_@ENV@_RAW.DATA_HUB.PUBLICATION drop column IF EXISTS PUBLISHERID;
ALTER TABLE MYDB_@ENV@_RAW.DATA_HUB.PUBLICATION drop column IF EXISTS KeyStoreName;
ALTER TABLE MYDB_@ENV@_RAW.DATA_HUB.PUBLICATION drop column IF EXISTS  NextExecutionDtm ;
ALTER TABLE MYDB_@ENV@_RAW.DATA_HUB.PUBLICATION add column if not exists NextExecutionDtm timestamp_tz ;
update MYDB_DEV_RAW.DATA_HUB.PUBLICATION
set NextExecutionDtm = dateadd(day,-1,current_timestamp);

