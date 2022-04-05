<##############################################################################

File:		Edit-Issue.ps1
Name:		Edit-Issue

Purpose:	


Params:    

        [string]$dbServer,

Called by:	
Calls:		n/a  

Errors:		1001 - unable to establish a connection to db.
			1002 - unable to insert the new issue record.

Author:		ffortunato
Date:		20171207
Version:    v01.03

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20171207	ffortunato		Initial iteration.
20180223	ffortunato		Made a few edits regarding src created dt.

##############################################################################>

function Edit-Issue {

<#

.SYNOPSIS
This function passes updates an existing issue id with new values passed as
paramaters.

.DESCRIPTION
This function passes updates an existing issue id with new values passed as
paramaters.

.EXAMPLE
Set an issue to failed.
:> Edit-Issue  -dbsn 'dedtedlsql01' -iss 1 -stat 'IF'

#>

    [CmdletBinding(
        DefaultParameterSetName=”Folder”,
        SupportsShouldProcess=$True
    )]
    param (
        [parameter(Mandatory=$true,
			Position = 0)]
        [alias("dbsn")]
        [string]$dbServer,
        
        [parameter(Mandatory=$true,
			Position = 1)]
        [alias("iss")]
        [string]$issueId,

        [parameter(Mandatory=$false,
			Position = 2)]
        [alias("stat")]
        [string][AllowNull()]$statusCode=$null,
        
        [parameter(Mandatory=$false,
			Position = 3)]
        [alias("rptdt")]
        [datetime][AllowNull()]$reportDate,
        
        [parameter(Mandatory=$false,
			Position = 4)]
        [alias("sPubrId")]
        [string][AllowNull()]$srcDFPublisherId=$null,

        [parameter(Mandatory=$false,
			Position = 5)]
        [alias("sPubnId")]
        [string][AllowNull()]$srcDFPublicationId,
        
        [parameter(Mandatory=$false,
			Position = 6)]
        [alias("sId")]
        [string][AllowNull()]$srcDFIssueId,
        
        [parameter(Mandatory=$false,
			Position = 7)]
        [alias("sDt")]
        [datetime][AllowNull()]$srcDFCreatedDate,

        [parameter(Mandatory=$false,
			Position = 8)]
        [alias("iName")]
        [string][AllowNull()]$issueName,

		[parameter(Mandatory=$false,
			Position = 9)]
        [alias("pubSeq")]
        [int][AllowNull()]$publicationSeq=-1,

        [parameter(Mandatory=$false,
			Position = 10)]
        [alias("fId")]
        [int][AllowNull()]$firstRecordSeq,
        
        [parameter(Mandatory=$false,
			Position = 11)]
        [alias("lId")]
        [int][AllowNull()]$lastRecordSeq,

        [parameter(Mandatory=$false,
			Position = 12)]
        [alias("fChk")]
        [string][AllowNull()]$firstRecordChecksum,
        
        [parameter(Mandatory=$false,
			Position = 13)]
        [alias("lChk")]
        [string][AllowNull()]$lastRecordChecksum,
        
        [parameter(Mandatory=$false,
			Position = 14)]
        [alias("psd")]
        [datetime][AllowNull()]$periodStartDate,

        [parameter(Mandatory=$false,
			Position = 15)]
        [alias("ped")]
        [datetime][AllowNull()]$periodEndDate,

        [parameter(Mandatory=$false,
			Position = 16)]
        [alias("rc")]
        [int][AllowNull()]$recordCount
        
        ,[parameter(Mandatory=$false,
			Position = 17)]
        [alias("usr")]
        [string][AllowNull()]$curUser
    )
BEGIN
{   
    [int]$ErrorNumber = 0
    [string]$ErrorMessage = 'Succcess.'
    [string]$curHost  = hostname
    [datetime]$date     = Get-Date
}
PROCESS
{

	if  ( $curUser -eq $null)
	{
		[string]$curUser = whoami
	}

    try 
    {
        $SqlConn = New-Object System.Data.SqlClient.SqlConnection
        $SqlConn.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Integrated Security=True"
        $SqlConn.Open()
    }
    catch
    {
        $ErrorNumber = 1001
        $ErrorMessage = "Error Number : " + $ErrorNumber.ToString() + ' Error Message : ' + $_.Exception.Message + " Unable to open a connection to the database: $dbServer."`
            + " Date: $date Host: $curHost User: $curUser"
        Write-Error $ErrorMessage
        return 1001
    }

    try {
<# Testing
"BEGIN PARM
		$issueId
		$statusCode
		$ReportDate
		$SrcDFPublisherId
		$SrcDFPublicationId
		$SrcDFIssueId
srcCdt:	$SrcDFCreatedDate
issnam:	$issueName
pubseq:	$publicationSeq 
		$FirstRecordSeq 
		$LastRecordSeq
		$FirstRecordChecksum
		$LastRecordChecksum
		$PeriodStartDate
		$PeriodEndDate
		$IssueConsumedDate
		$recCount
		$curUser
		$date
'END PARM"
Testing #>    
        # update the issue record so ETL knows we are ready to go.
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_UpdateIssue]", $SqlConn)
        $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

        $sqlCmd.Parameters.AddWithValue("@pIssueId", $issueId) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pStatusCode", $statusCode) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pReportDate", $reportDate) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pSrcDFPublisherId", $srcDFPublisherId) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pSrcDFPublicationId", $srcDFPublicationId) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pSrcDFIssueId",$srcDFIssueId) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pSrcDFCreatedDate", $srcDFCreatedDate) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pIssueName", $issueName) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pPublicationSeq", $publicationSeq) | Out-Null 
        $sqlCmd.Parameters.AddWithValue("@pFirstRecordSeq", $firstRecordSeq) | Out-Null 
        $sqlCmd.Parameters.AddWithValue("@pLastRecordSeq", $lastRecordSeq) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pFirstRecordChecksum", $firstRecordChecksum) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pLastRecordChecksum", $lastRecordChecksum) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pPeriodStartTime", $periodStartDate) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pPeriodEndTime", $periodEndDate) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pIssueConsumedDate", $issueConsumedDate) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pRecordCount", $recCount) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pModifiedBy", $curUser) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pModifiedDtm", $date) | Out-Null


        if ($VerbosePreference -eq 'Continue') 
        {
            # Want the verbose parm sent to the stored procedure.
            $sqlCmd.Parameters.AddWithValue("@pVerbose", "1") | Out-Null
            $sqlCmd.ExecuteNonQuery() | Write-Host
        }
        else
        {
            $sqlCmd.Parameters.AddWithValue("@pVerbose", "1") | Out-Null
            $sqlCmd.ExecuteNonQuery() | Out-Null
        }

    } 
    catch
	{   
		$ErrorMessage =  "Edit Issue Failed. `r`n Message: " + $_.Exception.Message
        throw  $ErrorMessage
    } 
    finally 
	{
		$sqlCmd.Dispose()
		$SqlConn.Close()
    }

} # process
end
{
}
} # function New-Issue

export-modulemember -function Edit-Issue