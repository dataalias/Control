"""
Unit tests for s3helper.py — no AWS connectivity required.
"""

import os
import pytest
import tempfile
from io import BytesIO
from unittest.mock import patch, MagicMock
import zipfile


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_s3helper.py")
    print("=" * 70)


def _make_zip_bytes(files: dict) -> bytes:
    """Build an in-memory zip archive from {filename: content} dict."""
    buf = BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        for name, content in files.items():
            zf.writestr(name, content)
    buf.seek(0)
    return buf.read()


class TestS3CreateFolder:
    def test_creates_folder_when_absent(self):
        from eimutils.s3helper import s3_create_folder

        mock_resource = MagicMock()
        mock_client = MagicMock()
        mock_resource.Bucket.return_value.objects.filter.return_value = []

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            with patch("eimutils.s3helper.boto3.client", return_value=mock_client):
                result = s3_create_folder("my-bucket", "path/", "subfolder/")

        assert result == "Success"
        mock_client.put_object.assert_called_once_with(
            Bucket="my-bucket", Key="path/subfolder/"
        )

    def test_skips_creation_when_folder_exists(self):
        from eimutils.s3helper import s3_create_folder

        mock_obj = MagicMock()
        mock_obj.key = "path/subfolder/"
        mock_resource = MagicMock()
        mock_client = MagicMock()
        mock_resource.Bucket.return_value.objects.filter.return_value = [mock_obj]

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            with patch("eimutils.s3helper.boto3.client", return_value=mock_client):
                result = s3_create_folder("my-bucket", "path/", "subfolder/")

        assert result == "Success"
        mock_client.put_object.assert_not_called()

    def test_raises_on_boto3_exception(self):
        from eimutils.s3helper import s3_create_folder

        with patch("eimutils.s3helper.boto3.resource", side_effect=Exception("AWS error")):
            with pytest.raises(Exception, match="AWS error"):
                s3_create_folder("my-bucket", "path/", "subfolder/")


class TestUploadObjectsToS3:
    def test_successful_upload_calls_put_object(self):
        from eimutils.s3helper import upload_objects_to_s3

        mock_resource = MagicMock()
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp.write(b"content")
            tmp_path = tmp.name
        try:
            with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
                upload_objects_to_s3(tmp_path, "my-bucket", "path/file.txt")
        finally:
            os.unlink(tmp_path)

        mock_resource.meta.client.put_object.assert_called_once_with(
            Body=b"content", Bucket="my-bucket", Key="path/file.txt"
        )

    def test_raises_and_logs_on_s3_failure(self):
        from eimutils.s3helper import upload_objects_to_s3

        mock_resource = MagicMock()
        mock_resource.meta.client.put_object.side_effect = Exception("put failed")

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            with patch("eimutils.s3helper.log_to_console") as mock_log:
                with pytest.raises(Exception):
                    upload_objects_to_s3(b"content", "my-bucket", "path/file.txt")
                mock_log.assert_called_once()
                _, level, _ = mock_log.call_args[0]
                assert level.lower() == "error"


class TestReadObjectsFromS3:
    def test_returns_s3_object(self):
        from eimutils.s3helper import Read_Objects_From_S3

        mock_resource = MagicMock()
        mock_obj = MagicMock()
        mock_resource.Object.return_value = mock_obj

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            result = Read_Objects_From_S3("my-bucket", "path/file.txt")

        assert result is mock_obj
        mock_resource.Object.assert_called_once_with("my-bucket", "path/file.txt")

    def test_raises_and_logs_on_exception(self):
        from eimutils.s3helper import Read_Objects_From_S3

        mock_resource = MagicMock()
        mock_resource.Object.side_effect = Exception("S3 not available")

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            with patch("eimutils.s3helper.log_to_console") as mock_log:
                with pytest.raises(Exception):
                    Read_Objects_From_S3("my-bucket", "path/file.txt")
                mock_log.assert_called_once()


class TestUnzipFile:
    def test_puts_each_extracted_file_to_s3(self):
        from eimutils.s3helper import unzip_file

        zip_bytes = _make_zip_bytes({"file1.txt": "hello", "file2.txt": "world"})
        mock_resource = MagicMock()
        mock_resource.Object.return_value.get.return_value = {"Body": BytesIO(zip_bytes)}

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            unzip_file("my-bucket", "src/", "dest/", "archive.zip")

        assert mock_resource.meta.client.put_object.call_count == 2

    def test_raises_on_s3_read_failure(self):
        from eimutils.s3helper import unzip_file

        mock_resource = MagicMock()
        mock_resource.Object.side_effect = Exception("bucket not found")

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            with pytest.raises(Exception):
                unzip_file("my-bucket", "src/", "dest/", "archive.zip")

    def test_raises_on_corrupt_zip(self):
        from eimutils.s3helper import unzip_file

        mock_resource = MagicMock()
        mock_resource.Object.return_value.get.return_value = {
            "Body": BytesIO(b"not a zip file")
        }

        with patch("eimutils.s3helper.boto3.resource", return_value=mock_resource):
            with pytest.raises(Exception):
                unzip_file("my-bucket", "src/", "dest/", "bad.zip")


"""
*******************************************************************************
Change History:

Author          Date        Description
----------      ----------  ---------------------------------------------------
ffortunato      2026-04-22  Initial iteration.
*******************************************************************************
"""
