<##############################################################################

File:		Invoke-ftpListCheckGet.ps1
Name:		Invoke-ftpListCheckGet

Purpose:    This function invokes the WinSCP dll to list available files, check
			to see if they have previously been retreived and get any un-
			processed files to the landing zone.

Called by:	
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180214
Version:    1.1.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20180214    ffortunato      Initial Iteration

20180227    ffortunato      Fixing bug where no results causes a failure.
                            Removing all references to write-error and 
                            replacing with throw. Fix done by checking row 
							counts of file list sent from ftp site. Removed 
							finally code and move associated dispose inline
							with their final use.

20180302    ffortunato      If the reader has no values exit. there are no
							files to get.

20180307    ffortunato      Sending a $dbServer to this as well.

20180511    ffortunato      Additional Logging.

20180627    ffortunato      Adding some additional variables to support sftp
							by passing fingerprints, private keys and 
							passphrase

20180705    ffortunato      Need to preserve the order the files were created.
							In the future this should use the file name mask
							rather than the created date time we use now. HAX

20180717    ffortunato      Minor edits to support secureftp.

20180831    ffortunato      Mask

20180912    ffortunato      Improving logging. $fileMask not $fileNameMask

20181012    ffortunato      Bringing the SQLConnection from calling proc.

20181016    ffortunato      Giving the system more time to make a connection.

20181026    ffortunato      Removed loging step.

20181204    ffortunato      Sorted the wrong list. Modifying code.

20181213    ochowkwale      Setting time out to two minutes (120000 ms)
							Providing the TLS/SSL fingerprint fot FTP

20190107	ochowkwale		FTP connector changes

20190215	ochowkwale		Setting session timeout to 2 minutes

##############################################################################>

function Invoke-ftpListCheckGet {

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
Invoke-ftpListCheckGet `
    -dbServer 'dedtedlsql01' `
    -protocol  'sftp' `
    -userName  "bpi_edu" `
    -password  "Password!" `
    -hostName  "sftp.civitaslearning.com" `
    -fp  "ssh-rsa 2048 ee:5e:36:9c:88:94:ca:71:79:f0:14:65:39:d9:11:67" `
    -remoteDir "" `
    -port "2222" `
    -destDir   "c:\\tmp\\" `
    -publicationCode "WD_ROSTER" `
    -LogFile   "c:\\tmp\\ftplog.log"

Invoke-ftpListCheckGet `
    -dbServer 'dedtedlsql01' `
    -protocol  'sftp' `
    -userName  "qa_bi_workday" `
    -password  "@ctive123" `
    -hostName  "sftp.bridgepointeducation.com" `
    -fp  "ssh-rsa 2048 65:89:b0:57:24:cf:ea:8f:da:b8:b5:36:f0:4f:20:8c" `
    -remoteDir "/home/qa_bi_workday/Roster/Inbound/" `
    -port "22" `
    -destDir   "c:\\tmp\\" `
    -publicationCode "WD_ROSTER" `
    -KeyPath "\\\\bpe-aesd-cifs\\powershellrepo\\DM\\QME3\\DataHub\\keys\\civitas_private_key.ppk " `
    -LogFile   "c:\\tmp\\ftplog.log"
    
$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$dbServer = 'dedtedlsql01'
$sqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Connection Timeout=60;Integrated Security=True;MultipleActiveResultSets=true"
$sqlCon.Open() 

$dbServer

Invoke-ftpListCheckGet `
    -sqlCon $sqlCon `
    -protocol  'ftp' `
    -userName  "review.sharefileftp.com/jeffery.drummond@bpiedu.com" `
    -password  "aqX3ZfMuUCfDcq9Y" `
    -hostName  "review.sharefileftp.com"`
    -fp  ""  `
    -remoteDir "/Reports/Bridgepoint/"`
    -port "990"  `
    -destDir   "c:\temp\"  `
    -publicationCode "TR-SESSION" `
    -LogFile   "c:\temp\ftplog.log" 



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

		,[parameter(Mandatory=$true,
		Position = 0,
		HelpMessage=’The protocol used for the transfer: ftp, sftp’
		)]
		[alias("p")]
		[string]$protocol
        
		,[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’User name to be authenticated to the site’
		)]
		[alias("usr")]
		[string]$userName

		,[parameter(Mandatory=$false,
		Position = 2)]
		[alias("pwd","pass")]
		[string]$password
        
		,[parameter(Mandatory=$true,
		Position = 3)]
		[alias("host")]
		[string]$hostName

		,[parameter(Mandatory=$false,
		Position = 4)]
		[alias("pt")]
		[int]$port

		,[parameter(Mandatory=$false,
		Position = 5)]
		[alias("fingerprint","fp")]
		[string]$sshHostKeyFingerprint

		,[parameter(Mandatory=$false,
		Position = 6)]
		[alias("TLSCertificate","cert")]
		[string]$TLSHostKeyCertificate

		,[parameter(Mandatory=$false,
		Position = 7)]
		[alias("rdir")]
		[string]$remoteDir

		,[parameter(Mandatory=$false,
		Position = 8)]
		[alias("ldir")]
		[string]$destDir

		,[parameter(Mandatory=$true,
		Position = 9)]
		[alias("pubnc","pc")]
		[string]$publicationCode = 'N/A'

		,[parameter(Mandatory=$false,
		Position = 10)]
		[alias("phrase")]
		[string]$privateKeyPassphrase

		,[parameter(Mandatory=$false,
		Position = 11)]
		[alias("KeyPath")]
		[string]$sshPrivateKeyPath


		,[parameter(Mandatory=$false,
		Position = 12)]
		[alias("fm")]
		[string]$fileMask

		,[parameter(Mandatory=$true,
		Position = 13)]
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
		$infoMessage = "Starting Invoke-ftpListCheckGet " #-dbServer $dbServer -protocol $protocol -userName $userName -password '******' -hostName $hostName -port $port -fp '******' -remoteDir $remoteDir -destDir $destDir -publicationCode $publicationCode -fileNameMask $fileMask -phrase '*****' -KeyPath $KeyPath" # -logFile $logFile"
		#$infoMessage = "Starting Invoke-ftpListCheckGet -dbServer $dbServer -protocol $protocol -userName $userName -password $password -hostName $hostName -port $port -fp $sshHostKeyFingerprint -remoteDir $remoteDir -destDir $destDir -publicationCode $publicationCode -fileNameMask $fileMask  -phrase $privateKeyPassphrase -KeyPath $KeyPath -logFile $logFile"
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

	# The name of a file and extension. No path information.
	[string]$fileName = 'N/A'

    # Prime the data table
    [System.Data.DataTable] $dtFileList = New-Object Data.datatable
    $dtFileList.Columns.Add("IssueName")      | Out-Null
    $dtFileList.Columns.Add("FileAction")     | Out-Null
	$dtFileList.Columns.Add("FileCreatedDtm") | Out-Null

    try # Create session options.
    {
        $sessionOptions = New-Object WinSCP.SessionOptions
        $sessionOptions.Protocol   = [WinSCP.Protocol]::$protocol
        $sessionOptions.HostName   = $hostName 
        $sessionOptions.UserName   = $userName
        $sessionOptions.FtpMode    = 'Passive'
        $sessionOptions.FtpSecure  = 'implicit'
		$sessionOptions.TimeoutInMilliseconds = 120000 #two minutes to create connection.

		if (($password -ne $null) -and ($password.Length -gt 0))
		{
			$sessionOptions.Password   = $password
		}

        if (($port -ne $null) -and ($port.Length -gt 0))
        {
            $sessionOptions.PortNumber = $port
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

		if (($protocol -eq 'FTP') -or `
			($protocol -eq 'ftp'))
		{
			if (($TLSHostKeyCertificate -ne $null) -and ($TLSHostKeyCertificate.Length -gt 0))
			{
				$sessionOptions.TlsHostCertificateFingerprint = $TLSHostKeyCertificate
			}
        } # if secure trransfer


	} # try Setting up Session Information.
	catch
	{
		    $ErrorMessage = "Issue collecting session information for WinSCP. :: " + $_.Exception.Message 
			throw $ErrorMessage
	}
	try # Generate session from session options.
    {
		# Setup session options    
		$session = New-Object WinSCP.Session
		$session.Timeout = '00:02:00.0000000'
		$transferOptions = New-Object WinSCP.TransferOptions
		$session.Open($sessionOptions)
		$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

		# listing the files available
        $listDirectoryResult = $session.ListDirectory("$remoteDir")

		# test to see if no files were found. Return if no files are found.
		if ($listDirectoryResult -eq $null)
		{
			#"Get out of here. No files on remote site."
			$infoMessage = "listDirectoryResult is null. No files found on remote site for PublicationCode: $publicationCode"
			Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			return $null
		}

        # Put the results in a data table.
        foreach ($file in $listDirectoryResult.Files)
        {
            #replace the conditions of this if later on with Mask.
            if (($fileName.Contains($publicationCode)) -or ($file.Name -match $fileMask))
            {
                $DR = $dtFileList.NewRow()   #Creating a new data row
                $DR.Item("IssueName")  = $file.Name
                $DR.Item("FileAction") = 'List'
				$DR.Item("FileCreatedDtm") = $file.LastWriteTime
                $dtFileList.Rows.Add($DR)
            }
        }
		#$listDirectoryResult.Dispose

		if ($dtFileList.Rows.Count -lt 1)
		{				
			#Get out of here. No files on remote site that match our values."
			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "No files found for PublicationCode: $publicationCode"
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
        $ErrorMessage = "Issue with WinSCP listing files on the remote server. :: " + $_.Exception.Message 
		throw $ErrorMessage
	}

	# checking to see if file has been loaded previously.
	try
	{
		$dtFilesToGet   = New-Object System.Data.DataTable
		$sqlCmd         = New-Object System.Data.SqlClient.SqlCommand ("ctl.GetIssueNamesToRetrieve", $SqlCon)
		$sqlAdapter     = New-Object System.Data.SqlClient.SqlDataAdapter
		$tableParameter = New-Object System.Data.SqlClient.SqlParameter

		# We need to be explicit about the table parameter we are passing.
		$tableParameter.ParameterName = '@pIssueNameLookup'
		$tableParameter.SqlDbType     = 'Structured'
		$tableParameter.Value         = $dtFileList
		$tableParameter.Direction     = 'Input'

		$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
		$sqlCmd.Parameters.Add($tableParameter) | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pPublicationCode", $publicationCode) | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pLookBack", '1/1/2018') | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pETLExecutionId", '-1') | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pPathId", '-1') | Out-Null
		$sqlCmd.Parameters.AddWithValue("@pVerbose", '0') | Out-Null

		$Reader = $sqlCmd.ExecuteReader()
		$dtFileList.Dispose()
		$sqlCmd.Dispose()

		if($Reader.HasRows)
		{
			$dtFilesToGet.Load($Reader)
			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "New files found for PublicationCode: $publicationCode"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			}
			$Reader.Dispose()
		}
		else
		{
			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "No new files found for PublicationCode: $publicationCode"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			}
			$Reader.Dispose()
			$dtFilesToGet.Dispose()
			return  $null
		}
	}
	catch
	{
        $ErrorMessage = "Issue determining if file has been loaded previously. :: " + $_.Exception.Message 
		Invoke-Nicelog -event 'Error' -message $ErrorMessage -logfile $logFile
		throw $ErrorMessage
	}

    try
    {
		# sort the list first
		$sorted      = new-object Data.DataView($dtFilesToGet)
		$dtFilesToGet.Dispose()
		$sorted.Sort = " FileCreatedDtm ASC" 

		foreach ($file in $sorted)
		{
			$GetFile = $remoteDir + $file.IssueName
			# Im a get so lets get some files.
			$transferResult = $session.GetFiles("$GetFile", "$destDir", $False, $transferOptions)
			# Throw on any error
			$transferResult.Check()
			# Print results and remove the files.
			if (($logFile -ne $null) -and ($logFile.Length -gt 0))
			{
				$infoMessage = "Getting new file found for PublicationCode: $publicationCode `t File: $GetFile"
				Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
			}
		}
		$session.Dispose()
		$sorted.Dispose()
    }
    catch
    {
        $ErrorMessage = "Something went wrong getting files from ftp/sftp site. :: " + $_.Exception.Message 
		throw $ErrorMessage
    }
} # Process

END
{
	if (($logFile -ne $null) -and ($logFile.Length -gt 0))
	{
		$infoMessage = "Completed Invoke-ftpListCheckGet"
		Invoke-Nicelog -event 'Info' -message $infoMessage -logfile $logFile
	}
} # End
} # Function Invoke-WinSCPGet

export-modulemember -function Invoke-ftpListCheckGet
