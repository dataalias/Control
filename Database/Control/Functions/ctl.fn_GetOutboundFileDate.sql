CREATE FUNCTION [ctl].[fn_GetOutboundFileDate] (
		 @pPackageExecutionDtm		datetime
		,@pETLExecutionId			int				= -1
		,@pPathId					int				= -1
		,@pVerbose					bit				= 0)

/*****************************************************************************
File:		fn_GetOutboundFileDate.sql
Name:		fn_GetOutboundFileDate
Purpose:    Gives out the date needed for file creation in format - YYYYMMDDHHMMSS
			This will be appended to the file name

select OutboundFileDate from pg.fn_GetOutboundFileDate(GETDATE(),-1,-1,0)

Parameters:	

Called by: ETL
Calls:          

Errors:		

Author:		ochowkwale
Date:		20190307

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20190307	ochowkwale		Initial iteration.

******************************************************************************/

RETURNS @ReturnTable TABLE (OutboundFileDate BIGINT) AS

BEGIN
	INSERT INTO @ReturnTable
	SELECT replace(replace(replace(convert(VARCHAR(19), @pPackageExecutionDtm, 126), '-', ''), 'T', ''), ':', '') OutboundFileDate
	RETURN
END
