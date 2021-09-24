<##############################################################################

File:		CanvasFileCheck.ps1
Name:		CanvasFileCheck

Purpose:    This function will check if new files are arrived
			
Called by:	
Calls:		n/a  

Errors:		

Returns:	

Author:		ochowkwale
Date:		20190418
Version:    1.1.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20190418    ochowkwale      Initial Iteration Version:    1.1.0.0
##############################################################################>

function Invoke-CanvasFileCheck {

<#
.EXAMPLE
Invoke-CanvasFileCheck `
    -ConfigSync    "C:\Canvas-Data-Cli-master\UoR\config.js" `
	-LastDumpValue "\\dsbxcvsapp01\CanvasSync\UoR\logs\LastDumpValue.dat" `
    -LogFile "\\dsbxcvsapp01\CanvasSync\UoR\logs\UoR_Script_20190418.txt" 
#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$false,
		Position = 0,
		HelpMessage = 'Canvas config file')]
		[alias("con")]
		[string]$ConfigSync

		,[parameter(Mandatory=$false,
		Position = 1,
		HelpMessage = 'Canvas log file')]
		[alias("ldir")]
		[string]$LogFile

		,[parameter(Mandatory=$true,
		Position = 2)]
        [alias("LastDumpDtm")]
        [ref]$myLastDumpDtm
)

BEGIN
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-CanvasFileCheck"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # Begin

PROCESS
{
    try
    {
		[datetime] $periodEndDate = '01/01/1900 00:00 AM'
		$date     = Get-Date
		$dumpListArray = @(canvasDataCli list -c $configSync)

	    $dumpId = $dumpListArray[0].Substring(13,36)
		[datetime]$createdDtm = $dumpListArray[6].Substring(14,24)  #This needs to be added to the IssueRecord SrcDFCreatedDate

    }
    catch  [Exception]
    {
		$infomessage = "Error           : " + $date + "`t Message    : " + $_.Exception.Message + " Unable to determine if new files from publisher are ready."
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
		throw $infoMessage
    }
	$myLastDumpDtm.Value = $createdDtm
} # Process
END
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-CanvasFileCheck"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	} 
} # End

} # Function Invoke-CanvasFileCheck

export-modulemember -function Invoke-CanvasFileCheck
