<##############################################################################

File:		Get-IssueNamesToRetrieve.ps1
Name:		Get-IssueNamesToRetrieve

Purpose:	

Params:		

Called by:	Windows Scheduler
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20180111
Version:    1.0.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20180111	ffortunato		Initial iteration.

##############################################################################>


function Get-IssueNamesToRetrieve {


<#

.SYNOPSIS
This script will download the qualtrics data export based on a scheduled task 
call.

.DESCRIPTION
Desc...

.EXAMPLE

#>

    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [parameter(Mandatory=$true,
			Position = 0)]
        [alias("fl")]
        $dtFileList,

        [parameter(Mandatory=$true,
			Position = 1)]
        [alias("pubnc","p")]
        [string]$strPublicationCode,
        
        [parameter(Mandatory=$true,
			Position = 2)]
        [alias("sc")]
        [System.Data.SqlClient.SqlConnection]$SqlCon
        )

begin
{

    # check to see if the connection is valid and open.

} # begin

process
{

    # Prime the data table

    <#
    [System.Data.DataTable] $dtFilesToGet      = New-Object Data.datatable
    $dtFileList.Columns.Add("IssueName")       | Out-Null
    $dtFileList.Columns.Add("FileAction")      | Out-Null
    #>


    #[string]$dbServer = 'DEDTEDLSQL01' #$configFileContent.BPIServer.DatabaseServer
    #$SqlCon = New-Object System.Data.SqlClient.SqlConnection
    #$SqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Integrated Security=True"
    #$SqlCon.Open()

    try
    {


        $dtFilesToGet   = New-Object System.Data.DataTable
        $sqlCmd         = New-Object System.Data.SqlClient.SqlCommand ("ctl.GetIssueDownloadList", $SqlCon)
        $sqlAdapter     = New-Object System.Data.SqlClient.SqlDataAdapter
        $tableParameter = New-Object System.Data.SqlClient.SqlParameter

        $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

        # We need to be explicit about the table parameter we are passing.
        $tableParameter.ParameterName = '@pIssueNameLookup'
        $tableParameter.SqlDbType     = 'Structured'
        $tableParameter.Value         = $dtFileList
        $tableParameter.Direction     = 'Input'

        $sqlCmd.Parameters.Add($tableParameter) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pPublicationCode", $strPublicationCode) | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pLookBack", '1/1/2018') | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pETLExecutionId", '-1') | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pPathId", '-1') | Out-Null
        $sqlCmd.Parameters.AddWithValue("@pVerbose", '0') | Out-Null

        $Reader = $sqlCmd.ExecuteReader()
        $dtFilesToGet.Load($Reader)

        $dtFilesToGet
    }
    catch
    {
        write-error $_.Exception.Message
    } # catch
} # process
end
{

} # end
} # function


export-modulemember -function Get-IssueNamesToRetrieve