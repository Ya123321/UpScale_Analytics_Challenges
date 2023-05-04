select * from paying_method
select * from players
select * from game_sessions
select * from session_details
select * from games

---1
select player_id,

email_address,
credit_card_type,
credit_card_number 
from(
select 
p.player_id,
p.email_address,
p_m.credit_card_type,
p_m.credit_card_number,
payment_method_rank=row_number() over (partition by p.player_id order by case credit_card_type
                                                               when 'americanexpreess'then 1
															   when'americancard' then 2
															   when  'visa' then 3
															   else null end)
 from players p left join paying_method p_m on p.player_id=p_m.player_id)
 as RANKED_PAYMENTS
 where payment_method_rank=1


 --2
select p.gender, p.age_group,
sum(case when p_m.credit_card_type='americanexpress' then 1 else 0 end) as americanexpress,
sum(case when p_m.credit_card_type='mastercard' then 1 else 0 end)  as mastercard,
sum(case when p_m.credit_card_type='visa' then 1 else 0 end) as visa
from players p join paying_method p_m on p.player_id=p_m.player_id
group by  p.gender, p.age_group
order by 1,2

--3
select g.game_name, count(g_s.session_id) as num_session,
dense_rank() over (order by count(g_s.session_id) desc) as num_sessions_rank
from game_sessions g_s join games g on g_s.game_id=g.id
group by g.game_name
order by count(g_s.session_id) desc

--4
select g.game_name, sum(datediff(MINUTE,g_s.session_begin_date,g_s.session_end_date)) as total_playing_minutes,
dense_rank() over (order by sum(datediff(MINUTE,g_s.session_begin_date,g_s.session_end_date)) desc) as total_playing_minutes_rank
from games g join game_sessions g_s on g.id=g_s.game_id
group by g.game_name
order by 2 desc

--5
select 
age_group,
game_name,
total_playing_minutes 
from(
select p.age_group, g.game_name, 
sum(datediff(MINUTE,g_s.session_begin_date,g_s.session_end_date)) as total_playing_minutes,
total_playing_minutes_rank = 
dense_rank() over (partition by p.age_group order by sum(datediff(MINUTE,g_s.session_begin_date,g_s.session_end_date)) desc) 
from games g 
left join game_sessions g_s on g.id=g_s.game_id 
left join players p on g_s.player_id=p.player_id
group by g.game_name, p.age_group
) as rank where total_playing_minutes_rank=1

--6
with balance as(
select 
g_s.session_id,
s_d.action_id,
s_d.action_type, 
case when s_d.action_type='loss' then (-1)*cast(s_d.amount as float) else s_d.amount end as amount
from game_sessions g_s 
left join session_details s_d on g_s.session_id=s_d.session_id)
select session_id,
action_id,
action_type,amount,
sum(amount) over (partition by session_id order by action_id
ROWS between unbounded preceding and current row) as balance from balance 

--7
select sum(case when balance<0 then 1 else 0 end) as total_losses,
       sum(case when balance>0 then 1 else 0 end) as total_gains,
       sum(case when balance=0 then 1 else 0 end) as total_draws
from(
select 
g_s.session_id,
s_d.action_id,
action_type,
amount,
sum(iif(action_type='loss',amount*(-1),amount)) over (partition by s_d.session_id order by s_d.action_id) balance
,rank = dense_rank() over (partition by s_d.session_id order by s_d.action_id desc) 
from game_sessions g_s 
left join session_details s_d on g_s.session_id=s_d.session_id)
as ranked_actuons where rank=1

--8

select gender,age_group,
       sum(case when balance<0 then 1 else 0 end) as total_losses,
       sum(case when balance>0 then 1 else 0 end) as total_gains,
       sum(case when balance=0 then 1 else 0 end) as total_draws
from(
select 
p.gender,p.age_group,
g_s.session_id,
s_d.action_id,
action_type,
amount,
sum(iif(action_type='loss',amount*(-1),amount)) over (partition by s_d.session_id order by s_d.action_id) balance
,rank = dense_rank() over (partition by s_d.session_id order by s_d.action_id desc) 
from game_sessions g_s 
left join session_details s_d on g_s.session_id=s_d.session_id
left join players p on p.player_id=g_s.player_id)
as ranked_actuons where rank=1
group by gender, age_group
order by 1,2


--9
select player_id,sum(balance) as total_gain_loss
from (
select 
g_s.player_id
,sum(iif(action_type='loss',amount*(-1),amount)) over (partition by s_d.session_id order by s_d.action_id) balance
,rank = dense_rank() over (partition by s_d.session_id order by s_d.action_id desc) 
from game_sessions g_s 
left join session_details s_d on g_s.session_id=s_d.session_id)
as ranked_actuons where rank=1
group by player_id
order by 1

--10
select 
sum(case when amount<0 then amount*(-1) end) as house_gains,
sum(case when amount>0 then amount*(-1) end) as house_losses,
sum(case when amount<0 then amount*(-1) end) + sum(case when amount>0 then amount*(-1) end) as overall_gain_loss
from (
select 
g_s.player_id
,sum(iif(action_type='loss',amount*(-1),amount)) over (partition by s_d.session_id order by s_d.action_id) amount
,rank = dense_rank() over (partition by s_d.session_id order by s_d.action_id desc) 
from game_sessions g_s 
left join session_details s_d on g_s.session_id=s_d.session_id)
as ranked_actuons where rank=1

--11
with year_and_quater as(
select distinct year(session_end_date) as year , DATEPART(QUARTER, session_end_date) as quarter, g.session_id,
sum(case when action_type='loss' then (amount)*(-1) else amount end) over (partition by g.session_id) as amount
from session_details s join game_sessions g on s.session_id=g.session_id)

select year,quarter, sum(case when amount<0 then amount*-1 end) as house_gains,
sum(case when amount>0 then amount*-1 end ) as house_losses,
sum(amount*(-1)) as overall_gain_losses
from year_and_quater
group by year,quarter
order by 1,2

--12

with session_balance as (
    SELECT YEAR(SESSION_BEGIN_DATE) AS SessionYear,
        DATEPART(month, session_begin_date) as SessionMonth,
        GSESSIONS.session_id,
        total_balance = SUM(IIF(ACTION_TYPE = 'LOSS', AMOUNT * -1, AMOUNT))
    FROM [dbo].[game_sessions] GSESSIONS
    LEFT JOIN [dbo].[session_details] SDETAILS ON GSESSIONS.session_id = SDETAILS.session_id
    GROUP BY YEAR(SESSION_BEGIN_DATE),
        DATEPART(month, session_begin_date),
        GSESSIONS.session_id
        ),

aggregate_year_month as (
    SELECT SessionYear,
        SessionMonth,
        SUM(case when total_balance < 0 then total_balance * -1 END) as house_gains,
        SUM(case when total_balance > 0 then total_balance * -1 END) as house_losses,
        SUM(total_balance) * -1 as overall_gain_loss
    from session_balance
    group by SessionYear,
         SessionMonth
),

ranked_months as (
    SELECT *,
        'Gain Top-' + cast(row_number () over(order by overall_gain_loss desc) as nvarchar(max)) overall_rank_top,
        row_number () over(order by overall_gain_loss desc) as rank_top,
        'Loss Top-' + cast(row_number () over(order by overall_gain_loss asc) as nvarchar(max)) as overall_rank_bottom,
        row_number () over(order by overall_gain_loss asc) as rank_bottom
    FROM aggregate_year_month
   )

SELECT * 
FROM (
    SELECT sessionYear,
        SessionMonth,
        house_gains,
        house_losses,
        overall_gain_loss,
        overall_rank_top
    from ranked_months
    where rank_top <= 3
    union 
    SELECT sessionYear,
       SessionMonth,
        house_gains,
        house_losses,
        overall_gain_loss,
        overall_rank_bottom
    from ranked_months
    where rank_bottom <= 3
) as t
order by 6
