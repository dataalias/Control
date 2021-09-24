<##############################################################################

File:		dbIntervalCheckGet.ps1
Name:		dbIntervalCheckGet

Purpose:	This is the SQL DB connector for the DataHub process. The follwing
			steps are executed:
			1) Determine last issue and get max date (ctl.Issue)
			2) Check interval and period (ctl.Publication)
				if met move forward
				if not met exit
			3) Determine if more current data is present (source data table)
				if met move forward
				if not met exit
			4) Enter a new issue record (ctl.Issue)
			5) Execute SSIS if all conditions are met.


Params:		

Called by:	Windows Scheduler
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180514
Version:    1.0.0.7

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180514	ffortunato		Initial iteration.

20181012	ffortunato		use calling procedure sql connection.

20181107	ffortunato		_Closing_ Reader.

20181108	ffortunato		more fixes for _Closing_ Reader.

20181109	ffortunato		MORE fixes for _Closing_ Reader.

20190625	ochowkwale		ReportDate to be equal to Current Date

##############################################################################>


function Invoke-dbIntervalCheckGet {

<#

.SYNOPSIS
This function is used to determine if any table sources should be checked for 
new data. If a tables invterval has been meet a new issue record is entered
and the associated SSIS package kicked off.

.DESCRIPTION
This cmdlet ...

.PARAMETER protocol
Protocol to be used for the transfer.
ftp:  File Transfer Protocol
sftp: Secure File Transfer Protocol

.EXAMPLE

#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (

		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db to cehck files with’
		)]
		[alias("dbsvr")]
		[string]$dbServer,

		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Acctive connection to the database being queried’
		)]
		[alias("sc")]
		$sqlCon

		,[parameter(Mandatory=$true,
		Position = 3)]
		[alias("pubnc","pc")]
		[string]$publicationCode = 'N/A'

		,[parameter(Mandatory=$false, 
		Position=4)]
	    [alias("fld")]
        [string]$SSISFolder

		,[parameter(Mandatory=$false, 
		Position=5)]
	    [alias("prj")]
        [string]$SSISProject

		,[parameter(Mandatory=$false, 
		Position=6)]
	    [alias("pkg")]
        [string]$SSISPackage

		,[parameter(Mandatory=$true,
		Position = 7)]
		[alias("log","l")]
		[string]$logFile = 'N/A'
)

begin
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-dbIntervalCheckGet -dbServer $dbServer  -pubc $publicationCode -period $intervalLength -interval $intervalCode -fld  $SSISFolder -prj $SSISProject -pkg $SSISPackage " # -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
}
process
{
	$CurrentUser = whoami
	try # find out if the issue is ready to run.
	{
		$date = Get-Date
		$dtTableToGet   = New-Object System.Data.DataTable
		$sqlCmd         = New-Object System.Data.SqlClient.SqlCommand ("ctl.GetTablePublicationList", $sqlCon)
			
		$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
		$sqlCmd.Parameters.AddWithValue("@pPublicationCode", $publicationCode) | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pETLExecutionId", '-1') | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pPathId", '-1') | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pVerbose", '0') | Out-Null

		$infoMessage = "Creating new Reader for PublicationCode: $publicationCode"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile

		$Reader = $sqlCmd.ExecuteReader()

		if($Reader.HasRows)
		{
			$dtTableToGet.Load($Reader)
			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "Table data sucessfully returned for PublicationCode: $publicationCode"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			}
		}
		else
		{
			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "No records returned from GetTablePublicationList for PublicationCode: $publicationCode"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			}
			return  $null  #Exiting procedure. No tables were found that need to run.
		}
	} # try
	catch
	{
		$errorMessage = "Error determining if interval is met for publication code: $publicationCode " + $_.Exception.Message 
		Invoke-Nicelog -event 'Error' -message $errorMessage -logfile $logFile
		throw $errorMessage
	}
	finally
	{
		# Done with the reader and the command so close them.
		$Reader.Close()
		$sqlCmd.Dispose()
	}
	try # insert the new issue.
	{
		foreach ($record in $dtTableToGet)
		{
			$IssueId = 0
			if ($record.IsIntervalMet -eq 1)
			{
				# add a new issue
				New-Issue  -sqlCon   $sqlCon `
					-pubn $publicationCode `
					-dfn  $record.IssueName `
					-s    'IP' `
					-sId  -1  `
					-sDt  $date `
					-fid  $record.FirstRecordSeq `
					-lid  -1 `
					-fchk 'N/A' `
					-lchk 'N/A' `
					-psd  $record.PeriodStartTime `
					-ped  '1/1/1900' `
					-rc   -1 `
					-ETLId -1 `
					-usr  $CurrentUser `
					-iss   ([ref]$IssueId)

				if (($logFile -ne $null) -and ($logFile.Length -gt 0))
				{
					$infoMessage = "New issue created IssueId: $IssueId"
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				}
				# kick off the SSIS.
				Invoke-StagingPackage `
					-dbsvr   $dbServer `
					-Folder  $SSISFolder `
					-Project $SSISProject `
					-Package $SSISPackage `
					-IssueId $IssueId `
					-logFile $logFile
			}
			else
			{
				if (($logFile -ne $null) -and ($logFile.Length -gt 0))
				{
					$infoMessage = "Interval not met for publication: $publicationCode"
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				}
			}
		}
	}
	catch
	{
		$errorMessage = "Error inserting new issue for publication code: $publicationCode " + $_.Exception.Message
		throw $errorMessage
	}
	finally
	{
		#Done with the data table so dispose it.
		$dtTableToGet.Dispose()
	}
}
end
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Complete Invoke-dbIntervalCheckGet"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
}
} # function
	
export-modulemember -function Invoke-dbIntervalCheckGet