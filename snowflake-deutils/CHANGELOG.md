# Change Log

All notable changes to the "deutils" project will be documented in this file.
Supporting confluence page: https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/3109683221/eim_deutils


|Version|Description|Release Date|Status|
|-------|--------------|------------|---------|
|1.10.0| o AI clenaup suggestions. sql injection etc ...  use pipeline 2.0.6 wheel and pip. |||
|1.9.4| o org account locator |||
|1.9.3| o pin urllib3<2.0.0 and snowflake-connector-python<3.0.0 for AWS Glue OpenSSL compatibility. + pytz dependency. o fully qualify SQL in StepLogger. Pipeline 2.0.4 |||
|1.9.1| + setting default roles for braze. |||
|1.9.0| + added a function for CSR jobs to process from last run date. |||
|1.8.0|	- reducing dependencies o restructuring branches to dev pipeline. |
|1.7.0|	o streamlit ui o dependencies o snowfalke steplog|
|1.6.6|	o working on boto3 / botocore redundencies|
|1.6.5|	o EIMARC-6825: 1.6.3 eim_deutils dependencies. Address non breaking issues from 1.6.4|
|1.6.4|	o StepDesc to Variant. EIMARC-6825: 1.6.3 eim_deutils dependencies. Known issue many versions of snowflake connector and botocore are downloaded to find correct version by glue. || Dev|
|1.6.3|	o dependency fixes.  EIMARC-6822: step_desc to variant||			Dev|
|1.6.2|	o dependency hotfix.||			Latest|
|1.6.1|	+ dbt project files.||			In Use|
|1.6.0|	+ Step logging. o Simplify build spec all feat, enh and dev branches do the same thing. o setup.py --> pyproject.toml.|08/28/2025|			In Use|
|1.5.2|	Updating requirements for snowflake-connector-python>=3.12.||			Dev-Only|
|1.5.1|	Linting the deutils code. There is no need to upgrade to this version it is just standardizing the code.||			Dev-Only|
|1.5.0|	python update from 3.7 --> 3.9	python_requires=">=3.9",	|7/14/2024|	In Use|   
|1.4.0|	Incremental changes to add get_current_publication:			|3/9/2025|In Use|
|1.3.0|	Adding the function, snowflake_pipeline_logging. This is to be used by Data Engineers for logging ETL executions	# Successful ETL Execution	|12/24/2024|	In Use|
|1.2.0|	Adding unittest to the build pipeline and making some minor changes to the schema	|	11/5/2024|	In Use|
|1.1.1|	Data Hub Class for accessing publisher, publication and issue data structures in DATA_HUB schema.	class DataHub: Zip unpack routine for archives with several files.|10/3/2024|In Use|
|1.0.7|	Hotfix. Do not require the role for creating a connection with deutils.	 |9/20/2024|	In Use|  
|1.0.6|	~ removing DataDog functionality.	||		Deprecated|
|1.0.4|	Adding in the function “gspread_try_catch”. This function can be used in conjuction with “gspread” (a way to use the Google Sheets API) for better exception handling.|8/7/2024|Deprecated|
|1.0.3|	Pyspark connection to snowflake	get_snowflake_connection_from_secret(secret_arn, env, aws_region, envlayer='', brand='', project='', spark_session = False):	||	Deprecated|
|1.0.1|	Building out Brand and Project specific roles for executing glue jobs.	my_role=f'{brand}_{env}_{project}_{envlayer}_ADMIN'|	4/24/2024	|Deprecated|
|1.0.0|	Addition of data dog logging	send_datadog_metric(secret_arn, env, aws_region, job_name, success, msg=''):	|4/9/2024|	Deprecated|
|0.0.10|	envlayer role creation	my_role = dictSecrets[f"SFROLE{envlayer}"]|	2/26/2024|	Deprecated|
|0.0.9|	Basic 3.0 snowflake connection|		2/25/2024|	Deprecated|
