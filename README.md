# Background
Within our application a teacher can create, join and leave a classroom at anytime. However, the application only tracks current classroom associations so if a teacher is no longer associated with a classroom that data is lost forever.

The purpose of this project was to create a table that provided the entire history of a teachers relationship with a classroom. So 1 row per teacher per classroom per start and end date.

# Approach
The problem is a variation of the gaps and islands question so that is the approach used.

There are 3 staging tables used, which each subsequent staging table depending on the prior.

teacher_classroom_date_ranges -> teacher_classroom_groups -> teacher_classrooms

# teacher_classroom_date_ranges

# teacher_classroom_groups

# teacher_classrooms

