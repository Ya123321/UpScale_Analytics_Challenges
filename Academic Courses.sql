select * from courses
select * from classes
select * from lecturers
select * from students 

--- Basic Analysis
--How many lecturers are living in Liverpool?
select count(*) from lecturers where city like'%Liverpool%'

--List all course titles containing the words “cognition” or “cognitive”
select * from courses where course_title like '%cognition%' or  course_title like '%cognitive%'



--How many classes, and how many students were taught by each lecturer
select distinct l.first_name, l.last_name, 
sum(class_id) over(partition by l.id) number_of_classes,
sum(student_id) over(partition by l.id) number_of_students
 from lecturers l left join classes c on l.id=c.lecturer_id
left join students s on s.id=c.student_id
 
--List the female students that are living in london
select * from students s where gender='female' and city='London' 


--Advanced Analysis
--Restrict your last query only for those who went through the course : “Topics in Applied Psychology”
select * from students s join classes c on c.student_id=s.id
join courses co on co.course_id=c.course_id where gender='female' and city='London' and 
course_title='Topics in Applied Psychology'

--How many students, in average, are being taught by each lecturer
select l.first_name,l.last_name, avg(count(s.id)) over (partition by l.id) 'number of students in average'
from students s
join classes c on s.id=c.student_id
join lecturers l on l.id=c.lecturer_id
group by l.first_name,l.last_name,l.id


--List the students who were tought by Mr Jacob Willshear
select * from students s join classes c on s.id=c.student_id 
join lecturers l on c.lecturer_id=l.id where l.first_name='Jacob' and l.last_name='Willshear'

--List all lecturers who are teaching the same courses as Mr Jacob Willshear
select distinct l.first_name,l.last_name from lecturers l
join classes c on l.id=c.lecturer_id where c.course_id = any(
select distinct course_id from lecturers l join classes c on l.id=c.lecturer_id
where l.first_name='Jacob' and l.last_name='Willshear') 
and l.first_name <>'Jacob' and l.last_name<>'Willshear'


--List all lecturers who are teaching “Topics in Perception & Cognition”
select distinct l.first_name,l.last_name from lecturers l
join classes c on l.id=c.lecturer_id join courses co on co.course_id=c.course_id
where co.course_title='Topics in Perception & Cognition'

--Display the lecturer whose students got the highest average score in ‘Topics in Perception & Cognition’
select top 1 l.first_name,l.last_name 
from lecturers l
join classes c on l.id=c.lecturer_id 
join courses co on co.course_id=c.course_id
where co.course_title='Topics in Perception & Cognition'
group by l.first_name,l.last_name 
order by avg(cast(COALESCE(grade_test_c,grade_test_b,grade_test_a) as int)) desc


--How many students have succeeded to improve their final grade
select count(distinct student_id) from students s join classes c 
on s.id=c.student_id join courses co on c.course_id=co.course_id
join lecturers l on l.id=c.lecturer_id
where c.grade_test_b > c.grade_test_a AND c.grade_test_c IS NULL
or c.grade_test_c > c.grade_test_b AND c.grade_test_c > c.grade_test_a

--How many courses in average were taken by each student
with number_of_courses as(
select student_id, count(course_id) as num from students s join classes c on
s.id=c.student_id
group by student_id)
select avg(num) from number_of_courses


--Display how many students and how many lecturers, are coming from outside of London
with s_and_l as(
select *, 'student' as type from students
union
select *, 'lectuers' as type from lecturers)
select count(*) number , type 'student/lectuers' from s_and_l
where city != 'London'
group by type

--For each course, display the top 2 students (by their final grade)
select course_title, first_name,last_name
from(
select course_title, s.first_name,s.last_name
, rank = dense_rank () over (partition by co.course_id order by cast(COALESCE(grade_test_c,grade_test_b,grade_test_a) as int) desc)  
from classes c join courses co on c.course_id=co.course_id 
join students s on s.id=c.student_id) as ranked
where rank<3


 