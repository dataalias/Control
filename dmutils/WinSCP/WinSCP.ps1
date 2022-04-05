<##############################################################################

File:		Invoke-WinSCP.ps1
Name:		Invoke-WinSCP

Purpose:    This function invokes the WinSCP dll to get files off of a remote
            server based on the parameters passed.	

Called by:	
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20170809
Version:    1.0.0.3

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20171205    ffortunato      Getting ready to be stand alone module.
20170202    jbonilla        Uncommitted the removal of files. 
20180214    ffortunato      Adding a new function InvokeWinSCP this function 
							will allow for listing and passing of data tables
							that define the impacted files. It will eventually
							replace  Invoke-WinSCPGet.
20180216    ffortunato      Based on QA bugs testing error messages.
##############################################################################>


function Invoke-WinSCPGet {

<#

.SYNOPSIS
This function invokes the WinSCP dll to _get_ files off of a remote server based on the parameters passed.	

.DESCRIPTION
This cmdlet requires an installation of WinSCP at C:\Program Files (x86)\WinSCP\WinSCPnet.dll 


.PARAMETER protocol
Protocol to be used for the transfer.
ftp:  File Transfer Protocol
sftp: Secure File Transfer Protocol

.PARAMETER userName
The user name that will be used for authentication to the host.

.PARAMETER password
The password that will be used for authentication to the host.

.PARAMETER hostName
The complete URL for the hosted ftp site.

.PARAMETER port
The port of the requested ftp service. This must be numeric.

.PARAMETER sshKey
The certificate for secure data transfers.

.PARAMETER remoteDir
The remote directory that contains the files to be retreived.

.PARAMETER destDir
The local directory that will recieve the files.

.PARAMETER fileName
Name of the file to be transfered. This can include wildcards


.EXAMPLE
Invoke-WinSCPGet `
    -protocol  'ftp' `
    -userName   'review.sharefileftp.com/jeffery.drummond@bpiedu.com' `
    -password  "aqX3ZfMuUCfDcq9Y" `
    -hostName  "review.sharefileftp.com" `
    -fileName   "*" `
    -remoteDir  "/Reports/Bridgepoint" `
    -destDir   "c:\\tmp\\" `
    -port  '990'

.EXAMPLE
Invoke-WinSCPGet `
    -protocol  'sftp' `
    -userName  "nettutor" `
    -password  "0BXATWbr}y8K]Y6j2-Gj" `
    -hostName  "vendorsftp.bridgepointeducation.com" `
    -sshKey  "ssh-rsa 2048 22:42:69:3e:34:98:b7:cd:3f:6b:47:bf:be:5f:18:55" `
    -remoteDir "/nettutor/" `
    -destDir   "c:\\tmp\\" `
    -fileName  "*" 

#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’The protocol used for the transfer: ftp, sftp’
		)]
		[alias("p")]
		[string]$protocol,
        
		[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’User name to be authenticated to the site’
		)]
		[alias("usr")]
		[string]$userName,

		[parameter(Mandatory=$true,
		Position = 2)]
		[alias("pwd","pass")]
		[string]$password,
        
		[parameter(Mandatory=$true,
		Position = 3)]
		[alias("host")]
		[string]$hostName,

		[parameter(Mandatory=$false,
		Position = 4)]
		[alias("pt")]
		[int]$port,

		[parameter(Mandatory=$false,
		Position = 5)]
		[alias("key")]
		[string]$sshKey,

		[parameter(Mandatory=$false,
		Position = 6)]
		[alias("rdir")]
		[string]$remoteDir,

		[parameter(Mandatory=$false,
		Position = 7)]
		[alias("ldir")]
		[string]$destDir,

		[parameter(Mandatory=$true,
		Position = 8)]
		[alias("f")]
		[string]$fileName
)

BEGIN
{

    #Lets set some variables
    [int]      $ErrorNumber  = 0
    [string]   $ErrorMessage = 'Succcess.'
    [string]   $curHost      = hostname
    [string]   $curUser      = whoami
    [datetime] $date         = Get-Date

    try # lets make sure we have our assembilies
    {
        Add-Type -Path ("C:\Program Files (x86)\WinSCP\WinSCPnet.dll")
    }
    catch
    {
        $ErrorNumber = 1000
        throw 'Unable to find assembilies needed to run.'
 
    }
    try #lets see if we have the right combo of data
    {
        #if im sftp better have a key.
        if (($protocol -eq 'sftp') -and ($sshKey -eq $null))
        {
            $ErrorNumber = 1001
            throw 'sftp was requested but no key was provided.'
        }
    }
    catch
    {
        return $ErrorNumber
    }
} # Begin

PROCESS
{
	$ErrorActionPreference = 'Stop'

    try
    {
        $sessionOptions = New-Object WinSCP.SessionOptions
        $sessionOptions.Protocol   = [WinSCP.Protocol]::$protocol
        $sessionOptions.HostName   = $hostName 
        $sessionOptions.UserName   = $userName
        $sessionOptions.Password   = $password
        $sessionOptions.FtpMode    = 'Passive'
        $sessionOptions.FtpSecure  = 'implicit'
       
        if ($port -ne $null)
        {
            $sessionOptions.PortNumber = $port
        }

        if (($protocol -eq 'sftp') -or `
            ($protocol -eq 'scp'))
        {
            $sessionOptions.SshHostKeyFingerprint = $sshKey
            $sessionOptions.FtpSecure  = 'none'
        }

        # Setup session options    
        $session = New-Object WinSCP.Session

        # Connect
        $session.Open($sessionOptions)
 
        # Upload files
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
        $transferResult = $session.GetFiles("$remoteDir$fileName", "$destDir", $False, $transferOptions)
    
        # Throw on any error
        $transferResult.Check()
 
        # Print results and remove the files.
        foreach ($transfer in $transferResult.Transfers)
        {
            #Write-Host ("Upload of {0} succeeded" -f $transfer.FileName)
            $session.RemoveFiles($transfer.FileName)
        }
    }
    catch  [Exception]
    {
		$errorMessage = "Error: " +  $_.Exception.Message + "`r`n" + "FileName: " + $transfer.FileName
		throw "$errorMessage"
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }
	
} # Process

END
{
    
} # End

} # Function Invoke-WinSCPGet

export-modulemember -function Invoke-WinSCPGet

function Invoke-WinSCPPut {

<#

.SYNOPSIS
Says 'Hi Mom'

.DESCRIPTION
Nothing at all going on here...

.EXAMPLE
Invoke-WinSCP-Put `

#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
        [parameter(Mandatory=$true,
            Position = 0,
            HelpMessage=’The protocol used for the transfer: ftp, sftp’
            )]
        [alias("p")]
        [string]$protocol)
begin
{

} # Begin
process
{
	'Hi Mom'
} # Process
end
{

} # End
} # Function Invoke-WinSCPPut

#export-modulemember -function Invoke-WinSCPPut
