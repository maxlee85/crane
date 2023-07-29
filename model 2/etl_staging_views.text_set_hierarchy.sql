CREATE OR REPLACE VIEW etl_staging_views.text_set_hierarchy AS
/*
Parent child relationships between text sets are now spread across these 2 tables.
The original table that stored the relationship was articles_textsetmembership.
*/
WITH text_sets AS (
    SELECT
        ts.content_id AS parent_text_set_content_id,
        ts.text_set_id AS parent_text_set_id,
        ts.text_set_title AS parent_text_set_title,
        ts2.content_id AS child_text_set_content_id,
        ts2.text_set_id AS child_text_set_id,
        ts2.text_set_title AS child_text_set_title
    FROM
        mysql_ebdb_tables.content_contentmembership cc
        JOIN etl_dim.text_sets ts ON cc.container_id = ts.content_id
        JOIN etl_dim.text_sets ts2 ON cc.member_id = ts2.content_id
    WHERE
        NOT cc._fivetran_deleted
    UNION
    SELECT
        ts.content_id AS parent_text_set_content_id,
        TO_VARCHAR(tsm.parent_text_set_id) AS parent_text_set_id,
        ts.text_set_title AS parent_text_set_title,
        ts2.content_id AS child_text_set_content_id,
        TO_VARCHAR(tsm.child_text_set_id) AS child_text_set_id,
        ts2.text_set_title AS child_text_set_title
    FROM
        mysql_ebdb_tables.articles_textsetmembership tsm
        JOIN etl_dim.text_sets ts ON tsm.parent_text_set_id = ts.text_set_id
        JOIN etl_dim.text_sets ts2 ON tsm.child_text_set_id = ts2.text_set_id
    WHERE
        NOT tsm._fivetran_deleted
)
SELECT
    parent_text_set_content_id,
    parent_text_set_id,
    parent_text_set_title,
    child_text_set_content_id,
    child_text_set_id,
    child_text_set_title
FROM
    text_sets
;
