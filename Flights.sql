select * from flights
SELECT * from airports
select * from airlines

---Basic Analysis
--1
select count(distinct(a.iata_code))
from airlines a
--2
select top 1 a.state, count(*)
from airports a group by a.state order by count(*) desc

--3
select top 1 f.cancel_reason, count(f.cancel_reason)
from flights f group by f.cancel_reason order by count(f.cancel_reason) desc 

-- Advanced Analytics 

--1 How many flights, carried out by “American Airlines Inc.”, flew out of “Los Angeles International Airport” to “Miami International Airport”?
select count(f.flight_id) from flights f join airports a_o on a_o.iata_code=f.origin_airport join airports a_d on f.destination_airport=a_d.iata_code
where f.airline =(select iata_code from airlines where airline='American Airlines Inc.')
and a_o.airport like '%Los Angeles International Airport%' and a_d.airport like '%Miami International Airport%'

--2 How many flights have been carried out by each airline?
select a.airline, count(f.flight_id) from airlines a join flights f on a.iata_code=f.airline group by a.airline order by 1

--3 Which company had the highest amount of delays (in minutes)
select top 1 a.airline from airlines a join flights f on a.iata_code=f.airline group by a.airline order by sum(f.delay_in_minutes) desc

--4 A customer is planning to take a flight from LAX to SFO, based on the data you have regarding delays, which airline will you recommend him to take?
select top 1 a.airline from flights f join airlines a on a.iata_code=f.airline where origin_airport='LAX' and destination_airport='SFO' 
group by a.airline order by sum(f.delay_in_minutes) 

--5 Based on the data you have, if a customer is planing to take a flight, what are the odds it’ll be cancelled?
select cast(cast(sum(case when cancelled=1 then 1 else 0 end)as float)/count(*)*100 as varchar)+'%' from flights

--6 Which aireline company has the highest cancellation rate?
select top 1 a.airline, cast(sum(f.cancelled)as float)/cast(count(f.flight_id)as float)*100 as  cancellation_rate
,dense_rank () over ( order by cast(sum(f.cancelled)as float)/cast(count(f.flight_id)as float)*100 desc) as rank from flights f join airlines a on a.iata_code=f.airline
group by a.airline
order by 2 desc

--7 Which airport had the highest number of cancellations due to security issues?
with security_issues as(
select a_o.airport, sum(case when f.cancel_reason like'%Security%' then 1 else 0 end) as security_issues  from airports a_o join flights f on a_o.iata_code=f.origin_airport 
group by  a_o.airport
UNION
select a_d.airport, sum(case when f.cancel_reason like'%Security%' then 1 else 0 end) as security_issues  from airports a_d join flights f on a_d.iata_code=f.destination_airport 
group by  a_d.airport) 

select top 1  airport from security_issues  order by security_issues desc

--8 Display the number of flights per month
select month(flight_date), count(flight_id) from flights where cancelled = 0 group by month(flight_date)