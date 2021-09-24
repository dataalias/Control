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

##############################################################################>


function Invoke-dbIntervalCheckGet {

<#

.SYNOPSIS
This function invokes the WinSCP dll to _list_ files on a remote server based 
on the parameters passed.	The list will be verfied against processed issues.
Any files that have not previously been processed will be retrieved from the 
remote host.

.DESCRIPTION
This cmdlet requires an installation of WinSCP at C:\Program Files (x86)\WinSCP\WinSCPnet.dll 


.PARAMETER protocol
Protocol to be used for the transfer.
ftp:  File Transfer Protocol
sftp: Secure File Transfer Protocol

.PARAMETER userName
The user name that will be used for authentication to the host.

.PARAMETER password
The password that will be used for authentication to the host.

.PARAMETER hostName
The complete URL for the hosted ftp site.

.PARAMETER port
The port of the requested ftp service. This must be numeric.

.PARAMETER sshKey
The certificate for secure data transfers.

.PARAMETER remoteDir
The remote directory that contains the files to be retreived.

.PARAMETER destDir
The local directory that will recieve the files.

.PARAMETER fileName
Name of the file to be transfered. This can include wildcards

.PARAMETER action
get - get files from remote; put - put files to remote; list list files on remote

.EXAMPLE
    

#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db maintaining the control structures’
		)]
		[alias("dbs")]
		[string]$dbServer
<#
		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db hosting the data feed that will be loaded to DataHub’
		)]
		[alias("dbp")]
		[string]$dbPublisher
#>
		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’the interval for data to be loaded.’
		)]
		[alias("i")]
		[ValidateSet("DLY","HR","MIN","MTHLY","WKLY","YRLY")] 
		[string]$interval

		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Integer value representing the duration of intervals between data pulls.’
		)]
		[ValidateRange(0,365)] 
		[alias("pd")]
		[int]$period
<#
		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db hosting the data feed that will be loaded to DataHub’
		)]
		[alias("iri")]
		[int]$initialRecordId

		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db hosting the data feed that will be loaded to DataHub’
		)]
		[alias("iri")]
		[string]$initialRecordDatetime


		,[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’The method used to generate the data set being loaded: SS, TXN, DLT’
		)]
		[alias("p")]
		[ValidateSet("SS","TXN","DLT")] 
		[string]$payloadMethod

		,[parameter(Mandatory=$true,
		Position = 2)]
		[alias("srcDB")]
		[string]$sourceDb
        
		,[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’User name to be authenticated to the site’
		)]
		[alias("usr")]
		[string]$userName

		,[parameter(Mandatory=$true,
		Position = 4)]
		[alias("pwd","pass")]
		[string]$password

		,[parameter(Mandatory=$false,
		Position = 5)]
		[alias("pt")]
		[int]$port

		,[parameter(Mandatory=$false,
		Position = 6)]
		[alias("key")]
		[string]$sshKey
#>
		,[parameter(Mandatory=$true,
		Position = 7)]
		[alias("pubnc","pc")]
		[string]$publicationCode = 'N/A'

		,[parameter(Mandatory=$true,
		Position = 8)]
		[alias("log","l")]
		[string]$logFile = 'N/A'
)

BEGIN
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-dbIntervalCheckGet -dbServer $dbServer  -pubc $publicationCode -period $period -interval $interval  -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}

}
process
{
	try # find out if the issue is ready to run.
	{

	}
	catch
	{
		$errorMessage = "Error determining if interval is met for publication code: $publicationCode " + $_.Exception.Message
		throw $errorMessage
	}
	try # determine applicable values for the issue.
	{

	}
	catch
	{
		$errorMessage = "Error gathering parameters for new issue for publication code: $publicationCode " + $_.Exception.Message
		throw $errorMessage
	}
	try # insert the new issue.
	{

	}
	catch
	{
		$errorMessage = "Error inserting new issue for publication code: $publicationCode " + $_.Exception.Message
		throw $errorMessage
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