import boto3


def s3_create_folder(s3_bucket_name, s3_bucket_path, s3_sub_folders):
    try:
        #Iterate result set to process further for folder creation in S3 bucket
        s3_resource = boto3.resource('s3')
        s3_client = boto3.client('s3')
        print(f"BucketName:{s3_bucket_name} BucketPath:{s3_bucket_path}  BucketSubFolder:{s3_sub_folders}")
        folder_exist = False
        for obj in s3_resource.Bucket(s3_bucket_name).objects.filter(Prefix=s3_bucket_path + s3_sub_folders):
            if obj.key.endswith(s3_sub_folders):
                folder_exist = True
                break
        #create the folder of current day
        if folder_exist == False:
            s3_client.put_object(Bucket=s3_bucket_name, Key=s3_bucket_path + s3_sub_folders)
            print("Day directory created on S3")
        else:
            print("Sub folders already exist")
        return 'Success'
    except Exception as e:
        print("Unable to create directory on S3.", e)
        return 'Failure'
## ---End of create_folder_in_s3 method


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------


*******************************************************************************
"""