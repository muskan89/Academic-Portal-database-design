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


