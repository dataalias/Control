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

//if (isset($_SESSION['VAR_DimUserID'])){ // logged in

	// check to make sure they are an admin
//	$tsql_AdminCheck = "select dbo.fn_AdminCheck(?, ?) as IsAdmin";
//	$params_AdminCheck = array($_SESSION['VAR_DimUserID'], IsNumeric($_GET['cid']));
//	$stmt_AdminCheck = sqlsrv_query($conn, $tsql_AdminCheck, $params_AdminCheck);
//	$row_AdminCheck = sqlsrv_fetch_array($stmt_AdminCheck, SQLSRV_FETCH_ASSOC);


//	if ($row_AdminCheck['IsAdmin'] == 1){



		$tsql_getRecentActivityList = "SELECT 
		TOP 100 
		pgp.CreatedDtm
		,pg.PostingGroupCode
		,pg.PostingGroupName
		,pg.IntervalCode
		,pg.SSISProject
		,pgp.DurationChar
		,pgp.RecordCount
		,pgp.RetryCount
		,s.StatusName
		FROM pg.PostingGroupProcessing as pgp
		inner join pg.PostingGroup as pg on pg.PostingGroupId=pgp.PostingGroupId
		inner join pg.RefStatus as s on s.StatusId=pgp.PostingGroupStatusId
		order by pgp.CreatedDtm desc";
		//$params_getRecentActivityList = array($_SESSION['VAR_DimUserID']);
		$stmt_getRecentActivityList = sqlsrv_query($conn, $tsql_getRecentActivityList);

//		echo "<img src='/images/icons/vcard.png'> <font class='darkgrey-14px'><b>Publishers</b></font>";
//		echo "<img src='/images/icons/vcard.png'> <font class='darkblue-14px'><b>Recent Activity</b></font>";
//		echo "<img src='/images/icons/database_start.png'> <font class='darkblue-14px'><b>Recent Activity</b></font>";
//		echo "<img src='/images/icons/lightning.png'> <font class='darkblue-14px'><b>Recent Activity</b></font>";
		echo "<img src='/images/icons/monitor.png'> <font class='darkblue-14px'><b>Posting Group Processing Activity</b></font>";
//		echo "<img src='/images/icons/monitor_go.png'> <font class='darkblue-14px'><b>Recent Activity</b></font>";
		echo "<table id='rt-darkblue' width='1200' border='0' cellspacing='0' cellpadding='3'>";

			echo "<tr bgcolor='#e0e0e0'>";
				echo "<td align='left' width='125'><font class='darkgrey-11px'><b>Created DateTime</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Posting Group Code</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Posting Group Name</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Interval Code</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>SSIS Project</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Duration</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Status Name</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Record Count</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Retry Count</b></font></td>";
			echo "</tr>";

			$RowColor = 1;
			while ($row_getRecentActivityList = sqlsrv_fetch_array($stmt_getRecentActivityList, SQLSRV_FETCH_ASSOC)){
				printf("<tr bgcolor='%s'>", ($RowColor%2 ? '#FFFFFF' : '#f2f2f2'));
				$RowColor++;

					if ($row_getRecentActivityList['StatusName'] == 'Posting Group Failed'){
						$FontColor = 'red-11px';
					} elseif ($row_getRecentActivityList['StatusName'] == 'Posting Group Complete'){
						$FontColor = 'green-11px';
					} elseif ($row_getRecentActivityList['StatusName'] == 'Posting Group Processing'){
						$FontColor = 'darkblue-11px';
					} else {
						$FontColor = 'darkgrey-11px';
					}

					printf('<td><font class="darkgrey-11px">%s</font></td>', date_format($row_getRecentActivityList['CreatedDtm'], 'm/d/Y H:i:s'));
//					printf('<td><a href="view-publisher.php?pid=%s"><font class="darkgrey-11px">%s</font></a></td>', $row_getRecentActivityList['PublisherId'], iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['PublisherName']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['PostingGroupCode']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['PostingGroupName']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['IntervalCode']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['SSISProject']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['DurationChar']));
					printf('<td><font class="%s">%s</font></td>', $FontColor, iconv("Windows-1252", "UTF-8", $row_getRecentActivityList['StatusName']));
					printf('<td align="center"><font class="darkgrey-11px">%s</font></td>', number_format($row_getRecentActivityList['RecordCount'], 0));
					printf('<td align="center"><font class="darkgrey-11px">%s</font></td>', number_format($row_getRecentActivityList['RetryCount'], 0));
				echo "</tr>";
			}

		echo "</table>";

//		small_space();
//		echo "<img src='/images/icons/application_form_add.png' border='0'> <a href='add-publisher.php'><font class='darkblue-12px'>Add Publisher</font></a>";


/*
		echo "<img src='/images/icons/vcard_add.png'> <font class='darkblue-13px'><b>New User Account</b></font>";
		echo "<table id='rt-darkblue' width='425' border='0' cellspacing='2' cellpadding='0'>";
			echo "<tr>";
				echo "<td>";


				echo "</td>";
			echo "</tr>";
		echo "</table>";
*/

//	} // end: check if admin



//} // end: check if logged in


footer();

echo "</center>";
echo "</body>";
echo "</html>";
?>
