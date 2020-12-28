/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

use Control
go




if not exists (select top 1 1 from ctl.Passphrase
	where	DatabaseName='Control'
	and		[SchemaName]='ctl'
	and		TableName='Publisher'
	and		[Passphrase]='Publisher')

insert into ctl.Passphrase (
	 [DatabaseName]
	,[SchemaName]
	,TableName
	,[Passphrase])
values( 
'Control',	'ctl',	'Publisher',	'Publisher')


if not exists (select top 1 1 from ctl.Passphrase
	where	DatabaseName='Control'
	and		[SchemaName]='ctl'
	and		TableName='Subscriber'
	and		[Passphrase]='Subscriber')

insert into ctl.Passphrase (
	 [DatabaseName]
	,[SchemaName]
	,TableName
	,[Passphrase])
values( 
'Control',	'ctl',	'Subscriber',	'Subscriber')



if not exists (select top 1 1 from ctl.Passphrase
	where	DatabaseName='BPI_DW'
	and		[SchemaName]='dbo'
	and		TableName='DimVendor'
	and		[Passphrase]='Vendor')

insert into ctl.Passphrase (
	 [DatabaseName]
	,[SchemaName]
	,TableName
	,[Passphrase])
values(
'BPI_DW',	'dbo',	'DimVendor',	'Vendor')
