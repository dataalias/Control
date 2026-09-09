CREATE VIEW [pg].[vw_PostingGroupDependencyDetails]
AS 
select	 pgd.PostingGroupDependencyId
		,pgd.DependencyCode
		,pgd.DependencyName
		,pgC.PostingGroupId			  ChildPostingGroupId
		,pgC.PostingGroupCode		  ChildPostingGroupCode
		,pgC.PostingGroupName		  ChildPostingGroupName
		,pgP.PostingGroupId			  ParentPostingGroupId
		,pgP.PostingGroupCode		  ParentPostingGroupCode
		,pgP.PostingGroupName		  ParentPostingGroupName
from	 pg.PostingGroupDependency	  pgd
join	 pg.PostingGroup			  pgC
on		 pgC.PostingGroupId			= pgd.ChildId
join	 pg.PostingGroup			  pgP
on		 pgP.PostingGroupId			= pgd.ParentId
GO