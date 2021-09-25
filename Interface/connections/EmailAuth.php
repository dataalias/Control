<?PHP
require_once "../includes/PHPMailer/src/Exception.php";
require_once "../includes/PHPMailer/src/PHPMailer.php";
require_once "../includes/PHPMailer/src/SMTP.php";

$mail = new PHPMailer\PHPMailer\PHPMailer(true);                            			// Passing `true` enables exceptions

//Server settings
$mail->SMTPDebug = 0;                                 									// Enable verbose debug output
$mail->isSMTP();                                     									// Set mailer to use SMTP

$mail->Host = 'smtp.gmail.com';  														// Specify main and backup SMTP servers (WAY faster than smtp-relay)
//$mail->Host = 'smtp-relay.gmail.com';  												// Specify main and backup SMTP servers
$mail->SMTPAuth = true;                               									// Enable SMTP authentication
$mail->Username = '@gmail.com';							     							// SMTP username
//$mail->Username = 'notifications@gmail.com';			   	 							// SMTP username
$mail->Password = '';                       											// SMTP password

/*
$mail->Host = 'smtp.gmail.com';  						// Specify main and backup SMTP servers
$mail->SMTPAuth = true;                               	// Enable SMTP authentication
$mail->Username = '@gmail.com';				        	// SMTP username
$mail->Password = '';                      			 	// SMTP password
*/

$mail->SMTPSecure = 'tls';                            									// Enable TLS encryption, `ssl` also accepted
$mail->Port = 587;                                    									// TCP port to connect to
$mail->setFrom('notifications@datahub.com', ' Data Hub');		// From
$mail->addReplyTo('support@datahub.com', ' Data Hub');			// Reply To
?>
