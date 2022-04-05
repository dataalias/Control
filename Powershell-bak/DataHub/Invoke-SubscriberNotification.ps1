<##############################################################################

File:		Invoke-SubscriberNotification.ps1
Name:		Invoke-SubscriberNotification

Purpose:	This function Invokes notifications.

Params:		

Called by:	Windows Scheduler - SSIS DataHub packages.
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180412
Version:    1.0.0.7

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180413	ffortunato		Initial iteration.

##############################################################################>

<#

.SYNOPSIS
...

.DESCRIPTION
Desc...

.EXAMPLE

#>

$ConfigFile = $args[0] # This should be the path for the config file.
$TaskName   = $args[1] # This is the specific task name.

if (!$ConfigFile) 
{
    $ConfigFile = "C:\Users\ffortunato\Source\Workspaces\BIDW\PowerShell\DataHub\config\DataHubConfig.json"
}

if (!$TaskName) 
{
    $TaskNum    = Get-Random -minimum 1 -maximum 4
    $TaskName   = "Task_0" + $TaskNum 
}

# This confgi file has a whole bunch of variables used in the script.
$configFileContent = Get-Content $ConfigFile -Raw | ConvertFrom-Json

###############################################################################
#
# Declarations / Initializations
#
###############################################################################

# Priming some data for the Issue insert
$CrLf     = "`r`n"
$CrLfTab  = "`r`n`t"
$curHost  = hostname
$curUser  = whoami
$dateInitial = Get-Date
$date     = Get-Date
$dateU    = $date.ToUniversalTime()
$yyymmdd  = Get-Date -format yyyyMMdd #hhmm  #ssms
$Version  = "1.0.0.7"

$logFile           = $configFileContent.Paths.Log + "Invoke-SubscriberNotification_" + $yyymmdd + "_" + $TaskName + ".log"
$EmailThrottleFile = $configFileContent.Paths.ThrottleFile
$eMailInterval     = $configFileContent.Limiters.eMailIntervalSeconds
$ScriptFile        = $configFileContent.Paths.Script + $MyInvocation.MyCommand.Name
$ScriptHash        = Get-FileHash -f $ScriptFile

[string]$dbServer  = $configFileContent.BPIServer.DatabaseServer
[string]$fileShareRoot = $configFileContent.BPIServer.FileServer

Invoke-Nicelog -event 'Start' -message 'Invoke-FileShareArchive Initiated' -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "Host    : $curHost"  -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "Db      : $dbServer" -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "User    : $curUser"  -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "Args    : $args"     -logfile $logfile 

# Set the SMTP Server address
$smtpserver = $configFileContent.BPIServer.EmailServer
$from       = $configFileContent.eMail.From
$to         = $configFileContent.eMail.To
$subject    = $configFileContent.eMail.Subject 
$emailBody  = @"
Failure:`tDataHub.Invoke-FileShareArchive

PID:`t`t$pid  
Date:`t`t$date 
UTCDate:`t$dateU
HostName:`t$curHost
DBName:`t$dbServer
User:`t`t$curUser
Script:`t$ScriptFile 
LogFile:`t`t$logfile

"@

$infoMessage = ""
$errorMessage = ""

# Prime the data table
[System.Data.DataTable] $dtArchiveList = New-Object Data.datatable

$SqlCon = New-Object System.Data.SqlClient.SqlConnection
$SqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Integrated Security=True"

<#
If (($Version    -ne $configFileContent.__Header.Version) `
-or ($curHost    -ne $configFileContent.BPIServer.ApplicationServer) `
-or ($ScriptHash -ne $configFileContent.__Header.InvokeFileShareArchiveHash))
{

    $errorMessage = "Incorrect configuration file." `
    + $CrLf +"`tVersion Match   : " + $Version + "`t`t`t`t : " + $configFileContent.__Header.Version `
    + $CrLf +"`tHost Match      : " + $curHost + "`t`t`t`t : " + $configFileContent.BPIServer.ApplicationServer `
    + $CrLf +"`tHash Match      : " + $ScriptHash + "`t : " + $configFileContent.__Header.InvokeFileShareArchiveHash
    

    Invoke-Nicelog -event 'Error' -message $errorMessage -logfile $logfile 
    Invoke-Nicelog -event 'Exit'  -message $CrLf         -logfile $logfile 
    $emailBody = $emailBody + $CrLf + "Incorrect configuration File. See attached log for additional detail. "
    Send-eMail -svr $smtpserver -t $to -f $from -s $subject -b $emailBody -a $null
    exit
}
else
{
    $infoMessage = "Version: $Version, Host: $curHost and Hash: $ScriptHash verified."
    Invoke-Nicelog -event 'Info'  -message $infoMessage  -logfile $logfile 
}
#>

<#
	IssueId is passed in as parameter
	Based on the issueId look up the distributions
	For each distribution
	{
		Identify notification procedure
		Execute notification procedure
		update distriburion status
	}
	Look for any distributions with 'DN' status and retry notification
	Add to notifiaction retry
	If notification retry exceeds 3 fail the distribution.
#>



try 
{
    $SqlCon.Open()
} 
catch 
{
	$customMessage = "Unable to open DB connection to $dbServer."
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage -act "Exit" 
	exit
}

try
{
    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter ("ctl.GetShareIssuesToArchive", $SqlCon)
    $sqlAdapter.Fill($dtArchiveList) | Out-Null
    $date     = Get-Date
    $infoMessage = "Archive list successfully retrieved from database." 
    Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logfile
    $sqlAdapter.Dispose()    
}
catch
{
    $customMessage =  "Unable to open stored procedure ctl.GetIssueNamesToRetrieve on $dbServer."
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage -act "Exit" 
    exit
}