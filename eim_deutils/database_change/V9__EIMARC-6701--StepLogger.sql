   CREATE SEQUENCE ULTRA_@ENV@_RAW.DATA_HUB.SEQ__STEP_LOG_ID;



    -- To get the ID before insertion:
    -- SET next_id = (SELECT my_sequence.NEXTVAL FROM DUAL);
    -- INSERT INTO my_table (id, name) VALUES ($next_id, 'John Doe');
    -- Now $next_id holds the value used for the 'id' column.




CREATE TABLE IF NOT EXISTS ULTRA_@ENV@_RAW.DATA_HUB.STEP_LOG(
	Step_Log_Id bigint DEFAULT ULTRA_@ENV@_RAW.DATA_HUB.SEQ__STEP_LOG_ID.NEXTVAL,
	Parent_Log_Id int NOT NULL DEFAULT 0,
	Process_Name varchar(256) NULL,
	Process_Type varchar(256) NULL,
	Step_Name varchar(256) NULL,
	Step_Desc varchar (8000)NULL,
	Step_Status varchar(10) NULL,
	Start_Dtm datetime NOT NULL,
	Duration_In_Seconds int NULL,
	Db_Name varchar(50) NULL,
	Record_Count int NULL,
	ETL_Execution_Id varchar(250) NOT NULL,
 CONSTRAINT Pk_StepLog__LogId PRIMARY KEY 
(
	Step_Log_Id
) 
);

GRANT USAGE ON SEQUENCE ULTRA_@ENV@_RAW.DATA_HUB.SEQ__STEP_LOG_ID TO ROLE PIPELINE_@ENV@_SVC;
GRANT OWNERSHIP ON TABLE ULTRA_@ENV@_RAW.DATA_HUB.STEP_LOG TO ROLE ULTRA_@ENV@_RAW__DATA_HUB__ADMIN COPY CURRENT GRANTS;
