CREATE VIEW ctl.[vw_PublicationContacts] AS 

select	 pn.PublicationCode
		,pn.PublicationName
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
from	 ctl.Publication				  pn
join	 ctl.MapContactToPublication	  mctp
on		 pn.PublicationId				= mctp.PublicationId
join	 ctl.Contact					  c
on		 c.ContactId					= mctp.ContactId