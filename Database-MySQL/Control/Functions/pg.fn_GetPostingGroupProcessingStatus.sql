CREATE FUNCTION [pg].[fn_GetPostingGroupProcessingStatus] (
     @pPGId                         int
    ,@pPGPBId                       int
	,@pPGPSeq						int)
RETURNS varchar(20)
AS

/*****************************************************************************
file:           fn_GetPostingGroupProcessingStatus.sql
name:           fn_GetPostingGroupProcessingStatus
purpose:        Gets the status of a given posting group.

exec ctl.fnGetPostingGroupProcessingStatus 8,2,'PC'

parameters:
    PC    Posting Group Complete
    PF    Posting Group Failed
    PP    Posting Group Processing
    PQ    Posting Group Queued


called by:    
calls:         N/A  

author:         ffortunato
date:           20161018


*******************************************************************************
      change history
*******************************************************************************
date      author         description
--------  -------------  ------------------------------------------------------
20161205  ffortunato     initial iteration.
20181004  ffortunato     Need to add the sequence as a parameter as well.
******************************************************************************/

-------------------------------------------------------------------------------
--  declarations
-------------------------------------------------------------------------------

BEGIN

-------------------------------------------------------------------------------
--  declarations
-------------------------------------------------------------------------------

declare 
		 @StatusCode			varchar(20)
		,@pPostingGroupBatchId	int
		,@PostingGroupId		int

select	@StatusCode				= RS.StatusCode
from	pg.PostingGroupProcessing  PGP
join	pg.RefStatus               RS
on		PGP.PostingGroupStatusId= RS.StatusId
where	PGP.PostingGroupBatchId	= @pPGPBId
and		PGP.PostingGroupId		= @pPGId
and		PGP.PGPBatchSeq			= @pPGPSeq


RETURN @StatusCode

END
GO


