CREATE OR REPLACE VIEW etl_staging_views.teacher_classroom_date_ranges AS
WITH inferred_dates AS (
    SELECT
        u.user_id,
        u.teacher_id,
        u.user_key,
        c.classroom_id,
        c.classroom_key,
        sc.date_created AS datetime_created,
        TO_DATE(sc.date_created) AS date_created,
        c.date_created AS classroom_date_created,
        sc._fivetran_synced,
        c.datetime_archived,
        sc._fivetran_deleted AS is_deleted,
        MIN(sc.date_created) OVER (PARTITION BY sc.id) AS inferred_datetime_created
    FROM
        mysql_ebdb_tables.people_teacher_classrooms_history sc
        LEFT JOIN etl.classroom_id_merges c_m ON sc.classroom_id = c_m.from_classroom_id
        JOIN etl_staging.classrooms c ON COALESCE(c_m.to_classroom_id, sc.classroom_id) = c.classroom_id
        JOIN etl_staging.users u ON u.teacher_id = sc.teacher_id
),
classroom_dates AS (
    SELECT
        user_id,
        teacher_id,
        user_key,
        classroom_id,
        classroom_key,
        classroom_date_created,
        inferred_datetime_created,
        _fivetran_synced,
        CASE WHEN is_deleted THEN COALESCE(LEAST(TO_DATE(_fivetran_synced), TO_DATE(datetime_archived)), TO_DATE(_fivetran_synced)) END AS teacher_classroom_end_date,
        TO_DATE(datetime_archived) AS classroom_archived_date,
        is_deleted,
        ROW_NUMBER() OVER (PARTITION BY user_id, classroom_id ORDER BY COALESCE(inferred_datetime_created, _fivetran_synced), _fivetran_synced, is_deleted) AS rn
    FROM
        inferred_dates
)
SELECT
    user_id,
    teacher_id,
    user_key,
    classroom_id,
    classroom_key,
    CASE WHEN rn = 1 THEN classroom_date_created ELSE COALESCE(TO_DATE(inferred_datetime_created), TO_DATE(_fivetran_synced)) END AS teacher_classroom_start_date,
    teacher_classroom_end_date,
    classroom_archived_date,
    is_deleted,
    LAG(is_deleted) OVER (PARTITION BY user_id, classroom_id ORDER BY rn) AS is_previous_row_deleted,
    LAG(teacher_classroom_start_date) OVER (PARTITION BY user_id, classroom_id ORDER BY rn) AS previous_teacher_classroom_start_date,
    LAG(teacher_classroom_end_date) OVER (PARTITION BY user_id, classroom_id ORDER BY rn) AS previous_teacher_classroom_end_date,
    rn
FROM
    classroom_dates
WHERE
    (classroom_archived_date IS NULL AND teacher_classroom_start_date <= teacher_classroom_end_date)
    OR (classroom_archived_date IS NULL AND teacher_classroom_end_date IS NULL)
    OR (teacher_classroom_start_date <= classroom_archived_date AND teacher_classroom_start_date <= teacher_classroom_end_date)
    OR (teacher_classroom_start_date <= classroom_archived_date AND teacher_classroom_end_date IS NULL)
;
