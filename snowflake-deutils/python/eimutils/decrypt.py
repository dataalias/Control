"""
***********************************************************************************************************************
File: decrypt.py

Purpose: decypt encrypted secter values.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

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
    try:
        key = bytes(dw30sfpkey, encoding="utf-8")
        passkey = bytes(dw30sfpprs, encoding="utf-8")
        p_key = serialization.load_pem_private_key(key, password=passkey)
        return p_key.private_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
    except (ValueError, TypeError) as e:
        raise ValueError(f"Failed to decrypt private key (DER): {e}") from e


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
    try:
        key = bytes(dw30sfpkey, encoding="utf-8")
        passkey = bytes(dw30sfpprs, encoding="utf-8")
        p_key = serialization.load_pem_private_key(key, password=passkey)
        pkb = p_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
        pkb = pkb.decode("UTF-8")
        return re.sub("-+(BEGIN|END) (ENCRYPTED )?PRIVATE KEY-+\n", "", pkb).replace("\n", "")
    except (ValueError, TypeError) as e:
        raise ValueError(f"Failed to decrypt private key (PEM): {e}") from e


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
----------	----------	-----------------------------------------------------------------------------------------------
dan         2024-11-01  + initial iteration
ffortunato  2025-07-22  o formatting.
***********************************************************************************************************************
"""
