<##############################################################################

File:		FileShareListCheckGet.ps1
Name:		FileShareListCheckGet

Purpose:    This function invokes the WinSCP dll to list available files, check
			to see if they have previously been retreived and get any un-
			processed files to the landing zone.

Called by:	
Calls:		n/a  

Errors:		

Returns:	0	 successful run.
			1001 no files found to xfer


Author:		ffortunato
Date:		20180214
Version:    1.2.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20180214    ffortunato      Initial Iteration
20180226    ffortunato      Checking to see if there are any files to add an
							issue to...
20180307    ffortunato      Sending a $dbServer to this as well.
20180322	ffortunato		more expressive error handling.
20180326	ffortunato		bringing in additional logging to support QA.
20180706	ffortunato		Doing more to preserve the order of the files.
							https://bridgepoint.atlassian.net/browse/DW-2234

20180827	ffortunato		Using the file mask now.
20181012	ffortunato		using calling procedure sql connection.
20181203	ffortunato		More Logging. 
							Cleaning up Readers. 
							Version:    1.2.0.0

##############################################################################>

function Invoke-FileShareListCheckGet {

<#

.SYNOPSIS
This function invokes the WinSCP dll to _list_ files on a remote server based 
on the parameters passed.	The list will be verfied against processed issues.
Any files that have not previously been processed will be retrieved from the 
remote host.

.DESCRIPTION
This cmdlet requires an installation of WinSCP at C:\Program Files (x86)\WinSCP\WinSCPnet.dll 

.PARAMETER fileMask
Mask of the file to be transfered. This can include wildcards

.EXAMPLE
Invoke-FileShareListCheckGet `
	-dbServer "DME1EDLSQL01" `
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

<#
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Db to cehck files with’
		)]
		[alias("dbs")]
		[string]$dbServer
#>		
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Acctive connection to the database being queried’
		)]
		[alias("sc")]
		$sqlCon

		,[parameter(Mandatory=$false,
		Position = 1)]
		[alias("rdir")]
		[string]$srcDir

		,[parameter(Mandatory=$false,
		Position = 2)]
		[alias("ldir")]
		[string]$destDir

		,[parameter(Mandatory=$true,
		Position = 3)]
		[alias("pubnc","pc")]
		[string]$publicationCode = 'N/A'

		,[parameter(Mandatory=$false,
		Position = 4)]
		[alias("mask","fm")]
		[string]$fileMask = 'N/A'

		,[parameter(Mandatory=$false,
		Position = 5)]
		[alias("log","l")]
		[string]$logFile

)

BEGIN
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-FileShareListCheckGet -dbServer $dbServer -srcDir $srcDir -destDir $destDir -pubnc $publicationCode -fileMask $fileMask " # -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # Begin

PROCESS
{
	# Declarations
	$ErrorActionPreference = 'Stop'

<#TESTING
"Source: $srcDir"
"Destin: $destDir"
"Public: $publicationCode"
"FMask:  $fileMask"
#>


	# The name of a file and extension. No path information.
	[string]$fileName = 'N/A'

    # Prime the data table
    [System.Data.DataTable] $dtFileList = New-Object Data.datatable
    $dtFileList.Columns.Add("IssueName")      | Out-Null
    $dtFileList.Columns.Add("FileAction")     | Out-Null
	$dtFileList.Columns.Add("FileCreatedDtm") | Out-Null

    try
    {
		
		#test to see if files exists that we are interested in. If not break.
		#$tstDir = $srcDir + $publicationCode + "*"
		if (-not(Test-Path -path $srcDir))
		{
			# No files found escaping out of here'
			$infoMessage = "Unable to find file location: $srcDir No files found to process."
			Invoke-Nicelog -event 'Warn' -message $infoMessage -logfile $logFile
			$infoMessage = "Completed Invoke-FileShareListCheckGet"
			Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			return $null
		}

		# listing the files available
		try
        {

			#Get-ChildItem -Path $srcDir -File -filter "$publicationCode*" | ForEach-Object `
			Get-ChildItem  -Path $srcDir -File | Where-Object { $_.Name -match $fileMask } | ForEach-Object `
			{
                $DR = $dtFileList.NewRow()   #Creating a new data row
                $DR.Item("IssueName")      = $_.Name
                $DR.Item("FileAction")     = 'List'
				$DR.Item("FileCreatedDtm") = $_.LastWriteTime
                $dtFileList.Rows.Add($DR)
            }

			if ($dtFileList.Rows.Count -lt 1)
			{				
				#"Get out of here. No files on remote site that match our values."
				if (($logFile -ne $null) -and ($logFile.Length -gt 0))
				{
					$infoMessage = "No files found for PublicationCode: $publicationCode"
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
					$infoMessage = "Completed Invoke-FileShareListCheckGet"
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				}
				return $null
			}
			else
			{
				if (($logFile -ne $null) -and ($logFile.Length -gt 0))
				{
					$infoMessage = "Files found for PublicationCode: $publicationCode" + ". Count:" + $dtFileList.Rows.Count
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				}
			}
        }
		catch
		{
			$errorMessage = "Error collecting list of files in the source folder: $srcDir for publication code: $publicationCode " + $_.Exception.Message
			throw $errorMessage
		}

		# checking to see if file has been loaded previously.
		try
		{
		    $dtFilesToGet   = New-Object System.Data.DataTable
			$sqlCmd         = New-Object System.Data.SqlClient.SqlCommand ("ctl.GetIssueNamesToRetrieve", $sqlCon)
			$sqlAdapter     = New-Object System.Data.SqlClient.SqlDataAdapter
			$tableParameter = New-Object System.Data.SqlClient.SqlParameter

			$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

			# We need to be explicit about the table parameter we are passing.
			$tableParameter.ParameterName = '@pIssueNameLookup'
			$tableParameter.SqlDbType     = 'Structured'
			$tableParameter.Value         = $dtFileList
			$tableParameter.Direction     = 'Input'

			$sqlCmd.Parameters.Add($tableParameter) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pPublicationCode", $publicationCode) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pLookBack", '1/1/2018') | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pETLExecutionId", '0') | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pPathId", '0') | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pVerbose", '0') | Out-Null

			$Reader = $sqlCmd.ExecuteReader()
			$dtFileList.Dispose()
			$sqlCmd.Dispose()

			# if records are returned there are indeed new files to process.
			if ($Reader.HasRows -eq $true)
			{
				$dtFilesToGet.Load($Reader)
				$Reader.Dispose()
			}
			#there are no files we should break and not try to copy the files again.
			else
			{
				if (($logFile -ne $null) -and ($logFile.Length -gt 0))
				{
					$infoMessage = "All files found on source have already been staged."
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				}
				$Reader.Dispose()
				return $null
			}			
		}
		catch
		{
			$errorMessage = "Error establishing if file has been previously been staged. " + $_.Exception.Message
			throw $errorMessage
		}

		# copying the files where they need to go.
		# TODO: test for source and destination folders.
        try
        {
			# sort the list first
			$sorted      = new-object Data.DataView($dtFilesToGet)
			$dtFilesToGet.Dispose()
			$sorted.Sort = " FileCreatedDtm ASC" 

			foreach ($file in $sorted)
			{
				$infile = $srcDir + $file.IssueName
				$infoMessage = "Copying file: $infile to the inbound folder: $destDir"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				copy-item -Path $infile -Destination $destDir

				if (($logFile -ne $null) -and ($logFile.Length -gt 0))
				{
					$infoMessage = "File: $infile Copied to: $destDir"
					Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
				}

			}
			$sorted.Dispose()
        }
        catch
        {
			$errorMessage = "Error with file copy. $infile " + $_.Exception.Message 
			throw $errorMessage
        }
    }
    catch  [Exception]
    {
		$errorMessage = "Error with the function Invoke-FileShareListCheckGet. " + $_.Exception.Message
        throw $errorMessage
    }

	return $null

} # Process

END
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-FileShareListCheckGet"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	} 
} # End

} # Function Invoke-WinSCPGet

export-modulemember -function Invoke-FileShareListCheckGet

