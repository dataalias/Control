<##############################################################################

Name:		Send-eMail

Purpose:	Simply sends an e-Mail.

Params:     Associated email values: $to, $from, $subject, $smtpserver
                                   , $body, $fileAttachment

Called by:	n/a
Calls:      n/a  

Errors:     n/a - This function is the notification of errors.

Author:     ffortunato
Date:		20170610

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20171211	ffortunato		Initial iteration.

20180322	ffortunato		DEPRECATED DO NOT USE THIS FUNCTION USE BUILT IN::
							<<<<<Send-MailMessage>>>>>

##############################################################################>

function Send-eMail {

<#

.SYNOPSIS
This function sends an e-mail based on the parameters passed.

.DESCRIPTION
Desc...

.EXAMPLE
send-email 'mail-tools.bridgepoint.local' 'some-email@bpiedu.com' 'no-reply@bpiedu.com' 'Some Subject' 'Some Body' $null #no attachment.

#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	param (
	[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Sever that will relay the email’
		)]
	[alias("svr")]
	[string[]]$smtpserver,
	
	[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’To e-mail address’
		)]
	[alias("t")]
	[string[]]$to,
	
	[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’From e-mail address’
		)]
	[alias("f")]
	[string[]]$from='no-reply@bpiedu.com',
	
	[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’Subject to the e-mail’
		)]
	[alias("s")]
	[string[]][AllowNull()]$subject,
	
	[parameter(Mandatory=$false,
		Position = 4,
		HelpMessage=’Content of the e-mail’
		)]
	[alias("b")]
	[string[]][AllowNull()]$body,
	
	[parameter(Mandatory=$false,
		Position = 5,
		HelpMessage=’Attachments to the e-mail’
		)]
	[alias("a")]
	[string[]][AllowNull()]$fileAttachment)

begin
{

}
process
{
    try
	{
            $mailer     = new-object Net.Mail.SMTPclient($smtpserver)
	        $msg        = new-object Net.Mail.MailMessage($from,$to,$subject,$body)

			if (($fileAttachment -ne $null) -and ($fileAttachment.Length -ge 1))
			{
				$attachment = new-object Net.Mail.Attachment($fileAttachment, 'text/plain')
				$msg.Attachments.Add($attachment)
			}

	        $msg.IsBodyHTML = 0
	        $mailer.send($msg)
    }
	catch
	{
        throw "$_.Exception.Message"
    }

} #process

end
{
	
}

} #function

export-modulemember -function Send-eMail