<##############################################################################

File:		Get-Canvas.ps1
Name:		Get-Canvas

Purpose:	This is the main Canvas process. It will first try to identify if new 
			files have been dropped by Canvas. If it finds new files, Issue records
			will be created, the gzip files will be copied over to local fileshare,
			the gzip files will be unpacked to a text file and if the unpack was 
			successful it will fire off the staging packages and finally the GZIP 
			files will be cleared off.

Params:		

Called by:	Windows Scheduler
Calls:		n/a  

Errors:		

Author:		ochowkwale	
Date:		20190418
Version:    1.1.0.0

##############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20190418    ochowkwale      Initial Iteration Version:    1.1.0.0
20190919    ochowkwale      Passing the config file location to function below
##############################################################################>

<#

.SYNOPSIS
This script will download new data extracts based on a scheduled task 
call.

Example: \\bpe-aesd-cifs\powershellrepo\DM\DME1\DataHub\Get-Canvas.ps1 "\\bpe-aesd-cifs\powershellrepo\DM\DME1\DataHub\config\DataHubConfig.json" "UoR" "OMKAR"

#>
$ConfigFile = $args[0] # This should be the path for the config file.
$InstCode = $args[1]
$TaskName   = $InstCode +'_' + $args[2] # This is the specific task name.

if (!$ConfigFile) 
{
    $ConfigFile = "C:\Users\ffortunato\Source\Workspaces\BIDW\PowerShell\DataHub\config\envSpecific\AUTODMESBX_DataHubConfig.json"
}

if (!$InstCode) 
{
    $InstCode = "UoR"
}

if (!$TaskName) 
{
    $TaskNum    = Get-Random -minimum 1 -maximum 4
    $TaskName   = "Task_0" + $TaskNum 
}

#Get the config values from config file
$configFileContent = Get-Content $ConfigFile -Raw | ConvertFrom-Json

$dbServer           = $configFileContent.BPIServer.DatabaseServer
$runEnv             = $configFileContent.__Header.Env.EnvironmentAbbreviation
$modulePath         = $configFileContent.Paths.Module
$ScriptFile         = $configFileContent.Paths.Script + "Get-Canvas.ps1"
$logLocation        = ($configFileContent.Paths.CanvasLogLocation).Replace("InstCode",$InstCode) # "\\\\dsbxcvsapp01\\CanvasSync\\InstCode\\logs\\"
$logArchiveLocation = ($configFileContent.Paths.CanvasLogArchiveLocation).Replace("InstCode",$InstCode) # "\\\\dsbxcvsapp01\\CanvasSync\\InstCode\\logs\\"
$fileShareFolder    = ($configFileContent.Paths.CanvasFileShare).Replace("InstCode",$InstCode) # "\\\\bpe-aesd-cifs\\canvassync\\dev\\Canvas\\InstCode\\Inbound\\"
$fileArchiveFolder  = ($configFileContent.Paths.CanvasArchive).Replace("InstCode",$InstCode) # "\\\\bpe-aesd-cifs\\canvassync\\dev\\Canvas\\InstCode\\Inbound\\Archive\\"
$ConfigSync         = ($configFileContent.Paths.CanvasSyncConfigLocation).Replace("InstCode",$InstCode) # "C:\\Canvas-Data-Cli-master\\InstCode\\config.js"
$dataFolder         = ($configFileContent.Paths.CanvasDataFolder).Replace("InstCode",$InstCode) #"\\\\dsbxcvsapp01\\CanvasSync\\InstCode\\dataFiles\\"
$unpackFolder       = ($configFileContent.Paths.CanvasUnpackLocation).Replace("InstCode",$InstCode) # "\\\\dsbxcvsapp01\\CanvasSync\\InstCode\\unpackedFiles\\"
$CanvasCLITool      = $configFileContent.Paths.CanvasCLITool # "C:\\Canvas_Root\\npm\\canvasDataCli.cmd"

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
$datePrevStep = Get-Date
$date     = Get-Date
$dateU    = $date.ToUniversalTime()
$yyyymmdd  = Get-Date -format yyyyMMdd #hhmm  #ssms
$LogDaysToRetain = 7
$ArchiveDaysToRetain = '-2'
$Version  = "1.1.0.0"
[datetime] $periodEndDate = '01/01/1900 00:00 AM'
[datetime] $LastDumpDtm = '01/01/1900 00:00 AM'
$publisherCode = 'CANVAS-' + $InstCode
$logFile       = $logLocation + "00_" + $InstCode + "_Script_Main.txt"

$SqlCon = New-Object System.Data.SqlClient.SqlConnection
$SqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Integrated Security=True"

# Set the SMTP Server address
$smtpserver = $configFileContent.BPIServer.EmailServer
$from       = $configFileContent.eMail.From
$to         = $configFileContent.eMail.CanvasTo
$subject    = $runEnv + ' ' + "Canvas Process Failure" 
$emailBody  = @"
Failure:`t$runEnv DataHub.Get-Canvas

PID:`t`t$pid  
Date:`t`t$date 
UTCDate:`t$dateU
HostName:`t$curHost
DBName:`t$dbServer
User:`t`t$curUser
Script:`t`t$ScriptFile 
LogFile:`t`t$logFile

"@

#Import the dmutils module
if (Get-Module -ListAvailable -Name dmutils) 
{
	Remove-Module dmutils
}

$env:PSModulePath = $env:PSModulePath + $modulePath
Import-Module dmutils

# Prime the data table
[System.Data.DataTable] $dtPublicationList = New-Object Data.datatable

#Clearing the logs from archive older than 7 days
if(Test-Path $logfile)
{
    $filecreatedDtm = (Get-ChildItem $logfile).CreationTime
    
    if(($date - $filecreatedDtm).TotalDays -gt $LogDaysToRetain)
    {        
        #Clear the log archive location
		Remove-Item "$logArchiveLocation*.*"
		
		#Copy the contents from log location to Archive location           
        Move-Item -Path "$logLocation\*.txt" -Destination $logArchiveLocation
    }
}

#Start the process
Invoke-Nicelog -event 'Start' -message '--------------------------------------------------------------------------------' -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message 'Get-Canvas Initiated' -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message "env : $runEnv"   -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message "pid : $pid"      -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message "host: $curHost"  -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message "db  : $dbServer" -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message "usr : $curUser"  -logfile $logFile 
Invoke-Nicelog -event 'Info'  -message "args: $args"     -logfile $logFile 

#Clearing the Archive locations of folder older than 2 days
try {# determine how far back we go based on current date
	$del_date = $date.AddDays($ArchiveDaysToRetain)
	# gets the list of folders created 2 days ago
	$folderlist = Get-ChildItem $fileArchiveFolder -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $del_date }
}

catch {
    Invoke-Nicelog -event 'Info'  -message "Unable to list the archived files at: $fileArchiveFolder. Error message: " + $_.Exception.Message    -logfile $logFile
	continue
} 

try {
	# checks count and deletes folders if they were created 2 days ago	
	if($folderlist.Count -gt 0){
		Invoke-Nicelog -event 'Info'  -message "Removing older than 2 days files from archive location: $fileArchiveFolder"     -logfile $logFile
		$folderlist | Remove-Item -force -confirm:$false -Recurse -ErrorAction SilentlyContinue		 
	}
}
catch {
    Invoke-Nicelog -event 'Info'  -message "Unable to remove files from archive location: $fileArchiveFolder. Error Message: " + $_.Exception.Message   -logfile $logFile
	continue
} 

#Check if connection with database can be established
try 
{
    $customMessage = "Opening DB connection: $dbServer"
	Invoke-Nicelog -event 'Info'  -message $customMessage     -logfile $logFile

    $sqlCon.Open()
} 
catch 
{
	$customMessage = "Unable to open DB connection: $dbServer"
	Invoke-Nicelog -event 'Info'  -message $customMessage     -logfile $logFile
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logFile -err ([ref]$_) -cust $customMessage   -act "exit" 
    exit
}

#Check if new files have arrived
try
{
    Invoke-CanvasFileCheck `
        -ConfigSync    $ConfigSync `
		-LogFile       $logFile `
		-LastDumpDtm ([ref]$LastDumpDtm)

	$infoMessage = "Last Dump was found at: " + $LastDumpDtm
	Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $logfile 
}
catch
{
	$customMessage = "Failure with checking if the new files were dropped "
	Invoke-Nicelog -event 'Info'  -message $customMessage     -logfile $logFile 
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logFile -err ([ref]$_) -cust $customMessage   -act "exit" 
	exit
}


#Get the list of Canvas Publications
try
{
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[lms_canvas].[usp_LMS_GetPublicationList]", $SqlCon)
    $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $sqlCmd.Parameters.AddWithValue("@pPublisherCode", $publisherCode) | Out-Null
    $sqlCmd.Parameters.AddWithValue("@pVerbose", "0") | Out-Null
	$sqlCmd.Parameters.AddWithValue("@pETLExecutionId", "-1") | Out-Null
	$sqlCmd.Parameters.AddWithValue("@pPathId", "-1") | Out-Null
    $result = $sqlCmd.executereader()
	$dtPublicationList.Load($result)
	$SqlCon.CLose()
	$SqlCon.Dispose()
	$date = Get-Date
    $infoMessage = "Publication list successfully retrieved from database." 
    Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile    
}
catch
{
	$customMessage = "Unable to return results from stored procedure ctl.usp_GetPublicationList on $dbServer."
	$SqlCon.CLose()
    $SqlCon.Dispose()
	Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logFile    
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logFile -err ([ref]$_) -cust $customMessage   -act "exit" 
    exit
}


#Invoke-CanvasGet
try
{
    # Lets decide what to do for each of the publications in the active list.
    foreach ($record in $dtPublicationList)
    {   
		#Process the Publication only if new Canvas Dump is identified
		if($record.NextExecutionDtm -lt $LastDumpDtm)
		{
			# Adding blank line to the log file
			$infoMessage = "Initiating data feed retreival process. `t`t PublicationCode: " + $record.PublicationCode
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $logfile 

			$periodEndDate = $LastDumpDtm

			try
			{
				Start-Job `
				-Name $record.PublicationCode `
				-ScriptBlock `
				{param($dbServer, $PubName, $PubCode, $PubSSISFolder, $PubSSISProject, $PubSSISPackage, $periodEndDate,	$unpackFolder, $dataFolder, $fileShareFolder, $fileArchiveFolder, $ConfigSync, $logLocation, $ConfigFile) `
						Invoke-CanvasGet `
							-dbServer      $dbServer `
							-PubName       $PubName `
							-PubCode       $PubCode `
							-PubFldr       $PubSSISFolder `
							-PubPrj        $PubSSISProject `
							-PubPkg        $PubSSISPackage `
							-PeriodEndDate $periodEndDate `
							-UnpkLoc       $unpackFolder `
							-DFLoc         $dataFolder `
							-Inbound       $fileShareFolder `
							-Archive       $fileArchiveFolder `
							-ConfigSync    $ConfigSync `
							-LogLocation   $logLocation `
                            -ConfigContent $ConfigFile
				}-ArgumentList $dbServer, $record.PublicationName, $record.PublicationCode, $record.SSISFolder, $record.SSISProject, $record.SSISPackage, $periodEndDate, $unpackFolder, $dataFolder, $fileShareFolder, $fileArchiveFolder, $ConfigSync, $logLocation, $ConfigFile
			}
			catch
			{
				$customMessage = "Failure with checking if the new files were dropped " + $record.PublicationCode
				Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logfile -err ([ref]$_) -cust $customMessage   -act "exit" 
			}
		}
		else
		{
			$infoMessage = "No new dump is found for publication: " + $record.PublicationCode
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $logfile 
		}
	}
	#Wait for all the jobs to finish
	Get-Job | Wait-Job
}
catch
{
	$customMessage = "There were failures with some Canvas Files. Check the Issue Status for the Publications"
	Invoke-Nicelog -event 'Info' -message $customMessage -logfile $logFile    
	Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $logFile -err ([ref]$_) -cust $customMessage   -act "exit" 
    exit
}