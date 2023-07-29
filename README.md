# Background
Within our application a teacher can create, join and leave a classroom at anytime. However, the application only tracks current classroom associations so if a teacher is no longer associated with a classroom that data is lost forever.

The purpose of this project was to create a table that provided the entire history of a teachers relationship with a classroom. Example shown below.

| user_id | classroom_id | classroom_start_date | classroom_end_date |
|---------|--------------|----------------------|--------------------|
| 1       | a            | 2021-01-01           | 2021-01-15         |
| 1       | a            | 2021-08-01           | 2023-08-01         |

# Approach
The problem is a variation of the gaps and islands question so that is the approach used.

There are 3 staging tables used, which each subsequent staging table depending on the prior.

teacher_classroom_date_ranges -> teacher_classroom_groups -> teacher_classrooms

# teacher_classroom_date_ranges
1. In the "source" table, mysql_ebdb_tables.people_teacher_classrooms_history, a row is inserted into this table/updated everytime a teacher's relationship with a classroom changes. _fivetran_deleted represents a hard delete while datetime_archived would be a soft delete.

A basic recreation of the table:

| user_id | classroom_id | date_created | _fivetran_synced | _fivetran_deleted |
|---------|--------------|--------------|------------------|-------------------|
| 1       | a            |              | 2022-01-01       |                   |
| 1       | a            | 2022-01-01   | 2022-01-02       | true              |
| 1       | a            | 2022-01-15   | 2022-01-16       |                   |
| 1       | a            | 2022-01-15   | 2022-06-01       | true              |

2. The issue is that there have been multiple data ingestion tools used in the past leading inconsistent values across date columns as well as duplicate rows being generated.



5. In the inferred_dates cte I am grabbing all potential date columns and generating an inferred created timestamp.
6. In the classroom_dates cte I am creating an end date and ordering the rows into a inferred chronological order.
7. Finally the query uses window functions to grab the delete and start and end dates of the previous row as well as filtering out rows of impossible or bad data.

| user_id | classroom_id | teacher_classroom_start_date | teacher_classroom_end_date | is_deleted | is_previous_row_deleted | previous_teacher_classroom_start_date | previous_teacher_classroom_end_date |
|---------|--------------|------------------------------|----------------------------|------------|-------------------------|---------------------------------------|-------------------------------------|
| 1       | a            | 2022-01-01                   |                            |            | false                   |                                       |                                     |
| 1       | a            | 2022-01-01                   | 2022-01-02                 | true       | false                   | 2022-01-01                            |                                     |
| 1       | a            | 2022-01-01                   |                            |            | true                    | 2022-01-01                            | 2022-01-02                          |
| 1       | a            | 2022-01-01                   | 2022-06-01                 | true       | false                   | 2022-01-01                            |                                     |

# teacher_classroom_groups

# teacher_classrooms

