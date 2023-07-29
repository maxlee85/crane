CREATE OR REPLACE VIEW etl_staging_views.teacher_classroom_groups AS
SELECT
    user_id,
    teacher_id,
    user_key,
    classroom_id,
    classroom_key,
    teacher_classroom_start_date,
    teacher_classroom_end_date,
    classroom_archived_date,
    is_deleted,
    is_previous_row_deleted,
    previous_teacher_classroom_start_date,
    previous_teacher_classroom_end_date,
    rn,
    SUM(
        CASE
            WHEN previous_teacher_classroom_end_date >= teacher_classroom_start_date
                 OR (previous_teacher_classroom_end_date IS NULL AND previous_teacher_classroom_start_date = teacher_classroom_start_date)
                 OR (previous_teacher_classroom_end_date IS NULL AND teacher_classroom_end_date IS NOT NULL)
                 OR teacher_classroom_start_date = previous_teacher_classroom_start_date+1
                 OR teacher_classroom_start_date = previous_teacher_classroom_end_date+1
                 OR (teacher_classroom_end_date IS NULL AND previous_teacher_classroom_end_date IS NULL AND NOT is_previous_row_deleted AND NOT is_deleted)
                 THEN 0
            ELSE 1
        END
    ) OVER (ORDER BY user_id, classroom_id, rn) AS date_group
FROM
    etl_staging.teacher_classroom_date_ranges
;
