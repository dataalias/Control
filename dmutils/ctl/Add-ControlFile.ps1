<##############################################################################
File:		Add-ControlFile.ps1
Name:		Add-ControlFile
Purpose:


Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunto
Date:		

###############################################################################

      CHANGE HISTORY

###############################################################################

Date		Author			Description

--------  ------------	---------------------------------------------------
20171206  ffortunato	Converting to a function.
20180208  ffortunato	Passing in the publication code.
						Formatting the control file.
20180327  ffortunato	Using native hash functions.
20180328  ffortunato	Lets make sure that we process the files in the 
						order they were created.
20180828  ffortunato	Passing the file mask rather than publication code.
						removing the Set-Location
##############################################################################>

#TODO
#Get this ready for pipe line.

function Add-ControlFile {

<#

.SYNOPSIS
This function looks at the provided directory and creates control files for
each file.

.DESCRIPTION
...

.PARAMETER directory
The directory with files that need control files generated.

.PARAMETER publicationCode
The code for the particular file being retreived.

.EXAMPLE
Add-ControlFile -dir "\\bpe-aesd-cifs\bi_admin_qa\FileShare\Civitas\inbound" -pc "Inspire_Engagement_Report" -fm "Inspire_Engagement_Report_([0][1-9]|[1][0-2])-([0][1-9]|[1][0-9]|[2][0-9]|[3][0-1])-([19]|[20])\d{2}"

#>


    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
        [parameter(Mandatory=$true,
            Position = 0,
            HelpMessage=’The folder to look for files that do not already have a control.’
            )]
        [alias("directory")]
        [string]$dir,
		
        [parameter(Mandatory=$true,
            Position = 1,
            HelpMessage=’This is the publication code for the files being retrieved.’
            )]
        [alias("pc")]
        [string]$publicationCode,
	
        [parameter(Mandatory=$false,
            Position = 2,
            HelpMessage=’File Mask being processed.’
            )]
        [alias("fm")]
        [string]$fileMask	

	)

begin
{

}
process
{
try
{
if ($dir -eq $null)
{
	throw "No directory provided. Mandatory field cannot be null or blank."
	return 1001
}

#Set-Location $dir | Out-Null

$date = date
$ctlExtension = ".ctl"
$version = "1.0.0.0"
$timeZone = 'PST'

# Get-ChildItem $dir -File -filter "$publicationCode*" | Sort -Property @{ Expression = {$_.CreationTime} } | ForEach-Object {

Get-ChildItem  -Path $dir -File | Where-Object { $_.Name -match $fileMask } |  Sort -Property @{ Expression = {$_.CreationTime} } | ForEach-Object {

# Determine the file we are working with.
    $inFile    = $_.FullName
    $extension = $_.Extension
	$inFileNameOnly = $_.Name
	$createDate = $_.CreationTime

# See if the contorl file is present. If so do not generate a ctl file.
	$controlFile = $inFile.Replace($extension,$ctlExtension) 

	if ((-not (Test-Path $controlFile)) -and ($extension -ne '.ctl'))
	{
	# Get the record count
		$recCount = @(Get-Content $inFile).Length

	# Determine the hash for the file

		$ScriptHashObj  = Get-FileHash  -Algorithm SHA256 -LiteralPath $inFile
		$hash           = $ScriptHashObj.Hash.ToString()

	# get the first record checksum
<#
		$firstLine = Get-Content -Path $inFile -First 1

		if (($firstLine -eq $null) -or ($firstLine -eq ''))
		{
			$firstHash = 'N/A'
		}
		else
		{
			$firstHash = Get-StringHash($firstLine)	
		}
#>
		$firstHash = 'N/A'
		$LastHash = 'N/A'

		"Publication Code=" + $publicationCode | Out-File $controlFile
		"Version="       + $version   | Out-File $controlFile -Append
		"File Name="     + $inFileNameOnly     | Out-File $controlFile -Append
		"File Checksum=" + $hash      | Out-File $controlFile -Append
		"Record Count="  + $recCount  | Out-File $controlFile -Append
		"First Record Checksum=" + $firstHash  | Out-File $controlFile -Append
		"Last Record Checksum="  + $lastHash   | Out-File $controlFile -Append
		"File Generated Datetime=" + $createDate   | Out-File $controlFile -Append
		"UTC Offset="     + $timeZone | Out-File $controlFile -Append
		"EOF"                         | Out-File $controlFile -Append
	} #if file does not exist.
<#
	else
	{
		"Hurray, control file found: $controlFile"
	}
#>
} # ForEach-Object
} # try
catch
{
	throw $_.Exception.Message
	return $null
} # catch
} # process
end
{

} #end
} #function

export-modulemember -function Add-ControlFile