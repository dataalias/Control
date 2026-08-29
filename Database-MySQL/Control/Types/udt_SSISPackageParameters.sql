/*****************************************************************************
file:           udt_SSISPackageParameters.sql
name:           udt_SSISPackageParameters
purpose:        The parameters needed for kicking off a PostingGroup SSIS 
				package.
				

called by:		
calls:			N/A  

author:			ffortunato
date:			20181206


******************************************************************************/

CREATE TYPE [pg].udt_SSISPackageParameters  AS TABLE  (
			 ParameterId		int			identity(1,1)
			,ObjectType			int			not null
			,ParameterName		nvarchar(128)	not null
			,ParameterValue		sql_variant	not null
)


/******************************************************************************
      change history
*******************************************************************************
date      author         description
--------  -------------  ------------------------------------------------------
20181206  ffortunato     initial iteration.

******************************************************************************/
