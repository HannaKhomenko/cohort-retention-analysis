with users_raw_clean as (
select
	user_id,
	promo_signup_flag,
	regexp_replace(trim(split_part(trim(signup_datetime),' ', 1)), '[-./]','-','g') as clean_date_str
from project.cohort_users_raw
),
users_data as (
select
	user_id,
	promo_signup_flag,
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
	regexp_replace(trim(split_part(trim(event_datetime ),' ', 1)), '[-./]','-','g') as clean_event_date
from project.cohort_events_raw
),
events_data as (
select
	event_id,
	user_id,
	event_type,	
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
	date_trunc('month', u.signup_date)::date as cohort_month,
	u.promo_signup_flag,
	date_trunc('month', e.event_date)::date as activity_month,
	(extract('year' from e.event_date)-extract('year' from u.signup_date))*12 + 
		(extract('month' from e.event_date)-extract('month' from u.signup_date)) as month_offset
from users_data as u
join events_data as e on u.user_id = e.user_id
where u.signup_date is not null
	and e.event_date is not null
	and e.event_type is not null
	and e.event_type <> '' 
	and e.event_type <> 'test_event'
)
select 
	promo_signup_flag,
	cohort_month,
	month_offset,
	count (distinct user_id) as users_total
from users_activity
where activity_month between '2025-01-01' and '2025-06-01'
group by promo_signup_flag, cohort_month, month_offset
order by promo_signup_flag, cohort_month, month_offset;
