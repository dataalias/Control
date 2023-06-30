"""
********************************************************************************
File:		deUtils/delogging/delogging.py
Name:		delogging
Purpose:	Logg to all sorts of different places.
Author:		ffortunato
Date:		20220401
********************************************************************************
"""

import paramiko
from delogging.delogging import log_to_console

"""
********************************************************************************
Name:		OpenFTPConnection
Purpose:	Use provided ftp credentials to create an ftp connection.
Example:	OpenFTPConnection
Parameters:    
Called by:	
Calls:          
Errors:		
Author:		ffortunato
Date:		20220401
********************************************************************************
"""


def open_ftp_connection(ftp_host, ftp_port, ftp_username, ftp_password, ftp_directory):

	client = paramiko.SSHClient()
	client.load_system_host_keys()

	try:
		transport = paramiko.Transport(ftp_host, ftp_port)
		transport.default_window_size = 4294967294
		transport.packetizer.REKEY_BYTES = pow(2, 40)
		transport.packetizer.REKEY_PACKETS = pow(2, 40)

		# log_to_console(__name__, 'Info', "paramiko.Transport Success")
	except Exception as e:
		err_msg = "conn_error: " + str(e)
		log_to_console(__name__, 'Err', err_msg)
		return "conn_error"

	try:
		transport.connect(username=ftp_username, password=ftp_password)
		# log_to_console(__name__, 'Info', "transport.connect Success")
	except Exception as e:
		err_msg = "auth_error: " + str(e)
		log_to_console(__name__, 'Err', err_msg)
		return "auth_error"

	try:
		ftp_connection = paramiko.SFTPClient.from_transport(transport)
		log_to_console(__name__, 'Info', "Connected to FTP site successfully.")
		ftp_connection.chdir(ftp_directory)

	except Exception as e:
		err_msg = "connection or change dir failure: " + str(e)
		log_to_console(__name__, 'Err', err_msg)
		return {'Status': 'Failure'}
	
	return ftp_connection
# End of open_ftp_connection


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  04/12/2022  Initial Iteration
ffortunato  07/29/2022  Fewer output messages.


*******************************************************************************
"""