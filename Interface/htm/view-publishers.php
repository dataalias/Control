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



		$tsql_getPublisherList = "select PublisherId, PublisherCode, PublisherName, PublisherDesc from [ctl].[Publisher] order by PublisherName";
		//$params_getPublisherList = array($_SESSION['VAR_DimUserID']);
		$stmt_getPublisherList = sqlsrv_query($conn, $tsql_getPublisherList);

//		echo "<img src='/images/icons/vcard.png'> <font class='darkgrey-14px'><b>Publishers</b></font>";
		echo "<img src='/images/icons/vcard.png'> <font class='darkblue-14px'><b>Publishers</b></font>";
		echo "<table id='rt-darkblue' width='900' border='0' cellspacing='0' cellpadding='3'>";

			echo "<tr bgcolor='#e0e0e0'>";
				echo "<td align='left'><font class='darkgrey-13px'><b>Code</b></font></td>";
				echo "<td align='left'><font class='darkgrey-13px'><b>Name</b></font></td>";
				echo "<td align='left'><font class='darkgrey-13px'><b>Description</b></font></td>";
				//echo "<td align='left'><font class='darkgrey-11px'><b><u></u></b></font></td>";
//				echo "<td align='center'>Edit";
//				echo "<td align='center'><font class='darkgrey-14px'><b><u>Description</u></b></font></td>";
			echo "</tr>";

			$RowColor = 1;
			while ($row_getPublisherList = sqlsrv_fetch_array($stmt_getPublisherList, SQLSRV_FETCH_ASSOC)){
				printf("<tr bgcolor='%s'>", ($RowColor%2 ? '#FFFFFF' : '#f2f2f2'));
				$RowColor++;
//					echo "<td>Test</td>";
					printf('<td><font class="darkgrey-13px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPublisherList['PublisherCode']));
//					printf('<td><a href="view-publisher.php?pid=%s"><font class="darkblue-14px">%s</font></a></td>', $row_getPublisherList['PublisherId'], iconv("Windows-1252", "UTF-8", $row_getPublisherList['PublisherName']));
					printf('<td><a href="view-publisher.php?pid=%s"><font class="darkgrey-13px">%s</font></a></td>', $row_getPublisherList['PublisherId'], iconv("Windows-1252", "UTF-8", $row_getPublisherList['PublisherName']));
					printf('<td><font class="darkgrey-13px">%s</font></td>', iconv("Windows-1252", "UTF-8", $row_getPublisherList['PublisherDesc']));
//					printf("<td><img src='/images/icons/application_form_edit.png'> <a href='edit-publisher.php?pid=%s'><font class='darkgrey-12px'>Edit</font></a></td>", $row_getPublisherList['PublisherId']);

				echo "</tr>";
			}

		echo "</table>";

		small_space();
		echo "<img src='/images/icons/application_form_add.png' border='0'> <a href='add-publisher.php'><font class='darkblue-12px'>Add Publisher</font></a>";


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
