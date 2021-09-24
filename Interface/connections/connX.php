<?PHP
/*Connect to the local server using Windows Authentication and specify
the AdventureWorks database as the database in use. To connect using
SQL Server Authentication, set values for the "UID" and "PWD"
 attributes in the $connectionInfo parameter. For example:
$connectionInfo = array("UID" => $uid, "PWD" => $pwd)); */

// sql server php driver
// http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=20098

//$serverName = "(local)";
//$serverName = ".";
//$serverName = "dedtedlsql01";
$serverName = "dme1edlsql01";
//$serverName = "(local)\MSSQLSERVER2K8";
$uid = "DataHubWeb";
$pwd = "1BE4AF70-3D37-4EDB-99C8-F1CE03BA07F6";
//$database = "CSR2";
$database = "BPI_DW_STAGE";
$connectionInfo = array("Database"=>$database, "UID" => $uid, "PWD" => $pwd);
$conn = sqlsrv_connect($serverName, $connectionInfo);

/*
// Testing
if( $conn )
{
     echo "Connection established.\n";
}
else
{
     echo "Connection could not be established.\n";
     die( print_r( sqlsrv_errors(), true));
}
*/

?>
