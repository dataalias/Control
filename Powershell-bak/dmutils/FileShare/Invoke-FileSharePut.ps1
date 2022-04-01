<##############################################################################

File:		FileSharePut.ps1
Name:		FileSharePut

Purpose:    This function copies a file from one share to another. Assumes
			a single file is being copied to a single destination.

Called by:	
Calls:		n/a  

Errors:		

Returns:	0	 successful run.
			1001 no files found to xfer


Author:		ffortunato
Date:		20190205
Version:    1.2.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20190205    ffortunato      Initial Iteration Version:    1.2.0.0
20190306	ochowkwale		Logic for exporting files to FileShare location

##############################################################################>

function Invoke-FileSharePut {

<#

.SYNOPSIS
This function 

.DESCRIPTION


.PARAMETER fileMask


.EXAMPLE
Invoke-FileSharePut `
    -srcDir   "\\bpe-aesd-cifs\BI_Admin_dev\FileShare\OIE\outbound\" `
    -destDir  "\\bpe-aesd-cifs\BI_Admin_dev\FileShare\OIE\inbound\" `
    -pubnc    "BEHAVE" `
    -fileMask "AU\sMGMT\sPL\sDTL\sMTM\s([0][1-9]|[1][1-2]).[0-9]{4}\.xlsx$" `
    -logFile  "C:\tmp\FileCopy.log"
    

#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Server used’
		)]
		[alias("ser")]
		[string]$dbServer

		,[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’File name to be copied.’
		)]
		[alias("fn")]
		[string]$IssueName

		,[parameter(Mandatory=$false,
		Position = 2)]
		[alias("rdir")]
		[string]$srcDir

		,[parameter(Mandatory=$false,
		Position = 3)]
		[alias("ldir")]
		[string]$destDir

		,[parameter(Mandatory=$false,
		Position = 4)]
		[alias("log","l")]
		[string]$logFile

)

BEGIN
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-FileSharePut -fileName $IssueName -srcDir $srcDir -destDir $destDir" # -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # Begin

PROCESS
{

	# Declarations
	$ErrorActionPreference = 'Stop'
	[string]$fullyQualifiedFileName = Join-Path $srcDir $IssueName

    try
    {
		# Check that source exists
		# Check the destination directory exists
		# Check that file does not already exist in destination
		# Copy the file
		Copy-Item $fullyQualifiedFileName $destDir

    }
    catch  [Exception]
    {
		$errorMessage = "Error with the function Invoke-FileSharePut. " + $_.Exception.Message
        throw $errorMessage
    }

	return $null

} # Process

END
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-FileSharePut"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	} 
} # End

} # Function Invoke-FileSharePut

export-modulemember -function Invoke-FileSharePut

