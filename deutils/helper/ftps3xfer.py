import math
import time
from delogging.delogging import log_to_console
import io


def transfer_chunk_from_ftp_to_s3(ftp_file, s3_conn, multipart_upload, bucket_name, s3_file_path,
                                  part_number, chunk_size, ):
    try:
        start_time = time.time()
        ftp_file.prefetch(chunk_size * part_number)
        chunk = ftp_file.read(int(chunk_size))
        part = s3_conn.upload_part(
            Bucket=bucket_name,
            Key=s3_file_path,
            PartNumber=part_number,
            UploadId=multipart_upload["UploadId"],
            Body=chunk,
        )
        end_time = time.time()
        total_seconds = end_time - start_time
        # print("Chunk ", part_number, " Speed is {} kb/s total seconds taken {}".format(math.ceil((int(chunk_size) / 1024) / total_seconds), total_seconds))
        part_output = {"PartNumber": part_number, "ETag": part["ETag"]}
    except Exception as e:
        print('Error in ftps3xfer.transfer_chunk_from_ftp_to_s3 ', e)
    return part_output
# End of transfer_chunk_from_ftp_to_s3


def transfer_file_from_ftp_to_s3(s3_conn, ftp_conn, file_name, bucket_name, s3_key_val, chunk_size):

    response = {'Status': 'Failure'}
    success = {'Status': 'Success'}

    ftp_file_val = ftp_conn.file(file_name, "r")
    # ftp_file_val.set_pipelined() #Getting weird error in garbage collection with this...
    # ftp_file_size = ftp_file_val._get_size()
    ftp_file_size = ftp_file_val.stat().st_size

    msg = "File is: " + str(ftp_file_size) + ' Bytes'
    log_to_console(__name__, 'Info', msg)
    start_time = time.time()

    if ftp_file_size <= int(chunk_size):
        # print("Transferring complete File from FTP to S3 in one go...")
        # upload file in one go
        try:
            ftp_file_val.prefetch(ftp_file_size)
            ftp_file_data = ftp_file_val.read(ftp_file_size)
            ftp_file_data_bytes = io.BytesIO(ftp_file_data)
            s3_conn.upload_fileobj(ftp_file_data_bytes, bucket_name, s3_key_val)
            response = success
        except Exception as e:
            msg = f"Failed Getting {s3_key_val} " + e
            log_to_console(__name__, 'Err', msg)
    else:
        try:
            # upload file in chunks
            chunk_count = int(math.ceil(ftp_file_size / float(chunk_size)))
            msg = "Transferring File from FTP to S3 in chunks. Chunk count: " + str(chunk_count)
            log_to_console(__name__, 'Info', msg)

            multipart_upload = s3_conn.create_multipart_upload(Bucket=bucket_name, Key=s3_key_val)
            parts = []
            for i in range(chunk_count):
                # print("Transferring chunk {}...".format(i + 1), "of ", chunk_count)
                part = transfer_chunk_from_ftp_to_s3(ftp_file_val, s3_conn, multipart_upload, bucket_name,
                                                     s3_key_val, i + 1, chunk_size, )
                parts.append(part)
                # print("Chunk {} Transferred Successfully!".format(i + 1))

            part_info = {"Parts": parts}

            s3_conn.complete_multipart_upload(
                Bucket=bucket_name,
                Key=s3_key_val,
                UploadId=multipart_upload["UploadId"],
                MultipartUpload=part_info,
            )
            response = success
        except Exception as e:
            msg = "Failure in multi chunk transfer.", e
            log_to_console(__name__, 'Err', msg)
    try:
        ftp_file_val.close()
        end_time = time.time()
        total_seconds = end_time - start_time
        msg = "Avg. speed was : ", int(ftp_file_size / 1024 / total_seconds), "kBps. Total Seconds: ", total_seconds
        log_to_console(__name__, 'Info', msg)
    except Exception as e:
        print('Error in ftps3xfer.transfer_file_from_ftp_to_s3 closing failed. ', e)
    return response


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
krishna		01/08/2022  Initial Iteration
ffortunato  04/22/2022  + adjusted transport and chunking read_forward to
                            increase throughput.

*******************************************************************************
"""