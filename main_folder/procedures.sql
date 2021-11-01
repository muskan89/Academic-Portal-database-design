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

CREATE or Replace FUNCTION RegisterCourse(_entry_num varchar(255),_Course_id varchar(255),_credit dec(10,2), _Sec_id int,_yearOfAdmission int,_semester int)
  RETURNS void AS
  $BODY$
      BEGIN
        INSERT INTO isGoingToTake(entry_num,Course_id,credit,Sec_id,yearOfAdmission,semester)
        VALUES(_entry_num,_Course_id,_credit, _Sec_id,_yearOfAdmission,_semester);
      END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

--to call it use this but ensure foreign key data is already present in the respective tables
select * from RegisterCourse('2019csb1100','CS301',4,1,2019,5);
--RegisterCourse procedure done



CREATE OR REPLACE FUNCTION uploadTimeSlot()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
COPY TimeSlot(Course_id, duration, startingtime, endingtime,day)
FROM 'D:\5th sem\CS301(DBMS)\project_collections\DBMS-project1\timeslot.csv'
DELIMITER ','
CSV HEADER;
END;
$$;

--to call it use this but ensure foreign key data is already present in the respective tables
select * from uploadTimeSlot();
--uploadTimeSlot procedure done



CREATE OR REPLACE FUNCTION uploadGrades()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
COPY historyOfStudent(entry_num, sem, Course_id, grade, credit, department, yearOfAdmission)
FROM 'D:\5th sem\CS301(DBMS)\project_collections\DBMS-project1\historyofstudent.csv'
DELIMITER ','
CSV HEADER;
END;
$$;

--to call it use this but ensure foreign key data is already present in the respective tables
 select * from uploadGrades();
--uploadGrades procedure done


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

for see in (select historyOfStudent.grade,historyOfStudent.credit from historyOfStudent where historyOfStudent.entry_num=_entry_num)loop
multi := (see.grade) * (see.credit);
points := points + multi;
totalCredits := totalCredits + (see.credit);
end loop;

cgpa := (points/totalCredits);

update student
set cg = cgpa
where student.entry_num=_entry_num;

update student
set total_credits = totalCredits
where student.entry_num=_entry_num;


return cgpa;
END;
$$;

--to call it use this but ensure foreign key data is already present in the respective tables
select * from CalculateCGPA(_entry_num);
--CalculateCGPA procedure done





--trigger to check if the course, student going to insert is fulfilling the cg constraint or not
CREATE OR REPLACE FUNCTION cg_constraint_checking()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
cgpa dec(10,2) := 0;
BEGIN
    cgpa := (select Student.cg from Student where Student.entry_num=New.entry_num);
    if(cgpa < (select CourseOfferings.cgConstraint from CourseOfferings where CourseOfferings.Course_id=New.Course_id))
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

--trigger to check if the course student going to insert is fulfilling pre-requisites or not
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
        then raise exception 'student has not fulfilled pre-requisites of the course';
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


----------------------------------------------------------------------------------------

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
----------------------------------------------------------------------------------------------------
--testing pending



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

-----------------------------------------------------------------------------------------


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
then raise exception 'this course LTPSC does not matches in courseofferings and coursecatalogue';
end if;
RETURN NEW;
END;
$$;

CREATE TRIGGER LTPSC_checker
Before INSERT
ON CourseOfferings
FOR EACH ROW
EXECUTE PROCEDURE LTPSC_same_or_not();