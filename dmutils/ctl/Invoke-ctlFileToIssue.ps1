
<##############################################################################

File:		Invoke-ctlFileToIssue.ps1
Name:		Invoke-ctlFileToIssue
Purpose:	This script is responsible for several activities.
              1) Look through specific file folder for all ctl files.
                  a) Ensure the file hasn't been loaded already.
              2) Parse all ctl files for date feed meta data
              3) Load meta data into ctl.Issue table
              4) Execute Staging SSIS package

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

--------	--------------	---------------------------------------------------
20170419	ffortunato		change to a better method to call stored procudures
							setting parameters accordingly.

20170427	ffortunato		chainging the InsertNewIssue procedure to return
                           the required package information.

20170427  ffortunato		Adding step to call package.
20180312  ffortunato		Only call the staging package if you got a good 
							IssueId back.

20180312  ffortunato		Squishing bug: for IssueId
							"System.Object[]" value of type "System.Object[]"
							to type "System.Int32"

20180322  ffortunato		Added logging

20180328  ffortunato		Lets make sure that we process the files in the
							order they were created.
							HAX making procedure wait 2 minutes before firing
							the same SSIS package a second time.

20180828  ffortunato		Using the file Mask.

20181012  ffortunato		Using the calling procedure sql connection.

20181016  ffortunato		Getting rid of set location.
##############################################################################>

###############################################################################
#
# Declarations / Initializations
#
###############################################################################

function Invoke-ctlFileToIssue {

<#
.SYNOPSIS
This function invokes a ETL catalog package.

.DESCRIPTION
This function receives catalog information for a specific package then 
shedules and executes the process.

.PARAMETER
$dbServer

.PARAMETER

.EXAMPLE
Invoke-ctlFileToIssue  -db '.' -dir '' -pc 'OIE_BEHAVE' -fld '' -prj '' -pkg ''

#>

    [CmdletBinding()] 
    param(

		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db to cehck files with’
		)]
		[alias("dbs","dbsvr")]
		[string]$dbServer
		
		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Acctive connection to the database being queried’
		)]
		[alias("sc")]
		$sqlCon
 
        ,[parameter(Mandatory=$true, 
		Position=1)]
		[alias("d","directory")]
        [string]$dir

 		,[parameter(Mandatory=$true,
		Position = 2)]
		[alias("pc")]
		[string]$publicationCode = 'N/A'

 		,[parameter(Mandatory=$true,
		Position = 3)]
		[alias("fm")]
		[string]$fileMask = 'N/A'

        ,[parameter(Mandatory=$false, 
		Position=4)]
	    [alias("fld")]
        [string]$SSISFolder

        ,[parameter(Mandatory=$false, 
		Position=5)]
	    [alias("prj")]
        [string]$SSISProject

		,[parameter(Mandatory=$false, 
		Position=6)]
	    [alias("pkg")]
        [string]$SSISPackage

		,[parameter(Mandatory=$false, 
		Position=7)]
	    [alias("log")]
        [string]$logFile
    )
begin
{
<#TESTING
	'begin Invoke-ctlFileToIssue'
<##>

	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = 'Starting Invoke-ctlFileToIssue'
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
	}
}
process
{

# Set-Location $dir

[string]$curUser = whoami
[string]$CrLf = "`r`n"
[string]$firstRecChk = 'Unknown'
[string]$lastRecChk  = 'Unknown'
[int]   $IssueId     = -2
[int]   $cntEnforeDelay = 0

###############################################################################
#
# Main
#
###############################################################################

# Lets find the control files and then get their data into the database.
# Lets make sure that we process the files in the order they were created.

# Get-ChildItem $dir -File -filter "$publicationCode*.ctl" | Sort -Property @{ Expression = {$_.CreationTime} } | ForEach-Object {
Get-ChildItem  -Path $dir -File | Where-Object { $_.Name -match $fileMask } |  Sort -Property @{ Expression = {$_.CreationTime} } | ForEach-Object {
    
	
	$inFile = $_.FullName -replace $_.Extension, ".ctl"
	# $inFile    = $_.FullName
    # $ctlExt    = $_.Extension
    # $fileBase  = $_.BaseName

    $reader = [System.IO.File]::OpenText($inFile)
    try 
	{
		# Now read every line in the control file for data that we need in the db
        for() 
		{
            $line = $reader.ReadLine()
            if ($line -eq $null)
			{ 
				break 
			}
            # process the line
            # $line
            switch -wildcard ($line) 
                { 
                    "Publication Code=*"        {$pubnCode = $line -replace "Publication Code=",''} 
                    "Version=*"                 {$version = $line -replace "Version=",''} 
                    "File Name=*"               {$dataFileName = $line -replace "File Name=",''} 
                    "File Checksum=*"           {$fileChecksum = $line -replace "File Checksum=",''} 
                    "Record Count=*"            {$recCnt = $line -replace "Record Count=",''} 
                    "First Record Checksum=*"   {$firstRecChk = $line -replace "First Record Checksum=",''} 
                    "Last Record Checksum=*"    {$lastRecChk = $line -replace "Last Record Checksum=",''} 
                    "File Generated Datetime=*" {$fileGenDate = $line -replace "File Generated Datetime=",''} 
                    "UTC Offset=*"              {$timeZone = $line -replace "UTC Offset=",''} 
                    "EOF=*"                     {$EOF = $line  -replace "EOF=",''}  
                    default                     {""}
                } #switch
        } #for loop through file lines
    } # try - looping through data within control files.
    catch 
	{
	    $reader.Close()
		$errorMessage = "Unable to parse the contorl file: $infile $CrLf System Message: " + $_.Exception.Message
		throw $errorMessage 
	} # catch
    finally 
	{
        $reader.Close()
    } # finally

    try 
	{

		# GetIssue Information to fire job.
		New-Issue -sqlCon    $sqlCon  -pubn $pubnCode -dfn $dataFileName `
			-s 'IP' -sId 0 -sDt $fileGenDate -fid 0 -lid 0 -fchk $firstRecChk `
			-lchk $lastRecChk -psd '1/1/1970' -ped '1/1/1970' -rc $recCnt -ETLId 0 `
			-usr $curUser -iss ([ref]$IssueId)


<#TESTING

	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "@
			Here is what I got from the control file:
			Publication Code=* + $pubnCode
			Version=*  + $version
			File Name=*  + $dataFileName
			File Checksum=*  + $fileChecksum 
			Record Count=*  + $recCnt
			First Record Checksum=*  + $firstRecChk 
			Last Record Checksum=*  + $lastRecChk
			File Generated Datetime=*  + $fileGenDate
			UTC Offset=*  + $timeZone
			EOF=*  + $EOF
			db +	$dbServer
			Folder  $SSISFolder 
			Project $SSISProject 
			Package $SSISPackage 
			IssueId $IssueId
@"
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
	}

<##>
	} # try
	catch 
	{
		$errorMessage = "Unable to write the issue record for: $infile $CrLf IssueId: $IssueId $CrLf System Message: " + $_.Exception.Message
		throw $errorMessage 

    } # catch

	try
	{
		# Fire the laser.
		# Hax we want to delay this from firing again 
		if ($IssueId -gt 0)
		{

			if ($cntEnforeDelay -gt 0)
			{
				#HAX Wait 2 minutes before staring a second time.
				$infoMessage = 'Second run of package waiting 2 minutes before firing. HAX.'
				Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
				Start-Sleep -s 120
			}

			Invoke-StagingPackage `
				-dbsvr   $dbServer `
				-Folder  $SSISFolder `
				-Project $SSISProject `
				-Package $SSISPackage `
				-IssueId $IssueId `
				-logFile $logFile

			$cntEnforeDelay = $cntEnforeDelay + 1
		}

    } # try
    catch 
	{
		$errorMessage = "Failure with Invoke-StagingPackage :: " + $_.Exception.Message
		throw $errorMessage 

    } # catch


} # Looping through files. Get-ChildItem
} # process
end
{

	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = 'Ending Invoke-ctlFileToIssue'
		Invoke-Nicelog -event 'Info' -message   $infoMessage -logfile   $logFile
	}

} # end
} # function

export-modulemember -function Invoke-ctlFileToIssue