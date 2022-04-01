<##############################################################################

File:		Invoke-SQLServerJob.ps1
Name:		Invoke-SQLServerJob

Purpose:	

Test Execution:		

Called by:	
Calls:		n/a  

Errors:		1001 - unable to establish a connection to db.


Author:		ffortunato
Date:		20180227
Version:    v01.03

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180227	ffortunato		Initial iteration.
20180301	ffortunato		Changing to SMO Behold!!!

##############################################################################>

function Invoke-SQLServerJob {

<#
.SYNOPSIS
This function will invoke a SQL Server job on the named server.

.DESCRIPTION
This function will invoke a SQL Server job on the named server.


.EXAMPLE
Invoke_SQLServerJob -d 'ServerName' -j 'JobName'
#>

    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [parameter(Mandatory=$true,
			Position = 0)]
        [alias("dbsn","d")]
        [string]$dbServer,
        
        [parameter(Mandatory=$true,
			Position = 1)]
        [alias("j")]
        [string]$jobName  
    )
BEGIN
{   

}
PROCESS
{
<#Testing
'Invoke_SQLServerJob'
'---Passed In----'
    "server: $dbServer"
    "job   : $jobName"
'----------------'
<##>
    try
    {
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
		$jobServer = New-Object Microsoft.SqlServer.Management.SMO.Server($dbServer) 
        $job = $jobServer.jobserver.jobs["$jobName"]
        if($job)
        {
<#TESTING
$job.Name  + "::" + $job.CurrentRunStatus
<##>
            # if the job is idel run it.
            if ($job.CurrentRunStatus -eq 'Idle')
            {
			    $job.Start()
				#HAX
				Start-Sleep -Seconds 2
            }
        }
    } #try
    catch
    {
        throw $_.Exception.Message
    }
} # process
END
{

}
} # function New-Issue

export-modulemember -function Invoke-SQLServerJob