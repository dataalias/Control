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


$tsql_getIssueInfo = "select
i.IssueId
,pr.PublisherName
,pn.PublicationCode
,pn.PublicationName
,i.IssueName
,i.StatusId
,s.StatusName
,i.RecordCount
,i.RetryCount
,i.ReportDate
,i.PeriodStartTime
,i.PeriodEndTime
,i.IssueConsumedDate
,i.CreatedBy
,i.CreatedDtm
,i.ModifiedBy
,i.ModifiedDtm
from ctl.Issue as i
inner join ctl.Publication as pn on i.PublicationId=pn.PublicationId
inner join ctl.Publisher as pr on pn.PublisherId=pr.PublisherId
inner join ctl.RefStatus as s on s.StatusId=i.StatusId
WHERE i.IssueId=?";
$params_getIssueInfo = array(IsNumeric($_GET['iid']));
$stmt_getIssueInfo = sqlsrv_query($conn, $tsql_getIssueInfo, $params_getIssueInfo);
$row_getIssueInfo = sqlsrv_fetch_array($stmt_getIssueInfo, SQLSRV_FETCH_ASSOC);


$UpdateCount = 0;
if (isset($_POST['Submit'])){
	
	$tsql_updateIssue = "update ctl.Issue set StatusId=?, ModifiedDtm=getdate() where IssueId=?";
	$params_updateIssue = array(
		 CleanseInput($_POST['StatusId'])  // don't allow nulls
		,$row_getIssueInfo['IssueId']
		);							
	$stmt_updateIssue = sqlsrv_query($conn, $tsql_updateIssue, $params_updateIssue);

	$SuccessMessage = sprintf("Issue <a href='view-issue.php?iid=%s'><font class='darkblue-13px'>%s</font></a> Updated", $row_getIssueInfo['IssueId'], $row_getIssueInfo['IssueName']);
	$UpdateCount = 1;

	$tsql_getIssueInfo = "select
	i.IssueId
	,pr.PublisherName
	,pn.PublicationCode
	,pn.PublicationName
	,i.IssueName
	,i.StatusId
	,s.StatusName
	,i.RecordCount
	,i.RetryCount
	,i.ReportDate
	,i.PeriodStartTime
	,i.PeriodEndTime
	,i.IssueConsumedDate
	,i.CreatedBy
	,i.CreatedDtm
	,i.ModifiedBy
	,i.ModifiedDtm
	from ctl.Issue as i
	inner join ctl.Publication as pn on i.PublicationId=pn.PublicationId
	inner join ctl.Publisher as pr on pn.PublisherId=pr.PublisherId
	inner join ctl.RefStatus as s on s.StatusId=i.StatusId
	WHERE i.IssueId=?";
	$params_getIssueInfo = array(IsNumeric($_GET['iid']));
	$stmt_getIssueInfo = sqlsrv_query($conn, $tsql_getIssueInfo, $params_getIssueInfo);
	$row_getIssueInfo = sqlsrv_fetch_array($stmt_getIssueInfo, SQLSRV_FETCH_ASSOC);
}


TitleBox (600, 'application_form_edit.png', 'center', 'Edit an Issue', "");
small_space();


//if ($ErrorCount == 1){
//	ErrorMessage(640, $ErrorMsg);
//	small_space();
//} // error
if ($UpdateCount == 1){
	SuccessMessage(600, $SuccessMessage);
	small_space();
} // error





// ISSUE INFO ======================================================================================================================================================================================
//printf("&nbsp;&nbsp;<img src='/images/icons/bullet_arrow_down.png' border='0'> <font class='darkgrey-14px'><b>%s Information</b></font>", $row_getIssueInfo['TypeName']);
echo "<form name='edit-publisher' method='post'>";
echo "&nbsp;&nbsp;<img src='/images/icons/bullet_arrow_down.png' border='0'> <font class='darkgrey-14px'><b>Issue Information</b></font>";
echo "<table id='rt-darkblue' width='600' border='0' cellspacing='2' cellpadding='2'>";
	echo "<tr>";
		echo "<td width='140' align='left'><font class='darkgrey-14px'><b>Publisher Name</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['PublisherName']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Publication Code</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['PublicationCode']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Publication Name</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['PublicationName']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Issue Name</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['IssueName']));
	echo "</tr>";

	$tsql_StatusList = "select * from ctl.RefStatus order by StatusName";
	$stmt_StatusList = sqlsrv_query($conn, $tsql_StatusList);
	echo "<tr>";
		echo "<td><div align='left'><font class='darkgrey-14px'><b>Status Name</b></font></div></td>";
		echo "<td>";
			echo "<select name='StatusId'>";
			while($row_StatusList = sqlsrv_fetch_array($stmt_StatusList, SQLSRV_FETCH_ASSOC)) {
				//printf("<option value='%s'>%s</option>", $row_ContactList['ContactId'], $row_ContactList['Name']);
				printf("<Option value='%s' %s>%s</option>", $row_StatusList['StatusId'], ($row_StatusList['StatusId'] == $row_getIssueInfo['StatusId'] ? 'selected' : ''), $row_StatusList['StatusName']);
			}	
			echo "</select>";
		echo "</td>";
	echo "</tr>";

//	echo "<tr>";
//		echo "<td align='left'><font class='darkgrey-14px'><b>Status Name</b></font></td>";
//		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['StatusName']));
//	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Record Count</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", number_format($row_getIssueInfo['RecordCount'], 0));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Retry Count</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", number_format($row_getIssueInfo['RetryCount'], 0));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Report DateTime</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getIssueInfo['ReportDate'], 'm/d/Y H:i:s'));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Period Start DateTime</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getIssueInfo['PeriodStartTime'], 'm/d/Y H:i:s'));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Period End DateTime</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getIssueInfo['PeriodEndTime'], 'm/d/Y H:i:s'));
	echo "</tr>";

	if ($row_getIssueInfo['IssueConsumedDate']){
		echo "<tr>";
			echo "<td align='left'><font class='darkgrey-14px'><b>Issue Consumed DateTime</b></font></td>";
			printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getIssueInfo['IssueConsumedDate'], 'm/d/Y H:i:s'));
		echo "</tr>";
	} else {
		echo "<tr>";
			echo "<td align='left'><font class='darkgrey-14px'><b>Issue Consumed DateTime</b></font></td>";
			echo "<td align='left'><font class='darkgrey-14px'>&nbsp;</font></td>";
		echo "</tr>";
	}

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Created By</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['CreatedBy']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Created DateTime</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getIssueInfo['CreatedDtm'], 'm/d/Y H:i:s'));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Modified By</b></font></td>";
		printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", iconv("Windows-1252", "UTF-8", $row_getIssueInfo['ModifiedBy']));
	echo "</tr>";

	echo "<tr>";
		echo "<td align='left'><font class='darkgrey-14px'><b>Modified DateTime</b></font></td>";
		if ($row_getIssueInfo['ModifiedDtm']){
			printf("<td align='left'><font class='darkgrey-14px'>%s</font></td>", date_format($row_getIssueInfo['ModifiedDtm'], 'm/d/Y H:i:s'));
		} else {
			echo "<td align='left'><font class='darkgrey-14px'>&nbsp;</font></td>";
		}
	echo "</tr>";

//	table_space();

//	if ($row_getIssueInfo['Description']) {
//		table_space();
//		echo '<tr><td align="left"><font class="darkgrey-13px"><u><b>Description</b></u></font></td></tr>';
//		printf('<tr><td align="left"><font class="darkgrey-13px">%s</font></td></tr>', iconv("Windows-1252", "UTF-8", $row_getIssueInfo['Description']));
//	}

echo "</table>";

small_space();

echo "<input type='submit' name='Submit' value='Submit'>";
echo "</form>";

small_space();
small_space();
small_space();
printf("<a href='view-issue.php?iid=%s'><font class='darkgrey-13px'>Back to %s</font></a>", $row_getIssueInfo['IssueId'], $row_getIssueInfo['IssueName']);
small_space();

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



footer();

echo "</center>";
echo "</body>";
echo "</html>";
?>
