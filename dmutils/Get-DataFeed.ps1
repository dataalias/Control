<##############################################################################

File:		Get-DataFeed.ps1
Name:		Get-DataFeed

Purpose:	This is the main DataHub process. It calls ctl structures on EDL
			to determine what sources should be checked for new files.
			If files are found it checks to see if the are loaded already.
			Those files not already loaded are downloaded to a local share,
			notifications are sent to ctl.issue and the associated SSIS
			packages are executed.

Params:		

Called by:	Windows Scheduler
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180111
Version:    1.1.0.0

##############################################################################>

<#

.SYNOPSIS
This script will download new data extracts based on a scheduled task 
call.

.DESCRIPTION
This is the main DataHub process. It calls ctl structures on EDL to determine
what sources should be checked for new files. If files are found it checks to
see if the are loaded already. Those files not already loaded are downloaded 
to a local share, notifications are sent to ctl.issue and the associated SSIS 
packages are executed.

.EXAMPLE

#>

$ConfigFile = $args[0] # This should be the path for the config file.
$TaskName   = $args[1] # This is the specific task name.

if (!$ConfigFile) 
{
    $ConfigFile = "C:\Users\ffortunato\Source\Workspaces\BIDW\PowerShell\DataHub\config\envSpecific\AUTODMESBX_DataHubConfig.json"
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
$Version  = "1.1.0.0"
$Source   = "DataHub"

[string]$dbServer = $configFileContent.BPIServer.DatabaseServer
[string]$fileShareRoot = $configFileContent.BPIServer.FileServer
[string]$fileSharePath = 'N/A'
[string]$runEnv = $configFileContent.__Header.Env.EnvironmentAbbreviation
[string]$modulePath = $configFileContent.Paths.Module

if (Get-Module -ListAvailable -Name dmutils) 
{
	Remove-Module dmutils
}

$env:PSModulePath = $env:PSModulePath + $modulePath
Import-Module dmutils

$logFile           = $configFileContent.Paths.Log + "Get-DataFeed_" + $yyymmdd + "_" + $TaskName + ".log"
$EmailThrottleFile = $configFileContent.Paths.ThrottleFile
$modulePath        = $configFileContent.Paths.Modules
$PrivateKeyPath    = $configFileContent.Paths.PrivateKeys
$eMailInterval     = $configFileContent.Limiters.eMailIntervalSeconds
$ScriptFile        = $configFileContent.Paths.Script + $MyInvocation.MyCommand.Name
$ScriptHashObj     = Get-FileHash  -Algorithm SHA256 -LiteralPath $ScriptFile
$ScriptHash        = $ScriptHashObj.Hash.ToString()

Invoke-Nicelog -event 'Start' -message '--------------------------------------------------------------------------------' -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message 'Get-DataFeed Initiated' -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "env : $runEnv"   -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "pid : $pid"      -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "host: $curHost"  -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "db  : $dbServer" -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "usr : $curUser"  -logfile $logfile 
Invoke-Nicelog -event 'Info'  -message "args: $args"     -logfile $logfile 

# Set the SMTP Server address
$smtpserver = $configFileContent.BPIServer.EmailServer
$from       = $configFileContent.eMail.From
$to         = $configFileContent.eMail.To
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
[System.Data.DataTable] $dtPublicationList = New-Object Data.datatable
[System.Data.DataTable] $dtJobToRun = New-Object Data.datatable

$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$sqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Connection Timeout=60;Integrated Security=True"

<#
If (($Version    -ne $configFileContent.__Header.Version) `
-or ($curHost    -ne $configFileContent.BPIServer.ApplicationServer) `
-or ($ScriptHash -ne $configFileContent.__Header.GetDataFeedHash))
{

    $errorMessage = "Incorrect configuration file." `
    + $CrLf +"Version Match   : " + $Version + "`t`t`t`t : " + $configFileContent.__Header.Version `
    + $CrLf +"Host Match      : " + $curHost + "`t`t`t`t : " + $configFileContent.BPIServer.ApplicationServer `
    + $CrLf +"Hash Match      : " + $ScriptHash + "`t : " + $configFileContent.__Header.GetDataFeedHash

    $customMessage = "Incorrect configuration File. See log for additional detail. "
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from `
		-s $subject `
		-b $emailBody `
		-log $logfile  `
		-err ([ref]$_)  `
		-cust $customMessage  `
		-act "Exit" 

    exit
}
else
{
    $date = Get-Date
    $infoMessage = "Version: $Version, Host: $curHost and Hash: $ScriptHash verified."
    Invoke-Nicelog -event 'Info'   -message $infoMessage         -logfile $logfile 
}
#>
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
    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter ("ctl.usp_GetPublicationList_DataHub", $sqlCon)
    $sqlAdapter.Fill($dtPublicationList) | Out-Null
    $date = Get-Date
    $infoMessage = "Publication list successfully retrieved from database." 
    Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logfile
    $sqlAdapter.Dispose()    
}
catch
{
	$customMessage = "Unable to return results from stored procedure ctl.usp_GetPublicationList_DataHub on $dbServer."
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue" 
    exit
}

try
{
    # Lets decid what to do for each of the publications in the active list.
    foreach($record in $dtPublicationList)
    {

        If ($sqlCon.State -ne 'Open')
        {
			$infoMessage = "sqlCon is _not_ open. `t PublicationCode: " + $record.PublicationCode
            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logfile 
            throw 'sqlCon is _not_ open' + $record.PublicationCode
        }

        # this switch goes out and transfers files if necessary
        # careful with siteprotocol vs InterfaceCode
        $date     = Get-Date
		# Adding blank line to the log file
		$CrLf | Out-File $logFile -Append
        $infoMessage = "Initiating data feed retreival process. `t`t PublicationCode: " + $record.PublicationCode  + " InterfaceCode: "  + $record.InterfaceCode
        Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $logfile 
		# Configuring the path for files...
		$fileSharePath = $fileShareRoot + $record.PublicationFilePath

		switch ($record.InterfaceCode)   
        {
            {($_ -eq "SFTP") -or ($_ -eq "FTP")}
            {
				$PrivateKeyPath = $PrivateKeyPath +  $record.PrivateKeyFile

                # Reach out to ftp site for new files.
                try
                {
						#-dbServer  $dbServer `
                    Invoke-ftpListCheckGet `
                        -sqlCon    $sqlCon `
                        -protocol  $record.SiteProtocol `
                        -userName  $record.SiteUser `
                        -password  $record.SitePassword `
                        -fp        $record.SiteHostKeyFingerprint `
						-cert      $record.SiteTLSHostKeyCertificate `
                        -hostName  $record.SiteURL `
                        -remoteDir $record.srcFilePath `
                        -destDir   $fileSharePath `
                        -port      $record.SitePort  `
                        -pc        $record.PublicationCode `
						-phrase    $record.PrivateKeyPassPhrase `
						-KeyPath   $PrivateKeyPath `
						-fm        $record.srcPublicationName `
						-log       $logfile 
                }
                catch
                {
	                $customMessage = "Failure with ftp / sftp for Publisher: " + $record.PublicationCode
	                Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "Continue" 
                }
            }
            "SHARE" 
            {
                try
                {
                    Invoke-FileShareListCheckGet `
                        -sqlCon    $sqlCon `
                        -srcDir    $record.srcFilePath `
                        -destDir   $fileSharePath `
                        -pubnc     $record.PublicationCode `
                        -fm        $record.srcPublicationName `
						-log       $logfile
                }
                catch
                {
                    $customMessage = "Failure with file share copies for Publisher: " + $record.PublicationCode
	                Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody `
		                -log $logfile  `
		                -err ([ref]$_)  `
		                -cust $customMessage  `
		                -act "Continue" 
                }
            }
            "API" 
            {
                # this should go away.
                #"API This should go away"
            }
            "TBL"
            {
				try
				{
					Invoke-dbIntervalCheckGet `
						-dbsvr    $dbServer `
                        -sqlCon   $sqlCon `
						-pubnc    $record.publicationCode `
						-fld      $record.SSISFolder `
						-prj      $record.SSISProject  `
						-pkg      $record.SSISPackage  `
						-logFile  $logFile
				} # try
                catch
                {
                    $customMessage = "Failure with table notification for Publisher: " + $record.PublicationCode
	                Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody `
		                -log $logfile  `
		                -err ([ref]$_)  `
		                -cust $customMessage  `
		                -act "Continue" 
                }
            }
            default 
            {
				$errorMessage = "Bad InterfaceCode Value: " + $record.InterfaceCode + ". Correct the ctl.Publisher.InterfaceCode."
                #$errorMessage = "Bad PublisherType Value: " + $record.PublisherType + " "
                Invoke-Nicelog -event 'Error' -message $errorMessage -logfile $logfile  
				Invoke-Nicelog -event 'Info'  -message 'Continuing' -logfile $logfile  
            }
        } # switch 

        # for file based transfers lets check for control files.
		if  ($record.InterfaceCode -in "SFTP","FTP","SHARE")   
        {
            try
            {
                # Create Control Files (if needed)
                Add-ControlFile `
                    -dir       $fileSharePath `
                    -pc        $record.PublicationCode `
					-fm        $record.srcPublicationName

                $infoMessage = "Control files generated for FTP processes. `t PublicationCode: " + $record.PublicationCode
                Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logfile 

                # Create Issue(s) for current publications.
                Invoke-ctlFileToIssue `
					-dbsvr     $dbServer `
                    -sqlCon    $sqlCon `
                    -dir       $fileSharePath `
                    -pc        $record.PublicationCode `
                    -fld       $record.SSISFolder `
                    -prj       $record.SSISProject  `
                    -pkg       $record.SSISPackage  `
					-fm        $record.srcPublicationName `
                    -log       $logfile

                $infoMessage = "Control files data written to issues table. `t PublicationCode: " + $record.PublicationCode
                Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logfile 
            }
            catch
            {
                $customMessage = "Error encountered with Control File processing for PublicationCode: " + $record.PublicationCode
	            Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage -act "Continue" 
            }
        }
    } # foreach($record in $dtPublicationList)
} # try
catch
{
    $customMessage = "Failure caught in main catch of Get-DataFeed."
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage -act "Continue" 
    return $null
}

$sqlCon.Close()
$sqlCon.Dispose()

$date        = Get-Date
$duration    = New-Timespan –Start $dateInitial –End $date
$infoMessage = "Get-DataFeed ended successfully. Duration: " + $duration
Invoke-Nicelog -event 'End'  -message $infoMessage -logfile $logfile 


<##############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180111	ffortunato		Initial iteration.
20180302	ffortunato		Making the file path configurable for easier code
							promotion.
20180307	ffortunato		calling package.
20180322	ffortunato		Cleaning up logging to use new functions.
20180326	ffortunato		Fixes for QA.
20180327	ffortunato		Fixes for QA. Using native Get-FileHash removing 
                            dmutils version.
20180510	ffortunato		Invoke-ftpListCheckGet
20180529	ffortunato		Invoke-dbIntervalCheckGet 
20180605	ffortunato		Did someone say SLAs?!
20180627	ffortunato		Lots more paprameters for the ftp.
20180828	ffortunato		Prep of PublisherType --> InterfaceCode
							blank line after each publication.
20180925	ffortunato		Minor logging changes for reading ease.
20181004	ffortunato		Moving SLA checks up. Versioning 1.1.0.0
20181012	ffortunato		passing sql connection
20181016	ffortunato		LineFeed before each publication log.
20181018	ffortunato		Loading Module dynamically
20181101	ffortunato		Make sure the SQL connection is still open.
20190107	ochowkwale		FTP additional field - SiteTLSHostKeyCertificate
##############################################################################>


<#Testing
' '
' ***************************'
"Code: " + $record.PublicationCode   
"Path: " + $fileSharePath
"fld : " + $record.SSISFolder 
"prj : " + $record.SSISProject  
"pkg : " + $record.SSISPackage 
"prd : " + $record.IntervalLength 
"int : " + $record.IntervalCode 
' '
<#
'Invoke-ListCheckGet `'
    "-protocol  '" +  $record.SiteProtocol + "' ``"
#    "-userName  '" +  $record.SiteUser + "' ``"
#    "-password  '" +  $record.SitePassword + "' ``"
#    "-sshKey    '" +  $record.SiteKey + "' ``"
#    "-hostName  '" +  $record.SiteURL + "' ``"
    "-remoteDir '" +  $record.srcFilePath+ "' ``"
    "-destDir   '" +  $fileSharePath
#    "-port      '" +  $record.SitePort + "' ``"
    "-publicationCode'" +    $record.PublicationCode + "'"
	"-fp  '"    +  $record.SiteHostKeyFingerprint  + "'"
	"-phrase '"  +  $record.PrivateKeyPassPhrase  + "'"
	"-KeyPath '" + $PrivateKeyPath +  $record.PrivateKeyFile  + "'"
' ***************************'
' '
<##>
<#
		# Determine if SLA was met. This is now done in the publication proc.

		if ($record.SLATime -match $record.SALRegEx)  # Make sure we have a nice SLA Format.
		{
			[boolean]$SLAMet      = Invoke-SLACheck      -dtm $date  -interval $record.IntervalCode -sla $record.SLATime -log $logfile
			[boolean]$IntervalMet = Invoke-IntervalCheck -intervalCode $record.IntervalCode -il $record.IntervalLength -le $record.LastExecution -log $logfile

			if (($SLAMet -eq $false) -or ($IntervalMet -eq $false))
			{
				$infoMessage = "SLA or Interval not met for PublicationCode: " + $record.PublicationCode + "`t SLA Met: $SLAMet`t Interval Met: $IntervalMet" 
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logfile 
				Invoke-Nicelog -event 'Info'  -message 'Continuing' -logfile $logfile 
				continue # Not processing this publication
			} 
		}
		else
		{
			$infoMessage = "SLA time not formatted correctly. `t SLATime: " + $record.SLATime + ' SLARegEx: ' + $record.SALRegEx
			Invoke-Nicelog -event 'Error' -message   $infoMessage -logfile   $logfile 
			Invoke-Nicelog -event 'Info'  -message 'Continuing' -logfile $logfile 
			continue # Not processing this publication
		}
		$infoMessage = "SLA and Interval met for PublicationCode: " + $record.PublicationCode # + " SLA Met: $SLAMet Interval Met: $IntervalMet" 
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logfile 
#>

