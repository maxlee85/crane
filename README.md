# Background
Within our application a teacher can create, join and leave a classroom at anytime. However, the application only tracks current classroom associations so if a teacher is no longer associated with a classroom that data is lost forever.

The purpose of this project was to create a table that provided the entire history of a teachers relationship with a classroom. So 1 row per teacher per classroom per start and end date.

# Approach
The problem is a variation of the gaps and islands question so that is the approach used.

There are 3 staging tables used, which each subsequent staging table depending on the prior.

teacher_classroom_date_ranges -> teacher_classroom_groups -> teacher_classrooms

# teacher_classroom_date_ranges
1. There have been multiple data ingestion tools used in the past leading inconsistent values across date columns and duplicate rows being generated.
2. mysql_ebdb_tables.people_teacher_classrooms_history, a row is inserted into this table/updated everytime a teacher's relationship with a classroom changes. _fivetran_deleted represents a hard delete while datetime_archived would be a soft delete.\
A basic recreation of the table

| user_id | classroom_id | date_created | _fivetran_synced | _fivetran_deleted |
|---------|--------------|--------------|------------------|-------------------|
| 1       | a            |              | 2022-01-01       |                   |
| 1       | a            | 2022-01-01   | 2022-01-02       | true              |
| 1       | a            | 2022-01-15   | 2022-01-16       |                   |
| 1       | a            | 2022-01-15   | 2022-06-01       | true              |

4. In the inferred_dates cte I am grabbing all potential date columns and generating an inferred created timestamp.
5. asdf
6. asdf

# teacher_classroom_groups

# teacher_classrooms

