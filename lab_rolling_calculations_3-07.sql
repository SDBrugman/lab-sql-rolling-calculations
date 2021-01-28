USE sakila;

-- 1-- 
-- Step 1: Get the account_id, date, year, month and month_number for every rental activity.
drop view if exists rental_activity; 
create or replace view rental_activity as
select customer_id, rental_id, convert(rental_date, date) as activity_date,
date_format(convert(rental_date,date), '%M') as activity_month,
date_format(convert(rental_date,date), '%m') as activity_month_number,
date_format(convert(rental_date,date), '%Y') as activity_year
from rental;

select * from rental_activity;

-- step 2: Check rental per month by distinct customer
select activity_year, activity_month, count(distinct customer_id) as active_customer from rental_activity
group by activity_month_number, activity_year
order by activity_year, activity_month_number asc;

-- Step 3: Storing the results on a view for later use.
drop view if exists monthly_active_customers;
create view monthly_active_customers as
select activity_year, activity_month, activity_month_number, count(distinct customer_id) as active_customer from rental_activity
group by activity_month, activity_year
order by activity_year, activity_month_number asc;

-- Check table
select * from monthly_active_customers;

-- 2 --
-- Active users in the previous month
select activity_year, activity_month, active_customer, 
   lag(active_customer,1) over (order by activity_year, activity_month_number) as active_users_last_month
from monthly_active_customers;

-- 3 --
-- Percentage change in the number of active customers
with cte_activity as (
  select activity_year, activity_month, active_customer, lag(active_customer,1) over (order by activity_year, activity_month_number) as active_users_last_month
  from monthly_active_customers
)
select activity_year, activity_month, active_customer, active_users_last_month, 
round(((active_customer - active_users_last_month) / active_customer) * 100, 2) AS diff_in_percentage 
from cte_activity
where active_users_last_month is not null;

-- 4 --
-- Retained customers every month

select distinct customer_id, activity_year, activity_month, activity_month_number from rental_activity;
select active_customer, activity_year, activity_month, activity_month_number from monthly_active_customers;

drop view if exists distinct_customers;
create view distinct_customers as
select distinct customer_id, activity_year, activity_month, activity_month_number from rental_activity;

Select * from distinct_customers;

select dc.activity_year, dc.activity_month, dc.activity_month_number, count(dc.customer_id) as retained_customers
from distinct_customers as dc
	join distinct_customers as dc2 on dc.customer_id = dc2.customer_id 
	and dc2.activity_month_number = dc.activity_month_number + 1 
group by dc.activity_year, dc.activity_month_number
order by dc.activity_year, dc.activity_month_number;

