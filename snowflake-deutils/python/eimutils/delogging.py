"""
********************************************************************************
File:		deUtils/delogging/delogging.py
Name:		delogging
Purpose:	Logg to all sorts of different places.
Author:		ffortunato
Date:		20220401
********************************************************************************
"""

import logging
from typing import Any

from eimutils.logger import get_logger

_LEVEL_MAP = {
    "debug": logging.DEBUG,
    "info": logging.INFO,
    "err": logging.ERROR,
    "error": logging.ERROR,
    "warn": logging.WARNING,
    "warning": logging.WARNING,
}

"""
********************************************************************************
Name:		log_to_console
Purpose:	Log to all sorts of different places.
Example:	log_to_console(__name__,'Info','I\'m good enough.')
Parameters:
Called by:
Calls:
Errors:
Author:		ffortunato
Date:		20220401
********************************************************************************
"""


def log_to_console(function_name: str, message_type: str, message: Any) -> None:
    level = _LEVEL_MAP.get(message_type.lower(), logging.INFO)
    logger = logging.getLogger(function_name)
    if not logger.handlers:
        logger = get_logger(function_name)
    logger.log(level, message)


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2022-04-14  Initial Iteration.
ffortunato  2023-11-01  Adding Data Dog logging.
jgabriel    2024-08-29  Removed Data Dog logging.
ffortunato  2025-07-22  o formatting
ffortunato  2025-10-13  o pad message_type to 5 characters.
ffortunato  2026-04-17  o logging was change by claude :-P.
*******************************************************************************
"""
