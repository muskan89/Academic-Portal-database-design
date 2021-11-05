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


CREATE OR REPLACE FUNCTION CalculateCGPA(_entry_num varchar(255))
RETURNS dec(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
points dec(10,2) := 0;
multi dec(10,2) := 0;
totalCredits dec(10,2) := 0;
cgpa dec(10,2);
see record;

BEGIN

if('s_'||_entry_num<>current_user and left(current_user,1)='s')
then raise exception 'Invalid Access';
end if;

for see in (select historyOfStudent.grade,historyOfStudent.credit from historyOfStudent where historyOfStudent.entry_num=_entry_num)loop
multi := (see.grade) * (see.credit);
points := points + multi;
totalCredits := totalCredits + (see.credit);
end loop;


cgpa := (points/totalCredits);
if(current_user='dean')
then
update student
set cg = cgpa
where student.entry_num=_entry_num;

update student
set total_credits = totalCredits
where student.entry_num=_entry_num;
end if;

return cgpa;
END;
$$;

--to call it use this but ensure foreign key data is already present in the respective tables
select * from CalculateCGPA(_entry_num);
--CalculateCGPA procedure done




CREATE or Replace FUNCTION OfferCourse(_Course_id varchar(255),_dept_name varchar(255),_semester int,_credit dec(10,2),_Instructor_id varchar(255),_LTPSC varchar(255),_cgConstraint dec(10,2))
  RETURNS void AS
  $BODY$
      BEGIN
        INSERT INTO CourseOfferings(Course_id, dept_name, semester, credit, Instructor_id, LTPSC,cgConstraint)
        VALUES(_Course_id,_dept_name,_semester,_credit,_Instructor_id,_LTPSC,_cgConstraint);
      END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

--to call it use this but ensure foreign key data is already present in the respective tables
select * from OfferCourse('CS301','CSE',5,4,'1','3-2-1-2-4',7 );
--offerCourse procedure done


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



CREATE OR REPLACE FUNCTION make_student_transcript_table()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
execute format('CREATE TABLE %I (Course_id varchar(255), grade int, credit dec(10,2),sem int);', 'transcript_entry_num_' || New.entry_num);
execute format('CREATE USER %s with password ''%s''','s_'||New.entry_num,New.entry_num);
execute format('Grant select on coursecatalogue to %I','s_'||New.entry_num);
 execute format ('Grant select on Faculty to %I','s_'||New.entry_num);
 execute format ('Grant select on Batch_Advisor to %I','s_'||New.entry_num);
 execute format ('Grant select on preRequisite to %I','s_'||New.entry_num);
 execute format ('Grant select on courseofferings to %I','s_'||New.entry_num);
 execute format ('Grant select on batchesallowed to %I','s_'||New.entry_num);
 execute format ('Grant select on department to %I','s_'||New.entry_num);
 execute format ('Grant select on student to %I','s_'||New.entry_num);
 execute format ('Grant select, insert,update,delete on isGoingtotake to %I','s_'||New.entry_num);
 execute format ('Grant select,update,insert,delete on studentsticketrequest to %I','s_'||New.entry_num);
 execute format ('Grant insert on facultyticketinfo to %I','s_'||New.entry_num);
 execute format ('Grant select on timeslot to %I','s_'||New.entry_num);
 execute format ('Grant select on coursethroughticket to %I','s_'||New.entry_num);
 execute format ('Grant select on historyofstudent to %I','s_'|| New.entry_num);
execute format('Grant select on %I to %I','transcript_entry_num_' || New.entry_num,'s_'||New.entry_num);

RETURN NEW;
END;
$$;

CREATE TRIGGER student_transcript_table
After INSERT
ON Student
FOR EACH ROW
EXECUTE PROCEDURE make_student_transcript_table();


CREATE OR REPLACE FUNCTION free_user()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN


execute format('revoke select on coursecatalogue from %I;','s_'||old.entry_num);
 execute format ('revoke select  on Faculty from %I;','s_'||old.entry_num);
 execute format ('revoke select on Batch_Advisor from %I;','s_'||old.entry_num);
 execute format ('revoke select on preRequisite from %I;','s_'||old.entry_num);
 execute format ('revoke select on courseofferings from %I;','s_'||old.entry_num);
 execute format ('revoke select on batchesallowed from %I;','s_'||old.entry_num);
 execute format ('revoke select on department from %I;','s_'||old.entry_num);
 execute format ('revoke select on student from %I;','s_'||old.entry_num);
 execute format ('revoke select, insert,update,delete on isGoingtotake from %I;','s_'||old.entry_num);
 execute format ('revoke select,update,insert,delete on studentsticketrequest from %I;','s_'||old.entry_num);
 execute format ('revoke insert on facultyticketinfo from %I','s_'||old.entry_num);
 execute format ('revoke select on timeslot from %I;','s_'||old.entry_num);
 execute format ('revoke select on coursethroughticket from %I;','s_'||old.entry_num);
 execute format ('revoke select on historyofstudent from %I','s_'|| old.entry_num);
execute format('revoke select on %I from %I;','transcript_entry_num_' || old.entry_num,'s_'||old.entry_num); 
execute format('Drop TABLE %I ;', 'transcript_entry_num_' || old.entry_num);
execute format('Drop USER %s;' ,'s_'||old.entry_num);
RETURN NEW;
END;
$$;

CREATE TRIGGER delete_student
After DELETE
ON Student
FOR EACH ROW
EXECUTE PROCEDURE free_user();

CREATE OR REPLACE FUNCTION generateTranscript(_entry_num varchar(255),_sem int)
RETURNS table(Course_id varchar(255), grade int, credit dec(10,2),sem int)
LANGUAGE plpgsql
AS $$
DECLARE
unit record;
BEGIN
for unit in (select * from historyOfStudent where historyOfStudent.entry_num=_entry_num and historyOfStudent.sem=_sem)
loop
execute format('insert into %I values(%L,%L,%L,%L)','transcript_entry_num_' || _entry_num,unit.Course_id,unit.grade,unit.credit,unit.sem);
end loop;

return query execute format('select * from %I ','transcript_entry_num_' || _entry_num); 
END;
$$;
CREATE OR REPLACE FUNCTION grant_faculty()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN

 execute format('CREATE USER %s with password ''%s''',lower(New.id),New.id);
 execute format('Grant select on coursecatalogue to %I',lower(New.id));
 execute format ('Grant select on Faculty to %I',lower(New.id));
 execute format ('Grant select on Batch_Advisor to %I',lower(New.id));
 execute format ('Grant select on preRequisite to %I',lower(New.id));
 execute format ('Grant select,insert,update,delete on courseofferings to %I',lower(New.id));
 execute format ('Grant select ,insert,update,delete on batchesallowed to %I',lower(New.id));
 execute format ('Grant select on department to %I',lower(New.id));
 execute format ('Grant select on student to %I',lower(New.id));
 execute format ('Grant select on isGoingtotake to %I',lower(New.id));
 execute format ('Grant select, insert,update,delete on historyofstudent to %I',lower(New.id));
 execute format ('Grant select ,insert,update,delete on facultyticketinfo to %I',lower(New.id));
 execute format ('Grant select,insert on batchadvisorticketinfo to %I',lower(New.id));
 execute format ('Grant select,insert,update,delete on timeslot to %I',lower(New.id));
 execute format ('Grant select on coursethroughticket to %I',lower(New.id));

RETURN NEW;
END;
$$;

CREATE TRIGGER faculty_grant
After INSERT
ON Faculty
FOR EACH ROW
EXECUTE PROCEDURE grant_faculty();



CREATE OR REPLACE FUNCTION free_faculty()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN


 execute format('Revoke select on coursecatalogue from %I',lower(old.id));
 execute format ('Revoke select on Faculty from %I',lower(old.id));
 execute format ('Revoke select on Batch_Advisor from %I',lower(old.id));
 execute format ('Revoke select on preRequisite from %I',lower(old.id));
 execute format ('Revoke select,insert,update,delete on courseofferings from %I',lower(old.id));
 execute format ('Revoke select ,insert,update,delete on batchesallowed from %I',lower(old.id));
 execute format ('Revoke select on department from %I',lower(old.id));
 execute format ('Revoke select on student from %I',lower(old.id));
 execute format ('Revoke select on isGoingtotake from %I',lower(old.id));
 execute format ('Revoke select, insert,update,delete on historyofstudent from %I',lower(old.id));
 execute format ('Revoke select ,insert,update,delete on facultyticketinfo from %I',lower(old.id));
 execute format ('revoke select,insert on batchadvisorticketinfo from %I',lower(old.id));
 execute format ('Revoke select,insert,update,delete on timeslot from %I',lower(old.id));
 execute format ('Revoke select on coursethroughticket from %I',lower(old.id));
 execute format('Drop USER %s;' ,lower(old.id));

RETURN NEW;
END;
$$;

CREATE TRIGGER delete_faculty
After DELETE
ON Faculty
FOR EACH ROW
EXECUTE PROCEDURE free_faculty();







CREATE OR REPLACE FUNCTION uploadTimeSlot()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
COPY TimeSlot(Course_id, duration, startingtime, endingtime,day)
FROM 'D:\DBMS\DBMS-project1\timeslot.csv'
DELIMITER ','
CSV HEADER;
END;
$$;

--to call it use this but ensure foreign key data is already present in the respective tables
select * from uploadTimeSlot();



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
two := lower(New.Instructor_id);
if(one != two)
then raise exception 'Someone else is trying to modify others data in the table';
end if;

three := (select distinct Faculty.dept_name from faculty where Faculty.id=one);
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


CREATE OR REPLACE FUNCTION course_offerings_delete()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
one varchar(255);
two varchar(255);
BEGIN
one :=  current_user;
two := lower(old.Instructor_id);
if(one != two and left(current_user,4)<>'dean')
then raise exception 'Someone else is trying to delete others data in the table';
end if;

RETURN old;
END;
$$;

CREATE TRIGGER course_offerings_delete_checker
Before DELETE
ON CourseOfferings
FOR EACH ROW
EXECUTE PROCEDURE course_offerings_delete();

CREATE or Replace FUNCTION RegisterCourse(_entry_num varchar(255),_Course_id varchar(255),_credit dec(10,2), _Sec_id int,_yearOfAdmission int,_semester int)
  RETURNS void AS
  $BODY$
      BEGIN
	if(_course_id not in (select courseofferings.course_id from courseofferings))
	then raise exception 'Course Not offered this sem';
	end if;
	if(current_user<> 's_'||_entry_num )
	then raise exception 'Invalid access';
	end if;
        INSERT INTO isGoingToTake(entry_num,Course_id,credit,Sec_id,yearOfAdmission,semester)
        VALUES(_entry_num,_Course_id,_credit, _Sec_id,_yearOfAdmission,_semester);
      END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION invalid_access()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
real_usrr varchar(255);
BEGIN
    if(current_user <> 's_'||old.entry_num and left(current_user,4)<>'dean')
    THEN raise exception 'someone else is trying to interupt in others data';
    end if;
RETURN old;
END;
$$;

CREATE TRIGGER delete_fault
Before Delete
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE invalid_access();

CREATE TRIGGER update_fault
Before Update
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE invalid_access();



CREATE OR REPLACE FUNCTION cg_constraint_checking()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
cgpa dec(10,2) := 0;
BEGIN
    cgpa := (select Student.cg from Student where Student.entry_num=New.entry_num);
    if(cgpa < (select CourseOfferings.cgConstraint from CourseOfferings where CourseOfferings.Course_id=New.Course_id))
then
	
     raise exception 'student has not fulfilled cgpa-constraint of the course';
    end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER cgpa_constraint_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE cg_constraint_checking();



CREATE OR REPLACE FUNCTION full_filling_preRequisite()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
pre record;
grad integer := 0;
BEGIN
for pre in (select * from PreRequisite where PreRequisite.Course_id=New.Course_id)
loop
    if pre.preRequisite_course_code in (select historyOfStudent.Course_id from historyOfStudent where historyOfStudent.entry_num=New.entry_num)
    then
        grad := (select historyOfStudent.grade from historyOfStudent where historyOfStudent.entry_num=New.entry_num and New.Course_id=historyOfStudent.Course_id);
        if grad<4
then
	
         raise exception 'student has not fulfilled pre-requisites of the course';
        end if;
    else
	
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
    if(New.yearofAdmission<>yr)
    then raise exception 'Details Entered is wrong';
    end if;
    if(New.credit<>(select Distinct coursecatalogue.credit from coursecatalogue where coursecatalogue.course_id=New.course_id))
    then raise exception 'Details Entered is Wrong'; 
    end if;
    for _unit in (select * from BatchesAllowed where BatchesAllowed.Course_id=New.Course_id)
    loop
        if dep = _unit.dept_name and yr = _unit.yearOfAdmission
        then flag := flag + 1;
        end if;
    end loop;
    if flag = 0
then

    raise exception 'student has not fulfilled batch-criteria of the course';
    end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER batch_criteria_handler
Before INSERT
ON isGoingToTake
FOR EACH ROW
EXECUTE PROCEDURE batch_criteria_checking();

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
for _unit in (select * from  TimeSlot where TimeSlot.Course_id=New.Course_id and TimeSlot.Course_id not in (select isGoingToTake.Course_id from isGoingToTake where New.entry_num=isGoingToTake.entry_num))
loop
    for _slot in (select * from TimeSlot where TimeSlot.Course_id!=New.Course_id and TimeSlot.Course_id in (select isGoingToTake.Course_id from isGoingToTake where New.entry_num=isGoingToTake.entry_num))
    loop
        --condition we will have to think
        if(_unit.Duration = _slot.Duration and _unit.startingTime=_slot.startingTime and _unit.endingTime=_slot.endingTime )
        then raise exception 'time slot % is clashing with other courses',_unit;
        
            
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

    for _unit in (select * from isGoingToTake where isGoingToTake.entry_num=New.entry_num and isGoingToTake.semester=(New.semester))
    loop
    
    credit3 := _unit.credit + credit3;
    
    end loop;
    
    credit3 := credit3 + (select DISTINCT CourseCatalogue.Credit from CourseCatalogue where CourseCatalogue.Course_id=New.Course_id);
    
    checking := (credit1 + credit2)/2;
    checking := checking * 1.25;
    
    if(credit3 > checking)

    THEN 
	
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



CREATE OR REPLACE FUNCTION ticketGenerate(_entry_num varchar(255),_course_id VARCHAR(255),_Sem integer)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
if('s_'||_entry_num <>current_user)
then raise exception 'Invalid Access';
end if;
execute format('insert into studentsTicketRequest values(%L,%L,%L,%L,%L,%L)',_entry_num,_Sem,_course_id,NULL,NULL,NULL);
END;
$$;


CREATE OR REPLACE FUNCTION move_to_batchAdvisor_ticket()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN


if(upper(current_user) <> (select distinct courseofferings.Instructor_id from courseofferings where courseofferings.course_id=New.Course_id))
THEN raise exception 'faculty who is updating is not offering that course';
end if;

execute format('insert into BatchAdvisorTicketinfo values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.sem,New.Course_id,New.facultyPermission,NULL,NULL);
RETURN NEW;
END;
$$;

CREATE TRIGGER to_batchAdvisor_ticket
After UPDATE
ON facultyTicketinfo
FOR EACH ROW
EXECUTE PROCEDURE move_to_batchAdvisor_ticket();


CREATE OR REPLACE FUNCTION free_batch_advisor()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN


 

 execute format ('revoke select,insert,update,delete on batchadvisorticketinfo from %I',lower(old.id));
 execute format ('revoke select,insert on deanticketinfo from %I',lower(old.id));
 execute format('Drop USER %s;' ,lower(old.id));

RETURN NEW;
END;
$$;

CREATE TRIGGER delete_batchadvisor
After DELETE
ON batch_advisor
FOR EACH ROW
EXECUTE PROCEDURE free_batchadvisor();


CREATE OR REPLACE FUNCTION grant_batchadvisor()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN


 execute format ('Grant select,insert,update,delete on batchadvisorticketinfo to %I',lower(New.id));
 execute format ('Grant select,insert on deanticketinfo to %I',lower(New.id));

RETURN NEW;
END;
$$;

CREATE TRIGGER batchadvisor_grant
After INSERT
ON batch_advisor
FOR EACH ROW
EXECUTE PROCEDURE grant_batchadvisor();



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


CREATE OR REPLACE FUNCTION move_to_dean_ticket()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
if((select distinct Batch_Advisor.dept_name from Batch_Advisor where Batch_Advisor.id=upper(current_user)) <> (select distinct student.dept_name from student where student.entry_num=New.entry_num))
THEN raise exception 'batch advisor who is updating is not advisor of student';
end if;
if((select distinct Batch_Advisor.Batch_year from Batch_Advisor where Batch_Advisor.id=upper(current_user)) <> (select distinct student.yearOfAdmission from student where student.entry_num=New.entry_num))
THEN raise exception 'batch advisor who is updating is not advisor of student';
end if;
execute format('insert into DeanTicketInfo values(%L,%L,%L,%L,%L,%L)',New.entry_num,New.sem,New.Course_id,New.facultyPermission,New.BatchAdvisorPermission,NULL);
RETURN NEW;
END;
$$;

CREATE TRIGGER to_dean_ticket
After UPDATE
ON BatchAdvisorTicketinfo
FOR EACH ROW
EXECUTE PROCEDURE move_to_dean_ticket();