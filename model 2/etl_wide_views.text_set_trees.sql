CREATE OR REPLACE VIEW etl_wide_views.text_set_trees AS
WITH text_set_tree AS (
    SELECT DISTINCT
        t.text_set_content_id,
        t.text_set_id,
        t.parent_text_set_content_id,
        t.parent_text_set_id,
        t.ancestor_text_set_content_id,
        t.ancestor_text_set_id,
        t.depth_from_ancestor,
        t.text_set_title,
        t.context,
        b.member_id AS content_id
    FROM
        etl_staging.text_set_trees_base t
        LEFT JOIN mysql_ebdb_tables.content_contentmembership b
            ON t.text_set_content_id = b.container_id
            AND NOT b._fivetran_deleted
        WHERE
            (
                b.member_id IS NOT NULL
                AND t.depth_from_ancestor != 0
            )
            OR t.is_standalone_text_set = 1
    UNION
    SELECT DISTINCT
        t.text_set_content_id,
        t.text_set_id,
        t.parent_text_set_content_id,
        t.parent_text_set_id,
        t.ancestor_text_set_content_id,
        t.ancestor_text_set_id,
        t.depth_from_ancestor,
        t.text_set_title,
        t.context,
        a.content_id
    FROM
        etl_staging.text_set_trees_base t
        JOIN mysql_ebdb_tables.content_contentmembership b
            ON t.text_set_content_id = b.container_id
            AND NOT b._fivetran_deleted
        JOIN etl_dim.article_headers ahe ON b.member_id = ahe.content_id
        JOIN etl_dim.articles a ON ahe.article_header_id = a.article_header_id
    WHERE
        t.depth_from_ancestor != 0
        OR t.is_standalone_text_set = 1
    UNION
    SELECT DISTINCT
        t.text_set_content_id,
        t.text_set_id,
        t.parent_text_set_content_id,
        t.parent_text_set_id,
        t.ancestor_text_set_content_id,
        t.ancestor_text_set_id,
        t.depth_from_ancestor,
        t.text_set_title,
        t.context,
        ahe.content_id
    FROM
        etl_staging.text_set_trees_base t
        JOIN mysql_ebdb_tables.articles_textsetarticleheader tah
            ON t.text_set_id = tah.text_set_id
            AND NOT tah._fivetran_deleted
        JOIN etl_dim.article_headers ahe ON tah.article_header_id = ahe.article_header_id
    WHERE
        t.depth_from_ancestor != 0
        OR t.is_standalone_text_set = 1
    UNION
    SELECT DISTINCT
        t.text_set_content_id,
        t.text_set_id,
        t.parent_text_set_content_id,
        t.parent_text_set_id,
        t.ancestor_text_set_content_id,
        t.ancestor_text_set_id,
        t.depth_from_ancestor,
        t.text_set_title,
        t.context,
        a.content_id
    FROM
        etl_staging.text_set_trees_base t
        JOIN mysql_ebdb_tables.articles_textsetarticleheader tah
            ON t.text_set_id = tah.text_set_id
            AND NOT tah._fivetran_deleted
        JOIN etl_dim.article_headers ahe ON tah.article_header_id = ahe.article_header_id
        JOIN etl_dim.articles a ON ahe.article_header_id = a.article_header_id
    WHERE
        t.depth_from_ancestor != 0
        OR t.is_standalone_text_set = 1
    UNION
    SELECT DISTINCT
        t.text_set_content_id,
        t.text_set_id,
        t.parent_text_set_content_id,
        t.parent_text_set_id,
        t.ancestor_text_set_content_id,
        t.ancestor_text_set_id,
        t.depth_from_ancestor,
        t.text_set_title,
        t.context,
        ls.lesson_spark_content_id AS content_id
    FROM
        etl_staging.text_set_trees_base t
        JOIN mysql_ebdb_tables.articles_lessonspark_paired_text_sets pts
            ON t.text_set_id = TO_VARCHAR(pts.textset_id)
            AND NOT pts._fivetran_deleted
        JOIN etl_dim.lesson_sparks ls ON TO_VARCHAR(pts.lessonspark_id) = ls.lesson_spark_id
    WHERE
        t.depth_from_ancestor != 0
        OR t.is_standalone_text_set = 1
    UNION
    SELECT DISTINCT
        t.text_set_content_id,
        t.text_set_id,
        t.parent_text_set_content_id,
        t.parent_text_set_id,
        t.ancestor_text_set_content_id,
        t.ancestor_text_set_id,
        t.depth_from_ancestor,
        t.text_set_title,
        t.context,
        ts.content_id
    FROM
        etl_staging.text_set_trees_base t
        JOIN etl_dim.text_sets ts ON t.text_set_id = ts.text_set_id
), non_licensed_collection_text_sets AS (
    SELECT DISTINCT
        tst.text_set_id
    FROM
          text_set_tree tst
        JOIN etl_dim.text_sets ts on ts.text_set_id = tst.text_set_id
        JOIN etl_dim.text_sets pts on pts.text_set_id = tst.parent_text_set_id
    WHERE
        ancestor_text_set_content_id IN
            ('ckre0behu00013h60110bb6px',
            'ckd51x1pr00023hoalzrknglr',
            'ckd0jvn3z00023jn8mkcw1jjd',
            'ckd0kn7y000013hqqp3k7t2yx')
        AND depth_from_ancestor = 2
        AND tst.text_set_id IS NOT NULL
        AND pts.user_id IS NULL
)
SELECT
    SHA2_HEX(
        ARRAY_TO_STRING(
            ARRAY_CONSTRUCT_COMPACT(
                tst.content_id,
                tst.context,
                tst.text_set_id,
                tst.ancestor_text_set_id,
                tst.parent_text_set_id
            ), ''
        ), 256
    ) AS text_set_tree_id,
    tst.text_set_content_id,
    tst.text_set_id,
    tst.parent_text_set_content_id,
    tst.parent_text_set_id,
    tst.ancestor_text_set_content_id,
    tst.ancestor_text_set_id,
    tst.depth_from_ancestor,
    tst.text_set_title,
    ts.user_id AS text_set_created_user_id,
    tst.context,
    tst.content_id,
    c.content_type,
    tsa.copied_from_id::VARCHAR AS ancestor_copied_from_id,
    TO_DATE(tsa.date_archived) AS ancestor_date_archived,
    TO_DATE(tsa.date_shared) AS ancestor_date_shared,
    TO_DATE(tsa.date_created) AS ancestor_date_created,
    tsa.text_set_description AS ancestor_description,
    tsa.text_set_label AS ancestor_text_set_label,
    tsa.text_set_title AS ancestor_text_set_title,
    tsa.slug AS ancestor_text_set_slug,
    tsa.user_id AS ancestor_created_user_id,
    tsa.text_set_type AS ancestor_text_set_type,
    tsa.license_tier AS ancestor_license_tier,
    tsa.text_set_requires_license AS ancestors_text_set_requires_license,
    tsa.text_set_is_ela AS ancestors_text_set_is_ELA,
    tsa.text_set_is_social_studies AS ancestors_text_set_is_social_studies,
    tsa.text_set_is_science AS ancestors_text_set_is_science,
    tsa.text_set_is_essentials AS ancestors_text_set_is_essentials,
    tsa.text_set_is_free_stream AS ancestors_text_set_is_free_stream,
    tsa.text_set_is_lgbtq AS ancestors_text_set_is_lgbtq,
    tsa.text_set_is_social_emotional_learning AS ancestors_text_set_is_social_emotional_learning,
    CASE
        WHEN ancestor_text_set_content_id IN ('ck8z34pfs00013cnwd17dkcbr'
        ,'ckd6kgccw000b3nnx3n5qy2zw'
        ,'ckd9fkj1h00013fl8ffsrm1yw')
            AND tst.depth_from_ancestor = 1
            AND c.content_type = 'textset'
        THEN 1
        ELSE 0
    END AS is_curriculum_complement,
    ahe.article_header_id,
    ahe.article_header_title,
    ahe.article_header_slug,
    ahe.article_language,
    ahe.article_header_requires_license,
    ahe.content_id AS article_header_content_id,
    ahe.date_article_header_published,
    TO_DATE(tah.date_created) AS date_article_header_added_to_text_set,
    ahe.content_provider AS article_header_content_provider,
    ahe.is_ela_subject AS is_article_ela_subject,
    ahe.is_social_studies_subject AS is_article_social_studies_subject,
    ahe.is_science_subject AS is_article_science_subject,
    ahe.is_essentials_subject AS is_article_essentials_subject,
    ahe.is_social_emotional_learning AS is_article_social_emotional_learning,
    ahe.is_appropriate_for_lower_elementary AS is_article_appropriate_for_lower_elementary,
    ahe.is_appropriate_for_upper_elementary AS is_article_appropriate_for_upper_elementary,
    ahe.is_appropriate_for_middle_school AS is_article_appropriate_for_middle_school,
    ahe.is_appropriate_for_high_school AS is_article_appropriate_for_high_school,
    v.video_content_id,
    v.video_title,
    v.video_slug,
    v.video_description,
    TO_DATE(v.video_date_created) AS date_video_created,
    TO_DATE(v.video_datetime_published) AS date_video_published,
    erl.external_link_title,
    erl.external_link_url,
    erl.external_link_description,
    erl.external_link_content_id,
    TO_DATE(erl.external_link_date_created) AS date_external_link_created,
    iv.interactive_video_content_id,
    iv.interactive_video_content_provider,
    TO_DATE(iv.interactive_video_date_created) AS date_interactive_video_created,
    iv.interactive_video_url,
    iv.interactive_video_title,
    iv.interactive_video_description,
    ls.lesson_spark_id,
    ls.lesson_spark_content_id,
    ls.lesson_spark_title,
    TO_DATE(ls.lesson_spark_created_date) AS lesson_spark_created_date,
    TO_DATE(ls.lesson_spark_published_date) AS lesson_spark_published_date,
    a.article_level_id,
    a.grade_level AS article_grade_level,
    a.lexile_level AS article_lexile_level,
    a.article_title,
    TO_DATE(a.datetime_created) AS date_article_created,
    CASE WHEN cs.container_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_content_selector,
    CASE WHEN nlcts.text_set_id IS NOT NULL THEN 1 ELSE 0 END AS is_non_license_collections_text_set
FROM
    text_set_tree tst
    JOIN etl_dim.text_sets ts ON tst.text_set_id = ts.text_set_id
    LEFT JOIN etl_dim.article_headers ahe ON tst.content_id = ahe.content_id
    LEFT JOIN mysql_ebdb_tables.articles_textsetarticleheader tah
        ON tst.text_set_id = tah.text_set_id
        AND ahe.article_header_id = tah.article_header_id
        AND NOT tah._fivetran_deleted
    LEFT JOIN etl_dim.articles a ON tst.content_id = a.content_id
    LEFT JOIN etl_dim.video v ON tst.content_id = v.video_content_id
    LEFT JOIN etl_dim.external_resource_link erl ON tst.content_id = erl.external_link_content_id
    LEFT JOIN etl_dim.interactive_video iv ON tst.content_id = iv.interactive_video_content_id
    LEFT JOIN etl_dim.lesson_sparks ls
        ON tst.content_id = ls.lesson_spark_content_id
    JOIN etl_dim.text_sets tsa ON tst.ancestor_text_set_id = tsa.text_set_id
    JOIN etl_dim.content c ON tst.content_id = c.content_id
    LEFT JOIN mysql_ebdb_tables.content_contentselector cs
        ON tst.text_set_content_id = cs.container_id
        AND NOT cs._fivetran_deleted
    LEFT JOIN non_licensed_collection_text_sets nlcts ON
        tst.text_set_id = nlcts.text_set_id
;
