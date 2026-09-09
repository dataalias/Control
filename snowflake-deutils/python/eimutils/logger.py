"""
***********************************************************************************************************************
File: logger.py

Purpose: Provides a pre-configured logger with a stdout StreamHandler.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

import logging
import sys
from datetime import datetime, timezone


class _ISOFormatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):  # noqa: ARG002
        dt = datetime.fromtimestamp(record.created, tz=timezone.utc)
        return dt.strftime("%Y-%m-%dT%H:%M:%S.") + f"{dt.microsecond // 1000:03d}Z"


def get_logger(name: str, level: int = logging.INFO) -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        stream_handler = logging.StreamHandler(stream=sys.stdout)
        stream_handler.setFormatter(
            _ISOFormatter("%(asctime)s - %(levelname)s - %(name)s - %(message)s")
        )
        logger.addHandler(stream_handler)
        logger.propagate = False
    logger.setLevel(level)
    return logger


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
            2022-04-14  Initial Iteration.
ffortunato  2026-04-17  o logging was change by claude :-P.

*******************************************************************************
"""
