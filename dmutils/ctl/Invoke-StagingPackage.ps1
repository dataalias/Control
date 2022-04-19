<##############################################################################

File:		Invoke-StagingPackage.ps1
Name:		Invoke-StagingPackage

Purpose:	This script is responsible for several activities.
			1) Create and execution
			2) Set parameters for the specific execution
			3) start the SSIS package execution

Invoke-StagingPackage `
-SQLInstance  'DEDTEDLSQL01' `
-Folder 'ETLFolder' `
-Project 'OIE' `
-Package 'shrug.dtsx' `
-IssueId 12345 `
-LogFile  'C:\PowerShell\logs\xzy.log'

			
Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunto
Date:		

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description
--------  --------------	---------------------------------------------------
20170419  ffortunato		change to a better method to call stored procudures
							setting parameters accordingly.

20180307  ffortunato		getting ready for DM utils.

20180322  ffortunato		Added logging

20180612  ffortunato		Getting the ref_id

20180817  ffortunato		if the ssis packages can be called the issue must be failed 

20180817  ffortunato		NEED TO TRY RUNNING THIS IN 32 BIT.
							$sqlCmd.Parameters.Add("use32bitruntime", [System.Data.SqlDbType]::Bit).Value = 1

20181012  ffortunato		using sqlCon

20190404  ffortunato		using sqlCon (really) and calling 
							ExecuteSSISPackage stored procedure

##############################################################################>

###############################################################################
#
# Declarations / Initializations
#
###############################################################################

function Invoke-StagingPackage {

<#
.SYNOPSIS
This function invokes a ETL catalog package.

.DESCRIPTION
This function receives catalog information for a specific package then 
shedules and executes the process.

.EXAMPLE
Invoke-StagingPackage -SQLInstance "LBPCA-6CZKF72" -Folder tstFolder -Project tstSSISPowerShell -Package FileStaging.dtsx -IssueId 3099


#>

    [CmdletBinding()] 
    param(
		
        [parameter(Mandatory=$true, Position=0)]
		[alias ("dbsvr")]
        [string]$dbServer,
		
		[parameter(Mandatory=$true, Position=0)]
		[alias ("dbsvr")]
        [string]$sqlCon,

        [parameter(Mandatory=$true, Position=1)]
        [string]$Folder,
 
        [parameter(Mandatory=$true, Position=2)]
        [string]$Project,
 
        [parameter(Mandatory=$true, Position=3)]
        [ValidatePattern('^.*\.dtsx$')]
        [string]$Package,

        [parameter(Mandatory=$true, Position=4)]
        [int]$IssueId,

		[parameter(Mandatory=$false, Position=5)]
        [string]$logFile

    )

begin
{

	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-StagingPackage -dbsvr $dbServer -Folder $Folder -Project $Project -Package $Package -IssueId " + $IssueId.ToString() 
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
	}

} # begin

process 
{
    
try  # get the refenence id so we can set some env variables.
{
    $infoMessage = "Executing SSIS package... Folder: $Folder Project: $Project, Package: $Package Server: " + $sqlCon.ConnectionString
	Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile

	[System.Data.DataTable] $dtPackageParameters = New-Object Data.datatable
    $dtPackageParameters.Columns.Add("ParameterId")    | Out-Null
    $dtPackageParameters.Columns.Add("ObjectType")     | Out-Null
	$dtPackageParameters.Columns.Add("ParameterName")  | Out-Null
	$dtPackageParameters.Columns.Add("ParameterValue") | Out-Null

    $DR = $dtPackageParameters.NewRow()   #Creating a new data row
    $DR.Item("ParameterId")    = 1
    $DR.Item("ObjectType")     = 3
	$DR.Item("ParameterName")  = 'pkg_IssueId'
	$DR.Item("ParameterValue") = $IssueId
    $dtPackageParameters.Rows.Add($DR)

	$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[pg].[ExecutePostingGroupProcessing]", $sqlConSSISDB)
    $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
	$sqlCmd.Parameters.AddWithValue("@pServerName", $dbServer) | Out-Null
    $sqlCmd.Parameters.AddWithValue("@pSSISFolder", $Folder) | Out-Null
    $sqlCmd.Parameters.AddWithValue("@pSSISProject", $Project) | Out-Null
    $sqlCmd.Parameters.AddWithValue("@pSSISPackage", $Package) | Out-Null
	$sqlCmd.Parameters.Add($dtPackageParameters) | Out-Null
    
	$infoMessage = "Staging package executed"
	Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile

}
catch
{
	Edit-Issue -dbServer $dbServer -issueId $IssueId -statusCode  'IF'
	$infoMessage = "Executing SSIS package Failed. see audit.StepLog for details. :: " + $_.Exception.Message
	Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
    # write-error "[catalog].[start_execution]"
	throw $_.Exception.Message
}
finally
{
    $sqlCmd.Dispose()
	$sqlConSSISDB.Dispose()
}
} # process

end
{

	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = 'Ending Invoke-StagingPackage'
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
	}

} # end
} # function

export-modulemember -function Invoke-StagingPackage