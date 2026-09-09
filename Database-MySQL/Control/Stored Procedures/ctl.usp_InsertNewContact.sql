DELIMITER //
-- DROP PROCEDURE ctl.usp_InsertNewContact
CREATE PROCEDURE ctl.usp_InsertNewContact (
		 p_pCompanyName				varchar(250)	/* = 'Unknown' */         
		,p_pContactName				varchar(250)	/* = 'Unknown' */
		,p_pTier						varchar(20)	/* = 1 */
		,p_pEmail					varchar(100)	/* = 'Unknown' */
		,p_pPhone					varchar(20)	/* = 'Unknown' */
		,p_pSupportURL				varchar(250)	/* = 'Unknown' */
		,p_pAddress01				varchar(100)	/* = 'Unknown' */
		,p_pAddress02				varchar(100)	/* = 'Unknown' */
		,p_pCity						varchar(30)	/* = 'Unknown' */
		,p_pState					varchar(10)	/* = 'Unknown' */
		,p_pZipCode					varchar(10)	/* = 'Unknown' */
		,p_pETLExecutionId			INT				/* = -1 */
		,p_pPathId					INT				/* = -1 */
		,p_pVerbose					TINYINT				/* = 0 */)
BEGIN
/* SQLINES DEMO *** **********************************************************
File:		ctl.usp_InsertNewContact.sql
Name:		ctl.usp_InsertNewContact
Purpose:	


EXEC [ctl].[usp_InsertNewContact] 
		 @pName						= 'Unit Test Name'
		,@pTier						= '1'
		,@pEmail					= 'MY_NOTIFICATION_EMAIL@example.com'
		,@pPhone					= '877.300.6069'
		,@pAddress01				= '10180 Telesis Ct'
		,@pAddress02				= '#400'
		,@pCity						= 'San Diego'
		,@pState					= 'CA'
		,@pZipCode					= '92121'


		

Parameters:    

Called by:	
Calls:          

Errors:		

Author:	ffortunato	
Date:	20201120	

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20201120	ffortunato		Initital Iteration

******************************************************************************/

--  SQLINES DEMO *** -----------------------------------------------------------
--  D... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

DECLARE  v_Rows				  int				DEFAULT 0
		; DECLARE v_ErrNum			  int				DEFAULT -1
		; DECLARE v_ErrMsg			  longtext		DEFAULT 'N/A'
		; DECLARE v_ParametersPassedChar  varchar(1000)	DEFAULT 'N/A'
		; DECLARE v_CRLF				  varchar(10)		DEFAULT cast(char(13) as char) + cast(char(10) as char)
		; DECLARE v_ProcName			  varchar(256)		DEFAULT 'usp_InsertNewContact'
		; DECLARE v_ParentStepLogId	  int				DEFAULT -1
		; DECLARE v_PrevStepLog		  int				DEFAULT -2
		; DECLARE v_ProcessStartDtm	  datetime(3)			DEFAULT now(3)
		; DECLARE v_CurrentDtm		  datetime(3)			DEFAULT now(3)
		; DECLARE v_PreviousDtm		  datetime(3)			DEFAULT now(3)
		; DECLARE v_DbName			  varchar(50)		DEFAULT DATABASE()
		; DECLARE v_CurrentUser		  varchar(50)		DEFAULT CURRENT_USER
		; DECLARE v_ProcessType		  varchar(10)		DEFAULT 'Proc'
		; DECLARE v_StepName			  varchar(256)		DEFAULT 'Start'
		; DECLARE v_StepOperation		  varchar(50)		DEFAULT 'N/A' 
		; DECLARE v_MessageType		  varchar(20)		DEFAULT 'Info' -- SQLINES DEMO *** Info, Warn
		; DECLARE v_StepDesc			  varchar(2048)	DEFAULT 'Procedure started' 
		; DECLARE v_StepStatus		  varchar(10)		DEFAULT 'Success'
		; DECLARE v_StepNumber		  varchar(10)		DEFAULT 0
		; DECLARE v_Duration			  varchar(10)		DEFAULT 0
		; DECLARE v_JSONSnippet		  longtext		DEFAULT NULL
		; DECLARE v_ContactId			  int				DEFAULT -1
		; DECLARE v_CreateDate		  datetime(3)			DEFAULT now(3);

call `audit`.usp_InsertStepLog(v_MessageType		,v_CurrentDtm		,v_PreviousDtm	,v_StepNumber		,v_StepOperation		,v_JSONSnippet		,v_ErrNum
		,v_ParametersPassedChar					,v_ErrMsg 	,v_ParentStepLogId	,v_ProcName			,v_ProcessType		,v_StepName
		,v_StepDesc 	,v_StepStatus		,v_DbName		,v_Rows				,v_pETLExecutionId	,v_pPathId			,v_ParentStepLogId 	
		,v_pVerbose);

--  SQLINES DEMO *** -----------------------------------------------------------
--  I... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

SET	 v_ParametersPassedChar	= 
      CONCAT('***** Parameters Passed to exec ctl.usp_insertnewcontact' , v_CRLF ,
      '     @pCompanyName = ''' , ifnull(p_pCompanyName ,'NULL') , '''' , v_CRLF , 
	  '     @pContactName = ''' , ifnull(p_pContactName ,'NULL') , '''' , v_CRLF , 
      '    ,@pTier = ''' , ifnull(p_pTier ,'NULL') , '''' , v_CRLF , 
      '    ,@pEmail = ''' , ifnull(p_pEmail ,'NULL') , '''' , v_CRLF , 
      '    ,@pPhone = ''' , ifnull(p_pPhone ,'NULL') , '''' , v_CRLF , 
	  '    ,@pSupportURL = ''' , ifnull(p_pSupportURL ,'NULL') , '''' , v_CRLF , 
      '    ,@pAddress01 = ''' , ifnull(p_pAddress01 ,'NULL') , '''' , v_CRLF , 
      '    ,@pAddress02 = ''' , ifnull(p_pAddress02 ,'NULL') , '''' , v_CRLF , 
      '    ,@pCity = ''' , ifnull(p_pCity ,'NULL') , '''' , v_CRLF , 
      '    ,@pState = ''' , ifnull(p_pState ,'NULL') , '''' , v_CRLF , 
      '    ,@pZipCode = ''' , ifnull(p_pZipCode ,'NULL') , '''' , v_CRLF , 
      '    ,@pETLExecutionId = ' , ifnull(cast(p_pETLExecutionId as char(100)),'NULL') , v_CRLF , 
      '    ,@pPathId = ' , ifnull(cast(p_pPathId as char(100)),'NULL') , v_CRLF , 
      '    ,@pVerbose = ' , ifnull(cast(p_pVerbose as char(100)),'NULL') , v_CRLF , 
      '***** End of Parameters' , v_CRLF); 

if p_pVerbose					= 1
	then 
		/* print v_ParametersPassedChar */
        select 1 from dual;
	end if;

--  SQLINES DEMO *** -----------------------------------------------------------
--  M... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------



	--  SQLINES DEMO *** -----------------------------------------------------------
	-- SQLINES DEMO *** tart
	--  SQLINES DEMO *** -----------------------------------------------------------
	set	 v_StepName			= 'Insert into contact values'
			,v_StepNumber		= v_StepNumber + 1
			,v_StepOperation		= 'Insert'
			,v_StepDesc			= 'Insert to ctl.contact';
	--  SQLINES DEMO *** -----------------------------------------------------------

	-- SQLINES LICENSE FOR EVALUATION USE ONLY
	INSERT INTO ctl.Contact(
		 CompanyName
		,ContactName
		,Tier		
		,Email	
		,Phone	
		,SupportURL
		,Address01
		,Address02
		,City		
		,`State`
		,ZipCode
		,CreatedBy
		,CreatedDtm
		,ModifiedBy
		,ModifiedDtm
		)
	VALUES(
		 p_pCompanyName		
		,p_pContactName
		,p_pTier		
		,p_pEmail	
		,p_pPhone	
		,p_pSupportURL
		,p_pAddress01
		,p_pAddress02
		,p_pCity		
		,p_pState	
		,p_pZipCode	
		,v_CurrentUser
		,v_CurrentDtm
		,v_CurrentUser
		,v_CurrentDtm
	);

	--  SQLINES DEMO *** -----------------------------------------------------------
	--  S... SQLINES DEMO ***
	--  SQLINES DEMO *** -----------------------------------------------------------
	set	 v_PreviousDtm		= v_CurrentDtm
			,v_Rows				= FOUND_ROWS(); 
	set	 v_CurrentDtm		= now(3);

	call `audit`.usp_InsertStepLog(v_MessageType		,v_CurrentDtm		,v_PreviousDtm	,v_StepNumber		,v_StepOperation		
			,v_JSONSnippet		,v_ErrNum			,v_ParametersPassedChar					
			,v_ErrMsg 	,v_ParentStepLogId		,v_ProcName			,v_ProcessType		,v_StepName
			,v_StepDesc 	,v_StepStatus		,v_DbName		,v_Rows				
			,v_pETLExecutionId	,v_pPathId			,v_PrevStepLog
			,v_pVerbose);

end;


--  SQLINES DEMO *** -----------------------------------------------------------
--  P... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

set 	 v_PreviousDtm			= v_CurrentDtm;
set	 v_CurrentDtm			= now(3)
		,v_StepNumber			= v_StepNumber + 1
		,v_StepName				= 'End'
		,v_StepDesc				= 'Procedure completed'
		,v_Rows					= 0
		,v_StepOperation			= 'N/A';

-- SQLINES DEMO *** tartDtm so the total duration for the procedure is added.
-- SQLINES DEMO *** (if you want total duration) 
-- SQLINES DEMO *** you want 0)
call `audit`.usp_InsertStepLog(v_MessageType		,v_CurrentDtm	,v_ProcessStartDtm	,v_StepNumber		,v_StepOperation		,v_JSONSnippet		,v_ErrNum
		,v_ParametersPassedChar					,v_ErrMsg 	,v_ParentStepLogId	,v_ProcName			,v_ProcessType		,v_StepName
		,v_StepDesc 	,v_StepStatus		,v_DbName		,v_Rows				,v_pETLExecutionId	,v_pPathId			,v_PrevStepLog
		,v_pVerbose);
END;
//


