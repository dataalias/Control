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



		$tsql_getIssueList = "select top 100
		i.IssueId
		,i.CreatedDtm
		,pr.PublisherName
		,pn.PublicationCode
		--,pn.PublicationName
		,i.IssueName
		,s.StatusName
		,i.RecordCount
		,i.RetryCount
		,i.ReportDate
		from ctl.Issue as i
		inner join ctl.Publication as pn on i.PublicationId=pn.PublicationId
		inner join ctl.Publisher as pr on pn.PublisherId=pr.PublisherId
		inner join ctl.RefStatus as s on s.StatusId=i.StatusId
		order by CreatedDtm desc";
		//$params_getIssueList = array($_SESSION['VAR_DimUserID']);
		$stmt_getIssueList = sqlsrv_query($conn, $tsql_getIssueList);

//		echo "<img src='/images/icons/vcard.png'> <font class='darkgrey-14px'><b>Publishers</b></font>";
		echo "<img src='/images/icons/vcard.png'> <font class='darkblue-14px'><b>Issues</b></font>";
		echo "<table id='rt-darkblue' width='1000' border='0' cellspacing='0' cellpadding='3'>";

			echo "<tr bgcolor='#e0e0e0'>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Created DateTime</b></font></td>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Publisher Name</b></font></td>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Publication Code</b></font></td>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Issue Name</b></font></td>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Status Name</b></font></td>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Record Count</b></font></td>";
				echo "<td align='left'><font class='darkgrey-12px'><b>Retry Count</b></font></td>";
//				echo "<td align='left'><font class='darkgrey-12px'><b>Report DateTime</b></font></td>";
			echo "</tr>";

			$RowColor = 1;
			while ($row_getIssueList = sqlsrv_fetch_array($stmt_getIssueList, SQLSRV_FETCH_ASSOC)){
				printf("<tr bgcolor='%s'>", ($RowColor%2 ? '#FFFFFF' : '#f2f2f2'));
				$RowColor++;
					if ($row_getIssueList['StatusName'] == 'Issue Failed'){
						$FontColor = 'red-11px';
					} elseif ($row_getIssueList['StatusName'] == 'Issue Complete'){
						$FontColor = 'green-11px';
					} elseif ($row_getIssueList['StatusName'] == 'Issue Staging'){
						$FontColor = 'darkblue-11px';
					} else {
						$FontColor = 'darkgrey-11px';
					}

					printf('<td><font class="darkgrey-11px">%s</font></td>', date_format($row_getIssueList['CreatedDtm'], 'm/d/Y H:i:s'));
//					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getIssueList['PublicationName']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getIssueList['PublisherName']));
					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getIssueList['PublicationCode']));
//					printf('<td><font class="darkgrey-11px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getIssueList['IssueName']));
					printf('<td><a href="view-issue.php?iid=%s"><font class="darkgrey-11px">%s</font></a></td>', $row_getIssueList['IssueId'], iconv("Windows-1252", "UTF-8", $row_getIssueList['IssueName']));
					printf('<td><font class="%s">%s</font></td>', $FontColor, iconv("Windows-1252", "UTF-8", $row_getIssueList['StatusName']));
					printf('<td align="center"><font class="darkgrey-11px">%s</font></td>', number_format($row_getIssueList['RecordCount'], 0));
					printf('<td align="center"><font class="darkgrey-11px">%s</font></td>', number_format($row_getIssueList['RetryCount'], 0));
//					printf('<td><font class="darkgrey-11px">%s</font></td>', date_format($row_getIssueList['ReportDate'], 'm/d/Y H:i:s'));
				echo "</tr>";
			}

		echo "</table>";

		//small_space();
		//echo "<img src='/images/icons/application_form_add.png' border='0'> <a href='add-publisher.php'><font class='darkblue-12px'>Add Publisher</font></a>";


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
