CREATE PROCEDURE [ctl].[usp_UpdateDistributionStatus] (	
	 @pIssueId					INTEGER
	,@pSubscriptionCode			VARCHAR(100)
	,@pStatus					VARCHAR(10))
AS 
/*****************************************************************************
 File:           UpdateDistributionStatus.sql
 Name:           usp_UpdateDistributionStatus
 Purpose:        Updates the distribution status when a process initiates
                 completes or fails.

 exec Control.ctl.usp_UpdateDistributionStatus
 	 @pIssueId					= 1
	,@pSubscriptionCode			= 'TSTPUBR01-TSTSUBR01-TSTPUBN01-ACCT'
	,@pStatus					= 'DC'

 Parameters:     


 Called by:      Application
 Calls:          

 Author:         ffortunato
 Date:           20091020
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
 Date      Author         Description
 --------  -------------  -----------------------------------------------------
 20170117  ffortunato     fixing up the error handling in this procedure.
 20180801  ffortunato     new changes for a new year.
******************************************************************************/
SET NOCOUNT ON    SET QUOTED_IDENTIFIER OFF     SET ANSI_NULLS OFF


declare	 @Rows                     integer
        ,@Err                      integer
		,@ErrMsg                   varchar(8000)
		,@PassedParameters         varchar(1000)
        ,@SubscriptionId           integer
        ,@ModifiedDate             datetime
        ,@ModifiedBy               varchar(30)
        ,@StatusId                 integer
        ,@StatusType               varchar(30)

declare  @IssueComplete            table (
		 DistributionId			   bigint
		,IssueId                   int
		,DistStatusCode      	   varchar(20)
		,TotalCount                int
		,CompleteCount             int)


-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @Rows					= -1
        ,@Err                   = -1
		,@ErrMsg				= 'sproc ' + OBJECT_NAME(@@PROCID) + 
		                           ' failed.' + Char(13)
		,@SubscriptionId		= -1
		,@ModifiedDate			= GETDATE()
		,@ModifiedBy			= SYSTEM_USER
		,@StatusId				= -1
		,@StatusType			= 'Distribution'
		,@PassedParameters		= char(13) + '    Parameters Passed: ' +
			'@pIssueId = '		+ cast(@pIssueId as varchar(100))  + char(13) +
			'@@pSubscriptionCode = '	 + @pSubscriptionCode + char(13) +
			'@pStatus = '		+ @pStatus + char(13) 

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------
begin try

select	 @SubscriptionId		= ISNULL(SubscriptionId ,-1)
FROM	 ctl.Subscription		  sn
WHERE	 sn.SubscriptionCode	= @pSubscriptionCode

select   @StatusId				= StatusId
from     ctl.RefStatus			  rst
where    StatusCode				= @pStatus
and      StatusType				= @StatusType

if       @SubscriptionId		= -1 
      or @StatusId				= -1
	begin
		select @ErrMsg			= 'Unable to find associated subscription id or status id' + 
									   char(13) + @PassedParameters
		raiserror(@ErrMsg,-1,-1)
	end

end try

begin catch

	select @ErrMsg	= @ErrMsg + ERROR_MESSAGE() + char(13) + @PassedParameters
	raiserror (@ErrMsg,-1,-1)

end catch

/*
-- debug
print @pprocessname
print cast(@subscriptionid as varchar(30))
print 'Status Id::  ' +  cast(@statusid as varchar(30))
*/

begin try

update   dist
set      StatusId                = @StatusId
        ,ModifiedDtm             = @ModifiedDate
        ,ModifiedBy              = @ModifiedBy
from     ctl.[Distribution]         dist
where    SubscriptionId          = @SubscriptionId
and      IssueId                 = @pIssueId

-------------------------------------------------------------------------------
-- If the distribution is complete see. If we can set the Issue to 
-- complete.
-------------------------------------------------------------------------------

insert   into @IssueComplete (DistributionId, IssueId, DistStatusCode)
select   DistributionId
		,D.IssueId
		,StatusCode
from    ctl.[Distribution]         D
join    ctl.Issue                  I
on      D.IssueId				 = I.IssueConsumedDate
join    ctl.RefStatus			   RS
on      D.StatusId               = RS.StatusId
where   I.IssueId                = @pIssueId

--TODO: Update the issue!!

end try-- main

begin catch
	select @ErrMsg	= @ErrMsg + ERROR_MESSAGE() + char(13) + @PassedParameters
	raiserror (@ErrMsg,-1,-1)
end catch

-------------------------------------------------------------------------------
-- End
-------------------------------------------------------------------------------
