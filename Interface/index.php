<?PHP
require('includes/functions.php');
DisplayErrors();
StartSession();
include('connections/connX.php');
require_once('includes/TableStyles.css');
require_once('includes/Styles.css');

// header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar)
header_start($HeaderTitle, 0, 0, 0, 0, '', '', 0);

echo "<body>";
TopMenu();
echo "<center>";
echo "<br>";

echo "<h1 style='font-family: Arial, Times New Roman; font-size: 30px; color: #4d504d; text-shadow: 1px 1px #7d7d7d;'>
	Welcome to the Data Hub & Posting Groups Admin Portal</h1>";

//echo "<img src='/images/image2.jpg' border='1'>";
//echo "<img src='/images/image2-6.jpg' border='0'>";
//echo "<img src='/images/image2-6.jpg' border='1'>";

echo "<img src='/images/image2.jpg' border='1'>";
echo "&nbsp;&nbsp;";
echo "<img src='/images/image2-6.jpg' border='1'>";
echo "&nbsp;&nbsp;";
echo "<img src='/images/image1-2.jpg' border='1'>";

echo "<br>";
//echo "<br>";
//echo "<br>";

echo "<br>";
echo '<hr style="height:1px; border:none; color:#dbdbdb; background-color:#dbdbdb;" width="45%">';
echo "<br>";

// -------------------------------------------------------------------------------------------------
// Data Hub
// -------------------------------------------------------------------------------------------------
echo "<table width='800' cellpadding='4' cellspacing='0' id='rt-white'>";
	echo "<tr>";
		echo "<td align='center'><h2 style='font-family: Arial, Times New Roman; font-size: 22px; color: #275587; padding: 2px; margin: 0px;'><b><i class='fas fa-database'></i> Data Hub</b></h2></td>";
	echo "</tr>";

	echo "<tr>";
	echo "<td align='left' valign='top'>";
		echo "<h3 style='font-family: Arial, Times New Roman; font-size: 20px; color: #4d504d;'>";
			echo "Data Hub is intended to manage all data entering and exiting the organization that requires a “large” batch transfer of data. This can include data files or data tables that are delivered from a source system into the enterprise. The system will maintain meta data about each transfer, i.e. source and destination. It will log each data payload and the destination for the information. ";	
		echo "</h3>";
	echo "</td>";
	echo "</tr>";

echo "</table>";
// -------------------------------------------------------------------------------------------------
echo "<br>";
echo '<hr style="height:1px; border:none; color:#dbdbdb; background-color:#dbdbdb;" width="45%">';
echo "<br>";
// -------------------------------------------------------------------------------------------------
// Posting Groups
// -------------------------------------------------------------------------------------------------
echo "<table width='800' cellpadding='4' cellspacing='0' id='rt-white'>";
	echo "<tr>";
		echo "<td align='center'><h2 style='font-family: Arial, Times New Roman; font-size: 22px; color: #275587; padding: 2px; margin: 0px;'><b><i class='fa fa-fw fa-check'></i> Posting Groups</b></h2></td>";
	echo "</tr>";

	echo "<tr>";
	echo "<td align='left' valign='top'>";
		echo "<h3 style='font-family: Arial, Times New Roman; font-size: 20px; color: #4d504d;'>";
			echo "Posting groups are used to orchestrate the processing of data within information systems. Processes can be complicated based on inter dependencies between processes. Posting Groups maintain metadata about discrete units of work that must be completed and the order that they must be completed. This system also maintains a history of the work taking place on the system in order to facilitate operational reporting and system restarts.";	
		echo "</h3>";
	echo "</td>";
	echo "</tr>";

echo "</table>";
// --------------------------------------------------------------------------------------------------

footer();

echo "</center>";
echo "</body>";
echo "</html>";
?>
