CREATE VIEW [ctl].[vw_PublisherContact] AS

select	 pn.PublisherCode
		,pn.PublisherName
		,c.[CompanyName]
		,c.ContactName				 
		,c.Tier	
		,c.Email						 
		,c.Phone			
		,c.SupportURL
		,c.Address01					 
		,c.Address02					 
		,c.City							 
		,c.[State]						 
		,c.ZipCode						 
from	 ctl.Publisher				  pn
join	 ctl.Contact				  c
on		 c.ContactId				= pn.ContactId
