# Introduction 
Data Hub and Posting Group provide a frame work for managing the ingress and egress of data from a system and the orchestration of processes that depend on the data. Please check the wiki for additional information. https://github.com/dataalias/Control/wiki

# Getting Started
Data Hub and Posting Group database projects are intended to be installed on SQL Server (2008+). Stored proceudrees can be used to insert metadata to allow for the load of data sets into a target database.

# Build and Test
This code can be built with Visual Studio (2017+). The repository also contains two test scripts to demonstrate the database components have been installed correctly.
https://github.com/dataalias/Control/tree/main/Database/Control/Test
tst_DataHub.sql
tst_PostingGroupProcessing.sql

# Contribute
Send me an email if you would like to contribute to this system.
dataalias@outlook.com



# Data Hub 
Data Hub is intended to manage all data entering and exiting the organization that requires a “large” batch transfer of data. This can include data files or data tables that are delivered from a source system into the enterprise. The system will maintain meta data about each transfer, i.e. source and destination. It will log each data payload and the destination for the information. 
## Publisher Metaphor
This system operates much like a magazine publication and the customers that subscribe to the periodical. 
A publisher creates a specific type of magazine(s) such as Wired or Red Herring. The Publisher entity will maintain a list of the various organizations that generate magazines. A publication is a specific magazine that well be readied for publication. A publisher can generate more than one publication. 
On a regular interval, the next installment of a magazine is prepared to send to customers as an issue. The Issue entity will manage the details for the various versions that a particular publication has prepared for consumption. The actual content of a particular publication will be stored in a database entity.
## Subscriber Metaphor
Subscribers are Individuals that receive publications of a magazine. The subscriber entity will describe each of the systems consuming information from a publisher. The subscription entity provides a look up for each of the publication that each of the subscribers have elected to receive. Each issue that a subscriber receives will be stored in the distribution entity. This entity will record the state of the issue for a particular subscriber.
 In following with our magazine metaphor, the distribution entity will follow the state of a single magazine (Has it been mailed, has it been received etc.)
# Posting Group
Posting groups are used to orchestrate the processing of data within information systems. Processes can be complicated based on inter dependencies between processes. Posting Groups maintain metadata about discrete units of work that must be completed and the order that they must be completed. This system also maintains a history of the work taking place on the system in order to facilitate operational reporting and system restarts.
## Processing Template
Posting groups identifies the template needed to orchestrate the batch process working on the data warehouse. Each package or job that needs to be executed during a day’s batch is maintained in the PostingGroup entity. Data warehouse ETL jobs are normally dependent on the execution of an upstream process before they can be fired. Posting Group Dependencies are maintained to enforce package completion of upstream requirements before subsequent processes are executed. The entity, PostingGroupDependencies maintains the mapping of processes to their successors by maintaining a parent child relationship. The entities mentioned are responsible for determine the processes that must run consecutively. This information will be propagated to other entities that are used to maintain statistics on each day’s batch.
## Batch Processing
Now that a template has been established for the process that must be run each day the specific tasks for a given interval of time (normally a day) must be generated so process can report on their success or failure, run time and other statistics. The PostingGroupBatch maintains a key value for each new (holistic) batch that must be run and does so on a daily interval. The template posting group records are effectively copied into the PostingGroupProcessing entity each day and identified with a posting group batch id. As processes execute, they report their status back to the processing entity. These statuses can be monitored through the day to ensure normal processing by logging number of records impacted and process start and end times as retries.
# Components
One repo to Rule Everything data hub. Includes: API, Schedule, and S3 Trigger datahub lambda as well as Class for logging issue activity.
## DataHubAPIGateway
Accepts and forwards Data Hub API calls. Normally from Glue workflows to the DataHubAPIHAndler <see DataHubAPIHAndler>.
## DataHubAPIHandler
Performs CRUD operations on the Data Hub database with Post, Put, and Get functions.

This AWS lambda function handles the processes that are scheduled by DataHub.

This lambda function is invoked by a scehduler every 10 minutes. It will gather a list of scheduled jobs , create and issue and fire the associated workflow.
## DataHubS3Trigger
This lambda function is triggered every time a file lands on the data lake /RawData folder. The name of the file is looked up within datahub and its associated meta data is returned in order to trigger down stream load processes.
## DataHubScehduler
This AWS lambda function handles Data Hub feeds that are scheduled for execution. For example data that is pulled from an API on an given interval (Pulling Google Analytics data every 4 hours) and then facilitates the insert of issue data within the DataHub / Control database. Subsequently the lambda will fire the appropriate Glue work flow to invoke the API and load the data into the data lake and ODS.

This lambda function is invoked by the Event Bridge Schedule deDataHubSchedule. When a dictionary (json object) is passed in that includes the key IssueId and an assoicated value the method will update the issue with any other information provided by the dictionary and respond with a dictionary (json object) that includes the current details of the issue.

The publication table has a new attribute TriggerMethodCode. Setting this value to 'SCH' will ensure the DataHubScehduler lambda function will call the approprate load routing based on the publication interval type and length.

## DataHubLayer
Manages the python DataHub class for programiatc management of Data Hub meta data and feed data. This layer is accessed from each of the DataHub* lambda functions. 
see /src_dh_layer/python/READ.md for more detail.
## deControl
Each of these packages have a dependency on the DataHub / Control database. The source code can be found in the deControl repository and will one day lande here.
https://github.com/Ascent-Funding/deControl (forked from: https://github.com/dataalias/Control)
# Infastructure
All AWS components are managed through terraform and can be found in /infra. *.tf files include everything needed to setup the data hub infrastructure with the one exception of the MS SQL database objects.

### Change Log:
| User       | Date       | Comment                                                                     |
|------------|------------|-----------------------------------------------------------------------------|                                                         |
| ffortunato | 05/24/2023 | Describing Overall package.        |
| ffortunato | 06/20/2023 | + DataHubScehduler + Overview + Infastructure |   

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
