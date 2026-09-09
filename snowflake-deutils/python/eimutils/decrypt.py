"""
***********************************************************************************************************************
File: decrypt.py

Purpose: decypt encrypted secter values.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
import re


"""
***********************************************************************************************************************
Function: getDERKey

Purpose:  decrypts a private key in DER format.

Parameters:
     dw30sfpkey - Encrypted private key in PEM format
     dw30sfpprs - Pssphrase for the encrypted private key

Calls:
Called by:
Returns:

***********************************************************************************************************************
"""


def getDERKey(dw30sfpkey: str, dw30sfpprs: str) -> bytes:
    key = bytes(dw30sfpkey, encoding="utf-8")
    passkey = bytes(dw30sfpprs, encoding="utf-8")
    p_key = serialization.load_pem_private_key(
        key, password=passkey, backend=default_backend()
    )
    return p_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )


"""
***********************************************************************************************************************
Function: getPEMKey

Purpose: decrypts a private key in PEM format.

Parameters:
     dw30sfpkey - Encrypted private key in PEM format
     dw30sfpprs - Pssphrase for the encrypted private key

Calls:
Called by:
Returns:

***********************************************************************************************************************
"""


def getPEMKey(dw30sfpkey: str, dw30sfpprs: str) -> str:
    key = bytes(dw30sfpkey, encoding="utf-8")
    passkey = bytes(dw30sfpprs, encoding="utf-8")
    p_key = serialization.load_pem_private_key(
        key, password=passkey, backend=default_backend()
    )
    pkb = p_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    pkb = pkb.decode("UTF-8")
    return re.sub("-*(BEGIN|END) PRIVATE KEY-*\n", "", pkb).replace("\n", "")


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
----------	----------	-----------------------------------------------------------------------------------------------
dan         2024-11-01  + initial iteration
ffortunato  2025-07-22  o formatting.
***********************************************************************************************************************
"""
