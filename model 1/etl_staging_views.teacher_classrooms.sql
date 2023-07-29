CREATE OR REPLACE VIEW etl_staging_views.teacher_classrooms AS
WITH teacher_classroom_date_ranges AS (
    SELECT
        user_id,
        user_key,
        classroom_id,
        classroom_key,
        teacher_classroom_start_date,
        teacher_classroom_end_date,
        date_group,
        rn,
        MAX(rn) OVER (PARTITION BY user_id, classroom_id, date_group) AS last_row_in_date_group,
        CASE WHEN last_row_in_date_group = rn THEN 1 ELSE 0 END AS is_last_row_in_date_group,
        MAX(classroom_archived_date) AS classroom_archived_date
    FROM
        etl_staging.teacher_classroom_groups
    GROUP BY
        user_id,
        user_key,
        classroom_id,
        classroom_key,
        teacher_classroom_start_date,
        teacher_classroom_end_date,
        date_group,
        rn
),
teacher_classrooms AS (
    SELECT
        user_id,
        user_key,
        classroom_id,
        classroom_key,
        MIN(teacher_classroom_start_date) AS teacher_classroom_start_date,
        MAX(CASE WHEN is_last_row_in_date_group = 1 THEN COALESCE(teacher_classroom_end_date, classroom_archived_date) ELSE NULL END) AS teacher_classroom_end_date,
        MAX(classroom_archived_date) AS classroom_archived_date
    FROM
        teacher_classroom_date_ranges
    GROUP BY
        user_id,
        user_key,
        classroom_id,
        classroom_key,
        date_group
),
current_teacher_classrooms AS (
    SELECT
        c.classroom_id,
        u.user_id
    FROM
        mysql_ebdb_tables.people_teacher_classrooms ptc
        LEFT JOIN etl.classroom_id_merges cm ON cm.from_classroom_id = ptc.classroom_id
        JOIN etl_staging.classrooms c ON c.classroom_id = COALESCE(cm.to_classroom_id, ptc.classroom_id)
        JOIN etl_dim.users u ON u.teacher_id = ptc.teacher_id AND is_teacher
    GROUP BY
        c.classroom_id,
        u.user_id
)
SELECT
    tc.classroom_id,
    tc.classroom_key,
    tc.teacher_classroom_start_date AS teacher_classroom_start_datetime,
    tc.teacher_classroom_end_date AS teacher_classroom_end_datetime,
    tc.user_id,
    tc.user_key,
    u.first_active_date,
    u.registration_date,
    CASE WHEN ctc.user_id IS NOT NULL THEN 1 ELSE 0 END AS is_teacher_currently_tied_to_classroom
FROM
    teacher_classrooms tc
    JOIN etl_dim.users u ON tc.user_id = u.user_id
    LEFT JOIN current_teacher_classrooms ctc
        ON tc.user_id = ctc.user_id
        AND tc.classroom_id = ctc.classroom_id
;
