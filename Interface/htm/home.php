<?PHP
require('../includes/functions.php');
DisplayErrors();
StartSession();
include('../connections/connX.php');
// header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar)
header_start($HeaderTitle, 0, 0, 1, 0, '', '', 0);

require_once('../includes/TableStyles.css');
//require_once('includes/TableListStyles.css');
//require_once('includes/ProgressBarStyles.css');
require_once('../includes/Styles.css');


echo "<body>";
TopMenu();
echo "<center>";
echo "<br>";

if (isset($_SESSION['VAR_DimUserID'])){ // logged in
	$tsql_getUserInfo = sprintf("SELECT FirstName, EmailAddr FROM DimUser WHERE DimUserID=%s", $_SESSION['VAR_DimUserID']);
	$stmt_getUserInfo = sqlsrv_query($conn, $tsql_getUserInfo);
	$row_getUserInfo = sqlsrv_fetch_array($stmt_getUserInfo, SQLSRV_FETCH_ASSOC);

//	printf('<font class="darkgrey-14px">Welcome Back %s</font>', $row_getUserInfo['FirstName']);

//	TitleBox('700', 'vcard.png', 'center', 'Welcome Back '.$row_getUserInfo['FirstName'], '');
	TitleBox('700', 'vcard.png', 'center', 'Welcome Back '.$row_getUserInfo['FirstName'], 'You are logged in as '.$row_getUserInfo['EmailAddr']);


	//echo "<br>";
	//echo "<br>";
	//echo "<br>";

	small_space();



} else { // end: check to see if they are logged in
	echo "<table id='rt-darkblue' width='700' border='0' cellspacing='2' cellpadding='0'>";
		echo "<tr>";
			echo "<td align='center'>";
			echo "<font class='darkgrey-14px'>Please login to view this page.</font>";
			echo "</td>";
		echo "</tr>";
	echo "</table>";
}
//small_space();


small_space();
small_space();
RandomPhotoBox(700);

footer();

echo "</center>";
echo "</body>";
echo "</html>";
?>
