<##############################################################################

File:		New-Issue.ps1
Name:		New-Issue

Purpose:	

Test Execution:		



$dbServer = 'dedtedlsql01'
$IssueId = -1
$sqlConSSISDB = New-Object System.Data.SqlClient.SqlConnection
$sqlConSSISDB.ConnectionString = "Server=$($dbServer);Database=BPI_DW_STAGE;Integrated Security=SSPI" 
$sqlConSSISDB.Open()
$sqlConSSISDB
$IssueId = 0
$IssueId = New-Issue  -sqlCon $sqlConSSISDB -pubn 'ACCOUNTDIM-AU' -dfn 'account_ZOOM_dim_20070112.txt' -s 'IP' -sId 0 -sDt '1/2/2017' -fid 1 -lid 100 -fchk 'ABC' -lchk 'DEF' -psd '1/1/2017' `
        -ped '1/1/2017' -rc 100 -ETLId 99 -usr 'ffortunato' -iss ([ref]$IssueId)
"Error: " + $_.Exception.Message
"Issue: " + $IssueId
$sqlConSSISDB.Close()
$sqlConSSISDB.Dispose()

Params:    

        [string]$dbServer,
        [string]$pubnCode,
        [string]$dataFileName,
        [string]$statusCode,
        [string]$srcDFIssueId,
        [string]$srcDate,
        [int]$firstRecId,
        [int]$lastRecId,
        [string]$firstChecksum,
        [string]$lastChecksum,
        [datetime]$periodStartDate,
        [datetime]$periodEndDate,
        [int]$recordCount,
        [int]$ETLExecId,
        [string]$curUser,
        [int]$verbose1

Called by:	
Calls:		n/a  

Errors:		1001 - unable to establish a connection to db.
			1002 - unable to insert the new issue record.

Author:		ffortunato
Date:		20171012
Version:    v01.03

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20171012	ffortunato		Initial iteration.
20180227	ffortunato		Change write-error to throw.
20180302	ffortunato		Checking to see if i can add the issue based on 
							previous entries.
20180314	ffortunato		Passing IssueId by reference to squash some bugs
							with data type conversion issues:
							"System.Object[]" value of type "System.Object[]" 
							to type "System.Int32"
20181012	ffortunato		Passing sqlconnection
##############################################################################>

function New-Issue {

<#
.SYNOPSIS
This function invokes a stored procedure that allows for the creation of a 
new issue record within the ctl schema.

.DESCRIPTION
This function passes meta data about feeds that will be consumed by the 
data warehouse. The input parameters will be written to the ctl.issue
table. The resulting issue id is passed back to this function and returned
by the function to the caller.


.EXAMPLE
$IssueId = 0
$IssueId = New-Issue  -dbsn 'dedtedlsql01' -pubn 'ACCOUNTDIM-AU' -dfn 'account_dim_20070112.txt' -s 'IP' -sId 0 -sDt '1/2/2017' -fid 1 -lid 100 -fchk 'ABC' -lchk 'DEF' -psd '1/1/2017' -ped '1/1/2017' -rc 100 -ETLId 99 -usr 'ffortunato'
$_.Exception.Message
$IssueId
#>

    [CmdletBinding(SupportsShouldProcess=$True)]
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
		$sqlCon,
        
        [parameter(Mandatory=$true,
			Position = 1)]
        [alias("pubn")]
        [string]$pubnCode,
        
        [parameter(Mandatory=$false,
			Position = 2)]
        [alias("dfn")]
        [string]$dataFileName,
        
        [parameter(Mandatory=$true,
			Position = 3)]
        [alias("s")]
        [string]$statusCode,
        
        [parameter(Mandatory=$true,
			Position = 4)]
        [alias("sId")]
        [string]$srcDFIssueId,
        
        [parameter(Mandatory=$true,
			Position = 5)]
        [alias("sDt")]
        [string]$srcDate,

        [parameter(Mandatory=$true,
			Position = 6)]
        [alias("fId")]
        [int]$firstRecId,
        
        [parameter(Mandatory=$true,
			Position = 7)]
        [alias("lId")]
        [int]$lastRecId,

        [parameter(Mandatory=$true,
			Position = 8)]
        [alias("fChk")]
        [string]$firstChecksum,
        
        [parameter(Mandatory=$true,
			Position = 9)]
        [alias("lChk")]
        [string]$lastChecksum,
        
        [parameter(Mandatory=$true,
			Position = 10)]
        [alias("psd")]
        [datetime][AllowNull()]$periodStartDate,

        [parameter(Mandatory=$false,
			Position = 11)]
        [alias("ped")]
        [string][AllowNull()]$periodEndDate,

        [parameter(Mandatory=$true,
			Position = 12)]
        [alias("rc")]
        [int]$recordCount,
        
        [parameter(Mandatory=$true,
			Position = 13)]
        [alias("ETLId")]
        [int]$ETLExecId,

        [parameter(Mandatory=$true,
			Position = 14)]
        [alias("usr")]
        [string]$curUser,

		[parameter(Mandatory=$true,
		Position = 15)]
        [alias("iss")]
        [ref]$myIssueId
    )
BEGIN
{   
    [int]$ErrorNumber = 0
    [string]$ErrorMessage = 'Succcess.'
    [string]$curHost  = hostname
    [string]$curUser  = whoami
    [datetime]$date     = Get-Date


<#Testing
	"@pPublicationCode= "+ $pubnCode
	"@pIssueName= "+ $dataFileName
	"@pStatusCode= "+ $statusCode
	"@pSrcDFIssueId= "+ $srcDFIssueId
	"@pSrcDFCreatedDate= "+ $srcDate
	"@pFirstRecordSeq= "+ $firstRecId
	"@pLastRecordSeq= "+ $lastRecId
	"@pFirstRecordChecksum= "+ $firstChecksum
	"@pLastRecordChecksum= "+ $lastChecksum
	"@pPeriodStartTime= "+ $periodStartDate
	"@pPeriodEndTime= "+ $periodEndDate
	"@pRecordCount= "+ $recordCount
	"@pETLExecutionId= "+  $ETLExecId
	"@pCreateBy= "+ $curUser
	"@pVerbose= " + $verbose1
<##>


}
PROCESS
{
	[int]$issueExists = -1
	[int]$IssueId = -1
<#
    try 
    {
        $SqlCon = New-Object System.Data.SqlClient.SqlConnection
        $SqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Integrated Security=True"
        $SqlCon.Open()
    }
    catch
    {
        $ErrorNumber = 1001
        $ErrorMessage = "Error Number : " + $ErrorNumber.ToString() + ' Error Message : ' + $_.Exception.Message + " Unable to open a connection to the database: $dbServer."`
            + " Date: $date Host: $curHost User: $curUser"
        throw $ErrorMessage
    }
#>

	try
	{
		# if the file has previously been written to the database we should not write it a second time.

		$sql ="select count(1) as IssueCount from ctl.issue where IssueName = '$dataFileName'"
		$sqlCmd1     = New-Object System.Data.SqlClient.SqlCommand($sql,$sqlCon)
		$issueExists = $sqlCmd1.ExecuteScalar()
		$sqlCmd1.Dispose()
<#Testing
"Issue with same name count: $issueExists"
<##>
		if($issueExists -eq 0)
		{	
			$sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[ctl].[usp_InsertNewIssue]", $sqlCon)

			$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
			$sqlCmd.Parameters.AddWithValue("@pPublicationCode", $pubnCode) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pIssueName", $dataFileName) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pStatusCode", $statusCode) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pSrcDFIssueId", $srcDFIssueId) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pSrcDFCreatedDate", $srcDate) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pFirstRecordSeq", $firstRecId) | Out-Null 
			$sqlCmd.Parameters.AddWithValue("@pLastRecordSeq", $lastRecId) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pFirstRecordChecksum", $firstChecksum) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pLastRecordChecksum", $lastChecksum) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pPeriodStartTime", $periodStartDate) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pPeriodEndTime", $periodEndDate) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pRecordCount", $recordCount) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pETLExecutionId",  $ETLExecId) | Out-Null
			$sqlCmd.Parameters.AddWithValue("@pCreateBy", $curUser) | Out-Null
			$sqlCmd.Parameters.Add("@pIssueId", [System.Data.SqlDbType]::Int).Direction `
				= [System.Data.ParameterDirection]::Output
			$sqlCmd.Parameters.AddWithValue("@pVerbose", $verbose1) | Out-Null
			$sqlCmd.ExecuteNonQuery() | Out-Null

			$IssueId    = $sqlCmd.Parameters["@pIssueId"].Value 
			$sqlCmd.Dispose()
		} # if file doesn't exist.
    }
    catch
    {
        $sqlCmd.Dispose()
		$myIssueId.Value = $IssueId
        $ErrorNumber = 1002
        $ErrorMessage = "Error Number : " + $ErrorNumber.ToString() + ' Error Message : ' + $_.Exception.Message + " Unable to create issue record."
        throw $ErrorMessage        
    } 
	$myIssueId.Value = $IssueId

} # process
end
{
}
} # function New-Issue

export-modulemember -function New-Issue