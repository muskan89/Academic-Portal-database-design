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





















CREATE OR REPLACE FUNCTION check_clashes_time_slot()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
--declared something
_unit record;
_slot record;
flag integer := 0;
BEGIN
for _unit in (select * from  TimeSlot where TimeSlot.Course_id=New.Course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where New.entry_num=isGoingToTake.entry_num))
loop
    for _slot in (select * from TimeSlot where TimeSlot.Course_id!=New.Course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where New.entry_num=isGoingToTake.entry_num))
    loop
        --condition we will have to think
        if(_unit.Duration = _slot.Duration and _unit.startingTime=_slot.startingTime and _unit.endingTime=_slot.endingTime)
        then flag := flag + 1;
        ELSE
            raise exception 'time slot % is clashing with other courses',_unit;
        end if;
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

CREATE OR REPLACE FUNCTION batch_criteria_checking()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
yr integer := 0;
dep varchar(255);
_unit record;
flag integer := 0; 
BEGIN
    dep := (select DISTINCT Student.dept_name from Student where Student.entry_num=New.entry_num);
    yr := (select DISTINCT Student.yearOfAdmission from Student where Student.entry_num=New.entry_num);
    for _unit in (select * from BatchesAllowed where BatchesAllowed.Course_id=New.Course_id)
    loop
        if dep = _unit.dept_name and yr = _unit.yearOfAdmission
        then flag := flag + 1;
        end if;
    end loop;
    if flag = 0
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

CREATE OR REPLACE FUNCTION credit_limit_checking()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
checking dec(10,2) := 0;
credit1 dec(10,2) := 0;
credit2 dec(10,2) := 0;
credit3 dec(10,2) := 0;

_unit record;
 
BEGIN
    for _unit in (select * from historyOfStudent where historyOfStudent.entry_num=New.entry_num and historyOfStudent.sem=(New.semester-1))
    loop
    if(_unit.grade >= 4)
    then credit1 := _unit.credit + credit1;
    end if;

    end loop;

    for _unit in (select * from historyOfStudent where historyOfStudent.entry_num=New.entry_num and historyOfStudent.sem=(New.semester-2))
    loop
    if(_unit.grade >= 4)
    then credit2 := _unit.credit + credit2;
    end if;
    end loop;

    for _unit in (select * from isGoingToTake where isGoingToTake.entry_num=New.entry_num and isGoingToTake.sem=(New.semester))
    loop
    if(_unit.grade >= 4)
    then credit3 := _unit.credit + credit3;
    end if;
    end loop;

    credit3 := credit3 + (select DISTINCT CourseCatalogue.Credit from CourseCatalogue where CourseCatalogue.Course_id=New.Course_id);
    checking := (credit1 + credit2)/2;
    checking := checking * 1.25;
    if(credit3 > checking)
    THEN raise exception 'credit limit will increase after taking this course';
    end if;


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





CREATE OR REPLACE FUNCTION make_user(id varchar(255))
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
Declare 
check varchar(255):=id;
BEGIN
    create user check with password 'iitropar';
RETURN NEW;
END;
$$;

CREATE TRIGGER _make_user
AFTER INSERT
ON Student
FOR EACH ROW
EXECUTE PROCEDURE make_user(entry_num);








--trigger to check if the LTPSC is same for courseofferings and coursecatalogue or not
CREATE OR REPLACE FUNCTION LTPSC_same_or_not()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
one varchar(255);
two varchar(255);
BEGIN
one := (select distinct CourseCatalogue.LTPSC from CourseCatalogue where CourseCatalogue.Course_id=New.Course_id);
two := New.LTPSC;
if(one != two)
then raise exception 'this course LTPSC does not matches in coursecatalogue';
end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER LTPSC_checker
Before INSERT
ON CourseOfferings
FOR EACH ROW
EXECUTE PROCEDURE LTPSC_same_or_not();




--trigger to check if the department or same user id faculties same or not in tables "faculty and batch_advisor"
CREATE OR REPLACE FUNCTION with_id_dept_same_or_not()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
one varchar(255);
two varchar(255);
BEGIN
one := (select distinct Faculty.dept_name from Faculty where Faculty.id=New.id);
two := New.dept_name;
if(one != two)
then raise exception 'Faculty and batch_advisor with same id cannot have different department';
end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER with_id_dept_checker
Before INSERT
ON Batch_Advisor
FOR EACH ROW
EXECUTE PROCEDURE with_id_dept_same_or_not();



--trigger to ensure instructor_id of the course to be inserted should be same as the user
--and the department of the course_id of the row should be same as the course_id’s
--department in course catalogue and user’s department is also same as the course’s
--department that is to be inserted
CREATE OR REPLACE FUNCTION course_offerings_some_criteria()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
one varchar(255);
two varchar(255);
three varchar(255);
four varchar(255);
BEGIN
one := (select current_user);
two := New.Instructor_id;
if(one != two)
then raise exception 'Someone else is trying to modify others data in the table';
end if;

three := (select distinct Faculty.dept_name where Faculty.id=one);
if(three != New.dept_name)
then raise exception 'Department of user and course is different';
end if;

four := (select distinct CourseCatalogue.dept_name from CourseCatalogue where CourseCatalogue.Course_id=New.Course_id);
if(four != New.dept_name)
then raise exception 'Department of course is different from CourseCatalogue';
end if;



RETURN NEW;
END;
$$;

CREATE TRIGGER course_offerings_other_criteria_insert_checker
Before INSERT
ON CourseOfferings
FOR EACH ROW
EXECUTE PROCEDURE course_offerings_some_criteria();

CREATE TRIGGER course_offerings_other_criteria_update_checker
Before UPDATE
ON CourseOfferings
FOR EACH ROW
EXECUTE PROCEDURE course_offerings_some_criteria();









--trigger to make create tables for students transcript at time of getting them into student table
CREATE OR REPLACE FUNCTION make_student_transcript_table()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
execute format('CREATE TABLE %I (Course_id varchar(255), grade int, credit dec(10,2),sem int);', 'transcript_entry_num_' || New.entry_num::text);
execute format('Grant select on %I to %I','transcript_entry_num_' || New.entry_num::text,'s_'||New.entry_num); 
RETURN NEW;
END;
$$;

CREATE TRIGGER student_transcript_table
After INSERT
ON Student
FOR EACH ROW
EXECUTE PROCEDURE make_student_transcript_table();


--stored procedure to generating transcript
CREATE OR REPLACE FUNCTION generateTranscript(_entry_num varchar(255),_sem int)
RETURNS table(Course_id varchar(255), grade int, credit dec(10,2),sem int)
LANGUAGE plpgsql
AS $$
DECLARE
unit record;
BEGIN
for unit in (select * from historyOfStudent where historyOfStudent.entry_num=_entry_num and historyOfStudent.sem=_sem)
loop
execute format('insert into %I values(%L,%L,%L,%L)','transcript_entry_num_' || _entry_num::text,unit.Course_id,unit.grade,unit.credit,unit.sem);
end loop;

return query execute format('select * from %I ','transcript_entry_num_' || _entry_num::text); 
END;
$$;




--testing pending

CREATE OR REPLACE FUNCTION credit_limit_checking()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
checking dec(10,2) := 0;
credit1 dec(10,2) := 0;
credit2 dec(10,2) := 0;
credit3 dec(10,2) := 0;

_unit record;
 
BEGIN
    for _unit in (select * from historyOfStudent where historyOfStudent.entry_num=New.entry_num and historyOfStudent.sem=(New.semester-1))
    loop
    if(_unit.grade >= 4)
    then credit1 := _unit.credit + credit1;
    end if;

    end loop;

    for _unit in (select * from historyOfStudent where historyOfStudent.entry_num=New.entry_num and historyOfStudent.sem=(New.semester-2))
    loop
    if(_unit.grade >= 4)
    then credit2 := _unit.credit + credit2;
    end if;
    end loop;

    for _unit in (select * from isGoingToTake where isGoingToTake.entry_num=New.entry_num and isGoingToTake.sem=(New.semester))
    loop
    if(_unit.grade >= 4)
    then credit3 := _unit.credit + credit3;
    end if;
    end loop;

    credit3 := credit3 + (select DISTINCT CourseCatalogue.Credit from CourseCatalogue where CourseCatalogue.Course_id=New.Course_id);
    checking := (credit1 + credit2)/2;
    checking := checking * 1.25;
    if(credit3 > checking)
    THEN 
    execute format('insert into studentsTicketRequest values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.semester,New.Course_id,NULL,NULL,NULL);
    raise exception 'credit limit will increase after taking this course';
    end if;


RETURN NEW;
END;
$$;

CREATE TRIGGER credit_limit_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE credit_limit_checking();

--trigger to make send ticket request to faculty
CREATE OR REPLACE FUNCTION move_to_faculty_ticket()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
execute format('insert into facultyTicketinfo values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.sem,New.Course_id,NULL,NULL,NULL);
RETURN NEW;
END;
$$;

CREATE TRIGGER to_faculty_ticket
After INSERT
ON studentsTicketRequest
FOR EACH ROW
EXECUTE PROCEDURE move_to_faculty_ticket();


--trigger to make send ticket request to batch advisor
CREATE OR REPLACE FUNCTION move_to_batchAdvisor_ticket()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
execute format('insert into BatchAdvisorTicketinfo values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.sem,New.Course_id,New.facultyPermission,NULL,NULL);
RETURN NEW;
END;
$$;

CREATE TRIGGER to_batchAdvisor_ticket
After UPDATE
ON facultyTicketinfo
FOR EACH ROW
EXECUTE PROCEDURE move_to_batchAdvisor_ticket();


--trigger to make send ticket request to dean
CREATE OR REPLACE FUNCTION move_to_dean_ticket()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
execute format('insert into DeanTicketInfo values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.sem,New.Course_id,New.facultyPermission,New.BatchAdvisorPermission,NULL);
RETURN NEW;
END;
$$;

CREATE TRIGGER to_dean_ticket
After UPDATE
ON BatchAdvisorTicketinfo
FOR EACH ROW
EXECUTE PROCEDURE move_to_dean_ticket();


--trigger to raise notice if dean refused and add course in table courseThroughTicket if he or she agreed.
CREATE OR REPLACE FUNCTION checking_dean_permission()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
_credit varchar(255); 
_Sec_id int;
_yearOfAdmission int;
BEGIN
_credit=(select DISTINCT CourseCatalogue.Credit from CourseCatalogue where CourseCatalogue.Course_id=New.Course_id);
_yearOfAdmission=(select DISTINCT Student.yearOfAdmission from Student where Student.entry_num=New.entry_num);
if New.DeanPermission = 'Yes'
THEN execute format('insert into courseThroughTicket values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.Course_id,_credit,NULL,_yearOfAdmission,New.sem);
else
raise notice 'ticket got rejected by dean';
end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER _dean_permission
After UPDATE
ON DeanTicketInfo
FOR EACH ROW
EXECUTE PROCEDURE checking_dean_permission();


