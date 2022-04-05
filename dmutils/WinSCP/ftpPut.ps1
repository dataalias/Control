<##############################################################################

File:		ftpPut.ps1
Name:		Invoke-ftpPut

Purpose:    This function invokes the WinSCP dll to put files on a remote to
			landing zone.

Called by:	
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180727
Version:    1.0.1.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20180727    ffortunato      Initial Iteration
20190306	ochowkwale		Logic for exporitng the files over FTP or SFTP
20190814	ochowkwale		Expilict FTP when connecting to port 21

##############################################################################>

function Invoke-ftpPut {

<#

.SYNOPSIS
This function invokes the WinSCP dll to _list_ files on a remote server based 
on the parameters passed.	The list will be verfied against processed issues.
Any files that have not previously been processed will be retrieved from the 
remote host.

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

.PARAMETER action
get - get files from remote; put - put files to remote; list list files on remote

.EXAMPLE
Invoke-ftpPut `
    -dbServer 'dedtedlsql01' `
    -protocol  'sftp' `
	-IssueName 'ChatTrafficExp_20190306095445.csv' `
    -userName  "nettutor_qa" `
    -password  "saMNDtUjAC9-Z45w" `
    -hostName  "qme1ampsft01.bridgepoint.local" `
    -fp  "ssh-rsa 2048 22:42:69:3e:34:98:b7:cd:3f:6b:47:bf:be:5f:18:55" `
    -remoteDir "\\bpe-aesd-cifs\BI_Admin_dev\DME3\FileShare\ChatTraffic\outbound\" `
    -port "22" `
    -destDir   "/nettutor_qa/Inbound" `
    -LogFile   "\\bpe-aesd-cifs\powershellrepo\DM\DME3\DataHub\logs\ftplog.log"
#>

    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
		[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’Server used’
		)]
		[alias("ser")]
		[string]$dbServer

		,[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’The protocol used for the transfer: ftp, sftp’
		)]
		[alias("p")]
		[string]$protocol

		,[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’Issue that is being transferred’
		)]
		[alias("i")]
		[string]$IssueName
        
		,[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’User name to be authenticated to the site’
		)]
		[alias("usr")]
		[string]$userName

		,[parameter(Mandatory=$false,
		Position = 4)]
		[alias("pwd","pass")]
		[string]$password
        
        ,[parameter(Mandatory=$false,
		Position = 5)]
		[alias("fingerprint","fp")]
		[string]$sshHostKeyFingerprint

		,[parameter(Mandatory=$true,
		Position = 6)]
		[alias("host")]
		[string]$hostName

        ,[parameter(Mandatory=$false,
		Position = 7)]
		[alias("rdir")]
		[string]$remoteDir

        ,[parameter(Mandatory=$false,
		Position = 8)]
		[alias("sdir")]
		[string]$destDir

		,[parameter(Mandatory=$false,
		Position = 9)]
		[alias("pt")]
		[int]$port

		,[parameter(Mandatory=$false,
		Position = 10)]
		[alias("phrase")]
		[string]$privateKeyPassphrase

		,[parameter(Mandatory=$false,
		Position = 11)]
		[alias("KeyPath")]
		[string]$sshPrivateKeyPath

		,[parameter(Mandatory=$true,
		Position = 12)]
		[alias("log","l")]
		[string]$logFile = 'N/A'
)

BEGIN
{

    #Lets set some variables
    [int]      $ErrorNumber  = 0
    [string]   $ErrorMessage = 'Succcess.'
    [string]   $curHost      = hostname
    [string]   $curUser      = whoami
    [datetime] $date         = Get-Date


	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Starting Invoke-ftpPut -dbServer $dbServer -protocol $protocol -IssueName $IssueName -userName $userName -password '******' -hostName $hostName -port $port -fp '******' -remoteDir $remoteDir -destDir $destDir -phrase '*****' -KeyPath $KeyPath -logFile $logFile"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}

    try # lets make sure we have our assembilies
    {
        Add-Type -Path ("C:\Program Files (x86)\WinSCP\WinSCPnet.dll")
    }
    catch
    {
        $ErrorNumber = 1000
        throw 'Unable to find assembilies needed to run.'
 
    }

} # Begin

PROCESS
{

	# Declarations
	$ErrorActionPreference = 'Stop'

	try
    {
		# set all session variables.
        $sessionOptions = New-Object WinSCP.SessionOptions
        $sessionOptions.Protocol   = [WinSCP.Protocol]::$protocol
        $sessionOptions.HostName   = $hostName 
        $sessionOptions.UserName   = $userName
        $sessionOptions.FtpMode    = 'Passive'
        $sessionOptions.FtpSecure  = 'implicit'

		if (($password -ne $null) -and ($password.Length -gt 0))
		{
			$sessionOptions.Password   = $password
		}

        if (($port -ne $null) -and ($port.Length -gt 0))
        {
            $sessionOptions.PortNumber = $port
        }

		if (($protocol -eq 'FTP') -or ($protocol -eq 'ftp') -and ($port -eq '21'))
		{
			$sessionOptions.FtpSecure  = 'explicit'
		}

        if (($protocol -eq 'sftp') -or `
            ($protocol -eq 'scp' ) -or `
            ($protocol -eq 'SFTP') -or `
            ($protocol -eq 'SCP'))
        {
			if (($sshHostKeyFingerprint -ne $null) -and ($sshHostKeyFingerprint.Length -gt 0))
			{
				$sessionOptions.SshHostKeyFingerprint = $sshHostKeyFingerprint
			}
			if (($privateKeyPassphrase -ne $null) -and ($privateKeyPassphrase.Length -gt 0))
			{
				$sessionOptions.PrivateKeyPassphrase  = $privateKeyPassphrase
			}
			if (($sshPrivateKeyPath -ne $null)-and ($sshPrivateKeyPath.Length -gt 0))
			{
				$sessionOptions.SshPrivateKeyPath     = $sshPrivateKeyPath
			}

            $sessionOptions.FtpSecure  = 'none'
        } # if secure trransfer
		try
        {
			# Setup session options    
			$session = New-Object WinSCP.Session

			# Connect
			$session.Open($sessionOptions)
			 # Upload files
			$transferOptions = New-Object WinSCP.TransferOptions
			$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
			
			[string]$fullyQualifiedFileNameSrc = Join-Path $remoteDir $IssueName
			$fullyQualifiedFileNameDest = "$($destDir)/$($IssueName)"
			
			$transferResult = $session.PutFiles($fullyQualifiedFileNameSrc,$fullyQualifiedFileNameDest,$false,$transferOptions)

			if($transferResult.IsSuccess -ne 'TRUE')
            {
				   throw $transferResult.Failures
            }

			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "Getting new file found for Subscription`t File: $GetFile"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			}
			$session.Dispose()
        }
        catch
        {
            $ErrorMessage = "Something went wrong getting files from ftp/sftp site. :: " + $_.Exception.Message 
			throw $ErrorMessage
        }
    }
    catch  [Exception]
    {
            $ErrorMessage = "Issue thrown from main try. :: " + $ErrorMessage + " :: " + $_.Exception.Message 
			throw $ErrorMessage
    }
} # Process

END
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-ftpPut"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
    
} # End

} # Function Invoke-ftpPut

export-modulemember -function Invoke-ftpPut