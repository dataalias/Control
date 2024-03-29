"""
********************************************************************************
File:		deUtils/delogging/delogging.py
Name:		delogging
Purpose:	Logg to all sorts of different places.
Author:		ffortunato
Date:		20220401
********************************************************************************
"""

#imports

# Public Packages
from datetime import datetime

"""
********************************************************************************
Name:		LogToConsole
Purpose:	Logg to all sorts of different places.
Example:	LogToConsole(__name__,'Info','I\'m good enough.')
Parameters:    
Called by:	
Calls:          
Errors:		
Author:		ffortunato
Date:		20220401
********************************************************************************
"""


def log_to_console(function_name, message_type, message):

    current_time = datetime.today().strftime('%Y-%b-%d %H:%M:%S')

    try:
        # print(current_time + ',' + function_name + ',' + message_type + ',' + message)
        print(current_time, ',', function_name, ',', message_type, ',', message)
    except Exception as e:
        print("Unable to Log!", e)


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  04/14/2022  Initial Iteration

*******************************************************************************
"""