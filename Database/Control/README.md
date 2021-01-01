This project consists of two components:

Data Hub:

A framework is required to manage the publication of data from a source system to a destination system. Publisher systems will be able to publish information to a centralized repository using various connectors. Information will be staged in a relational model. Subscribers interested in the publication will be notified of new information. When the subscriber has consumed the requested information datahub is notified of success or failure. Once all distributions of information have been consumed staged information can be archived.

Data Hub Concept
Data Hub is intended to manage all data entering and exiting the organization that requires a “large” batch transfer of data. This can include data files or data tables that are delivered from a source system into the enterprise. The system will maintain meta data about each transfer, i.e. source and destination. It will log each data payload and the destination for the information. 

Publisher Metaphor
This system operates much like a magazine publication and the customers that subscribe to the periodical. 
A publisher creates a specific type of magazine(s) such as Wired or Red Herring. The Publisher entity will maintain a list of the various organizations that generate magazines. A publication is a specific magazine that well be readied for publication. A publisher can generate more than one publication. 

On a regular interval, the next installment of a magazine is prepared to send to customers as an issue. The Issue entity will manage the details for the various versions that a particular publication has prepared for consumption. The actual content of a particular publication will be stored in a database entity.

Subscriber Metaphor
Subscribers are Individuals that receive publications of a magazine. The subscriber entity will describe each of the systems consuming information from a publisher. The subscription entity provides a look up for each of the publication that each of the subscribers have elected to receive. Each issue that a subscriber receives will be stored in the distribution entity. This entity will record the state of the issue for a particular subscriber.

 In following with our magazine metaphor, the distribution entity will follow the state of a single magazine (Has it been mailed, has it been received etc.)

Posting Groups:  
 
Posting groups are used to orchestrate the processing of data within information systems. Processes can be complicated based on inter dependencies between processes. Posting Groups maintain metadata about discrete units of work that must be completed and the order that they must be completed. This system also maintains a history of the work taking place on the system in order to facilitate operational reporting and system restarts.

Processing Template
Posting groups identifies the template needed to orchestrate the batch process working on the data warehouse. Each package or job that needs to be executed during a day’s batch is maintained in the PostingGroup entity. Data warehouse ETL jobs are normally dependent on the execution of an upstream process before they can be fired. Posting Group Dependencies are maintained to enforce package completion of upstream requirements before subsequent processes are executed. The entity, PostingGroupDependencies maintains the mapping of processes to their successors by maintain a parent child relationship. The entities mentioned are responsible for maintain the template for each process that needs to run during a given day. This information will be propagated to other entities that are used to maintain statistics on each day’s batch.

Batch Processing
Now that a template has been established for the process that must be run each day the specific tasks for a given interval of time (normally a day) must be generated so process can report on their success or failure, run time and other statistics. The PostingGroupBatch maintains a key value for each new (holistic) batch that must be run and does so on a daily interval. The template posting group records are effectively copied into the PostingGroupProcessing entity each day and identified with a posting group batch id. As processes execute, they report their status back to the processing entity. These statuses can be monitored through the day to ensure normal processing by logging number of records impacted and process start and end times as retrys.