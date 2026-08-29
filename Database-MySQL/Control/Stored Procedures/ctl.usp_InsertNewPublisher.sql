-- drop procedure `ctl`.`usp_InsertNewPublisher`

DELIMITER \\ 
CREATE PROCEDURE `ctl`.`usp_InsertNewPublisher` (
		 p_pPublisherCode			VARCHAR(10)
		,p_pContactName				VARCHAR(30)
		,p_pPublisherName			VARCHAR(50)
		,p_pPublisherDesc			VARCHAR(1000)	/* = 'Unknown' */
		,p_pInterfaceCode			VARCHAR(20)
		,p_pCreatedBy				VARCHAR(50)		/* = 'Unknown' */
		,p_pSiteURL					VARCHAR(256)	/* = NULL */  
		,p_pSiteUser				VARCHAR(256)	/* = NULL */ 
		,p_pSitePassword			VARCHAR(256)    /* = NULL */           
		,p_pSiteHostKeyFingerprint	VARCHAR(256)	/* = NULL */             
		,p_pSitePort				VARCHAR(10)		/* = NULL */
		,p_pSiteProtocol			VARCHAR(100)	/* = NULL */
		,p_pPrivateKeyPassPhrase	VARCHAR(256)	/* = NULL */ 
		,p_pPrivateKeyFile			VARCHAR(256)	/* = NULL */ 
		,p_pETLExecutionId			INT				/* = -1 */
		,p_pPathId					INT				/* = -1 */
		,p_pVerbose					TINYINT			/* = 0 */)
        
/***********************************************************************
File:		usp_InsertNewPublisher.sql
Name:		usp_InsertNewPublisher
Purpose:	


	declare	 @StartDtm				datetime		= getdate()
			,@EndDtm				datetime		= getdate() + .013
			,@ErrMsgFormatted		nvarchar(max)
			,@ErrorJSON				nvarchar(max)
			,@duration				int				= 0
			,@JsonMessage			varchar(1000)	= '{"animal":"moose"}'

	exec [ctl].[usp_InsertNewPublisher] 
			 @pMessageType				= 'INFO' -- 'ErrCust'
			,@pStartDtm					= @StartDtm
			,@pEndDtm					= @EndDtm
			,@pStepNumber				= 5
			,@pOperation				= 'Insert'
			,@pStepDescription			= 'Neat Description'
			,@pJSONSnippet				= '{"hi":"bye"}'
			,@pErrNum					= 0
			,@pErrMsg					= 'I failed as a person'
			,@pParametersPassedChar 	= 'Parameters ...'
			,@pStepLogId				= -1 
			,@pJSONMsg					= @JsonMessage	output
			,@pFormatErrorMsg			= @ErrMsgFormatted	output
			,@pDuration					= @duration	output	 
			,@pETLExecutionId			= -1
			,@pPathId					= -1
			,@pVerbose					= 0

	print '@ErrMsgFormatted: ' + isnull(@ErrMsgFormatted,'null')
	print '@ErrorJSON:       ' + isnull(@ErrorJSON,'null')
	print '@JsonMessage:     ' + isnull(@JsonMessage,'null')
	print '@duration:        ' + isnull(cast(@duration as varchar(100)),'null')

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		9/7/2017

******************************************************************************/
BEGIN


-- ---------------------------------------------------------------------------
--  Initializations
-- ---------------------------------------------------------------------------

DECLARE v_Rows					int					DEFAULT 0;
DECLARE v_ErrNum				int					DEFAULT -1;
DECLARE v_ErrMsg				longtext			DEFAULT 'N/A';
		 DECLARE v_ParametersPassedChar	varchar(1000)		DEFAULT 'N/A'
		 ;DECLARE v_CRLF					varchar(10)			DEFAULT cast(char(13) as char) + cast(char(10) as char)
		 ;DECLARE v_ProcName				varchar(256)		DEFAULT 'usp_InsertNewPublisher'
		 ;DECLARE v_ParentStepLogId		int					DEFAULT -1
		 ;DECLARE v_PrevStepLog			int					DEFAULT -2
		 ;DECLARE v_ProcessStartDtm		datetime(3)			DEFAULT now(3)
		 ;DECLARE v_CurrentDtm			datetime(3)			DEFAULT now(3)
		 ;DECLARE v_PreviousDtm			datetime(3)			DEFAULT now(3)
		 ;DECLARE v_DbName				varchar(50)			DEFAULT DATABASE()
		 ;DECLARE v_CurrentUser			varchar(50)			DEFAULT CURRENT_USER
		 ;DECLARE v_SchemaName			varchar(256)		DEFAULT 'ctl'
		 ;DECLARE v_PassphraseTableName	varchar(256)		DEFAULT 'Publisher'
		 ;DECLARE v_Passphrase			varchar(100)		DEFAULT ''
		 ;DECLARE v_ProcessType			varchar(10)			DEFAULT 'Proc'
		 ;DECLARE v_StepName				varchar(256)		DEFAULT 'Start'
		 ;DECLARE v_StepOperation			varchar(50)			DEFAULT 'N/A' 
		 ;DECLARE v_MessageType			varchar(20)			DEFAULT 'Info' -- SQLINES DEMO *** Info, Warn
		 ;DECLARE v_StepDesc				varchar(2048)		DEFAULT 'Procedure started' 
		 ;DECLARE v_StepStatus			varchar(10)			DEFAULT 'Success'
		 ;DECLARE v_StepNumber			varchar(10)			DEFAULT 0
		 ;DECLARE v_Duration				varchar(10)			DEFAULT 0
		 ;DECLARE v_JSONSnippet			longtext		DEFAULT NULL
		 ;DECLARE v_ContactId				int					DEFAULT -1
		 ;DECLARE v_CreateDate			datetime(3)			DEFAULT now(3);

call `audit`.usp_InsertStepLog(v_MessageType		,v_CurrentDtm		,v_PreviousDtm	,v_StepNumber		,v_StepOperation		,v_JSONSnippet		,v_ErrNum
		,v_ParametersPassedChar					,v_ErrMsg 	,v_ParentStepLogId	,v_ProcName			,v_ProcessType		,v_StepName
		,v_StepDesc 	,v_StepStatus		,v_DbName		,v_Rows				,v_pETLExecutionId	,v_pPathId			,v_ParentStepLogId 	
		,v_pVerbose);

--  SQLINES DEMO *** -----------------------------------------------------------
--  I... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

SET	 v_ParametersPassedChar	= 
			CONCAT('EXEC BPI_DW_Stage.ctl.usp_InsertNewPublisher' , v_CRLF ,
			'    ,@p_PUBLISHER_CODE		= ' , ifnull(cast(p_pPublisherCode as char(100)),'NULL') , v_CRLF ,
			'    ,@p_CONTACT_NAME		= ' , ifnull(cast(p_pContactName as char(100)),'NULL') , v_CRLF ,
			'    ,@pPublisherName		= ' , ifnull(cast(p_pPublisherName as char(100)),'NULL') , v_CRLF ,
			'    ,@pPublisherDesc		= ' , ifnull(cast(p_pPublisherDesc as char(100)),'NULL') , v_CRLF ,
			'    ,@pInterfaceCode 		= ' , ifnull(cast(p_pInterfaceCode  as char(100)),'NULL') , v_CRLF ,
			'    ,@p_CREATED_BY		    = ' , ifnull(cast(p_pCreatedBy as char(100)),'NULL') , v_CRLF ,
			'    ,@pSiteURL			    = ' , ifnull(cast(p_pSiteURL as char(100)),'NULL') , v_CRLF ,
			'    ,@pSiteUser		    = ' , ifnull(cast(p_pSiteUser as char(100)),'NULL') , v_CRLF ,
			'    ,@pSitePassword		= ' , ifnull(cast(p_pSitePassword as char(100)),'NULL') , v_CRLF ,
			'    ,@pSiteKey				= ' , ifnull(cast(p_pSiteHostKeyFingerprint as char(100)),'NULL') , v_CRLF ,
			'    ,@pSitePort          	= ' , ifnull(cast(p_pSitePort as char(100)),'NULL') , v_CRLF ,
			'    ,@pSiteProtocol		= ' , ifnull(cast(p_pSiteProtocol as char(100)),'NULL') , v_CRLF ,
			'     @pETLExecutionId		= ' , ifnull(cast(p_pETLExecutionId as char(100)),'NULL') , v_CRLF , 
			'    ,@pPathId				= ' , ifnull(cast(p_pPathId as char(100)),'NULL') , v_CRLF , 
			'    ,@pVerbose				= ' , ifnull(cast(p_pVerbose as char(100)),'NULL'));

if p_pVerbose					= 1
	then 
		/* print v_ParametersPassedChar */
        set @pVerbose = 2;
	end if;

--  -----------------------------------------------------------
--  Main
--  -----------------------------------------------------------


	--  SQLINES DEMO *** -----------------------------------------------------------
	-- SQLINES DEMO *** tart
	--  SQLINES DEMO *** -----------------------------------------------------------
	set	 v_StepName			= 'Insert into publisher values'
			,v_StepNumber		= v_StepNumber + 1
			,v_StepOperation		= 'Insert'
			,v_StepDesc			= 'Insert to ctl.publisher';
	--  SQLINES DEMO *** -----------------------------------------------------------

	SET	v_Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.`Passphrase`
		WHERE	 DatabaseName	= v_DbName
		AND		 SchemaName		= v_SchemaName
		AND		 TableName		= v_PassphraseTableName
	);

    IF(NOT EXISTS (SELECT v_Passphrase ) OR v_Passphrase IS NULL OR v_Passphrase = '') -- SQLINES DEMO *** tion>
	   
	   THEN

		  SET v_ErrNum = 50001,
			    v_ErrMsg = CONCAT('Error Number: ',CAST(v_ErrNum AS CHAR(10))+v_CRLF,
			    'Custom Error: Passphrase for the Publisher table does not exist in the BPI_DW_STAGE.ctl.Passshrase table.',v_CRLF,
			    'Phrase must be created for this table.',v_CRLF,
			    ifnull(v_ParametersPassedChar, 'Parmeter input resulted in NULL or non-existing output'));

		  select v_ErrMsg from dual;
	   END IF;

	SELECT ContactId INTO v_ContactId
	FROM	 ctl.Contact
	WHERE	 `ContactName`		= p_pContactName;

    IF(NOT EXISTS(SELECT v_ContactId) OR v_ContactId IS NULL) -- SQLINES DEMO *** tion>

	  THEN

		  SET v_ErrNum = 50001,
			    v_ErrMsg = CONCAT('Error Number: ',CAST(v_ErrNum AS CHAR(10))+v_CRLF,
			    'Custom Error: Contact ID does not exist in the contact table.',v_CRLF,
			    'Contact must be created for this table.',v_CRLF,
			    ifnull(v_ParametersPassedChar, 'Parmeter input resulted in NULL or non-existing output'));

		  select v_ErrMsg from dual;
	   END IF;

-- SQLINES DEMO *** vides a User name us it...
	If  p_pCreatedBy <> 'Unknown' Then
		set v_CurrentUser = p_pCreatedBy;
	End if;
-- SQLINES DEMO *** ct @CurrentUser	= CURRENT_USER
	


 -- SQLINES LICENSE FOR EVALUATION USE ONLY
 INSERT INTO ctl.Publisher
    (`ContactId`
	,`PublisherCode`
	,`PublisherName`
	,`PublisherDesc`
	,InterfaceCode
    /*
	`SiteURL`,
	`SiteUser`,
	`SitePassword`,
	`SiteHostKeyFingerprint`,
	`SitePort`,
	`SiteProtocol`
	,PrivateKeyPassPhrase
	,PrivateKeyFile
    */
	,CreatedDtm
	,CreatedBy
	,ModifiedDtm
	,ModifiedBy
    )
  VALUES
    (v_ContactId
	,p_pPublisherCode
	,p_pPublisherName
	,p_pPublisherDesc
	,p_pInterfaceCode
    /*
	,p_pSiteURL
	,p_pSiteUser
	,ENCRYPTBYPASSPHRASE(v_Passphrase, p_pSitePassword)
	,ENCRYPTBYPASSPHRASE(v_Passphrase, p_pSiteHostKeyFingerprint)   --  SQLINES DEMO *** or  
	,p_pSitePort
	,p_pSiteProtocol
	,ENCRYPTBYPASSPHRASE(v_Passphrase, p_pPrivateKeyPassPhrase)
	,ENCRYPTBYPASSPHRASE(v_Passphrase, p_pPrivateKeyFile) 
    */
	,v_CurrentDtm
	,v_CurrentUser
	,v_CurrentDtm
	,v_CurrentUser
    );

	--  SQLINES DEMO *** -----------------------------------------------------------
	--  S... SQLINES DEMO ***
	--  SQLINES DEMO *** -----------------------------------------------------------
	set	 v_PreviousDtm		= v_CurrentDtm
			,v_Rows			= ROW_COUNT() ;
	set	 v_CurrentDtm		= now(3);

	call `audit`.usp_InsertStepLog(v_MessageType		,v_CurrentDtm		,v_PreviousDtm	,v_StepNumber		,v_StepOperation		
			,v_JSONSnippet		,v_ErrNum			,v_ParametersPassedChar					
			,v_ErrMsg 	,v_ParentStepLogId		,v_ProcName			,v_ProcessType		,v_StepName
			,v_StepDesc 	,v_StepStatus		,v_DbName		,v_Rows				
			,v_pETLExecutionId	,v_pPathId			,v_PrevStepLog
			,v_pVerbose);


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
\\



/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170908	ffortunato		Getting Snippets. Adding Duration to steplog.

20170911	ffortunato		Consolidated formatting to reduce code. added 
							message type.

20170913	ffortunato		Errors cannot exceed 2048 characters
							Errors cannot have a % symbol in them w/o escaping 
							it first. (e.g. %% )

20171116	ffortunato		Adding Operation into one of the messages. 
							Updating test execution to work with ne parameters.
							Ignoring JSON parameter if its NULL, 'N/A' or ''
							Renaming snippet area from "Misc" to "Custom"

20180404	ffortunato		Missed a snippet area from "Misc" to "Custom" 

20180906	ffortunato		Cleaning up issues with Code analysis.
							@pErrNum varchar(10) --> int
							header / execute updates. better unit testing.
******************************************************************************/