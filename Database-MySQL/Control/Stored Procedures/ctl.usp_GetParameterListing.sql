-- SQLINES FOR EVALUATION USE ONLY (14 DAYS)
delimiter //

create procedure `ctl`.`usp_GetParameterListing`(
		 p_pObjectName varchar(255)
		,out p_pParameterString longtext
		,p_pVerbose tinyint /* = 0 */
)

sp_lbl:

/* SQLINES DEMO *** **********************************************************
 File:           usp_GetParameterListing.sql
 Name:           usp_GetParameterListing
 Purpose:        Gets all parameters passed and their values.

 declare @pParameterString nvarchar(4000)
	exec ctl.[usp_GetParameterListing]  [usp_insertnewcontact] ,@pParameterString output, 1
	print @pParameterString

 Parameters:    



 Called by:      Application
 Calls:          

 Author:         ffortunato
 Date:           20161114
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
 Date      Author         Description
 --------	-------------	---------------------------------------------------
 20161114	ffortunato		Original draft
 20170322	ffortunato		Adding special processing for datetime fields.
							Identifying output variables.
20201119	ffortunato		cleaning up.

******************************************************************************/
begin

drop temporary table if exists tmp_ParameterList;
create temporary table	tmp_ParameterList 
(
	 ObjectType						nvarchar(60)
	,ParameterName					nvarchar(128)
	,ParameterId					int					not null default -1
	,ParameterDataType				nvarchar(128)
	,IsOutput						tinyint
	,SchemaName						nvarchar(200)
);

declare	 v_ParameterString			longtext
		; declare v_Max						int
		; declare v_Cnt						int
		; declare v_parameterpassedchar		varchar(4000)
		; declare v_LiteralCRLF				varchar(20)
		; declare v_CRLF						nvarchar(20)
		; declare v_CurrentParameterName		varchar(255)
		; declare v_CurrentParameterType		varchar(255)
		; declare v_CurrentParameterOutput	int 
		; declare v_CurrentParameterSchema    varchar(200)
		; declare v_Tab						varchar(5)	default '    ' -- ch... SQLINES DEMO ***
		; declare v_2Tab						varchar(8)	default '        ' -- ch... SQLINES DEMO ***
		; declare v_3Tab						varchar(12)	default '            ' -- SQLINES DEMO ***  + char(9)
		; declare v_ParmLength				int default -1
		; declare v_TabLenght					int default 4
		; declare v_MaxParmLength				int default -1
		; declare v_TargetTabLength			int default -1
		; declare v_TabsToAddCount			int default -1
		; declare v_TabsToAddChar				varchar(20);

set	v_ParameterString		= 'No Parameters Passed to Procedure.'
		,v_Max = -1
		,v_Cnt = -1
		,v_CRLF =  cast(char(13) as char) + cast(char(10) as char) -- CR... SQLINES DEMO ***
		,v_LiteralCRLF = 'char(13) + char(10)'
		,v_parameterpassedchar  = CONCAT('***** Parameters Passed to usp_GetParameterListing' , v_CRLF ,
								'@pObjectName = ''' , ifnull(p_pObjectName ,'NULL') , '''' , v_CRLF , 
								'@pParameterString = ''' , ifnull(p_pParameterString ,'NULL') , '''' , v_CRLF , 
								'@pVerbose = ' , ifnull(cast(p_pVerbose as char(100)),'NULL') , v_CRLF , 
								'***** End of Parameters' , v_CRLF);

/* print v_parameterpassedchar */

insert into tmp_ParameterList (
		 ObjectType
		,ParameterName
		,ParameterId
		,ParameterDataType
		,IsOutput
		,SchemaName)
SELECT 	SO.type_desc			ObjectType,
		P.name					ParameterName,
		P.parameter_id			ParameterID,
		TYPE_NAME(P.user_type_id) ParameterDataType,
		is_output,
		S.name					SchemaName
FROM	sys.objects				  SO
JOIN	sys.parameters			  P 
ON		SO.object_id			= P.object_id
join    sys.schemas				  S
on		SO.schema_id			= S.schema_id
WHERE	SO.object_id IN (
	SELECT object_id 
	FROM sys.objects
	WHERE type IN ('P','FN'))
and		SO.name					= p_pObjectName
ORDER BY P.parameter_id;

-- SQLINES DEMO *** arameterList

if exists (select 1 from tmp_ParameterList
limit 1)
	then
		set	 v_Cnt			= 1
				,v_Max			= (select max(ParameterId) from tmp_ParameterList);

		set v_CurrentParameterSchema = (select SchemaName
								from tmp_ParameterList
								where ParameterId = v_Cnt);	


		set v_ParameterString	= CONCAT(v_CRLF , v_3Tab , '''***** Parameters Passed to exec ', v_CurrentParameterSchema ,'.' , p_pObjectName , ''' + @CRLF +' , v_CRLF);

		select max(char_length(rtrim(ParameterName))) + 2 into v_MaxParmLength from tmp_ParameterList;
		set v_TargetTabLength	= (v_MaxParmLength / v_TabLenght) + 1;

/* SQLINES DEMO *** gth % @TabLenght = 0 begin
			select @TargetTabLength = @TargetTabLength + 1 --falls on a tab level so add one.
		end
*/
		
		/* print  CONCAT('@MaxParmLength : ' , cast(v_MaxParmLength as char(100))) */
		/* print  CONCAT('@TargetTabLength : ' , cast(v_TargetTabLength as char(100))) */
	end if;


	

while  v_Cnt <= v_Max and v_Cnt <> -1
	do
		--  SQLINES DEMO ***  @ParameterString = ' char(13) + '

		set v_CurrentParameterName = (select ParameterName
								from tmp_ParameterList
								where ParameterId = v_Cnt);
		set v_CurrentParameterType = (select ParameterDataType
								from tmp_ParameterList
								where ParameterId = v_Cnt);
		set v_CurrentParameterOutput = (select IsOutput
								from tmp_ParameterList
								where ParameterId = v_Cnt);
	
/* SQLINES DEMO *** gth = 0, @TabsToAddCount = 0 , @TabsToAddChar =''

		select @ParmLength		= len(@CurrentParameterName)
-- HERE	
		
		select @TabsToAddCount	= (@TargetTabLength - (@ParmLength / @TabLenght) )

		if @ParmLength % @TabLenght = 0 begin
			select @TabsToAddCount = @TabsToAddCount + 1 --falls on a tab level so add one.
			--print '% = 0'
		end
		
		select @TabsToAddChar = case @TabsToAddCount 
								when 1 then @Tab
								when 2 then @2Tab
								when 3 then @3Tab
								else @3Tab end

		print   @CurrentParameterName
		+  '	(@ParmLength / @TabLenght)' + cast(@ParmLength / @TabLenght as varchar(100))
		+  '	@ParmLength : ' + cast(@ParmLength as varchar(100))
		+  '	@TabsToAddCount : ' + cast(@TabsToAddCount as varchar(100))
		+  '	@TabsToAddChar : ' + cast(@TabsToAddChar as varchar(100))
*/
		if v_Cnt = 1 then 
			set v_ParameterString	= CONCAT(v_ParameterString , v_3Tab , '''' , v_Tab , ' ' , v_CurrentParameterName); -- + @... SQLINES DEMO ***
		else 
			set v_ParameterString	= CONCAT(v_ParameterString , v_3Tab , '''' , v_Tab , ',' , v_CurrentParameterName);
		end if; -- + @... SQLINES DEMO ***
		
		if v_CurrentParameterOutput = 0 then

			if v_CurrentParameterType in ('varchar','char','nvarchar') then 
				set v_ParameterString	= CONCAT(v_ParameterString , ' = ' , ''''''' + isnull(');
				set v_ParameterString	= CONCAT(v_ParameterString , v_CurrentParameterName);
				set v_ParameterString	= CONCAT(v_ParameterString , ' ,''NULL'') + '''''''' + @CRLF + ' , v_CRLF);
		 elseif v_CurrentParameterType in ('int','bit','bigint') then 
				set v_ParameterString	= CONCAT(v_ParameterString , ' = ' , ''' + isnull(cast(');
				set v_ParameterString	= CONCAT(v_ParameterString , v_CurrentParameterName);
				set v_ParameterString	= CONCAT(v_ParameterString , ' as varchar(100)),''NULL'') + @CRLF + ' , v_CRLF);
		 elseif v_CurrentParameterType in ('datetime') then 
				set v_ParameterString	= CONCAT(v_ParameterString , ' = ' , ''''''' + isnull(convert(varchar(100),');
				set v_ParameterString	= CONCAT(v_ParameterString , v_CurrentParameterName);
				set v_ParameterString	= CONCAT(v_ParameterString , ' ,13) ,''NULL'') + '''''''' + @CRLF + ' , v_CRLF);
		 else
				set v_ParameterString	= CONCAT(v_ParameterString , ' = ' , ''' + isnull(cast(');
				set v_ParameterString	= CONCAT(v_ParameterString , v_CurrentParameterName);
				set v_ParameterString	= CONCAT(v_ParameterString , ' as varchar(100)),''NULL'') + @CRLF + ' , v_CRLF);
			end if;


		elseif v_CurrentParameterOutput = 1 then
		-- SQLINES DEMO *** e end of the line.
		-- SQLINES DEMO *** ue to the parameter name.
			set v_ParameterString	= CONCAT(v_ParameterString , ' = ' , v_CurrentParameterName 
					, ' --output '' + @CRLF +' , v_CRLF); 
		end if;
		
		if v_Cnt = v_Max then
			set v_ParameterString	= CONCAT(v_ParameterString , v_3Tab , '''***** End of Parameters'' + @CRLF ');
		end if;
										
		set	 v_Cnt = v_Cnt + 1
				,v_CurrentParameterName = 'N/A'
				,v_CurrentParameterType = 'N/A';
		--  SQLINES DEMO ***  cast(@cnt as varchar(20))
	end while;

	set p_pParameterString = v_ParameterString;

leave sp_lbl	-5;

end;

//

delimiter ;
