CREATE VIEW [pg].[vw_PostingGroupProcessingStatus] AS
	

select 
		 pgp.PostingGroupProcessingId
		,pgp.PostingGroupBatchId
		,pg.PostingGroupId
		,pgp.PGPBatchSeq					PGPBatchSeq
		,pg.PostingGroupCode
		,rs.StatusCode						PostingGroupStatusCode
		,pgp.IssueId
		,pgp.DistributionId
		,pgp.DateId
		,pgp.StartTime
		,pgp.EndTime
		,pgp.DurationChar
		,pgp.DurationSec
		,pgp.CreatedDtm
		,pgp.ModifiedDtm
from	 pg.PostingGroupProcessing		  pgp
join	 pg.RefStatus					  rs
on		 pgp.PostingGroupStatusId		= rs.StatusId
join	 pg.PostingGroup				  pg
on		 pgp.PostingGroupId				= pg.PostingGroupId

GO