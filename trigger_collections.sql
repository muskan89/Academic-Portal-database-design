CREATE TABLE CourseCatalogue
(
Course_id varchar(255),
Title varchar(255),
--LTPSC  varchar(255)
Lecture int,
Tutorial int,
Practical int,
SelfStudy int,
Credit int
);

CREATE TABLE isGoingToTake
(
    entry_num varchar(255),
    Course_id varchar(255),
    credit int, 
    Sec_id int,
    year int,
    semester int, 
);



--Course should be present in course catalogue
CREATE TABLE CourseOfferings
(
Course_id varchar(255),
Title varchar(255),
semester int,
Instructor varchar(255),
LTPSC varchar(255),
Batch_allowed_department varchar(255),
Batch_allowed_year int,
--timeslot
cgConstraint int,
foreign key (Code, Title) references CourseCatalogue(Code,Title)
);

CREATE TABLE BatchesAllowed
(
    Course_id varchar(255),
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
    cg int;
);

CREATE TABLE TimeSlot
(
Course_id varchar(255),
Duration varchar(255),
startingTime varchar(255),
endingTime varchar(255),
day varchar(255)
);
CREATE TABLE PreRequisite
(
Course_id varchar(255),
preRequisite_course_code varchar(255),
foreign key (Code, preRequisite_course_code) references CourseCatalogue(code)
);

CREATE TABLE historyOfStudent
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    grade int,
    credit int,
    department varchar(255),
    yearOfAdmission int
);

CREATE TABLE studentsTicketRequest
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission int,
    BatchAdvisorPermission int,
    DeanPermission int
);

CREATE TABLE facultyTicketRequest
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission int,
    BatchAdvisorPermission int,
    DeanPermission int
);

CREATE TABLE BatchAdvisorTicketRequest
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission int,
    BatchAdvisorPermission int,
    DeanPermission int
);

CREATE TABLE DeanTicketRequest
(
    entry_num varchar(255),
    sem int,
    Course_id varchar(255), 
    facultyPermission int,
    BatchAdvisorPermission int,
    DeanPermission int
);


CREATE OR REPLACE FUNCTION TriggerGenerator(entry_no varchar(255),course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
--declared something
_unit record;
_slot record;
flag integer := 0;
BEGIN
for _unit in (select * from  TimeSlot where TimeSlot.Course_id=course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where entry_no=isGoingToTake.entry_num))
loop
    for _slot in (select * in TimeSlot where TimeSlot.Course_id!=course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where entry_no=isGoingToTake.entry_num))
    loop
        --condition we will have to think
        if(_unit.Duration == _slot.Duration and _unit.startingTime==_slot.startingTime and _unit.endingTime==_slot.endingTime)
        then flag := flag + 1;
        ELSE
        THEN
            raise exception 'time slot % is clashing with other courses',_unit;
    end loop;
end loop;
RETURN NEW;
END;
$$;

CREATE TRIGGER clashes_time_slot
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE check_clashes_time_slot();





















CREATE OR REPLACE FUNCTION check_clashes_time_slot(entry_no varchar(255),course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
--declared something
_unit record;
_slot record;
flag integer := 0;
BEGIN
for _unit in (select * from  TimeSlot where TimeSlot.Course_id=course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where entry_no=isGoingToTake.entry_num))
loop
    for _slot in (select * in TimeSlot where TimeSlot.Course_id!=course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where entry_no=isGoingToTake.entry_num))
    loop
        --condition we will have to think
        if(_unit.Duration == _slot.Duration and _unit.startingTime==_slot.startingTime and _unit.endingTime==_slot.endingTime)
        then flag := flag + 1;
        ELSE
        THEN
            raise exception 'time slot % is clashing with other courses',_unit;
    end loop;
end loop;
RETURN NEW;
END;
$$;

CREATE TRIGGER clashes_time_slot
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE check_clashes_time_slot();


--trigger to check if the course student going to insert is fulfilling pre-requisites or not
CREATE OR REPLACE FUNCTION full_filling_preRequisite(entry_no int,course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
pre record;
grad integer := 0;
BEGIN
for pre in (select * from PreRequisite where PreRequisite.Course_id=course_id)
loop
    if pre.Course_id in (select historyOfStudent.Course_id from historyOfStudent where historyOfStudent.entry_num=entry_no)
    then
        grad := (select historyOfStudent.grade from historyOfStudent where historyOfStudent.entry_num=entry_no and course_id=historyOfStudent.Course_id);
        if grade<4
        then raise exception 'student has not fulfilled pre-requisites of the course';
        end if;
    else
    then
        raise exception 'student has not fulfilled pre-requisites of the course';
    end if;
end loop;
RETURN NEW;
END;
$$;

CREATE TRIGGER preRequisites_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE full_filling_preRequisite();

--trigger to check if the course, student going to insert is fulfilling the cg constraint or not
CREATE OR REPLACE FUNCTION cg_constraint_checking(entry_no int,course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
cgpa integer := 0;
BEGIN
    cgpa := (select Student.cg from Student where Student.entry_num=entry_no);
    if(cgpa < (select CourseOfferings.cgConstraint from CourseOfferings where CourseOfferings.Course_id=course_id))
    then raise exception 'student has not fulfilled cgpa-constraint of the course';
    end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER cgpa_constraint_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE cg_constraint_checking();

--trigger to check if the course, student going to insert is fulfilling the batch criteria or not

CREATE OR REPLACE FUNCTION batch_criteria_checking(entry_no int,course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
yr integer := 0;
dep varchar(255);
_unit record;
flag integer := 1; 
BEGIN
    dep := (select Student.dept_name from Student where Student.entry_num=entry_no);
    yr := (select Student.yearOfAdmission from Student where Student.entry_num=entry_no);
    for _unit in (select * from BatchesAllowed where BatchesAllowed.Course_id=course_id)
    loop
        if dep == _unit.dept_name and yr == _unit.yearOfAdmission
        then flag := flag + 1;
        end if;
    end loop;
    if flag == 0
    then raise exception 'student has not fulfilled batch-criteria of the course';
    end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER batch_criteria_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE batch_criteria_checking();


--trigger to check if the course, student going to insert is fulfilling the credit limit this semester or not

CREATE OR REPLACE FUNCTION credit_limit_checking(entry_no int,thisSem int,course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
checking integer := 0;
credit1 integer := 0;
credit2 integer := 0;
credit3 integer := 0;

_unit record;
 
BEGIN
    for _unit in (select unit from historyOfStudent where historyOfStudent.entry_num=entry_no and historyOfStudent.sem=(thisSem-1))
    loop
    if(_unit.grade >= 4)
    then credit1 := _unit.credit + credit1;
    end if;

    end loop;

    for _unit in (select unit from historyOfStudent where historyOfStudent.entry_num=entry_no and historyOfStudent.sem=(thisSem-2))
    loop
    if(_unit.grade >= 4)
    then credit2 := _unit.credit + credit2;
    end if;
    end loop;

    for _unit in (select unit from isGoingToTake where isGoingToTake.entry_num=entry_no and isGoingToTake.sem=(thisSem-2))
    loop
    if(_unit.grade >= 4)
    then credit3 := _unit.credit + credit3;
    end if;
    end loop;

    credit3 := credit3 + (select CourseCatalogue.Credit from CourseCatalogue where CourseCatalogue.Course_id=course_id);
    checking := (credit1 + credit2)/2;
    checking := checking * 1.25;
    if(credit3 > checking)
    THEN raise exception 'credit limit will increase after taking this course';
    endif;


RETURN NEW;
END;
$$;

CREATE TRIGGER credit_limit_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE credit_limit_checking();


































--this trigger will be used when faculty before faculty tries to add course in courese offering

CREATE OR REPLACE FUNCTION course_is_in_catalogue_or_not(course_id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
checking integer:=0;
BEGIN
    if course_id not in (select CourseCatalogue.Course_id from CourseCatalogue)
    then raise exception 'this course does not exist in course catalogue';
    end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER check_course_is_in_catalogue_or_not
Before INSERT
ON CourseOfferings
FOR EACH ROW
EXECUTE PROCEDURE course_is_in_catalogue_or_not();


