with users_raw_clean as (
select
	user_id,
	signup_source,
	signup_device,
	UPPER(country) as country,
	case 
		when promo_signup_flag = 1 then 'Promo'
		else 'Organic'
	end as signup_type,
	regexp_replace(trim(split_part(trim(signup_datetime),' ', 1)), '[-./]','-','g') as clean_date_str
from project.cohort_users_raw
),
users_data as (
select
	user_id,
	signup_type,
	signup_source,
	signup_device,
	country,
	case 
		when clean_date_str ~ '^\d{1,2}[-./]\d{1,2}[-./]\d{4}$' then to_date(clean_date_str, 'DD.MM.YYYY')			
		when clean_date_str ~ '^\d{1,2}[-./]\d{1,2}[-./]\d{2}$' then to_date(clean_date_str, 'DD.MM.YY')
		else NULL
	end	as signup_date
from users_raw_clean
),
events_raw_clean as (
select
	event_id,
	user_id,
	event_type,
	regexp_replace(trim(split_part(trim(event_datetime ),' ', 1)), '[-./]','-','g') as clean_event_date,
	sum(revenue) as total_revenue
from project.cohort_events_raw
group by event_id, user_id, event_type, clean_event_date
),
events_data as (
select
	event_id,
	user_id,
	event_type,	
	total_revenue,
	case 
		when clean_event_date ~ '^\d{1,2}[-./]\d{1,2}[-./]\d{4}$' then to_date(clean_event_date, 'DD.MM.YYYY')			
		when clean_event_date ~ '^\d{1,2}[-./]\d{1,2}[-./]\d{2}$' then to_date(clean_event_date, 'DD.MM.YY')
		else NULL
	end	as event_date
from events_raw_clean
),
users_activity as (
select
	u.user_id,
	u.signup_date,
	e.event_date,
	u.signup_type,
	u.signup_source,
	u.signup_device,
	u.country,
	e.event_type,
	e.total_revenue as total_revenue
from users_data as u
join events_data as e on u.user_id = e.user_id
where u.signup_date is not null
	and e.event_date is not null
	and e.event_type is not null
	and e.event_type <> '' 
	and e.event_type <> 'test_event'
)
select 
	user_id,
	signup_date,
	signup_type,
	event_date,
	signup_source,
	signup_device,
	country,
	event_type,
	sum(total_revenue) as total_revenue
from users_activity
group by 1, 2, 3, 4, 5, 6, 7, 8 
order by signup_type, signup_date, user_id, event_date, event_type;
