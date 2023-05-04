select * from ads
select * from advertisers
select * from conversions
select * from clicks

--Basic Analysis
--List the first 10 ads, sort the results by their names in an ascending order
select top 10 ad_name from ads order by 1

--Display all clicks made in Sweden using Chrome browser
select click_id from clicks where browser='Chrome' and country='Sweden' 

--List all conversions made in 2017
select * from conversions where year(conversion_date)=2017

--Advanced Analysis
--Using Clicks table, what is the most frequently used browser ?
select top 1 browser, count(browser) from clicks group by browser order by 2 desc

--Which ad has the highest amount of clicks ? display the distribution of clicks for each country
select ad_name,country, count(*) 
from ads a join clicks c on a.ad_id=c.ad_id where a.ad_id=
(select top 1 ad_id from clicks 
group by ad_id
order by count(click_id) desc)
group by ad_name, country
order by 3 desc

--Conversion rate is calculated using the following formula 
-- : SUM(total_conversions) \ SUM(total_clicks) * 100. Find out the conversion rate for the ad with the highest amount of clicks
select ad_name, round(cast(count(co.conversion_id)as float)/cast(count(c.click_id) as float)*100,2) as [Conversion rate]
from ads a join 
clicks c on a.ad_id=c.ad_id left join conversions co on co.click_id=c.click_id 
where a.ad_id=
(select top 1 ad_id from clicks 
group by ad_id
order by count(click_id) desc)
group by ad_name


--Display the top-5 ads, having the highest conversion rate
select top 5 ad_name, round(cast(count(co.conversion_id)as float)/cast(count(c.click_id) as float)*100,2) as [Conversion rate]
from ads a join 
clicks c on a.ad_id=c.ad_id left join conversions co on co.click_id=c.click_id 
group by ad_name
order by 2 desc

--Is there any conversion rate differance between the browsers?
select c.browser, round(cast(count(co.conversion_id)as float)/cast(count(c.click_id) as float)*100,2) as [Conversion rate]
from ads a join 
clicks c on a.ad_id=c.ad_id left join conversions co on co.click_id=c.click_id 
group by c.browser
order by 2 desc

--In average, for each ad, how many days it took for a click to become a conversion?
select ad_name, avg(datediff(day,c.click_date,co.conversion_date)) as average
from clicks c join conversions co on c.click_id=co.click_id
join ads a on a.ad_id=c.ad_id
group by ad_name

--What is the most frequently used browser in Brazil
select top 1 browser, count(*) from clicks where country='Brazil' group by browser order by 2 desc
 
