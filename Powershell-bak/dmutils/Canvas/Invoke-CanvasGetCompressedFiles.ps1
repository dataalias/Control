<##############################################################################

File:		CanvasGetCompressedFiles.ps1
Name:		CanvasGetCompressedFiles

Purpose:    This function gets CANVAS zipped files to the local server
			
Called by:	
Calls:		n/a  

Errors:		

Returns:	

Author:		ochowkwale
Date:		20190919
Version:    1.1.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20190919    ochowkwale      Initial Iteration Version:    1.1.0.0
##############################################################################>

function Invoke-CanvasGetCompressedFiles {

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
		HelpMessage=’logfile’
		)]
		[alias("logfile")]
		[string]$CanvasOutput
		
		,[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’Issue Name’
		)]
		[alias("in")]
		[string]$issueFileName

		,[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’toFile’
		)]
		[alias("File")]
		[string]$toFile

		,[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’Configuration file’
		)]
		[alias("config")]
		[string]$configSync

		,[parameter(Mandatory=$true,
		Position = 4,
		HelpMessage=’unpackFileName’
		)]
		[alias("UnPkFileName")]
		[string]$unpackFileName

		,[parameter(Mandatory=$true,
		Position = 5,
		HelpMessage=’issueFile’
		)]
		[alias("issue")]
		[string]$issueFile
)

BEGIN
{
	$date = Get-Date
} # Begin

PROCESS
{
    #Fetch the GZIP files
	try
	{
        $infoMessage = "Start fetching the GZIP files"
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput

		if (Test-Path $issueFileName){
            $infoMessage = "The file has already been fetched, unpacked and copied to fileshare: " + $issueFileName
			Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
        }
		else
        {
            if (Test-Path $toFile){
                $infoMessage = "The file has already been fetched, unpacked to location: " + $toFile
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput
            }
            else
            {
				canvasDataCli fetch  -c $configSync -t $unpackFileName  | Out-File $CanvasOutput -Append
				$infoMessage = "Fetched         : " + $issueFile
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile $CanvasOutput 
            }
		}
	}
    catch
	{
		$errorMessage = "Unable to fetch the GZIP files. System Message: " + $_.Exception.Message
		Invoke-Nicelog -event 'Info' -message   $errorMessage -logfile $CanvasOutput 
		throw $errorMessage
	}           	
	return $null
} # Process

END
{
	if (($CanvasOutput  -ne $null) -and ($CanvasOutput.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-CanvasGetCompressedFiles"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $CanvasOutput 
	} 
} # End

} # Function Invoke-CanvasGet

export-modulemember -function Invoke-CanvasGetCompressedFiles
