
-- Now lets see if other things should run.
/*
     @pPGId                         Int
    ,@pPGPBatchId                   int
*/
exec ctl.ExecutePostingGroupProcessing 1,1


declare @pPGId int = 7

-- get all the parent posting groups
Select RS.StatusCode, PGP.PGId, PGD.ParentId, PGD.ChildId
From   ctl.PostingGroupProcessing   PGP
join   ctl.RefStatus                RS 
on      RS.StatusId               = PGP.StatusId
join   ctl.PostingGroupDependencies PGD
on     PGP.PGId = PGD.ChildId
Where   RS.StatusCode             = 'PC'  -- Child's status is complete
and    PGP.PGId                   = @pPGId -- Child's posting group.


-- so now this is my working set. 
select @pPGId = 9

select RS.StatusCode,PGD.ParentId,PGD.ChildId
,RS.StatusCode, PGD.*, PGP.* 
from  ctl.PostingGroupDependencies PGD
join  ctl.PostingGroupProcessing   PGP
on    PGD.ChildId = PGP.PGId
join  ctl.RefStatus                RS 
on     RS.StatusId               = PGP.StatusId
where PGD.ParentId in (9,12)--= @pPGId
order by PGD.ParentId



select DISTINCT PGD.ParentId
,count( 1 ) over (partition by PGD.ParentId)
,sum( case when RS.StatusCode = 'PC' then 1 else 0 end
      ) over (partition by PGD.ParentId)
--RS.StatusCode,PGD.ParentId,PGD.ChildId
--,RS.StatusCode, PGD.*, PGP.* 
from  ctl.PostingGroupDependencies PGD
join  ctl.PostingGroupProcessing   PGP
on    PGD.ChildId = PGP.PGId
join  ctl.RefStatus                RS 
on     RS.StatusId               = PGP.StatusId
where PGD.ParentId in (9,12)--= @pPGId
order by PGD.ParentId





Select *
From   ctl.PostingGroupProcessing   PGP
join   ctl.RefStatus                RS 
on      RS.StatusId               = PGP.StatusId
join   ctl.PostingGroupDependencies PGD
on     PGP.PGId = PGD.ChildId
join   ctl.PostingGroupProcessing   PGP2
on     PGD.ParentId = PGP2.PGId
join   ctl.RefStatus                RS2 
on      RS.StatusId               = PGP2.StatusId
Where   RS.StatusCode             = 'PC'
and    RS2.StatusCode             = 'PI'