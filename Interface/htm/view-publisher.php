<?PHP
require('../includes/functions.php');
DisplayErrors();
StartSession();
include('../connections/connX.php');
require_once('../includes/TableStyles.css');
require_once('../includes/Styles.css');

// header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar)
header_start($HeaderTitle, 0, 0, 0, 0, '', '', 0);

echo "<body>";
TopMenu();
echo "<center>";
echo "<br>";

/*
if (isset($_SESSION['VAR_DimUserID'])){ // logged in

	// check to make sure they are an admin
	$tsql_AdminCheck = "select dbo.fn_AdminCheck(?, ?) as IsAdmin";
	$params_AdminCheck = array($_SESSION['VAR_DimUserID'], IsNumeric($_GET['cid']));
	$stmt_AdminCheck = sqlsrv_query($conn, $tsql_AdminCheck, $params_AdminCheck);
	$row_AdminCheck = sqlsrv_fetch_array($stmt_AdminCheck, SQLSRV_FETCH_ASSOC);


	if ($row_AdminCheck['IsAdmin'] == 1){

		echo "<img src='/images/icons/vcard_add.png'> <font class='darkblue-13px'><b>New User Account</b></font>";
		echo "<table id='rt-darkblue' width='425' border='0' cellspacing='2' cellpadding='0'>";
			echo "<tr>";
				echo "<td>";


				echo "</td>";
			echo "</tr>";
		echo "</table>";


	} // end: check if admin



} // end: check if logged in
*/


$tsql_getPublisherInfo = "select 
PublisherId
,PublisherCode
,PublisherName
,PublisherDesc 
,InterfaceCode
,SiteURL
,SiteUser
,SitePort
,SiteProtocol
,CreatedBy
,CreatedDtm
from [ctl].[Publisher]
WHERE PublisherId=?";
$params_getPublisherInfo = array(IsNumeric($_GET['pid']));
$stmt_getPublisherInfo = sqlsrv_query($conn, $tsql_getPublisherInfo, $params_getPublisherInfo);
$row_getPublisherInfo = sqlsrv_fetch_array($stmt_getPublisherInfo, SQLSRV_FETCH_ASSOC);

// PUBLISHER INFO ======================================================================================================================================================================================
//printf("&nbsp;&nbsp;<img src='/images/icons/bullet_arrow_down.png' border='0'> <font class='darkgrey-14px'><b>%s Information</b></font>", $row_getPublisherInfo['TypeName']);
echo "&nbsp;&nbsp;<img src='/images/icons/bullet_arrow_down.png' border='0'> <font class='darkgrey-14px'><b>Publisher Information</b></font>";
echo "<table id='rt-darkblue' width='600' border='0' cellspacing='2' cellpadding='2'>";
	echo "<tr>";
		echo "<td width='125' align='left'><font class='darkgrey-14px'><b>Publisher Code</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['PublisherCode']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Name</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['PublisherName']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Description</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['PublisherDesc']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Interface Code</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['InterfaceCode']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Site URL</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['SiteURL']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Site User</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['SiteUser']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Site Port</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['SitePort']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Created By</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['CreatedBy']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Created DateTime</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getPublisherInfo['CreatedDtm'], 'm/d/Y H:i:s'));
	echo "</tr>";

//	table_space();

//	if ($row_getPublisherInfo['Description']) {
//		table_space();
//		echo '<tr><td align="left"><font class="darkgrey-13px"><u><b>Description</b></u></font></td></tr>';
//		printf('<tr><td align="left"><font class="darkgrey-13px">%s</font></td></tr>', iconv("Windows-1252", "UTF-8", $row_getPublisherInfo['Description']));
//	}


//if (isset($_SESSION['VAR_DimUserID']) && $row_AdminCheck['IsAdmin'] == 1){
	//small_space();
//	printf("<tr><td colspan='2'><div align='center'><img src='/images/icons/application_form_edit.png' border='0'> <a href='edit-.php?cid=%s'><font class='darkblue-12px'>Edit Information</font></a></div></td></tr>", $row_getPublisherInfo['DimID']);
table_space();
	//small_space();
	echo "<tr><td colspan='2'><div align='center'>";
		printf("<img src='/images/icons/application_form_delete.png' border='0'> <a href='delete-publisher.php?pid=%s'><font class='darkblue-12px'>Delete Publisher</font></a>"
			, $row_getPublisherInfo['PublisherId']);
		echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		printf("<img src='/images/icons/application_form_edit.png' border='0'> <a href='edit-publisher.php?pid=%s'><font class='darkblue-12px'>Edit Publisher</font></a>"
			, $row_getPublisherInfo['PublisherId']);
	echo "</div></td></tr>";

//} // end: logged in and admin


/*
if (isset($_SESSION['VAR_DimUserID'])){

	$tsql_PermissionsCheck = "select dbo.fn_GetRoleBy(?, ?) as UserTypeName";
	$params_PermissionsCheck = array($_SESSION['VAR_DimUserID'], IsNumeric($_GET['cid']));
	$stmt_PermissionsCheck = sqlsrv_query($conn, $tsql_PermissionsCheck, $params_PermissionsCheck);
	$row_PermissionsCheck = sqlsrv_fetch_array($stmt_PermissionsCheck, SQLSRV_FETCH_ASSOC);

	if (!in_array($row_PermissionsCheck['UserTypeName'], array(' Admin',' Employee'))){

		$tsql_getSavedCount = "select count(*) as RecordCount from dbo.FactSaved where DimUserID=? and DimID=?";
		$params_getSavedCount = array($_SESSION['VAR_DimUserID'], IsNumeric($_GET['cid']));
		$stmt_getSavedCount = sqlsrv_query($conn, $tsql_getSavedCount, $params_getSavedCount);
		$row_getSavedCount = sqlsrv_fetch_array($stmt_getSavedCount, SQLSRV_FETCH_ASSOC);

		//echo "<form name='saved-s' action='post'>";
		echo "<form method='post' name='saved-s' style='margin-bottom:5;margin-top:5;'>";
		if ($row_getSavedCount['RecordCount'] == 0){
			echo "<tr><td colspan='2' align='center'><input type='Submit' name='Submit' value='Save '></td></tr>";
		} else {
			echo "<tr><td colspan='2' align='center'><input type='Submit' name='Submit' value='Remove '></td></tr>";
		}
		echo "</form>";
		//echo "<input type='submit' name='Submit' value='Apply Discount'>";
	} // end: check if they should see the buttons
} // end: check if logged in
*/



echo "</table>";

small_space();
small_space();
echo "<a href='view-publishers.php'><font class='darkgrey-13px'>Back to Publisher List</font></a>";
small_space();


footer();

echo "</center>";
echo "</body>";
echo "</html>";
?>
