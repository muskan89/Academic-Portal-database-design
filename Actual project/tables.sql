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
Credit dec(10,2),
PRIMARY KEY (Course_id),
Foreign KEY (dept_name) REFERENCES Department(dept_name)
);

CREATE TABLE Faculty
(
    name varchar(255),
    id varchar(255),
    dept_name varchar(255),
    PRIMARY KEY(id),
    Foreign KEY (dept_name) REFERENCES Department(dept_name)
);

CREATE TABLE Batch_Advisor
(
    name varchar(255), 
    id varchar(255),
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
credit dec(10,2),
Instructor_id varchar(255),
LTPSC varchar(255),
cgConstraint dec(10,2),
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
    cg dec(10,2),
    total_credits dec(10,2),
    primary key(entry_num)
);

CREATE TABLE BatchesAllowed
(
    Course_id varchar(255),
    yearOfAdmission int,
    dept_name varchar(255),
    foreign key (Course_id) references CourseCatalogue(Course_id)
);

CREATE TABLE isGoingToTake
(
    entry_num varchar(255),
    Course_id varchar(255),
    credit dec(10,2), 
    Sec_id int,
    yearOfAdmission int,
    semester int,
    foreign key(entry_num) references  student(entry_num),
    foreign key(course_id) references  CourseCatalogue(course_id)
);

CREATE TABLE historyOfStudent
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    grade int,
    credit dec(10,2),
    department varchar(255),
    yearOfAdmission int,
    foreign key(entry_num) references  student(entry_num)
);

CREATE TABLE studentsTicketRequest
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission varchar(255),
    BatchAdvisorPermission varchar(255),
    DeanPermission varchar(255),
    foreign key(entry_num) references student(entry_num),
    foreign key(Course_id) references CourseCatalogue(course_id)
    
);

CREATE TABLE facultyTicketinfo
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission varchar(255),
    BatchAdvisorPermission varchar(255),
    DeanPermission varchar(255),
    foreign key(entry_num) references student(entry_num),
    foreign key(Course_id) references CourseCatalogue(course_id)
    
);

CREATE TABLE BatchAdvisorTicketinfo
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission varchar(255),
    BatchAdvisorPermission varchar(255),
    DeanPermission varchar(255),
    foreign key(entry_num) references student(entry_num),
    foreign key(Course_id) references CourseCatalogue(course_id)
    
);

CREATE TABLE DeanTicketInfo
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission varchar(255),
    BatchAdvisorPermission varchar(255),
    DeanPermission varchar(255),
    foreign key(entry_num) references student(entry_num),
    foreign key(Course_id) references CourseCatalogue(course_id)
    
);

CREATE TABLE TimeSlot
(
Course_id varchar(255),
Duration varchar(255),
startingTime varchar(255),
endingTime varchar(255),
foreign key(Course_id) references CourseCatalogue(course_id)
);

CREATE TABLE Day_table
(
   day varchar(255),
   PRIMARY KEY(day)
);


CREATE TABLE courseThroughTicket
(
    entry_num varchar(255),
    Course_id varchar(255),
    credit varchar(255), 
    Sec_id int,
    yearOfAdmission int,
    semester int,
    foreign key(entry_num) references  student(entry_num),
    foreign key(course_id) references  CourseCatalogue(course_id)
);
