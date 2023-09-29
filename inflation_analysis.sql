-- Inflation analysis from 1990 to present (yearly data)
-- Project contains 4 table
-- 1. Inflation table that shows the country_name,country_code,year,inflation_rate of each country 
-- 2. Exports table that shows the country_name, country_code,year, and the exports (% of gdp)
-- 3. Gdp growth table that show the country_name, country_code, year and gdp growth percentage
-- 4. Savings table that shows the country_name,country_code,year and the household_saving(% of gdp)

create database project;
use project;
create table inflation (Country varchar(50) , Country_code varchar(5), 
recorded_year year, inflation_Rate float  null);
create table exports (Country_name varchar(50),Country_code varchar(5),
recorded_year year ,exports float null);
create table gdp_growth (country_name varchar(50),Country_code varchar(5),
recorded_year year ,growth_rate float null);
create table savings (Country_name varchar(50),Country_code varchar(5),
recorded_year year ,household_Savings float null);

-- imported data through command line as the data is very big


--  The greatest fluctuation in inflation rates for each country between 1990 and 2023

select country,round(max(rate),2) as highest_change_in_inflation from (
select country,lag(inflation_rate) over(partition by country order by recorded_year),
(inflation_Rate/lag(inflation_rate) over(partition by country order by recorded_year))*100 as rate from inflation) as a
group by country;


--  Inflation comparison: 2017-2021 to 2022  
with cte as(select country,round(avg(inflation_rate),2) as avg_inflation from inflation
			where   recorded_year between 2017 and 2021
			group by country),
cte2 as(select country,inflation_rate 
		from inflation 
		where recorded_year='2022' 
		group by country),
cte3 as(select cte.country,cte.avg_inflation,cte2.inflation_rate from cte2
		join cte
		on
		cte.country=cte2.country)

select country,avg_inflation,inflation_rate,
round((inflation_rate-avg_inflation)/avg_inflation,2)*100 as percent_increase_in_inflation
from cte3 
order by 4 desc;


-- Maximum consecutive years of inflation decline in each country

with inflation_data as(select country,recorded_year,inflation_rate,
                        lag(inflation_rate) over(partition by country order by recorded_year) as prev_inflation_rate
                        from inflation),
consecutive_falls as(select country,recorded_year,inflation_rate,
					(case when inflation_rate<prev_inflation_rate  then 1 else 0 end) as falling
                    from inflation_data),
tb1 as( select *,
        row_number() over(partition by country,falling order by recorded_year),
        recorded_year-(row_number() over(partition by country,falling order by recorded_year)) as group_date
        from consecutive_falls)
select country,max(cnt) as max_year_falls from(
select country ,group_Date,count(group_date) as cnt from tb1
where falling=1
group by country,group_date) as tb1
group by country;


-- Impact on exports during the lowest and highest inflation  in each country

with min_inf as(select country, recorded_year, inflation_rate as min_inflation 
				from inflation
				where (country,inflation_rate) in (select country,min(inflation_rate) from inflation
						group by country)),

exp_min_inf as( select country_name,round(exports,2) as export_percent_of_gdp
				from exports 
				where (country_name,recorded_year)in (Select country, recorded_year from min_inf)),

max_inf as(select country, recorded_year, inflation_rate as max_inflation 
			from inflation
			where (country,inflation_rate) in (select country,max(inflation_rate) from inflation
					group by country)),

exp_max_inf as( select country_name,round(exports,2) as export_percent_of_gdp
				from exports 
                where (country_name,recorded_year)in (Select country, recorded_year from max_inf))
                
select distinct min_inf.country,min_inf.min_inflation,max_inf.max_inflation,
exp_min_inf.export_percent_of_gdp as export_during_low_inflation,
exp_max_inf.export_percent_of_gdp as export_during_high_inflation,
round(max_inf.max_inflation-min_inf.min_inflation,2) as change_in_inflation_rate,
round(((exp_max_inf.export_percent_of_gdp-exp_min_inf.export_percent_of_gdp) /exp_min_inf.export_percent_of_gdp)*100,2) as change_in_exports
from exp_min_inf
join 
min_inf
on min_inf.country=exp_min_inf.country_name
join max_inf
on max_inf.country=min_inf.country
join exp_max_inf 
on exp_max_inf.country_name=min_inf.country;


-- GDP growth during high inflation

with cte as(select country, recorded_year, inflation_rate as max_inflation 
			from inflation
			where (country,inflation_rate) in (select country,max(inflation_rate) from inflation
												group by country)),
cte2 as(select country_name,growth_Rate from gdp_growth
		where (country_name, recorded_year) in(Select country,recorded_year from cte))

select cte.*,growth_rate as gdp_growth from cte
join cte2
on cte.country=cte2.country_name;


-- How many times a country's inflation has been lower than the inflation in previous year

with inflation_data as(select country,recorded_year,inflation_rate,
                        lag(inflation_rate) over(partition by country order by recorded_year) as prev_inflation_rate
                        from inflation),
consecutive_falls as(select country,recorded_year,inflation_rate,
					(case when inflation_rate<prev_inflation_rate  then 1 else 0 end) as falling
                    from inflation_data)

select country,max(consecutive_falls_count) as consecutive_falls from(
select country,recorded_year,
sum(falling) over(partition by country order by recorded_year) as consecutive_falls_count
from consecutive_falls) as max_counts
group by country;



-- In which year did most countries experience the highest inflation between 1990 and 2023
select recorded_year,count(*),group_concat(Country) from (
select country,recorded_year,inflation_rate from inflation 
where (country,inflation_Rate) in(select country, max(inflation_rate) from inflation
									group by country)) as tb1
group by recorded_year
order by 2 desc; 

 
  







