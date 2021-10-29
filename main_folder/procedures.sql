CREATE or Replace FUNCTION OfferCourse(_Course_id varchar(255),_dept_name varchar(255),_semester int,_credit int,_Instructor_id int,_LTPSC varchar(255),_cgConstraint dec(10,2))
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








  CREATE or Replace FUNCTION RegisterCourse(_entry_num varchar(255),_Course_id varchar(255),_credit int, _Sec_id int,_yearOfAdmission int,_semester int)
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