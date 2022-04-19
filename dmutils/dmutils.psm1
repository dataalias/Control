<##############################################################################

File:		dmutils.psm1
Name:		dmutils

Purpose:	This is the Data Management Utilities Powershell Modeule

Params:		

Called by:	
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180111
Version:    1.2.1.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180111	ffortunato		Initial iteration. Adding Invoke-NiceLog.
20180322	ffortunato		Revamped nicelog for better formatting and 
							messaging as well as fixing date issue.
20190109	ffortunato		Small changes to logging to determine if file is 
							locked before writing. 
							1.2.1.0

##############################################################################>


function Get-dmutils {

process
{
	# '*****Get-Module*****'
	# Get-Module dmutils -ListAvailable | % { $_.ExportedCommands.Values }
	
	'*****Get-Commands*****'
	Get-Command -Module dmutils
} # process
} # function

export-modulemember -function  Get-dmutils

<##############################################################################

Name:		Invoke-NiceLog

Purpose:	Logging function for writing messages to a flat file. 
			Writes issues to the log file.

Example:	Invoke-NiceLog -event "Info" -message "Hi there" -logFile='C:\Log.txt'

##############################################################################>

function Invoke-NiceLog {

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
<#
    param (
		[string] $event,
		[string] $date,     # remove this parm when you have time but hopefully soon !!
		[string] $message,
		[string] $logFile)
#>

	param (
	[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’The event being logged. LOV: Start, End, Info, Warn, Exit’
		)]
	[ValidateSet("Start","End","Info","Warn","Exit","Error","Cont")] 
	[alias("e")]
	[string]$event,
	
	[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’This is the full message to be logged.’
		)]
	[alias("m")]
	[string]$message,
	
	[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’File the message will be logged to.’
		)]
	[alias("f")]
	[string]$logFile='C:\Log.txt')



begin
{

} #begin
process
{
	try
	{
		[string]$CrLf = "`r`n"
		$curDate      =  Get-Date  -format "yyyy/MM/dd HH:mm:ss"
		$fmtEvent     =  $event.PadRight(6,' ') 
		$writeToFile  = "$fmtEvent : $curDate`tMsg: $message"

		$FileExisits = Test-Path -Path $logFile
<#
		If ($FileExisits -eq $false)
		{
			throw "Log file not found."
		}
#>
		if ($event -eq 'Start')
		{
			$writeToFile = $CrLf + $writeToFile
		}

		if ($event -eq 'End')
		{
			$writeToFile = $writeToFile + $CrLf
		}

#		$IsFileLocked = Test-IsFileLocked -Path $logFile
#
#		If ($IsFileLocked.IsLocked -eq $false)
#		{
			$writeToFile | Out-File $logFile -Append
#		}
#		else
#		{
#			# do nothing throw "File cannot be accessed for write." + $_.Exception.Message
#		}
	}
	catch
	{
		throw $_.Exception.Message
	}
} #process
end
{

} #end 
} #function Invoke-Nicelog

export-modulemember -function Invoke-NiceLog

<##############################################################################

Name:		Test-IsFileLocked

Purpose:	Check to see if a file is locked. If the file can be opened it 
			returns false. if the file is locked it returns true.

##############################################################################>

Function Test-IsFileLocked {
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName','PSPath')]
        [string[]]$Path
    )
    Process
	{
        ForEach ($Item in $Path)
		{
            #Ensure this is a full path
            $Item = Convert-Path $Item
            #Verify that this is a file and not a directory
            If ([System.IO.File]::Exists($Item))
			{
                try
				{
                    $FileStream = [System.IO.File]::Open($Item,'Open','Write')
                    $FileStream.Close()
                    $FileStream.Dispose()
                    $IsLocked = $False
                }
				catch [System.UnauthorizedAccessException]
				{
                    $IsLocked = 'AccessDenied'
                }
				catch
				{
                    $IsLocked = $True
                }
				[pscustomobject]@{
					File     = $Item 
					IsLocked = $IsLocked
				}
            } # If
        } # ForEach
    } # Process
} # Function

export-modulemember -function Test-IsFileLocked