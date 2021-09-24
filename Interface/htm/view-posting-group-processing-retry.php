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



		$tsql_getPGList = "exec pg.usp_SelectIncompletePostingGroupProcessing";
		//$params_getPGList = array($_SESSION['VAR_DimUserID']);
		$stmt_getPGList = sqlsrv_query($conn, $tsql_getPGList);

		echo "<img src='/images/icons/monitor.png'> <font class='darkblue-14px'><b>Incomplete Posting Group Processing Activity</b></font>";
//		echo "<img src='/images/icons/monitor_go.png'> <font class='darkblue-14px'><b>Recent Activity</b></font>";
		echo "<table id='rt-darkblue' width='1200' border='0' cellspacing='0' cellpadding='3'>";

			echo "<tr bgcolor='#e0e0e0'>";
				echo "<td align='left' width='125'><font class='darkgrey-11px'><b>Created DateTime</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Posting Group Code</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Posting Group Name</b></font></td>";

				//echo "<td align='left'><font class='darkgrey-11px'><b>Interval Code</b></font></td>";
				//echo "<td align='left'><font class='darkgrey-11px'><b>Duration</b></font></td>";
				//echo "<td align='left'><font class='darkgrey-11px'><b>Status Code</b></font></td>";

				echo "<td align='left'><font class='darkgrey-11px'><b>Status Name</b></font></td>";
//				echo "<td align='left'><font class='darkgrey-11px'><b>ProcessingModeCode</b></font></td>";
				echo "<td align='left'><font class='darkgrey-11px'><b>Processing Mode Name</b></font></td>";

//				echo "<td align='left'><font class='darkgrey-11px'><b>Record Count</b></font></td>";
//				echo "<td align='left'><font class='darkgrey-11px'><b>Retry Count</b></font></td>";
			echo "</tr>";

			$RowColor = 1;
			while ($row_getPGList = sqlsrv_fetch_array($stmt_getPGList, SQLSRV_FETCH_ASSOC)){
				echo "test";
				printf("<tr bgcolor='%s'>", ($RowColor%2 ? '#FFFFFF' : '#f2f2f2'));
				$RowColor++;

					if ($row_getPGList['StatusName'] == 'Posting Group Failed'){
						$FontColor = 'red-11px';
					} elseif ($row_getPGList['StatusName'] == 'Posting Group Complete'){
						$FontColor = 'green-11px';
					} elseif ($row_getPGList['StatusName'] == 'Posting Group Processing'){
						$FontColor = 'darkblue-11px';
					} else {
						$FontColor = 'darkgrey-11px';
					}

					printf('<td><font class="darkgrey-11px">%s</font></td>', date_format($row_getPGList['CreatedDtm'], 'm/d/Y H:i:s'));
//					printf('<td><a href="view-publisher.php?pid=%s"><font class="darkgrey-11px">%s</font></a></td>', $row_getPGList['PublisherId'], iconv("Windows-1252", "UTF-8", $row_getPGList['PublisherName']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPGList['PostingGroupCode']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPGList['PostingGroupName']));
//					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPGList['IntervalCode']));
//					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPGList['SSISProject']));
//					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPGList['DurationChar']));
					printf('<td><font class="%s">%s</font></td>', $FontColor, iconv("Windows-1252", "UTF-8", $row_getPGList['StatusName']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPGList['ProcessingModeName']));
//					printf('<td align="center"><font class="darkgrey-11px">%s</font></td>', number_format($row_getPGList['RecordCount'], 0));
//					printf('<td align="center"><font class="darkgrey-11px">%s</font></td>', number_format($row_getPGList['RetryCount'], 0));
				echo "</tr>";
			}

		echo "</table>";


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
