create procedure [ctl].[usp_GetParameterListing](
		 @pObjectName varchar(255)
		,@pParameterString varchar(4000) output
		,@pVerbose bit = 0
)

as
/*****************************************************************************
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

declare	@ParameterList table 
(
	 ObjectType						nvarchar(60)
	,ParameterName					nvarchar(128)
	,ParameterId					int
	,ParameterDataType				nvarchar(128)
	,IsOutput						bit
	,SchemaName						nvarchar(200)
)

declare	 @ParameterString			nvarchar(4000)
		,@Max						int
		,@Cnt						int
		,@parameterpassedchar		nvarchar(4000)
		,@LiteralCRLF				nvarchar(20)
		,@CRLF						nvarchar(20)
		,@CurrentParameterName		varchar(255)
		,@CurrentParameterType		varchar(255)
		,@CurrentParameterOutput	int 
		,@CurrentParameterSchema    nvarchar(200)
		,@Tab						varchar(5)	= '    ' -- char(9)
		,@2Tab						varchar(6)	= '        ' -- char(9) + char(9)
		,@3Tab						varchar(6)	= '            ' -- char(9) + char(9) + char(9)
		,@ParmLength				int = -1
		,@TabLenght					int = 4
		,@MaxParmLength				int = -1
		,@TargetTabLength			int = -1
		,@TabsToAddCount			int = -1
		,@TabsToAddChar				varchar(20)

select	@ParameterString		= 'No Parameters Passed to Procedure.'
		,@Max = -1
		,@Cnt = -1
		,@CRLF =  char(13) + char(10) -- CR + LF
		,@LiteralCRLF = 'char(13) + char(10)'
		,@parameterpassedchar  = '***** Parameters Passed to usp_GetParameterListing' + @CRLF +
								'@pObjectName = ''' + isnull(@pObjectName ,'NULL') + '''' + @CRLF + 
								'@pParameterString = ''' + isnull(@pParameterString ,'NULL') + '''' + @CRLF + 
								'@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
								'***** End of Parameters' + @CRLF

print @parameterpassedchar

insert into @ParameterList (
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
and		SO.name					= @pObjectName
ORDER BY P.parameter_id

-- select  * from @ParameterList

if exists (select top 1 1 from @ParameterList)
	begin
		select	 @Cnt			= 1
				,@Max			= (select max(ParameterId) from @ParameterList)

		select @CurrentParameterSchema = (select SchemaName
								from @ParameterList
								where ParameterId = @Cnt)	


		select @ParameterString	= @CRLF + @3Tab + '''***** Parameters Passed to exec '+ @CurrentParameterSchema +'.' + @pObjectName + ''' + @CRLF +' + @CRLF

		select @MaxParmLength	= max(len(ParameterName)) + 2 from @ParameterList
		select @TargetTabLength	= (@MaxParmLength / @TabLenght) + 1

/*	
		if @MaxParmLength % @TabLenght = 0 begin
			select @TargetTabLength = @TargetTabLength + 1 --falls on a tab level so add one.
		end
*/
		
		print  '@MaxParmLength : ' + cast(@MaxParmLength as varchar(100))
		print  '@TargetTabLength : ' + cast(@TargetTabLength as varchar(100))
	end


	

while  @Cnt <= @Max and @Cnt <> -1
	begin
		--if @Cnt = 1 select @ParameterString = ' char(13) + '

		select @CurrentParameterName = (select ParameterName
								from @ParameterList
								where ParameterId = @Cnt)
		select @CurrentParameterType = (select ParameterDataType
								from @ParameterList
								where ParameterId = @Cnt)
		select @CurrentParameterOutput = (select IsOutput
								from @ParameterList
								where ParameterId = @Cnt)
	
/*
		select @ParmLength = 0, @TabsToAddCount = 0 , @TabsToAddChar =''

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
		if @Cnt = 1 
			select @ParameterString	= @ParameterString + @3Tab + '''' + @Tab + ' ' + @CurrentParameterName --+ @TabsToAddChar
		else 
			select @ParameterString	= @ParameterString + @3Tab + '''' + @Tab + ',' + @CurrentParameterName --+ @TabsToAddChar
		
		if @CurrentParameterOutput = 0 begin

			if @CurrentParameterType in ('varchar','char','nvarchar') begin 
				select @ParameterString	= @ParameterString + ' = ' + ''''''' + isnull('
				select @ParameterString	= @ParameterString + @CurrentParameterName
				select @ParameterString	= @ParameterString + ' ,''NULL'') + '''''''' + @CRLF + ' + @CRLF
			end else if @CurrentParameterType in ('int','bit','bigint') begin 
				select @ParameterString	= @ParameterString + ' = ' + ''' + isnull(cast('
				select @ParameterString	= @ParameterString + @CurrentParameterName
				select @ParameterString	= @ParameterString + ' as varchar(100)),''NULL'') + @CRLF + ' + @CRLF
			end else if @CurrentParameterType in ('datetime') begin 
				select @ParameterString	= @ParameterString + ' = ' + ''''''' + isnull(convert(varchar(100),'
				select @ParameterString	= @ParameterString + @CurrentParameterName
				select @ParameterString	= @ParameterString + ' ,13) ,''NULL'') + '''''''' + @CRLF + ' + @CRLF
			end else begin
				select @ParameterString	= @ParameterString + ' = ' + ''' + isnull(cast('
				select @ParameterString	= @ParameterString + @CurrentParameterName
				select @ParameterString	= @ParameterString + ' as varchar(100)),''NULL'') + @CRLF + ' + @CRLF
			end

		end

		else if @CurrentParameterOutput = 1 begin
		-- adds output to the end of the line.
		-- set the equal value to the parameter name.
			select @ParameterString	= @ParameterString + ' = ' + @CurrentParameterName 
					+ ' --output '' + @CRLF +' + @CRLF 
		end
		
		if @Cnt = @Max
			select @ParameterString	= @ParameterString + @3Tab + '''***** End of Parameters'' + @CRLF '
										
		select	 @Cnt = @Cnt + 1
				,@CurrentParameterName = 'N/A'
				,@CurrentParameterType = 'N/A'
		--print 'Count : ' + cast(@cnt as varchar(20))
	end

	select @pParameterString = @ParameterString

return	-5

end

GO

