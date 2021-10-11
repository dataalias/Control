<?PHP
require('../includes/functions.php');
DisplayErrors();
StartSession();
require_once('../connections/connX.php');

$ErrorCount = 0;
if (isset($_POST['Submit']) == 'Submit'){ // not logged in. show login form
	if ($_POST['EmailAddr'] && $_POST['Password']){
		$tsql_getUser = "select du.DimUserID, du.AccountEnabledFlag, dut.UserTypeName
		,Password = convert(varchar, DECRYPTBYPASSPHRASE(PassPhrase, [Password])) 
		from dbo.DimUser as du
		inner join dbo.DimUserType as dut on dut.DimUserTypeID = du.DimUserTypeID
		WHERE du.EmailAddr=?";
		$params_getUser = array(RemoveKeywords($_POST['EmailAddr']));
		$stmt_getUser = sqlsrv_query($conn, $tsql_getUser, $params_getUser);
		$row_getUser = sqlsrv_fetch_array($stmt_getUser, SQLSRV_FETCH_ASSOC);

		if (!$row_getUser['DimUserID']){  // no account found with that name
			//$wrong_username = 1;
			$ErrorCount = 1;
			$ErrorMsg = 'Invalid Email Address or Password';
		}else{
			if ($_POST['Password'] == $row_getUser['Password']){
				if ($row_getUser['AccountEnabledFlag'] == 1){
					// register session variables
					$_SESSION['VAR_DimUserID'] = $row_getUser['DimUserID'];
					$_SESSION['VAR_UserTypeName'] = $row_getUser['UserTypeName'];
					
					// update the last login datetime
					$tsql_updateLastLogin = "update dbo.DimUser set LastLoginDtm_UTC = getutcdate(), IPAddr=? where DimUserID=?";
					$params_updateLastLogin = array($_SERVER['REMOTE_ADDR'], $row_getUser['DimUserID']);
					$stmt_updateLastLogin = sqlsrv_query($conn, $tsql_updateLastLogin, $params_updateLastLogin);
				}else{
					//$disabled = 1;
					$ErrorCount = 1;
					$ErrorMsg = 'Account Disabled';
				}
			}else{
				//$wrong_password = 1;
				$ErrorCount = 1;
				//$ErrorMsg = 'Incorrect Password';
				$ErrorMsg = 'Invalid Email Address or Password';
			}
		}
	} else {
		//$ErrorCount = 0;
		$ErrorCount = 1;
		$ErrorMsg = 'Please Include an Email Address and Password';
	} // check if they submitted a username and password
	
} // check if they are logging in




if (isset($_SESSION['VAR_DimUserID'])){

	// if they are logged in, redirect them to the edit personal info page
	// <meta http-equiv="Refresh" content="0; url=https://www.w3docs.com" />
	echo "<html>";
	echo "<head>";
		echo "<meta http-equiv='Refresh' content='0; url=home.php' />";
	echo "</head>";
	echo "<body>";
		//echo "<p>Please follow <a href='/htm/edit-user-account.php'>this link</a>.</p>";
	echo "</body>";
	echo "</html>";

}else{ // show login form or not


	// header_start($Title, $EnableShareBar, $EnableCountryAreaList, $EnableHighSlide, $EnableGoogleMaps, $LatDec, $LngDec, $EnableCalendar)
	header_start($HeaderTitle, 0, 0, 0, 0, '', '', 0);

	require_once('../includes/TableStyles.css');
	//require_once('../includes/TableListStyles.css');
	//require_once('../includes/ProgressBarStyles.css');
	require_once('../includes/Styles.css');

	echo "<body>";
	TopMenu();
	echo "<center>";
	echo "<br>";


	if ($ErrorCount == 1){
			echo "<table id='rt-red' width='450' border='0' cellspacing='2' cellpadding='4'>";
				echo "<tr div align='center'>";
					echo "<td>";
						printf('<img src="/images/icons/error.png" border="0"> <font class="darkgrey-14px">%s</font>', $ErrorMsg);
					echo "</td>";
				echo "</tr>";
			echo "</table>";
			small_space();
	}
	echo "<img src='/images/icons/lock.png'> <font class='darkblue-13px'><b>Login</b></font>";
	echo "<form method='POST' NAME='login_form' style='margin-bottom:5;margin-top:5;'>";
		  echo "<table id='rt-darkblue' width='450' border='0' cellspacing='2' cellpadding='4'>";
			echo "<tr>";
				echo "<td width='92'><div align='right'><font class='darkgrey-14px'>Email </font></div></td>";
				echo "<td><div align='left'><input name='EmailAddr' type='email' size='35'></div></td>";
			echo "</tr>";
			echo "<tr>";
				echo "<td><div align='right'><font class='darkgrey-14px'>Password </font></div></td>";
				echo "<td><div align='left'><input name='Password' type='password' size='35'></div></td>";
			echo "</tr>";
			echo "<tr>";
				echo "<td colspan='2'><div align='center'><input type='submit' name='Submit' value='Submit'></div></td>";
			echo "</tr>";
		  echo "</table>";
	echo "</form>";
	//echo "<a href='forgot-password.php'><font class='darkgrey-11px'>Forgot Password</font></a>";
	//echo "&nbsp;&nbsp;-&nbsp;&nbsp;";
	//echo "<a href='add-user.php'><font class='darkgrey-11px'>Create New Account</font></a>";
	echo "<br>";
	//echo "<br>";
	//echo "<br>";
	//echo "<br>";

	small_space();
	footer();

	echo "</center>";
	echo "</body>";
	echo "</html>";
} // check if they are logged in

?>
