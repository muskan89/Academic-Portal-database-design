CREATE TABLE CourseCatalogue
(
Code varchar(255),
Title varchar(255),
--LTPSC  varchar(255)
Lecture int,
Tutorial int,
Practical int,
SelfStudy int,
Credit int
);

CREATE TABLE PreRequisite
(
Code varchar(255),
preRequisite_course_code varchar(255),
foreign key (Code, preRequisite_course_code) references CourseCatalogue(code)
);


--Course should be present in course catalogue
CREATE TABLE CourseOfferings
(
Code varchar(255),
Title varchar(255),
semester int,
Instructor varchar(255),
LTPSC  varchar(255),
--Batch allowed
--timeslot
cgConstraint int
foreign key (Code, Title) references CourseCatalogue(Code,Title)
);

CREATE TABLE TimeSlot
(
Code varchar(255),
Duration varchar(255),
startingTime varchar(255),
endingTime varchar(255),
day varchar(255)
);

CREATE TABLE BATCH
(
    yearOfAdmission int,
    dept_name varchar(255) 
);

CREATE TABLE Student
(
    entry_num varchar(255),
    student_name varchar(255), 
    yearOfAdmission int,
    dept_name varchar(255),
    total_credit int 
);

        