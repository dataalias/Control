/******************************************************************************
File:		ctlTableComments.sql
Name:		ctlTableComments
Purpose:	Captures all the definitions to the Control schemas.

Author:		ffortunato
Date:		20210329

******************************************************************************/

-------------------------------------------------------------------------------
-- Table And Column Comments: ctl.Publisher
-------------------------------------------------------------------------------
print 'Adding column descriptions for: ctl.Publisher'
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='Publisher' )
begin
   	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Stores all metadata for a system that creates data for down stream consumption.' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'Publisher'
end

-------------------------------------------------------------------------------
-- Table And Column Comments: ctl.Publisher
-------------------------------------------------------------------------------
print 'Adding column descriptions for: ctl.Publication'

-- Table ctl.Publication
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='Publication' )
begin
   	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Stores all metadata for a specific incomming feed.' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'Publication'
end

-- Column ctl.Publication.SrcPublicationName
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='Publication' 
   and clmns.name				='SrcPublicationName'
   and p.name					='Description')
begin
	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Name of the feed used by the Publisher system.' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'Publication' 
		,@level2type = N'Column', @level2name = 'SrcPublicationName'
end

-- Column ctl.Publication.MethodCode
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='Publication' 
   and clmns.name				='MethodCode'
   and p.name					='Description')
begin
	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Refers to the method used to transfer the data from the source to the target. This is used to derive the template that will be used to load the data. LOV SS - Snapshot, TXN - Transaction, DLT - Delta.' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'Publication' 
		,@level2type = N'Column', @level2name = 'MethodCode'
end

print 'Complete loading table and column descriptions for ctl.Publication.'

-------------------------------------------------------------------------------
-- Table And Column Comments: ctl.Subscriber
-------------------------------------------------------------------------------

print 'Adding column descriptions for: ctl.Subscriber'

-- Table ctl.Publication
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='Subscriber' )
begin
   	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Stores all metadata for the target system of a feed..' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'Subscriber'
end

print 'Complete loading table and column descriptions for ctl.Subscriber.'


-------------------------------------------------------------------------------
-- Table And Column Comments: ctl.Publisher
-------------------------------------------------------------------------------
print 'Adding column descriptions for: ctl.Publisher'
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='Publisher' )
begin
   	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Stores all metadata for a system that creates data for down stream consumption.' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'Publisher'
end

-------------------------------------------------------------------------------
-- Table And Column Comments: ctl.RefTransferMethod
-------------------------------------------------------------------------------
print 'Adding column descriptions for: ctl.RefTransferMethod'

-- Table ctl.Publication
if not exists ( SELECT top 1 1 FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id INNER JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id AND p.minor_id=clmns.column_id AND p.class=1 WHERE
   SCHEMA_NAME(tbl.schema_id)	='ctl'
   and tbl.name					='RefTransferMethod' )
begin
   	execute sp_addextendedproperty
		 @name = N'Description' 
		,@value = N'Determines the method that data is transfered from the source. DLT - Delta, SS - Snapshot' 
		,@level0type = N'Schema', @level0name = 'ctl' 
		,@level1type = N'Table',  @level1name = 'RefTransferMethod'
end

print 'Complete loading table and column descriptions for ctl.reftransfermethod.'


print 'Complete all descriptions tbale and column.'

