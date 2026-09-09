/*

CALL USP_INSERT_NEW_PUBLISHER(
     pPublisherCode => 'CLLMNR'
    ,pPublisherName => 'Callminer'
    ,pContactName   => 'John Smith'
    ,pPublisherDesc => 'Callminer speech analytics publisher'
    ,pCreatedBy     => 'ffortunato');

*/

CREATE OR REPLACE PROCEDURE USP_INSERT_NEW_PUBLISHER(
     pPublisherCode  varchar(25)
    ,pPublisherName  varchar(255)
    ,pContactName    varchar(255)
    ,pPublisherDesc  varchar(255)
    ,pCreatedBy      varchar(255))
RETURNS INTEGER
LANGUAGE SQL
AS
$$
DECLARE
    publisher_id INTEGER;
BEGIN
    INSERT INTO DATA_HUB.Publisher
    (
         PublisherCode
        ,PublisherName
        ,ContactName
        ,PublisherDesc
        ,CreatedBy
        ,CreatedDtm
    ) VALUES (
         :pPublisherCode
        ,:pPublisherName
        ,:pContactName
        ,:pPublisherDesc
        ,:pCreatedBy
        ,CURRENT_DATE
    );

    publisher_id := (SELECT PublisherId FROM DATA_HUB.Publisher WHERE PublisherCode = :pPublisherCode);
    RETURN publisher_id;
END;
$$;

/******************************************************************************
       change history
*******************************************************************************
date        author          description
--------    -------------   ---------------------------------------------------
20260626    ffortunato      initial iteration — replaced duplicate of
                            USP_INSERT_NEW_PUBLICATION with actual publisher insert
******************************************************************************/
