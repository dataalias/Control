<##############################################################################

File:		Invoke-Unizip.ps1
Name:		Invoke-Unzip

Purpose:	Provide a powershell function that unzips a compressed arcive.

Params:	    see below
		

Called by:	Any module that needs to unzip a file.
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20171120
Version:    v01.00

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20171120	ffortunato		Initial iteration.

20171206	ffortunato		Adding to the module and readying for pipeline.


##############################################################################>

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Invoke-Unzip
{

<#

.SYNOPSIS
This function uncompresses a zip archive to a destination directory. It will
first ensure that the uncompressed file does not already exist.

.DESCRIPTION
This function invokes the .NET [System.IO.Compression.ZipFile]::ExtractToDirectory(source,dest)
function in order to uncompress a zip archive to a destination directory. 
The commandlet requires the System.IO.Compression.FileSystem assembly.

.PARAMETER zipFile
The explicit directory path and file name to be unzipped.

.PARAMETER outPath
The explicit direcotry path where the archive will be extracted.

.EXAMPLE
Invoke-Unzip -zipfile  'c:\file.zip' -outpath  'c:\tmp\'

#>

	[CmdletBinding (SupportsShouldProcess=$True)]

	param (
	[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Explicit location of the zip archive to be unzipped.’,
		ValueFromPipeline=$true
		)]
	[alias("z")]
	[string[]]$zipFile,
        
	[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’Explicit destination for the unzipped files.’,
		ValueFromPipeline=$true
	)]
	[alias("o")]
	[string[]]$outPath <#,

	[parameter(Mandatory=$false,
		Position = 1,
		HelpMessage=’Explicit destination for the unzipped files.’,
		ValueFromPipeline=$true
	)]
	[alias("f")]
	[boolean[]]$force=$false#>)


	begin
	{

	}
    process
    {
		try # Make sure the unzipped files does not already exist in the target.
		{

			foreach($sourceFile in (Get-ChildItem -path $zipFile))
			{
				$archiveList = [IO.Compression.ZipFile]::OpenRead($sourceFile.FullName).Entries.FullName 
				$unzippedFile = $destination +'\'+ $archiveList
				
				if(test-path $unzippedFile) 
				# if the file is present with force, remove it.
				{
				<#
					if ($force -eq $true)
					{
						Remove-Item $unzippedFile -Force
					}
					else
					{
				#>
						$ErrorMessage = 'Cannot unzip file. One or more already exists in target destination. ' + $unzippedFile
						throw $ErrorMessage
				#	}
				}
            }
		}
		catch
		{
			throw  "`r`n  $_.Exception.Message  Issue establishing if any items in archive are already unzipped in :  $unzippedFile"
		}

		try # Unzip the file
		{
			[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outPath)
		}
		catch
		{
			$ErrorMessage = "Unzip of $zipfile to $outpath `r`n Error Message: " + $_.Exception.Message
			throw  $ErrorMessage
		}
	}
	 #process
	end
	{

	}
} #function

export-modulemember -function Invoke-Unzip