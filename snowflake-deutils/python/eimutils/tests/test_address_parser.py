"""
Unit tests for address_parser.py — no external dependencies required.
"""


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_address_parser.py")
    print("=" * 70)


class TestExtractAddresses:
    def test_basic_address_parses_correctly(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("456 Elm St Suite 2 Anytown CA 90210")
        assert len(result) == 1
        assert "Elm" in result[0]["address_line_1"]
        assert result[0]["city"] == "Anytown"
        assert result[0]["state"] == "CA"
        assert result[0]["zip_code"] == "90210"

    def test_email_is_stripped_before_parsing(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("789 Oak St Smallville KS 67524 jane@example.com")
        assert len(result) == 1
        assert result[0]["zip_code"] == "67524"
        assert "jane" not in str(result[0])

    def test_ten_digit_phone_is_stripped(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("123 Main St Springfield IL 62701 2175551234")
        assert len(result) == 1
        assert result[0]["state"] == "IL"
        assert "2175551234" not in str(result[0])

    def test_multiple_lines_returns_multiple_results(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses(
            "456 Elm St Anytown CA 90210\n789 Oak St Smallville KS 67524"
        )
        assert len(result) == 2

    def test_empty_string_returns_empty_list(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("")
        assert result == []

    def test_returns_list_of_dicts(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("456 Elm St Anytown CA 90210")
        assert isinstance(result, list)
        assert all(isinstance(r, dict) for r in result)

    def test_dict_has_expected_keys(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("456 Elm St Anytown CA 90210")
        assert len(result) == 1
        expected_keys = {"address_line_1", "address_line_2", "city", "state", "zip_code"}
        assert set(result[0].keys()) == expected_keys

    def test_unparseable_line_is_skipped(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("not an address at all !!!@@@\n456 Elm St Anytown CA 90210")
        assert any(r["zip_code"] == "90210" for r in result)

    def test_suite_address_captured_in_line_2(self):
        from eimutils.address_parser import extract_addresses

        result = extract_addresses("456 Elm St Suite 2 Anytown CA 90210")
        assert len(result) == 1
        assert "2" in result[0]["address_line_2"] or "Suite" in result[0]["address_line_2"]


"""
*******************************************************************************
Change History:

Author          Date        Description
----------      ----------  ---------------------------------------------------
ffortunato      2026-04-22  Initial iteration.
*******************************************************************************
"""
