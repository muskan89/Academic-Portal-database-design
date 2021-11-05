Triggers:

LTPSC_checker on courseofferings:-> Checks the ltpsc same or not for the couseoffered and in coursecatalogue

with_id_dept_checker on Batch_advisor:->before insert in the batch_advisor it checks whether it has the same department as in the faculty table.

student_transcript_table on student:-> As a student is inserted into student, it makes it as user and grant the required access to it and generate a transcript table particularly for that student that get filled after when dean generate the transcript.

delete_student on student:-> if a student is deleted from the student then all the access is revoked and user is dropped.

faculty_grant on faculty:-> if dean add some faculty to faculty table then it becomes user and all required access are given to it.

delete_faculty on faculty:-> if a faculty is being to be deleted then it revokes all the access from him/her and drop him/her as user.


course_offering_other_criteria_insert_checker on courseofferings:-> it is for security purpose, if some other faculty try to add course from other department then it will throw an error i.e a faculty can only add a course which belongs to his/her department.

course_offering_other_criteria_update_checker on courseofferings:->it is for security purpose, if some other faculty try to update course from other department then it will throw an error i.e a faculty can only update a course which belongs to his/her department. 


course_offerings_delete_checker on courseoferings:-> it is for security purpose, if some other faculty try to delete course from other department then it will throw an error i.e a faculty can only delete a course which belongs to his/her department.


delete_fault on isgoingtotake:-> it is for security purpose if some other student want to delete someone course then it will throw and error for the same.

update_fault on isgoingtotake:-> it is for security purpose if some other student want to update someone course then it will throw and error for the same.

cgpa_constraint_handler on isgoingtotake:-> when a student try to enroll in a course it will check the cgpa fullfilling or not. If not then error occurs.

preRequisites_handler on igoingtotake:-> when a student try to enroll in a course it will check the  prerequisites fullfilling or not. If not then error occurs.

batch_criteria_checking on isgoingtotake:->when a student try to enroll in a course it will check the  batches allowed fullfilling or not. If not then error occurs.

clash_time_slot on isgoingtotake:-> when a student try to enroll in a course whose time clash with it's one of the already enrolled courses it will throw an error.

credit_limit_handler on isgoingtotake:-> when a student try to enroll in a course and if he/she exceeds the credit limits then it will throw an error.

to_batch_advisor_ticket on facultyticketinfo:-> when a faculty update the facultyticketinfo then it passes to the batch advisor.