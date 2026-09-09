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
//$serverName = "<MY_SQL_SERVER>";
$serverName = "dme1edlsql01";
//$serverName = "(local)\MSSQLSERVER2K8";
$uid = "DataHubWeb";
$pwd = "";
//$database = "CSR2";
$database = "MY_DB_STAGE";
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
