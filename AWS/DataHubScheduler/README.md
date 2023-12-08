MOVED TO MAIN PROJECT README.md

# deDataHubScheduler
## Overview
This AWS lambda function handles Data Hub feeds that are scheduled for execution. For example data that is pulled from an API on an given interval (Pulling Google Analytics data every 4 hours) and then facilitates the insert of issue data within the DataHub / Control database. Subsequently the lambda will fire the appropriate Glue work flow to invoke the API and load the data into the data lake and ODS.

## Functions

### lambda_handler
 This lambda function is invoked by the Event Bridge Schedule deDataHubSchedule. When a dictionary (json object) is passed in that includes the key IssueId and an assoicated value the method will update the issue with any other information provided by the dictionary and respond with a dictionary (json object) that includes the current details of the issue.

 ## DataHub Metadata
 ### Publication
The publication table has a new attribute TriggerMethodCode. Setting this value to 'SCH' will ensure the DataHubScehduler lambda function will call the approprate load routing based on the publication interval type and length.


### Change Log:
| User       | Date       | Comment                                                                     |
|------------|------------|-----------------------------------------------------------------------------|
| ffortunato | 05/24/2023 | Initial Iteration. |
| ffortunato | 06/20/2023 | Additional details regarding publication data. |

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)