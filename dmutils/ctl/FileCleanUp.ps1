<##############################################################################
File:		FileCleanUp.ps1
Name:		
Purpose:    Given a folder recurse through the structure and look for duplicate
            files. Create a list of duplicates. (later we may remove the 
            duplicates)


Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunto
Date:		

###############################################################################

      CHANGE HISTORY

###############################################################################

Date		Author			Description

--------  ------------	---------------------------------------------------
20171206  ffortunato	


##############################################################################>

function FileCleanUp {

<#

.SYNOPSIS
This function looks at the provided directory and creates control files for
each file.

.DESCRIPTION
...

.PARAMETER directory
The directory with files that need control files generated.

.PARAMETER publicationCode
The code for the particular file being retreived.

.EXAMPLE
FileCleanUp -dir "\\diskstation\DataStore\Music\Unknown Artist" -fm "Nada"

#>




    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
        [parameter(Mandatory=$true,
            Position = 0,
            HelpMessage=’The folder to look for files that do not already have a control.’
            )]
        [alias("directory")]
        [string]$dir,
		
	
        [parameter(Mandatory=$false,
            Position = 2,
            HelpMessage=’File Mask being processed.’
            )]
        [alias("fm")]
        [string]$fileMask	

	)

begin
{

}
process
{

$dbServer = "."

try
{
    $date = date
    "Start: $date"

    if ($dir -eq $null)
    {
	    throw "No directory provided. Mandatory field cannot be null or blank."
	    return 1001
    }

    $sqlCon = New-Object System.Data.SqlClient.SqlConnection
    $sqlCon.ConnectionString = "Server=$dbServer;Database=BPI_DW_Stage;Connection Timeout=60;Integrated Security=True"
    $sqlCon.Open()

    # update the issue record so ETL knows we are ready to go.
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand ("[dbo].[InsertMusic]", $SqlCon)
    $sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

    $sqlCmd.Parameters.Add("@pMusicFile", [System.Data.SqlDbType]::VarChar   ) | Out-Null
    $sqlCmd.Parameters.Add("@pFileCreatedDtm",[System.Data.SqlDbType]::DateTime) | Out-Null
    $sqlCmd.Parameters.Add("@pFullPath",[System.Data.SqlDbType]::VarChar) | Out-Null
    $sqlCmd.Parameters.Add("@pExtension",[System.Data.SqlDbType]::VarChar) | Out-Null
    $sqlCmd.Parameters.Add("@pFileHash",[System.Data.SqlDbType]::VarChar) | Out-Null
    $sqlCmd.Parameters.Add("@pFileSize",[System.Data.SqlDbType]::VarChar) | Out-Null
    $sqlCmd.Parameters.AddWithValue("@pVerbose", "1") | Out-Null

    Get-ChildItem -Path $dir -File -recurse -include *.mp3, *.m4a, *.wma, *.m3u, *.mp4 | ForEach-Object {

<#
        $inFile    = $_.FullName
        $extension = $_.Extension
	    $inFileNameOnly = $_.Name
	    $createDate = $_.CreationTime

        "InFile: $inFile"
        "Ext:    $extension"
	    "Name:   $inFileNameOnly"
	    "Create: $createDate"

$_
$_.FullName
$_.Length

#>

        $ScriptHashObj  = Get-FileHash  -Algorithm SHA256 -LiteralPath $_.FullName
#	    $hash           = $ScriptHashObj.Hash.ToString()

#	    "Hash:   $hash       "


        $sqlCmd.Parameters[0].Value = $_.Name
        $sqlCmd.Parameters[1].Value = $_.CreationTime
        $sqlCmd.Parameters[2].Value = $_.FullName
        $sqlCmd.Parameters[3].Value = $_.Extension
        $sqlCmd.Parameters[4].Value = $ScriptHashObj.Hash.ToString()
        $sqlCmd.Parameters[5].Value = $_.Length

        $sqlCmd.ExecuteNonQuery() | Out-Null
        $cnt ++

    } # for each
    $sqlCmd.Dispose | out-null
    $sqlCon.Close | out-null
} #try
catch
{
	throw $_.Exception.Message
	return $null
} # catch

    $date = date
    "End  : $date"
    "Recs : $cnt"


} # Process
} # function