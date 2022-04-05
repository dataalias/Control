<##############################################################################

File:		Invoke-IntervalCheck.ps1
Name:		Invoke-IntervalCheck

Purpose:	Determine when the last feed was loaded. If the interval hasn't 
			been exceeded no need to look for another file.

Params:		$currentDatetime
			$SLATime

Called by:	Get-DataFeed (TBL)


$CurDtm = Get-Date
$SLA = "09:00:00"
$interval = "DLY"

			Invoke-IntervalCheck -dtm $CurDtm -sla $SLA -interval $interval -log ""

Calls:		n/a  

Returns:	1 - true
			0 - false

Errors:		

Author:		ffortunato
Date:		20181004
Version:    1.1.0.0

###############################################################################
       CHANGE HISTORY
###############################################################################

Date		Author			Description

########	##########      ###################################################

20181004	ffortunato		Initial iteration.

##############################################################################>

function Invoke-IntervalCheck {

<#

.SYNOPSIS
This function is used to determine .

.DESCRIPTION
This cmdlet ...

.EXAMPLE

#>

	[CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (

		[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’Interval Code is needed to interpret the SLATime string.’
		)]
		[alias("interval","ic")]
		[string]$intervalCode
		,[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’Interval Code is needed to interpret the SLATime string.’
		)]
		[alias("length","il")]
		$intervalLength
		,[parameter(Mandatory=$true,
		Position = 3)]
		[alias("le")]
		[datetime]$lastIssueFileDate
		,[parameter(Mandatory=$true,
		Position = 4)]
		[alias("log","l")]
		[string]$logFile = 'N/A'

	)
begin
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-IntervalCheck -ic $intervalCode -il $intervalLength -le $lastIssueFileDate" # -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # begin
process
{
<#testing
"PublicationCode: $publicationCode"
"SLATime: $SLATime"
"IssueFileDate: $lastIssueFileDate"
"IntervalCode: $intervalCode"
"IntervalLen: $intervalLength"
#>
	try 
	{
        $date = get-date
        $retVal = $false # retVal returns true or false.
        $timeDiff = NEW-TIMESPAN –Start $lastIssueFileDate –End $date

		switch ($intervalCode)
		{
			'MIN'
			{
                if ($timeDiff.TotalMinutes -gt $intervalLength)
                {
                    $retVal = $true
                }
			}
			'HR'
			{
                if ($timeDiff.TotalHours -gt $intervalLength)
                {
                    $retVal = $true
                }
			}
			'DLY' 
			{
                if ($timeDiff.TotalDays -gt $intervalLength)
                {
                    $retVal = $true
                }
			}
			'WKLY'
			{
                if ($timeDiff.TotalDays -gt (7 * $intervalLength))
                {
                    $retVal = $true
                }
			}
			'MTHLY'
			{

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
			$infoMessage = "LastIssueDatetime: $lastIssueFileDate and CurrentDatetime: $date Hours difference: " + $timeDiff.TotalHours + " Returning: $retVal"
			Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
		}
	} # try
	catch
	{
		$errorMessage = "Error with the function Invoke-IntervalCheck. " + $_.Exception.Message
        throw $errorMessage
    } # catch

    return $retVal

} # process
end
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Complete Invoke-IntervalCheck"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # end
} # function

export-modulemember -function Invoke-IntervalCheck