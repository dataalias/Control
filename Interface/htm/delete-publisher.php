<?PHP
require('../includes/functions.php');
DisplayErrors();
StartSession();
include('../connections/connX.php');
require_once('../includes/TableStyles.css');
require_once('../includes/Styles.css');

//if (isset($_SESSION['VAR_DimUserID'])){ // logged in

	// check to make sure they are an admin
//	$tsql_AdminCheck = "select dbo.fn_AdminCheck(?, ?) as IsAdmin";
//	$params_AdminCheck = array($_SESSION['VAR_DimUserID'], IsNumeric($_GET['cid']));
//	$stmt_AdminCheck = sqlsrv_query($conn, $tsql_AdminCheck, $params_AdminCheck);
//	$row_AdminCheck = sqlsrv_fetch_array($stmt_AdminCheck, SQLSRV_FETCH_ASSOC);


//	if ($row_AdminCheck['IsAdmin'] == 1){

		$tsql_getPublisherInfo = "select PublisherId, PublisherCode, PublisherName from [ctl].[Publisher] where PublisherId=?";
		$params_getPublisherInfo = array(IsNumeric($_GET['pid']));
		$stmt_getPublisherInfo = sqlsrv_query($conn, $tsql_getPublisherInfo, $params_getPublisherInfo);
		$row_getPublisherInfo = sqlsrv_fetch_array($stmt_getPublisherInfo, SQLSRV_FETCH_ASSOC);


		if (isset($_POST['Submit']) && $_POST['Submit'] == 'No'){
			echo "<html>";
			echo "<head>";
				//echo "<meta http-equiv='Refresh' content='0; url=http://localhost:8083/index.php' />";
				printf("<meta http-equiv='Refresh' content='0; url=view-publisher.php?pid=%s' />", $_GET['pid']);
				//printf("<a href='/htm/edit-amenities.php?cid=%s'><font class='darkgrey-13px'>Back to Amenities</font></a>", $_GET['cid']);

			echo "</head>";
			echo "<body>";
				//echo "<p>Please follow <a href='http://localhost:8083/index.php'>this link</a>.</p>";
			echo "</body>";
			echo "</html>";
		
		} elseif (isset($_POST['Submit']) && $_POST['Submit'] == 'Yes'){

			header_start($HeaderTitle, 0, 0, 0, 0, '', '', 0);

			echo "<body>";
			TopMenu();
			echo "<center>";
			echo "<br>";

			echo "<img src='/images/icons/application_form_delete.png'> <font class='darkblue-13px'><b>Delete Publisher</b></font>";
			small_space();
			
			// -- DELETE THE ENTRY
			$tsql_deletePublisher = "DELETE FROM ctl.Publisher WHERE PublisherId=?";
			$params_deletePublisher = array(IsNumeric($_GET['pid']));
			$stmt_deletePublisher = sqlsrv_query($conn, $tsql_deletePublisher, $params_deletePublisher);
			
			$SuccessMessage = sprintf("Publisher <i>%s</i> has been removed.", $row_getPublisherInfo['PublisherName']);
			SuccessMessage(650, $SuccessMessage);

			//echo "<br>";
			//printf("<a href='view-publisher.php?pid=%s'><font class='darkgrey-13px'>Back to %s</font></a>", $row_getPublisherInfo['PublisherId'], $row_getPublisherInfo['PublisherName']);
			small_space();

			footer();

			echo "</center>";
			echo "</body>";
			echo "</html>";
			
		
		} else { // end: check if approved or not. show form
		
			// header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar)
			header_start($HeaderTitle, 0, 0, 0, 0, '', '', 0);

			echo "<body>";
			TopMenu();
			echo "<center>";
			echo "<br>";

			echo "<img src='/images/icons/application_form_delete.png'> <font class='darkblue-13px'><b>Delete Publisher</b></font>";
			echo "<table id='rt-darkblue' width='650' border='0' cellspacing='0' cellpadding='4'>";
			echo "<tr>";
				echo"<td align='center'>";
//				small_space();
				
				printf("<br><font class='red-14px'><b>Are you sure you want to remove publisher <i>%s</i>?</b></font>", $row_getPublisherInfo['PublisherName']);
				small_space();
				echo "<form name='Delete' style='margin-bottom:5;margin-top:0;' method='post'>";
					echo "<input type='submit' name='Submit' value='Yes'>";
					echo "&nbsp;&nbsp;&nbsp;&nbsp;";
					echo "<input type='submit' name='Submit' value='No'>";
				echo "</form>";

				echo "</td>";
			echo "</tr>";
			echo "</table>";
		
			echo "<br>";
			//small_space();
			//small_space();
			printf("<a href='view-publisher.php?pid=%s'><font class='darkgrey-13px'>Back to %s</font></a>", $_GET['pid'], $row_getPublisherInfo['PublisherName']);

			footer();

			echo "</center>";
			echo "</body>";
			echo "</html>";

		} // check if submitted

//	} // end: check if admin

//} // end: check if logged in

?>
