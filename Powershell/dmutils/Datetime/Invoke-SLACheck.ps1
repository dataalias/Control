<##############################################################################

File:		Invoke-SLACheck.ps1
Name:		Invoke-SLACheck

Purpose:	This is functions determines if a SLA threshold has been reached.

Params:		$currentDatetime
			$SLATime

Called by:	Get-DataFeed (TBL)


$CurDtm = Get-Date
$SLA = "09:00:00"
$interval = "DLY"

			Invoke-SLACheck -dtm $CurDtm -sla $SLA -interval $interval -log ""

Calls:		n/a  

Returns:	1 - true
			0 - false

Errors:		

Author:		ffortunato
Date:		20180605
Version:    1.1.0.0

ToDo:		Should this function consider IntervalCode and IntervalLength

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180605	ffortunato		Initial iteration.

##############################################################################>


function Invoke-SLACheck {

<#

.SYNOPSIS
This function is used to determine if any table sources should be checked for 
new data. If a tables invterval has been meet a new issue record is entered
and the associated SSIS package kicked off.

.DESCRIPTION
This cmdlet ...

.PARAMETER protocol
Protocol to be used for the transfer.
ftp:  File Transfer Protocol
sftp: Secure File Transfer Protocol

.EXAMPLE

#>

	[CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Current date time’
		)]
		[alias("dtm")]
		[datetime]$currentDatetime

		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’A properly formatted SLA time.’
		)]
		[alias("sla")]
		[string]$SLATime

		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Interval Code is needed to interpret the SLATime string.’
		)]
		[alias("interval")]
		[string]$intervalCode

		,[parameter(Mandatory=$true,
		Position = 7)]
		[alias("log","l")]
		[string]$logFile = 'N/A'
	)
begin
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-SLACheck -dtm $currentDatetime -sla $SLATime -interval $intervalCode" # -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # begin
process
{
	try 
	{
		switch ($intervalCode)
		{
			'MIN'
			{
				[string]$stringCurDtm = get-date -Format yyyyMMddThhmm  # ss
				[string]$SLA =  $stringCurDtm + $SLATime -replace ':',''
				$SLADtm = [datetime]::ParseExact($SLA,'yyyyMMddTHHmmss',$null)
			}
			'HR'
			{
				[string]$stringCurDtm = get-date -Format yyyyMMddThh  # mmss
				[string]$SLA =  $stringCurDtm + $SLATime -replace ':',''
				$SLADtm = [datetime]::ParseExact($SLA,'yyyyMMddTHHmmss',$null)
			}
			'DLY' 
			{
				[string]$stringCurDtm = get-date -Format yyyyMMddT  # hhmmss
				[string]$SLA =  $stringCurDtm + $SLATime -replace ':',''
				$SLADtm = [datetime]::ParseExact($SLA,'yyyyMMddTHHmmss',$null)
			}
			'WKLY'
			{
				# later
			}
			'MTHLY'
			{
				# need some more code to drop day 30,31 etc to the last day of a short month.
				[string]$stringCurDtm = get-date -Format yyyyMM  # ddThhmmss
				[string]$SLA =  $stringCurDtm + $SLATime -replace ':',''
				$SLADtm = [datetime]::ParseExact($SLA,'yyyyMMddTHHmmss',$null)
			}
			'YRLY'
			{
				# later
			}
			default
			{
				$infoMessage = "Invalid interval code passed to SLA check: $intervalCode"
				Invoke-Nicelog -event 'Warn' -message $infoMessage -logfile $logFile
			}
		} # switch

		if (($logFile -ne $null) -and ($logFile.Length -gt 0))
		{
			$infoMessage = "About to compare SLA Time: $SLADtm  and Current Datetime: $currentDatetime"
			Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
		}
	} # try
	catch
	{
		$errorMessage = "Error with the function Invoke-SLACheck. " + $_.Exception.Message
        throw $errorMessage
    } # catch
	if ($currentDatetime -gt $SLADtm)
	{
		return $true
	}
	else
	{
		return $false
	}
} # process
end
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Complete Invoke-SLACheck"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # end
} # function


export-modulemember -function Invoke-SLACheck