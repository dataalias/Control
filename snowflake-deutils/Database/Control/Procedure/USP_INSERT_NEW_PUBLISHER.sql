/*

CALL USP_INSERT_NEW_PUBLICATION(pPublisherCode=>'CLLMNR');

*/

CREATE OR REPLACE PROCEDURE USP_INSERT_NEW_PUBLICATION(
     pPublisherCode            varchar(25)
    ,pPublicationCode          varchar(25)
    ,pPublicationName          varchar(255)
    ,pPublicationDesc          varchar(255) 
    ,pSrcPublicationCode       varchar(255) 
    ,pSrcPublicationName       varchar(255)
    ,pPublicationEntity        varchar(255))
RETURNS INTEGER
LANGUAGE SQL
AS
$$
DECLARE
    publication_id INTEGER;
BEGIN
    publication_id := (select publicationid from DATA_HUB.PUBLICATION where PUBLISHERCODE = :pPublisherCode limit 1);  -- this query should return single value

    INSERT INTO DATA_HUB.PUBLICATION
    (
         PublisherId
        ,PublisherCode     
        ,PublicationCode   
        ,PublicationName   
        ,PublicationDesc   
        ,SrcPublicationCode
        ,SrcPublicationName
        ,PublicationEntity  
    ) values (
         pPublisherCode     
        ,pPublicationCode   
        ,pPublicationName   
        ,pPublicationDesc   
        ,pSrcPublicationCode
        ,pSrcPublicationName
        ,pPublicationEntity 
    )
    
END;
$$;