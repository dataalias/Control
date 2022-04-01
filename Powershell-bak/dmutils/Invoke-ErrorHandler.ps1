<##############################################################################

Name:		Invoke_ErrorHandler

Purpose:	

Params:     

Called by:	n/a
Calls:      n/a  

Errors:     n/a - This function is the notification of errors.

Author:     ffortunato
Date:		20180315

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180315	ffortunato		Initial iteration.

##############################################################################>#

function Invoke_ErrorHandler {

<#

.SYNOPSIS
This function ofers a generic method for handleing errors thrown to a catch block.

.DESCRIPTION
Desc...

.EXAMPLE
Invoke_ErrorHandler 'mail-tools.bridgepoint.local' 'some-email@bpiedu.com' 'no-reply@bpiedu.com' 'Some Subject' 'Some Body' $null #no attachment.

#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	param (
	[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Sever that will relay the email’
		)]
	[alias("svr")]
	[string]$smtpserver,
	
	[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’To e-mail address’
		)]
	[alias("t")]
	[string]$to,
	
	[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’From e-mail address’
		)]
	[alias("f")]
	[string]$from='no-reply@bpiedu.com',
	
	[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’Subject to the e-mail’
		)]
	[alias("s")]
	[string][AllowNull()]$subject,
	
	[parameter(Mandatory=$false,
		Position = 4,
		HelpMessage=’Content of the e-mail’
		)]
	[alias("b")]
	[string][AllowNull()]$body,
	
	[parameter(Mandatory=$false,
		Position = 5,
		HelpMessage=’Attachments to the e-mail’
		)]
	[alias("a")]
	[string][AllowNull()]$fileAttachment,

	[parameter(Mandatory=$false,
		Position = 6,
		HelpMessage=’File that contains the running log.’
		)]
	[alias("log")]
	[string][AllowNull()]$logFile,

	[parameter(Mandatory=$false,
		Position = 7,
		HelpMessage=’System thrown error message.’
		)]
	[alias("err")]
	[ref][AllowNull()]$errorObject,

	[parameter(Mandatory=$false,
		Position = 8,
		HelpMessage=’Custom Error Message.’
		)]
	[alias("cust")]
	[string][AllowNull()]$customMessage,

	[parameter(Mandatory=$false,
		Position = 8,
		HelpMessage=’Action to take by calling procedure.’
		)]
	[ValidateSet("Exit","Continue")] 
	[alias("act")]
	[string][AllowNull()]$Action,
	
	[parameter(Mandatory=$false,
		Position = 9,
		HelpMessage=’This is the event log source.’
		)]
#	[ValidateSet("DataHub")] 
	[alias("src")]
	[string][AllowNull()]$Source='DataHub'
	)
begin 
{

} # begin
process
{
	[string]$CrLf         = "`r`n"
	[string]$errorMessage = "N/A"
		    $date         = Get-Date
<#Testing
"-smtpserver $smtpserver"
"-To         $to"
"-From       $from"
"-Subject    $subject"
"-Body       $body"
$fileAttachment
$logFile
$errorObject
$customMessage
$Action
<##>
	try
	{

		$errorMessage = $errorObject.Value.Exception.Message + $CrLf +  $errorObject.Value.InvocationInfo.PositionMessage + $CrLf + "Custom Message: " + $customMessage
		
		$date         = Get-Date
		Invoke-Nicelog -event 'Error' -message $errorMessage -logfile $logFile 
		
		if ($Action -eq 'Exit')
		{
			Invoke-Nicelog -event 'Exit' -message "$CrLf $CrLf" -logfile $logFile
		}
		elseif ($Action -eq 'Continue')
		{
			Invoke-Nicelog -event 'Cont' -message "$CrLf $CrLf" -logfile $logFile
		}

		$body = $body + $errorMessage 
		Send-MailMessage -From $from -To $to -Subject $subject -Body $body -Priority High -SmtpServer $smtpserver
<#
		try
		{
			Write-EventLog –LogName Application –Source $source –EntryType "Error" –EventID $PID -Message $body -ComputerName 'localhost'
		}
		catch
		{
			# Do Nothing.
		}
#>
	}
	catch
	{
		'Error Handler broke' + $_.Exception.Message
		throw $_.Exception.Message
	}
} # process
end
{
	
} # end
} # function  Invoke_ErrorHandler

export-modulemember -function Invoke_ErrorHandler