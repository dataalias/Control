/*

CALL USP_INSERT_NEW_PUBLICATION(
     pPublisherCode    => 'CLLMNR'
    ,pPublicationCode  => 'CLLMNR_DAILY'
    ,pPublicationName  => 'Callminer Daily Feed'
    ,pPublicationDesc  => 'Daily callminer extract'
    ,pSrcPublicationCode => 'SRC_CLLMNR'
    ,pSrcPublicationName => 'Source Callminer'
    ,pPublicationEntity  => 'CallminderRecord');

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
    INSERT INTO DATA_HUB.PUBLICATION
    (
         PublisherCode
        ,PublicationCode
        ,PublicationName
        ,PublicationDesc
        ,SrcPublicationCode
        ,SrcPublicationName
        ,PublicationEntity
    ) VALUES (
         :pPublisherCode
        ,:pPublicationCode
        ,:pPublicationName
        ,:pPublicationDesc
        ,:pSrcPublicationCode
        ,:pSrcPublicationName
        ,:pPublicationEntity
    );

    publication_id := (SELECT PublicationId FROM DATA_HUB.PUBLICATION WHERE PublicationCode = :pPublicationCode);
    RETURN publication_id;
END;
$$;

/******************************************************************************
       change history
*******************************************************************************
date        author          description
--------    -------------   ---------------------------------------------------
20181011    ffortunato      initial iteration
20260626    ffortunato      fix: removed PublisherId from INSERT (AUTOINCREMENT);
                            fixed VALUES alignment; added RETURN of new id;
                            renamed file USP_INSERT_NEW_PUBLISHER.sql -> this file
******************************************************************************/
