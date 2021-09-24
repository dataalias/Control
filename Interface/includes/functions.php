<?PHP
// --------------------------------------------------------------------------------------------------------------------------------
// --------------------------                  Data Hub / Posting Group Functions                     -----------------------------
// --------------------------------------------------------------------------------------------------------------------------------
// Site went live on: 
//
// free stock photos
// https://www.viralsweep.com/blog/free-stock-images-for-commercial-use/
// http://unsplash.com
// http://realisticshots.com/
// https://www.pexels.com/public-domain-images/
//
// https://fontawesome.com/cheatsheet
// https://fontawesome.com/icons?d=gallery&p=2
//
//$EnableShareBar = 0;

$TestMode = 0; // disable fees on the checkout page. DON'T ENABLE THIS ON PRODUCTION
$HeaderTitle = "Data Hub / Posting Group Admin Portal";

// --------------------------------------------------------------------------------------------------------------------------------
function DisplayErrors(){
	ini_set ('display_errors', '1');
}
// --------------------------------------------------------------------------------------------------------------------------------
function StartSession(){
	session_start();
	// prevent session hijacking
	if (isset($_SESSION['HTTP_USER_AGENT'])){
		if ($_SESSION['HTTP_USER_AGENT'] != md5($_SERVER['HTTP_USER_AGENT'])){
			exit;
		}
	} else {
		$_SESSION['HTTP_USER_AGENT'] = md5($_SERVER['HTTP_USER_AGENT']);
	}
}
// --------------------------------------------------------------------------------------------------------------------------------

// Header Start
// header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar)
function header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar){
//		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
//		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
	
		echo "<!doctype html>";
		echo "<html lang='en'>";
		echo "<head>";

			echo "<meta charset='utf-8'>";
			echo "<meta http-equiv='X-UA-Compatible' content='IE=edge'>";
			echo "<meta name='viewport' content='width=device-width, initial-scale=1'>";		
			printf("<title>%s</title>", $Title);

			if ($EnableShareBar == 1){
				echo "<script type='text/javascript' src='//platform-api.sharethis.com/js/sharethis.js#property=5a3c19579d192f00137433ba&product=sticky-share-buttons'></script>"; 
			} // end: check if share bar is enabled

			if ($EnableCountryAreaList == 1){
				echo "<script language='javascript' src='/includes/CountryAreaList.js'></script>";
			} // end: check if country area list is enabled

			echo "<script src='https://code.jquery.com/jquery-latest.min.js' type='text/javascript'></script>";
			echo "<script src='https://s3.amazonaws.com/menumaker/menumaker.min.js' type='text/javascript'></script>";
			echo "<script src='/includes/menu-script.js'></script>";
			echo "<link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css'>";
//			echo "<link rel='stylesheet' href='/includes/font-awesome.css'>";
			echo "<link rel='stylesheet' href='/includes/menu-styles.css'>";
//			echo "<script src='https://kit.fontawesome.com/b56f1f5923.js'></script>";
//			echo "<script src='/includes/b56f1f5923.js'></script>";
			echo "<script src='/includes/font-awesome.js'></script>";

			if ($EnableHighSlide == 1){ //----------------------------------------------------------------------------------------------------
				?>
				<!-- High Slide -->
				<script type="text/javascript" src="/includes/highslide/highslide-full.js"></script>
				<link rel="stylesheet" type="text/css" href="/includes/highslide/highslide.css" />
				
				<script type="text/javascript">
					hs.graphicsDir = '/includes/highslide/graphics/';
					hs.align = 'center';
					hs.transitions = ['expand', 'crossfade'];
					hs.outlineType = 'rounded-white';
					hs.fadeInOut = true;
					//hs.dimmingOpacity = 0.75;
				
					// Add the controlbar
					hs.addSlideshow({
						//slideshowGroup: 'group1',
						interval: 5000,
						repeat: false,
						useControls: true,
						fixedControls: 'fit',
						overlayOptions: {
							opacity: .75,
							position: 'bottom center',
							hideOnMouseOut: true
						}
					});
				</script>
			<?PHP
			} // end: check if high slide is enabled ------------------------------------------------------------------------------------------


			if ($EnableGoogleMaps == 1){ //----------------------------------------------------------------------------------------------------
				?>
				<script type="text/javascript"
				src="https://maps.googleapis.com/maps/api/js?key=AIzaSyD1iuooDwTOpurkrVELqDHDMW81SKZ14NY&sensor=false&libraries=weather">    
				</script>
				
				<style type="text/css">
					html, body, #map-canvas { height: 100%; margin: 0; }
				</style>
					
				<script type="text/javascript">
				function initialize() {
				var map = new google.maps.Map(
				document.getElementById('map-canvas'), {
				center: new google.maps.LatLng(<?PHP echo $LatDec; ?>, <?PHP echo $LngDec; ?>),
				zoom: 13,
				mapTypeId: google.maps.MapTypeId.ROADMAP
				});

				var marker = new google.maps.Marker({
					position: new google.maps.LatLng(<?PHP echo $LatDec; ?>, <?PHP echo $LngDec; ?>),
					map: map
				});			
				
				}
				google.maps.event.addDomListener(window, 'load', initialize);
				</script>
			<?PHP
			} // end: enable google maps ----------------------------------------------------------------------------------------------------

			if ($EnableCalendar == 1){
//				echo "<script language='JavaScript' src='/includes/calendar_us.js'></script>";
//				echo "<link rel='stylesheet' href='/includes/calendar.css'>";
				echo "<script language='JavaScript' src='./calendar_us.js'></script>";
				echo "<link rel='stylesheet' href='./calendar.css'>";
			} // end: check if share bar is enabled


			echo "<meta charset='UTF-8'>"; // HTML 5

		echo "</head>";
		codeBreak();
	//ini_set ('display_errors', '1'); 
}
// --------------------------------------------------------------------------------------------------------------------------------
function TopMenu(){

	// connect to db
	if (basename($_SERVER['PHP_SELF']) == 'index.php' || basename($_SERVER['PHP_SELF']) == 'index2.php'){
		include('connections/connX.php');
	} else {
		include('../connections/connX.php');
	}

	echo "<div id='cssmenu' class='align-center'>";
	echo "<ul>";
		// yellow
	   	//echo "<li><a href='/index.php' style='color:#fffeb0;'><i class='fas fa-'></i>  Reservations</a></li>";

		// white
//	   	echo "<li><a href='/index.php'><i class='fas fa-database'></i> DH/PG Portal</a></li>";
	   	echo "<li><a href='/index.php'><i class='fas fa-globe-americas'></i> DH/PG Portal</a></li>";

   		if (!isset($_SESSION['VAR_DimUserID'])){
			echo "<li><a href='#'><i class='fa fa-fw fa-cog'></i> Admin</a>";
				echo "<ul>";
//					echo "<li><a href='/htm/add-the-reservation-system-to-your-website.php'><i class='fas fa-book'></i> Publishers</a></li>";
					echo "<li><a href='/htm/view-publishers.php'><i class='fas fa-book-open'></i> Publishers</a></li>";
					echo "<li><a href='/htm/view-publications.php'><i class='fas fa-copy'></i> Publications</a></li>";
					echo "<li><a href='/htm/view-issues.php'><i class='fas fa-file'></i> Issues</a></li>";
//					echo "<li><a href='/htm/'><i class='fas fa-arrow-right'></i> Posting Groups</a></li>";
					echo "<li><a href='/htm/view-posting-groups.php'><i class='fa fa-fw fa-check'></i> Posting Groups</a></li>";
					echo "<li><a href='/htm/view-contacts.php'><i class='fas fa-user'></i> Contacts</a></li>";
				echo "</ul>";
			echo "</li>";

			echo "<li><a href='#'><i class='fas fa-desktop'></i> Monitoring</a>";
				echo "<ul>";
					echo "<li><a href='/htm/view-issue-activity.php'><i class='fas fa-desktop'></i> Issues</a></li>";
					echo "<li><a href='/htm/view-posting-group-processing-activity.php'><i class='fas fa-desktop'></i> Posting Group Processing</a></li>";
				echo "</ul>";
			echo "</li>";

			echo "<li><a href='#'><i class='fa fa-fw fa-cog'></i> Operations</a>";
				echo "<ul>";
					echo "<li><a href='/htm/view-data-hub-retry.php'><i class='fa fa-fw fa-check'></i> Data Hub Retry</a></li>";
					echo "<li><a href='/htm/view-posting-group-processing-retry.php'><i class='fa fa-fw fa-check'></i> Posting Group Processing Retry</a></li>";
				echo "</ul>";
			echo "</li>";

//       		echo "<li><a href='/htm/view-recent-activity.php'><i class='fa fa-fw fa-line-chart'></i> Recent Activity</a></li>";
       		//echo "<li><a href='/htm/add-user.php'><i class='fa fa-fw fa-user-plus'></i> Create Account</a></li>";
			echo "<li><a href='/htm/login.php'><i class='fa fa-fw fa-lock'></i> Login</a></li>";
		} else { // logged in options

		} // end: check if logged in

	echo "</ul>";
	echo "</div>";
}


// --------------------------------------------------------------------------------------------------------------------------------
function body() {echo "<body>";}
//function body() {echo "<body style='margin: 2; padding: 0;'>";}
// --------------------------------------------------------------------------------------------------------------------------------
function footer(){
	small_space();
	echo '<hr style="height:2px; border:none; color:#dbdbdb; background-color:#dbdbdb;">';
	small_space();

	echo "<a href='https://www.zovio.com' target='_blank'><font class='grey-12px'>Zovio.com</font></a>";

	echo "&nbsp;&nbsp;<font class='grey-11px'>-</font>&nbsp;&nbsp";
	echo "<a href='https://www.facebook.com/ZovioSolutions' target='_blank'><font class='fab fa-facebook-square' style='font-size: 12px; color: rgb(156, 156, 156);'></font></a>";
//	echo "&nbsp;&nbsp;<font class='grey-11px'>-</font>&nbsp;&nbsp";
	echo "&nbsp;&nbsp;";
	echo "&nbsp;&nbsp;";
	echo "<a href='https://twitter.com/ZovioSolutions' target='_blank'><font class='fab fa-twitter-square' style='font-size: 12px; color: rgb(156, 156, 156);'></font></a>";
//	echo "&nbsp;&nbsp;";
//	echo "<a href='https://www.linkedin.com/company/' target='_blank'><font class='fab fa-linkedin' style='font-size: 12px; color: rgb(156, 156, 156);'></font></a>";
//	echo "&nbsp;&nbsp;";
//	echo "<a href='https://www.instagram.com/' target='_blank'><font class='fab fa-instagram' style='font-size: 12px; color: rgb(156, 156, 156);'></font></a>";

	echo "<br>";
	printf("<font class='grey-12px'>Copyright &#169; %s Zovio. All rights reserved</font>", date('Y'));

	echo "<br><br>";
}
// --------------------------------------------------------------------------------------------------------------------------------
function small_space(){
	echo "<table border='0'><tr><td height='5'></td></tr></table>";
}
function small_space2($height){
	printf("<table border='0'><tr><td height='%s'></td></tr></table>", $height);
}
function table_space(){
	echo "<tr><td height='5'></td></tr>";
}
// --------------------------------------------------------------------------------------------------------------------------------
function ErrorMessage($width, $message){
	printf("<table id='rt-red' width='%s' border='0' cellspacing='2' cellpadding='4'>", $width);
		echo "<tr div align='center'>";
			echo "<td>";
				printf('<img src="/images/icons/error.png" border="0"> <font class="darkgrey-14px">%s</font>', $message);
			echo "</td>";
		echo "</tr>";
	echo "</table>";
}
// --------------------------------------------------------------------------------------------------------------------------------
function SuccessMessage($width, $message){
	printf("<table id='rt-green' width='%s' border='0' cellspacing='2' cellpadding='4'>", $width);
		echo "<tr div align='center'>";
			echo "<td>";
				printf('<img src="/images/icons/tick.png" border="0"> <font class="darkgrey-13px">%s</font>', $message);
			echo "</td>";
		echo "</tr>";
	echo "</table>";
}
// --------------------------------------------------------------------------------------------------------------------------------
function TitleBox($width, $icon, $align, $title, $message){
	printf("<table id='rt-blue1' width='%s' border='0' cellspacing='2' cellpadding='4'>", $width);
		echo "<tr>";
			echo "<td>";
				printf("<div align='center'><img src='/images/icons/%s'> <font class='darkgrey-13px'><b>%s</b></font></div>", $icon, $title);
				printf("<div align='%s'>", $align);
				printf('<font class="darkgrey-13px">%s</font>', $message);
				echo "</div>";
			echo "</td>";
		echo "</tr>";
	echo "</table>";
}
// --------------------------------------------------------------------------------------------------------------------------------
function MessageBox($width, $align, $message){
	printf("<table id='rt-blue1' width='%s' border='0' cellspacing='2' cellpadding='4'>", $width);
		echo "<tr>";
			echo "<td>";
				printf("<div align='%s'>", $align);
				printf('<font class="darkgrey-13px">%s</font>', $message);
				echo "</div>";
			echo "</td>";
		echo "</tr>";
	echo "</table>";
}
// --------------------------------------------------------------------------------------------------------------------------------
function ToolTip($message){
	sprintf("&nbsp;<div class='tooltip'><img src='/images/icons/information.png' border='0'><span class='tooltiptext'>%s</span></div>", $message);
}
// --------------------------------------------------------------------------------------------------------------------------------
function CurrencySymbol($conn, $cid){
	// get a 's selected currency code
	$tsql_CurrencySymbol = "select dc.HTMLCode
	from dbo.DimCurrency as dc
	inner join res.DimReservationSettings as drs on drs.DimCurrencyID=dc.DimCurrencyID
	where drs.DimID=?";
	$params_CurrencySymbol = array($cid);
	$stmt_CurrencySymbol = sqlsrv_query($conn, $tsql_CurrencySymbol, $params_CurrencySymbol);
	$row_CurrencySymbol = sqlsrv_fetch_array($stmt_CurrencySymbol, SQLSRV_FETCH_ASSOC);	
	return $row_CurrencySymbol['HTMLCode'];
}
// --------------------------------------------------------------------------------------------------------------------------------
function CurrencyCode($conn, $cid){
	// get a 's selected currency code
	$tsql_CurrencyCode = "select dc.CurrencyNameCode
	from dbo.DimCurrency as dc
	inner join res.DimReservationSettings as drs on drs.DimCurrencyID=dc.DimCurrencyID
	where drs.DimID=?";
	$params_CurrencyCode = array($cid);
	$stmt_CurrencyCode = sqlsrv_query($conn, $tsql_CurrencyCode, $params_CurrencyCode);
	$row_CurrencyCode = sqlsrv_fetch_array($stmt_CurrencyCode, SQLSRV_FETCH_ASSOC);	
	return $row_CurrencyCode['CurrencyNameCode'];
}
// --------------------------------------------------------------------------------------------------------------------------------
function NumberFormat($conn, $uid, $number, $decimalplaces){
	// take a number and format it to the users preference
	$tsql_NumberFormat = "select dnf.* 
	from dbo.DimNumberFormat as dnf
	inner join dbo.DimUser as du on du.DimNumberFormatID=dnf.DimNumberFormatID
	where du.DimUserID=?";
	$params_NumberFormat = array($uid);
	$stmt_NumberFormat = sqlsrv_query($conn, $tsql_NumberFormat, $params_NumberFormat);
	$row_NumberFormat = sqlsrv_fetch_array($stmt_NumberFormat, SQLSRV_FETCH_ASSOC);	
//	return number_format($number, $row_NumberFormat['DecimalPlaces'], $row_NumberFormat['DecimalPointChar'], $row_NumberFormat['ThousandsSeparatorChar']);
	return number_format($number, $decimalplaces, $row_NumberFormat['DecimalPointChar'], $row_NumberFormat['ThousandsSeparatorChar']);
}
// --------------------------------------------------------------------------------------------------------------------------------
function DateFormat($conn, $uid, $date){
	// take a date and format it to the users preference
	$tsql_DateFormat = "select df.DateFormat 
	from dbo.DimDateFormat as df
	inner join dbo.DimUser as du on du.DimDateFormatID=df.DimDateFormatID
	where du.DimUserID=?";
	$params_DateFormat = array($uid);
	$stmt_DateFormat = sqlsrv_query($conn, $tsql_DateFormat, $params_DateFormat);
	$row_DateFormat = sqlsrv_fetch_array($stmt_DateFormat, SQLSRV_FETCH_ASSOC);	
	return date_format($date, $row_DateFormat['DateFormat']);
}
// --------------------------------------------------------------------------------------------------------------------------------
function TimeFormat($conn, $uid, $datetime){
	// take a date and format it to the users preference
	$tsql_TimeFormat = "select tf.TimeFormat 
	from dbo.DimTimeFormat as tf
	inner join dbo.DimUser as du on du.DimTimeFormatID=tf.DimTimeFormatID
	where du.DimUserID=?";
	$params_TimeFormat = array($uid);
	$stmt_TimeFormat = sqlsrv_query($conn, $tsql_TimeFormat, $params_TimeFormat);
	$row_TimeFormat = sqlsrv_fetch_array($stmt_TimeFormat, SQLSRV_FETCH_ASSOC);	
	return date_format($datetime, $row_TimeFormat['TimeFormat']);
}
// --------------------------------------------------------------------------------------------------------------------------------
function DateTimeFormat($conn, $uid, $datetime){
	// take a date and format it to the users preference
	$tsql_DateTimeFormat = "select df.DateFormat, tf.TimeFormat 
	from dbo.DimUser as du 
	inner join dbo.DimDateFormat as df on du.DimDateFormatID=df.DimDateFormatID
	inner join dbo.DimTimeFormat as tf on du.DimTimeFormatID=tf.DimTimeFormatID
	where du.DimUserID=?";
	$params_DateTimeFormat = array($uid);
	$stmt_DateTimeFormat = sqlsrv_query($conn, $tsql_DateTimeFormat, $params_DateTimeFormat);
	$row_DateTimeFormat = sqlsrv_fetch_array($stmt_DateTimeFormat, SQLSRV_FETCH_ASSOC);	
	return date_format($datetime, $row_DateTimeFormat['DateFormat'].' '.$row_DateTimeFormat['TimeFormat']);
}
// --------------------------------------------------------------------------------------------------------------------------------
function DBNumberFormat($conn, $uid, $number){
	// use their format to undo it so that it can go into the db
	$tsql_NumberFormat = "select dnf.* 
	from dbo.DimNumberFormat as dnf
	inner join dbo.DimUser as du on du.DimNumberFormatID=dnf.DimNumberFormatID
	where du.DimUserID=?";
	$params_NumberFormat = array($uid);
	$stmt_NumberFormat = sqlsrv_query($conn, $tsql_NumberFormat, $params_NumberFormat);
	$row_NumberFormat = sqlsrv_fetch_array($stmt_NumberFormat, SQLSRV_FETCH_ASSOC);

	// apply to all
//	$FormattedNumber = str_replace("'", "", str_replace('-', '.', str_replace('/', '.', str_replace(' ', '', $number))));
	$FormattedNumber = str_replace("'", "", str_replace('/', '.', str_replace(' ', '', $number)));

	if ($row_NumberFormat['DimNumberFormatID'] == 2){
		// 1.234,56		flip
		$FormattedNumber = str_replace('.', '', $FormattedNumber); // remove the decimal. not needed
		$FormattedNumber = str_replace(',', '.', $FormattedNumber); // now change the comma into a decimal
	} elseif ($row_NumberFormat['DimNumberFormatID'] == 3 || $row_NumberFormat['DimNumberFormatID'] == 4){
		// 1 234,56		fix decimal
		// 1 234,56		fix decimal
		$FormattedNumber = str_replace(',', '.', $FormattedNumber);
	} 

	return $FormattedNumber;
}
// --------------------------------------------------------------------------------------------------------------------------------
function RemoveKeywords($input){
	$CleansedOutput = str_replace('iframe', '', $input);
	$CleansedOutput = str_replace('insert ', '', $CleansedOutput);
	$CleansedOutput = str_replace('update ', '', $CleansedOutput);
	$CleansedOutput = str_replace('delete ', '', $CleansedOutput);
	$CleansedOutput = str_replace('select ', '', $CleansedOutput);
//	$CleansedOutput = str_replace('http', '', $CleansedOutput); // external map links use this
	$CleansedOutput = str_replace('onload', '', $CleansedOutput);
	$CleansedOutput = str_replace('prompt', '', $CleansedOutput);
	$CleansedOutput = str_replace('--', '', $CleansedOutput);
//	$CleansedOutput = str_replace('script', '', $CleansedOutput); // try leaving out for now. messes up the word description
	$CleansedOutput = str_replace('</script>', '', $CleansedOutput);
	$CleansedOutput = str_replace('<script>', '', $CleansedOutput);
	$CleansedOutput = str_replace('exec ', '', $CleansedOutput);
	$CleansedOutput = str_replace('dbcc', '', $CleansedOutput);
	$CleansedOutput = str_replace('usp_', '', $CleansedOutput);
	$CleansedOutput = str_replace('sp_', '', $CleansedOutput);
	$CleansedOutput = str_replace('join', '', $CleansedOutput);
	$CleansedOutput = str_replace('union', '', $CleansedOutput);
	$CleansedOutput = str_replace('1=1', '', $CleansedOutput);
//	$CleansedOutput = str_replace(' where ', '', $CleansedOutput);
//	$CleansedOutput = str_replace(' or ', '', $CleansedOutput);
	return $CleansedOutput;
}
// --------------------------------------------------------------------------------------------------------------------------------
function CleanseInput($input){
	$CleansedOutput = RemoveKeywords($input);
	// cleanse inputs to prevent sql injections and XSS (Cross Site Scripting)
	$CleansedOutput = str_replace('"', '', $CleansedOutput);
	$CleansedOutput = str_replace('<', '', $CleansedOutput);
	$CleansedOutput = str_replace('>', '', $CleansedOutput);
	$CleansedOutput = str_replace('[', '', $CleansedOutput);
	$CleansedOutput = str_replace(']', '', $CleansedOutput);
	$CleansedOutput = str_replace('{', '', $CleansedOutput);
	$CleansedOutput = str_replace('}', '', $CleansedOutput);
//	$CleansedOutput = str_replace('(', '', $CleansedOutput);
//	$CleansedOutput = str_replace(')', '', $CleansedOutput);
	$CleansedOutput = str_replace('=', '', $CleansedOutput);
//	$CleansedOutput = str_replace('/', '', $CleansedOutput);	
	return $CleansedOutput;
}
// --------------------------------------------------------------------------------------------------------------------------------
function IsNumeric($input){
	// check if a value is numeric else exit
	if (is_numeric($input)){
		return $input;
	} else {
		exit();
	}
}
// --------------------------------------------------------------------------------------------------------------------------------
// code gets strung together. use this to put in a new line. cleans up code when you do a view source
function new_line(){
	echo "\n";
}
function codeBreak(){
	echo "\n\n";
}
// --------------------------------------------------------------------------------------------------------------------------------
// Do a specified number of line breaks
function breaks($break_num){
  $i = 0;
  while (++$i <= $break_num)
  {
    echo "<br>";
  }
}
// --------------------------------------------------------------------------------------------------------------------------------
//This function reads the extension of the file. It is used to determine if the file  is an image by checking the extension.
function getFileExtension($str) {
	$i = strrpos($str,".");
	if (!$i) { return ""; }
	$l = strlen($str) - $i;
	$ext = substr($str,$i+1,$l);
	return $ext;
}
// --------------------------------------------------------------------------------------------------------------------------------
function RotateImage($filename, $degrees) {
	$source = imagecreatefromjpeg($filename);
	$rotate = imagerotate($source, $degrees, 0);
	
	if (file_exists($filename)) {
		unlink($filename);
	}
	imagejpeg($rotate, $filename, 100); // 85 is my choice, make it between 0 - 100 for output image quality with 100 being the most luxurious		
	imagedestroy($source); // free the memory
	imagedestroy($rotate); // free the memory
}
// --------------------------------------------------------------------------------------------------------------------------------
function FormatURL($URL){
	return (substr($URL, 0, 7) == 'http://' ? $URL : 'http://'.$URL);
}
// --------------------------------------------------------------------------------------------------------------------------------
function CleansePhoneNumber($DirtyNum){
	$CleanNum = str_replace('-','',$DirtyNum);
	$CleanNum = str_replace('.','',$CleanNum);
	$CleanNum = str_replace('(','',$CleanNum);
	$CleanNum = str_replace(')','',$CleanNum);
	$CleanNum = str_replace(' ','',$CleanNum);
	$CleanNum = str_replace(':','',$CleanNum);

	return $CleanNum;
}

// --------------------------------------------------------------------------------------------------------------------------------
?>
