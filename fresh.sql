CREATE TABLE Department
(
dept_name varchar(255),
PRIMARY KEY (dept_name)
);

CREATE TABLE CourseCatalogue
(
Course_id varchar(255),
Title varchar(255),
dept_name varchar(255),
LTPSC varchar(255),
Credit int,
PRIMARY KEY (Course_id),
Foreign KEY (dept_name) REFERENCES Department(dept_name)
);



CREATE TABLE Faculty
(
    name varchar(255),
    id int,
    dept_name varchar(255),
    PRIMARY KEY(id),
    Foreign KEY (dept_name) REFERENCES Department(dept_name)
);

CREATE TABLE Batch_Advisor
(
    name varchar(255), 
    id int,
    Batch_year int,
    dept_name varchar(255),
    foreign key (id) references Faculty(id),
    Foreign KEY (dept_name) REFERENCES Department(dept_name)
);

CREATE TABLE CourseOfferings
(
Course_id varchar(255),
dept_name varchar(255),
semester int,
credit int,
Instructor_id int,
LTPSC varchar(255),
cgConstraint int,
foreign key (Course_id) references CourseCatalogue(Course_id),
foreign key (dept_name) references Department(dept_name),
foreign key (Instructor_id) references Faculty(id)
);


CREATE TABLE PreRequisite
(
Course_id varchar(255),
preRequisite_course_code varchar(255),
foreign key (Course_id) references CourseCatalogue(Course_id),
foreign key (preRequisite_course_code) references CourseCatalogue(Course_id)
);

CREATE TABLE Student
(
    entry_num varchar(255),
    student_name varchar(255), 
    yearOfAdmission int,
    dept_name varchar(255),
    total_credit int, 
    cg int,
    primary key(entry_num)
);

CREATE TABLE BatchesAllowed
(
    Course_id varchar(255),
    yearOfAdmission int,
    dept_name varchar(255),
    foreign key (Course_id) references CourseCatalogue(Course_id)
);

