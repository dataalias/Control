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

$UpdateCount = 0;
if (isset($_POST['Submit'])){
	
		$tsql_insertPublisher = "INSERT INTO ctl.Publisher (PublisherCode, PublisherName, PublisherDesc, ContactId, InterfaceCode, CreatedBy, CreatedDtm) 
			VALUES (?,?,?,?,?, 'jprom', getdate())";
		$params_insertPublisher = array(
			 CleanseInput($_POST['PublisherCode'])  // don't allow nulls
			,CleanseInput($_POST['PublisherName'])  // don't allow nulls
			,($_POST['PublisherDesc'] == '' ? NULL : CleanseInput($_POST['PublisherDesc']))
			,($_POST['ContactId'] == '' ? -1 : IsNumeric($_POST['ContactId']))
			,CleanseInput($_POST['InterfaceCode'])  // don't allow nulls
			);							
		$stmt_insertPublisher = sqlsrv_query($conn, $tsql_insertPublisher, $params_insertPublisher);

		// Get the ID that was just created
		$tsql_getPublisherID = "SELECT @@IDENTITY AS PublisherId";
		$stmt_getPublisherID = sqlsrv_query($conn, $tsql_getPublisherID);
		$row_getPublisherID = sqlsrv_fetch_array($stmt_getPublisherID, SQLSRV_FETCH_ASSOC);

		$SuccessMessage = sprintf("Publisher <a href='view-publisher.php?pid=%s'><font class='darkblue-13px'>%s</font></a> Added", $row_getPublisherID['PublisherId'], CleanseInput($_POST['PublisherName']));
		$UpdateCount = 1;
}


TitleBox (600, 'application_form_add.png', 'center', 'Add a Publisher', "");
small_space();


//if ($ErrorCount == 1){
//	ErrorMessage(640, $ErrorMsg);
//	small_space();
//} // error
if ($UpdateCount == 1){
	SuccessMessage(600, $SuccessMessage);
	small_space();
} // error



echo "<form name='add-publisher' method='post'>";
//echo "<img src='/images/icons/vcard_add.png'> <font class='darkblue-14px'><b>Add Publisher</b></font>";
echo "<table id='rt-darkblue' width='600' border='0' cellspacing='0' cellpadding='4'>";
	
		echo "<tr>";
			echo "<td width='150'><div align='right'><font class='darkgrey-14px'>Publisher Code </font></div></td>";
			echo "<td><div align='left'><input type='text' name='PublisherCode' size='20'></div></td>";
		echo "</tr>";

		echo "<tr>";
			echo "<td><div align='right'><font class='darkgrey-14px'>Publisher Name </font></div></td>";
			echo "<td><div align='left'><input type='text' name='PublisherName' size='20'></div></td>";
		echo "</tr>";

		echo "<tr>";
			echo "<td valign='top'><div align='right'><font class='darkgrey-14px'>Description </font></div></td>";
//			echo "<td><div align='left'><input type='text' name='PublisherDesc' size='50'></div></td>";
		  	echo "<td><div align='left'><textarea cols='50' rows='3' name='PublisherDesc'></textarea></div></td>";
		echo "</tr>";

		$tsql_ContactList = "select * from ctl.Contact order by Name";
		$stmt_ContactList = sqlsrv_query($conn, $tsql_ContactList);
		echo "<tr>";
			echo "<td><div align='right'><font class='darkgrey-14px'>Contact Name </font></div></td>";
			echo "<td>";
				echo "<select name='ContactId'>";
				while($row_ContactList = sqlsrv_fetch_array($stmt_ContactList, SQLSRV_FETCH_ASSOC)) {
					printf("<option value='%s'>%s</option>", $row_ContactList['ContactId']
					, $row_ContactList['Name']);
				}	
				echo "</select>";
			echo "</td>";
		echo "</tr>";


		$tsql_InterfaceList = "select * from ctl.RefInterface order by InterfaceName";
		$stmt_InterfaceList = sqlsrv_query($conn, $tsql_InterfaceList);
		echo "<tr>";
			echo "<td><div align='right'><font class='darkgrey-14px'>Interface Type </font></div></td>";
			echo "<td>";
				echo "<select name='InterfaceCode'>";
				while($row_InterfaceList = sqlsrv_fetch_array($stmt_InterfaceList, SQLSRV_FETCH_ASSOC)) {
					printf("<option value='%s'>%s</option>", $row_InterfaceList['InterfaceCode']
					, $row_InterfaceList['InterfaceName']);
				}	
				echo "</select>";
			echo "</td>";
		echo "</tr>";
echo "</table>";

small_space();

echo "<input type='submit' name='Submit' value='Submit'>";
echo "</form>";

/*
		echo "<tr>";
		echo "<td><div align='right'><font class='darkgrey-14px'>Reservable </font></div></td>";
			echo "<td><div align='left'>";
			echo "<input type='radio' name='IsReservableFlag' value='0'><font class='darkgrey-14px'>No</font>";
			echo "<input type='radio' name='IsReservableFlag' value='1' checked><font class='darkgrey-14px'>Yes</font>";
			echo "</div></td>";
		echo "</tr>";
*/


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


footer();

echo "</center>";
echo "</body>";
echo "</html>";
?>
