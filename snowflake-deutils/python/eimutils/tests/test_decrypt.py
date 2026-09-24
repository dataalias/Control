"""
Unit tests for decrypt.py — no AWS or Snowflake connectivity required.
"""

import pytest
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_decrypt.py")
    print("=" * 70)


def _make_encrypted_pem() -> tuple:
    """Generate a fresh RSA key pair and return (pem_str, passphrase_str)."""
    passphrase = b"test_passphrase_123"
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend(),
    )
    pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.BestAvailableEncryption(passphrase),
    )
    return pem.decode("utf-8"), passphrase.decode("utf-8")


class TestGetDERKey:
    def test_returns_bytes(self):
        from eimutils.decrypt import getDERKey
        pem_str, passphrase = _make_encrypted_pem()
        result = getDERKey(pem_str, passphrase)
        assert isinstance(result, bytes)

    def test_der_is_valid_private_key(self):
        from eimutils.decrypt import getDERKey
        pem_str, passphrase = _make_encrypted_pem()
        der_bytes = getDERKey(pem_str, passphrase)
        key = serialization.load_der_private_key(
            der_bytes, password=None, backend=default_backend()
        )
        assert key is not None

    def test_wrong_passphrase_raises(self):
        from eimutils.decrypt import getDERKey
        pem_str, _ = _make_encrypted_pem()
        with pytest.raises(Exception):
            getDERKey(pem_str, "wrong_passphrase")

    def test_invalid_pem_raises(self):
        from eimutils.decrypt import getDERKey
        with pytest.raises(Exception):
            getDERKey("not-a-pem-key", "passphrase")


class TestGetPEMKey:
    def test_returns_string(self):
        from eimutils.decrypt import getPEMKey
        pem_str, passphrase = _make_encrypted_pem()
        result = getPEMKey(pem_str, passphrase)
        assert isinstance(result, str)

    def test_no_pem_headers(self):
        from eimutils.decrypt import getPEMKey
        pem_str, passphrase = _make_encrypted_pem()
        result = getPEMKey(pem_str, passphrase)
        assert "BEGIN PRIVATE KEY" not in result
        assert "END PRIVATE KEY" not in result

    def test_no_newlines(self):
        from eimutils.decrypt import getPEMKey
        pem_str, passphrase = _make_encrypted_pem()
        result = getPEMKey(pem_str, passphrase)
        assert "\n" not in result

    def test_wrong_passphrase_raises(self):
        from eimutils.decrypt import getPEMKey
        pem_str, _ = _make_encrypted_pem()
        with pytest.raises(Exception):
            getPEMKey(pem_str, "wrong_passphrase")

    def test_der_and_pem_same_key(self):
        """DER and PEM outputs should represent the same underlying key."""
        from eimutils.decrypt import getDERKey, getPEMKey
        pem_str, passphrase = _make_encrypted_pem()
        der_bytes = getDERKey(pem_str, passphrase)
        der_key = serialization.load_der_private_key(
            der_bytes, password=None, backend=default_backend()
        )
        pem_result = getPEMKey(pem_str, passphrase)
        full_pem = (
            "-----BEGIN PRIVATE KEY-----\n"
            + pem_result
            + "\n-----END PRIVATE KEY-----\n"
        )
        pem_key = serialization.load_pem_private_key(
            full_pem.encode(), password=None, backend=default_backend()
        )
        assert (
            der_key.private_numbers().d
            == pem_key.private_numbers().d
        )


"""
*******************************************************************************
Change History:

Author          Date        Description
----------      ----------  ---------------------------------------------------
ffortunato      2026-04-22  Initial iteration.
*******************************************************************************
"""
