<##############################################################################

File:		CanvasGet.ps1
Name:		CanvasGet

Purpose:    This function gets CANVAS zipped files into a datafiles folder,
			unpacks them in unpacked files location	and then removes zipped files 
			from datafiles folder
			
Called by:	
Calls:		n/a  

Errors:		

Returns:	

Author:		ochowkwale
Date:		20190415
Version:    1.2.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20190415    ochowkwale      Initial Iteration Version:    1.2.0.0
20190919    ochowkwale      Timeout of 30 minutes for fetching the GZIP files
##############################################################################>

function Invoke-CanvasGet {

<#
.EXAMPLE
Invoke-CanvasGet `
    -PublicationName   "discussion_entry_dim" `
    -UnpkLoc  "\\bpe-aesd-cifs\BI_Admin_dev\FileShare\OIE\inbound\" `
	-DFLoc "D:\CanvasSync\UoR\dataFiles\" `
    -ConfigSync    "C:\Canvas-Data-Cli-master\UoR\config.js" `
    -LogFile "\\dsbxcvsapp01\CanvasSync\UoR\logs\" 
#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Server’
		)]
		[alias("ser")]
		[string]$dbServer
		
		,[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’Publication Name’
		)]
		[alias("pn")]
		[string]$PubName

		,[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’Publication Code’
		)]
		[alias("pc")]
		[string]$PubCode

		,[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’Publication SSIS FOlder’
		)]
		[alias("psf")]
		[string]$PubFldr

		,[parameter(Mandatory=$true,
		Position = 4,
		HelpMessage=’Publication SSIS Project’
		)]
		[alias("pspr")]
		[string]$PubPrj

		,[parameter(Mandatory=$true,
		Position = 5,
		HelpMessage=’Publication SSIS Package’
		)]
		[alias("pspa")]
		[string]$PubPkg

		,[parameter(Mandatory=$true,
		Position = 6,
		HelpMessage=’PeriodEnddate for Issue’
		)]
		[alias("ped")]
		[datetime]$PeriodEndDate

		,[parameter(Mandatory=$true,
		Position = 7,
		HelpMessage=’Location where files will be unpacked’
		)]
		[alias("ul")]
		[string]$UnpkLoc

		,[parameter(Mandatory=$true,
		Position = 8,
		HelpMessage=’Location where files will be downloaded’
		)]
		[alias("dl")]
		[string]$DFLoc

		,[parameter(Mandatory=$true,
		Position = 9,
		HelpMessage=’Location where issued files will be copied’
		)]
		[alias("cl")]
		[string]$Inbound

		,[parameter(Mandatory=$true,
		Position = 10,
		HelpMessage=’Location where issued files will be archived’
		)]
		[alias("al")]
		[string]$Archive

		,[parameter(Mandatory=$false,
		Position = 11,
		HelpMessage = 'Canvas config file')]
		[alias("con")]
		[string]$ConfigSync

		,[parameter(Mandatory=$false,
		Position = 12,
		HelpMessage = 'Canvas log file location')]
		[alias("ldir")]
		[string]$LogLocation
        
        ,[parameter(Mandatory=$false,
		Position = 13,
		HelpMessage = 'Email Content')]
		[alias("ConfigContent")]
		[string]$ConfigFile
)

BEGIN
{
	$date = Get-Date
	$periodStartDate = $PeriodEndDate.AddDays(-1)
	$yyyymmdd  = ($PeriodEndDate).ToString("yyyyMMdd")
	$hhmmss = ($PeriodEndDate).ToString("HHmmss")

	$curUser  = whoami
	$IssueId = -1
    $val = 0
    $FileCorrectCounter = 0

	#Prep the file names going to be used
	$unpackFileName = $PubName
    $jobName = $PubName + $PubCode
    $fromFile  = $UnpkLoc +  $unpackFileName + '.txt'
	$issueFile = $unpackFileName + '_' + $yyyymmdd +'_' + $hhmmss +'.txt'
    $issueFileName = $Inbound + $PubCode + '-' + $yyyymmdd +'-' + $hhmmss +'.txt'
    $toFile    = $UnpkLoc +  $PubCode + '-' + $yyyymmdd +'-' + $hhmmss +'.txt'
	$CanvasOutput  = $LogLocation + $unpackFileName + '.txt'		
    
    $configFileContent = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    $runEnv     = $configFileContent.__Header.Env.EnvironmentAbbreviation
    $smtpserver = $configFileContent.BPIServer.EmailServer
    $from       = $configFileContent.eMail.From
    $to         = $configFileContent.eMail.CanvasTo
	$timeout	= $configFileContent.Limiters.DownloadTimeOutSeconds
    $subject    = $runEnv + ' ' + "Canvas Process Failure" 
    $emailBody  = "Failure:`t$runEnv invoke-CanvasGet "
} # Begin

PROCESS
{
    try
    {
		Invoke-Nicelog -event 'Start' -message '--------------------------------------------------------------------------------' -logfile $CanvasOutput 
		
		$sqlCon = New-Object System.Data.SqlClient.SqlConnection
		$sqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Integrated Security=True"
		$sqlCon.Open()

		#Create Issue Record
		try 
		{	
			New-Issue -sqlCon $sqlCon  -pubn $PubCode -dfn $issueFileName `
				-s 'IP' -sId 0 -sDt $PeriodEndDate -fid 0 -lid 0 -fchk 0 `
				-lchk 0 -psd $periodStartDate -ped $PeriodEndDate -rc 0 -ETLId 0 `
				-usr $curUser -iss ([ref]$IssueId)

			if($IssueId -ne -1)
			{
				$infoMessage = "Issue record was created: " + $IssueId
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput 
			}
			else
			{
				throw $IssueId
			}
		}
		catch 
		{
			$errorMessage = "Unable to write the issue record. System Message: " + $_.Exception.Message
			Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			throw $errorMessage
		} # catch
		
		#Create archive folder for files in inbound location
		try
		{
			if (!(Test-Path ($Archive + $yyyymmdd +'-' + $hhmmss)))
			{
				New-Item -Path ($Archive + $yyyymmdd +'-' + $hhmmss) -ItemType Directory
			}
		}
		catch
		{
			$infoMessage = "Unable to create the archive folder. Error message: " + $_.Exception.Message
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
		}

        while($FileCorrectCounter -le 1)# Retries if file is empty
        {		
		    #Fetch the GZIP files
		    try
		    {
                while($val++ -le 4)# Retry downloading GZIP files if stuck
                {
                    Start-Job `
                    -Name $jobName `
                    -ScriptBlock `
                    {param($CanvasOutput, $issueFileName, $toFile, $configSync, $unpackFileName, $issueFile) `
                        Invoke-CanvasGetCompressedFiles `
	                        -logfile       $CanvasOutput `
	                        -in            $issueFileName `
	                        -File          $toFile `
	                        -config        $configSync `
	                        -UnPkFileName  $unpackFileName `
	                        -issue         $issueFile
                    }-ArgumentList $CanvasOutput, $issueFileName, $toFile, $configSync, $unpackFileName, $issueFile

                    $done = Invoke-Command -Command {Wait-Job -Name $jobName -Timeout $timeout}

                    if($done.Count -eq 0)
                    {
                        Stop-Job -Name $jobName
                        $removeFolder = $DFLoc + $unpackFileName
			            Remove-Item $removeFolder -recurse

                        $infoMessage = "Fetch failed. Retry fetching the GZIP files"
			            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
                    }
                    else
                    {                    
                        break
                    }

                    if($val -eq 4){throw 400}
                }# Retry downloading GZIP files if stuck
		    }
            catch
		    {
			    $errorMessage = "Unable to fetch the GZIP files. System Message: " + $_.Exception.Message
			    Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			    throw $errorMessage
		    }
            
                
		    #Unpack the GZIP files
		    try
		    {
                $infoMessage = "Start unpacking the GZIP files"
			    Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

			    if (Test-Path $issueFileName){
                    $infoMessage = "The file has already been fetched, unpacked and copied to fileshare: " + $issueFileName
				    Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
                }
			    else
                {
                    if (Test-Path $toFile)
					{
                        $infoMessage = "The file has already been fetched, unpacked to location: " + $toFile
				        Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
                    }
                    else
                    {
			            canvasDataCli unpack -c $configSync -f $unpackFileName  | Out-File $CanvasOutput -Append
			            $infomessage = "Unpacked        : " + $issueFile
			            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
                    }
                }
		    }
            catch
		    {
			    $errorMessage = "Unable to unpack the GZIP files. System Message: " + $_.Exception.Message
			    Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			    throw $errorMessage
		    }  
            
            #Check the file if it has zero records in it
            $property = Get-ItemProperty $fromFile

            if ($property.Length -lt 10000)
            {
                $dataRecords = Get-Content $fromFile | Measure-Object -Line
                if ($dataRecords.Lines -eq 1)
                {
                    $infomessage = "Downloaded file is not valid. The file contains no records"
		            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
        
                    $removeFolder = $DFLoc + $unpackFileName
		            Remove-Item $removeFolder -recurse
		            $infoMessage = "Removed         : " + $removeFolder
		            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

		            Remove-Item $fromFile
		            $infoMessage = "Removed         : " + $fromFile
		            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
            
                    $FileCorrectCounter = $FileCorrectCounter + 1
                    $infoMessage = "Starting the re-download"
		            Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput     

                    if ($FileCorrectCounter -gt 1)
                    {
                        $errorMessage = "Error downloading the files"
			            Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			            throw $errorMessage
                    }
                                               
                }
                else
                {
                    break       
                }
            }
            else
            {
                break
            }
      
        }# Retries if file is empty
		#Rename the file to include current date
		try
		{
            $infoMessage = "Rename the file to include current date"
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

			if (Test-Path $issueFileName)
			{
                $infoMessage = "The file has already been fetched, unpacked and copied to fileshare: " + $issueFileName
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
            }
			else
            {
                if (Test-Path $toFile)
				{
                    $infoMessage = "The file has already been fetched, unpacked to location: " + $toFile
				    Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
                }
                else
                {
			        Rename-Item $fromFile $toFile
        			$infomessage = "Renamed        : " + $toFile
		        	Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
                }
            }
		}
        catch
		{
			$errorMessage = "Unable to rename the unpacked files. System Message: " + $_.Exception.Message
			Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			throw $errorMessage
		}         
		     
		#copy the file to inbound location and remove the file from unpacked location
		try
		{
            $infoMessage = "Copy the file to inbound fileshare folder location"
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

			if (Test-Path $issueFileName)
			{
                $infoMessage = "The file has already been fetched, unpacked and copied to fileshare: " + $issueFileName
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
            }
			else
            {
			    Copy-Item $toFile $Inbound
			    $infoMessage = "Copied         : " + $issueFile + " to location: " + $Inbound
			    Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput			
            }
		}
        catch
		{
			$errorMessage = "Unable to copy files to location: " + $Inbound + " System Message: " + $_.Exception.Message
			Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			throw $errorMessage
		}         
		
		#fire-off staging package
		try 
		{	# GetIssue Information to fire job.
			Invoke-StagingPackage `
				-dbsvr   $dbServer `
				-Folder  $PubFldr `
				-Project $PubPrj `
				-Package $PubPkg `
				-IssueId $IssueId `
				-logFile $CanvasOutput

			$infoMessage = "Staging process initiated for Issue: " + $IssueId
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
		}
		catch 
		{
			$errorMessage = "Unable to fire staging. System Message: " + $_.Exception.Message
			throw $errorMessage
		}

		#remove the old gzip file and unpacked files...
		try
		{
			$removeFolder = $DFLoc + $unpackFileName
			Remove-Item $removeFolder -recurse
			$infoMessage = "Removed         : " + $removeFolder
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

			Remove-Item $toFile
			$infoMessage = "Removed         : " + $toFile
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
		}
        catch
		{
			$errorMessage = "Unable to delete the GZIP files or unpacked files. System Message: " + $_.Exception.Message
			Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
			throw $errorMessage
		}  
    }
    catch  [Exception]
    {
		try
		{
			$infoMessage = "Issue Failed         : " + $IssueId
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

			$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateIssue]", $SqlCon)
			$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
			$sqlCmd.Parameters.AddWithValue("@pIssueId", $IssueId) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pStatusCode", "IF") | Out-Null
			$sqlCmd.executereader()
			$sqlCon.Close()
			
			$errorMessage = "Error with the function Invoke-CanvasGet. " + $_.Exception.Message  + "PublicationCode =" + $PubCode          
			Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $CanvasOutput -err ([ref]$_) -cust $errorMessage   -act "exit"
		}
		catch
		{
			$errorMessage = "Unable to fail the IssueId: " + $IssueId + " System Message: " + $_.Exception.Message
			Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput
			Invoke_ErrorHandler -svr $smtpserver -t $to  -from $from -s $subject -b $emailBody -log $CanvasOutput -err ([ref]$_) -cust $errorMessage   -act "exit"
		}			     
    }
	$sqlCon.Close()
	return $null
} # Process

END
{
	if (($CanvasOutput  -ne $null) -and ($CanvasOutput.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-CanvasGet"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $CanvasOutput 
	} 
} # End

} # Function Invoke-CanvasGet

export-modulemember -function Invoke-CanvasGet
