ALTER TABLE ULTRA_@ENV@_RAW.DATA_HUB.PUBLICATION drop column IF EXISTS PUBLISHERID;
ALTER TABLE ULTRA_@ENV@_RAW.DATA_HUB.PUBLICATION drop column IF EXISTS KeyStoreName;
ALTER TABLE ULTRA_@ENV@_RAW.DATA_HUB.PUBLICATION drop column IF EXISTS  NextExecutionDtm ;
ALTER TABLE ULTRA_@ENV@_RAW.DATA_HUB.PUBLICATION add column if not exists NextExecutionDtm timestamp_tz ;
update ULTRA_DEV_RAW.DATA_HUB.PUBLICATION
set NextExecutionDtm = dateadd(day,-1,current_timestamp);

