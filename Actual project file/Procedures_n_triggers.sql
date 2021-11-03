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


