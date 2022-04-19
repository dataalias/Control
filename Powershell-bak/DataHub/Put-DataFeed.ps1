<##############################################################################

File:		Put-DataFeed.ps1
Name:		Put-DataFeed

Purpose:	This is the main outbound DataHub process. It calls ctl structures
			on EDL to determine what sources must be sent to subscribers.
Params:		

Called by:	Windows Scheduler
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180822  
Version:    2.0.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180822	ffortunato		Initial iteration. Adapted from Get-DataFeed

20181009	ffortunato		Make a hard exit and clean up the sql connection.
20190306	ochowkwale		Rework on exporting functionality
20190814	ochowkwale		Adding error email to every catch block
						
##############################################################################>

<#

.SYNOPSIS
This script will send data extracts to subscribers based on a scheduled task 
call.

.DESCRIPTION
This is the export (outbound, departure) DataHub process. It calls ctl 
structures on EDL to determine what sources should be checked for new files. 

.EXAMPLE

#>

$ConfigFile = $args[0] # This should be the path for the config file.
$IssueId = $args[1] # This is the IssueId
$TaskName   = $args[2] # This is the specific task name.

if (!$ConfigFile) 
{
    $ConfigFile = "C:\Users\ffortunato\Source\Workspaces\BIDW\PowerShell\DataHub\config\AUTODMESBX_DataHubConfig.json"
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
$Source   = "DataHub"

[string]$dbServer = $configFileContent.BPIServer.DatabaseServer
[string]$fileShareRoot = $configFileContent.BPIServer.FileServer
[string]$fileSharePath = 'N/A'
[string]$modulePath = $configFileContent.Paths.Module

$env:PSModulePath = $env:PSModulePath + $modulePath
Import-Module dmutils

$logFile           = $configFileContent.Paths.Log + "Put-DataFeed_" + $yyymmdd + "_" + $TaskName + ".log"
$EmailThrottleFile = $configFileContent.Paths.ThrottleFile
$modulePath        = $configFileContent.Paths.Modules
$PrivateKeyPath    = $configFileContent.Paths.PrivateKeys
$eMailInterval     = $configFileContent.Limiters.eMailIntervalSeconds
$ScriptFile        = $configFileContent.Paths.Script + $MyInvocation.MyCommand.Name

#Selecting the Distribution Status
[string]   $DistributionStart = 'DT'
[string]   $DistributionComplete = 'DC'
[string]   $DistributionFail = 'DF'

Invoke-Nicelog -event 'Start' -message 'Put-DataFeed Initiated' -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "host: $curHost"  -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "db  : $dbServer" -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "usr : $curUser"  -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "args: $args"     -logfile $logfile 


if (!$IssueId) 
{
    $errorMessage = "No IssueId passed"
    Invoke-Nicelog -event 'Error' -message $errorMessage -logfile $logfile  	
}


# Set the SMTP Server address
$smtpserver = $configFileContent.BPIServer.EmailServer
$from       = $configFileContent.eMail.From
$to         = "omkar.chowkwale@bpiedu.com"
$subject    = $runEnv + ' ' + $configFileContent.eMail.Subject 
$emailBody  = @"
Failure:`t$runEnv DataHub.Get-DataFeed

PID:`t`t$pid  
Date:`t`t$date 
UTCDate:`t$dateU
HostName:`t$curHost
DBName:`t$dbServer
User:`t`t$curUser
Script:`t`t$ScriptFile 
LogFile:`t`t$logfile

"@

[string]$infoMessage = " "
[string]$errorMessage = " "

# Prime the data table
[System.Data.DataTable] $dtSubscriptionList = New-Object Data.datatable
#[System.Data.DataTable] $dtJobToRun = New-Object Data.datatable

$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$sqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Connection Timeout=60;Integrated Security=True"

try 
{
    $sqlCon.Open()
} 
catch 
{
	$customMessage = " Unable to open DB connection: $dbServer."
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
	exit
}

try
{
	$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_PutSubscriptionList_Datahub]", $sqlCon)
	$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
	$sqlCmd.Parameters.AddWithValue("@pIssueId", $IssueId) | Out-Null

    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter ($sqlCmd)
    $sqlAdapter.Fill($dtSubscriptionList) | Out-Null
    $date = Get-Date
    $infoMessage = "Subscription list successfully retrieved from database." 
    Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logfile
    $sqlAdapter.Dispose()    
}
catch
{
	$customMessage = "Unable to return results from stored procedure ctl.usp_PutSubscriptionList_datahub on $dbServer."
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue" 
	exit    
}

try
{
    # Lets decide what to do for each of the subscriptions in the active list.
    foreach($record in $dtSubscriptionList)
    {
        #Set Distribution Status as started
        try
        {
            $sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateDistributionStatus]", $sqlCon)
			$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
			$sqlCmd.Parameters.AddWithValue("@pIssueId", $record.IssueId) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pSubscriptionCode", $record.SubscriptionCode) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pStatus", $DistributionStart) | Out-Null
			$sqlCmd.ExecuteNonQuery() | Out-Null
			$sqlCmd.Dispose()

            $date = Get-Date
            $infoMessage = "Subscription list successfully retrieved from database." 
            Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logfile
        }
        catch
        {
	        $customMessage = "Unable to set Distribution Status to Started on $dbServer."
            Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
			Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
			continue
        }

        $date     = Get-Date
        $infoMessage = "Initiating data feed export process. `t`t SubscriptionCode: " + $record.SubscriptionCode + " Subscription Type: " + $record.InterfaceCode
        Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $logfile 
		# Configuring the path for files...
		$fileSharePath = Join-Path $fileShareRoot $record.SrcFilePath


        switch ($record.InterfaceCode)   
        {
            {($_ -eq "SFTP") -or ($_ -eq "FTP")}
            {
				$PrivateKeyPath = $PrivateKeyPath +  $record.PrivateKeyFile

                # Reach out to ftp site for new files.
                try
                {
                    Invoke-ftpPut `
                        -dbServer  $dbServer `
						-IssueName  $record.IssueName `
                        -protocol  $record.SiteProtocol `
                        -userName  $record.SiteUser `
                        -password  $record.SitePassword `
                        -fp        $record.SiteHostKeyFingerprint `
                        -hostName  $record.SiteURL `
                        -remoteDir $fileSharePath `
                        -destDir   $record.SubscriptionFilePath `
                        -port      $record.SitePort  `
						-phrase    $record.PrivateKeyPassPhrase `
						-KeyPath   $PrivateKeyPath `
						-log       $logfile 

					#Set Distribution Status as Complete
					try
					{
						$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateDistributionStatus]", $sqlCon)
						$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
						$sqlCmd.Parameters.AddWithValue("@pIssueId", $record.IssueId) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pSubscriptionCode", $record.SubscriptionCode) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pStatus", $DistributionComplete) | Out-Null
						$sqlCmd.ExecuteNonQuery() | Out-Null
						$sqlCmd.Dispose()
						$date = Get-Date						
					}
					catch
					{
						$customMessage = "Unable to set Distribution Status to complete from stored procedure ctl.usp_PutSubscriptionList on $dbServer."
						Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
						Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
						continue
					}

                }
                catch
                {
	                $customMessage = "Failure with ftp / sftp for Subscription: " + $record.SubscriptionCode
	                Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
					Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
					try
					{
						$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateDistributionStatus]", $sqlCon)
						$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
						$sqlCmd.Parameters.AddWithValue("@pIssueId", $record.IssueId) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pSubscriptionCode", $record.SubscriptionCode) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pStatus", $DistributionFail) | Out-Null
						$sqlCmd.ExecuteNonQuery() | Out-Null
						$sqlCmd.Dispose()
						$date = Get-Date
					}
					catch
					{
						$customMessage = "Unable to set Distribution Status to fail from stored procedure ctl.usp_PutSubscriptionList on $dbServer."
						Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
						Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
					}
					continue
                }
            }
            "SHARE" 
            {
                try
                {
                    Invoke-FileSharePut `
                        -dbServer  $dbServer `
						-IssueName  $record.IssueName `
                        -srcDir    $fileSharePath `
                        -destDir   $record.SubscriptionFilePath `
						-log       $logfile

					#Set Distribution Status as Complete
					try
					{
						$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateDistributionStatus]", $sqlCon)
						$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
						$sqlCmd.Parameters.AddWithValue("@pIssueId", $record.IssueId) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pSubscriptionCode", $record.SubscriptionCode) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pStatus", $DistributionComplete) | Out-Null
						$sqlCmd.ExecuteNonQuery() | Out-Null
						$sqlCmd.Dispose()
						$date = Get-Date						
					}
					catch
					{
						$customMessage = "Unable to set Distribution Status to complete from stored procedure ctl.usp_PutSubscriptionList on $dbServer."
						Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
						Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
						continue
					}

                }
                catch
                {
                    $customMessage = "Failure with file share copies for Subscription: " + $record.SubscriptionCode
	                Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
					Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
					try
					{
						$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateDistributionStatus]", $sqlCon)
						$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
						$sqlCmd.Parameters.AddWithValue("@pIssueId", $record.IssueId) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pSubscriptionCode", $record.SubscriptionCode) | Out-Null
						$sqlCmd.Parameters.AddWithValue("@pStatus", $DistributionFail) | Out-Null
						$sqlCmd.ExecuteNonQuery() | Out-Null
						$sqlCmd.Dispose()
						$date = Get-Date
					}
					catch
					{
						$customMessage = "Unable to set Distribution Status to fail from stored procedure ctl.usp_PutSubscriptionList on $dbServer."
						Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
						Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
					}
					continue
                }
            }
            default 
            {
                $errorMessage = "Bad InterfaceCode Value: " + $record.InterfaceCode + " "
                Invoke-Nicelog -event 'Error' -message $errorMessage -logfile $logfile  		
				Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
				
				try
				{
					$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateDistributionStatus]", $sqlCon)
					$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
					$sqlCmd.Parameters.AddWithValue("@pIssueId", $record.IssueId) | Out-Null
					$sqlCmd.Parameters.AddWithValue("@pSubscriptionCode", $record.SubscriptionCode) | Out-Null
					$sqlCmd.Parameters.AddWithValue("@pStatus", $DistributionFail) | Out-Null
					$sqlCmd.ExecuteNonQuery() | Out-Null
					$sqlCmd.Dispose()
		            $date = Get-Date
				}
				catch
				{
					$customMessage = "Unable to set Distribution Status to fail from stored procedure ctl.usp_PutSubscriptionList on $dbServer."
					Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logfile
					Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue"
				}						
            }
        } # switch 


        # for file based transfers lets check for control files.
<#        if  ($record.InterfaceCode -in "SFTP","FTP","SHARE")   
        {
            try
            {
                # Create Control Files (if needed)
                Add-ControlFile `
                    -dir       $fileSharePath `
                    -pc        $record.PublicationCode

                $infoMessage = "Control files generated for FTP processes. `t PublicationCode: " + $record.PublicationCode
                Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logfile 
            }
            catch
            {
                $customMessage = "Error encountered with Control File processing for Publisher: " + $record.InterfaceCode
	            Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage -act "Continue" 
            }
        }#>
    } # foreach
} # try
catch
{
    $customMessage = "Failure caught in main catch of Put-DataFeed."
	
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage -act "Continue" 
    return $null
}

$SqlCon.Close()

$date        = Get-Date
$duration    = New-Timespan –Start $dateInitial –End $date
$infoMessage = "Put-DataFeed ended successfully. Duration: " + $duration
Invoke-Nicelog -event 'End'  -message $infoMessage -logfile $logfile 
