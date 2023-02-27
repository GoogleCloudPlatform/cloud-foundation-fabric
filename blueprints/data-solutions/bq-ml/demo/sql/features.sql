CREATE view if not exists `{project_id}.{dataset}.ecommerce_abt` as

with abt as (
  SELECT user_id, session_id, city, postal_code, browser,traffic_source, min(created_at) as session_starting_ts,  sum(case when event_type = 'purchase' then 1 else 0 end) has_purchased
  FROM `bigquery-public-data.thelook_ecommerce.events` 
  group by user_id, session_id, city, postal_code, browser, traffic_source
), previous_orders as (
select user_id, array_agg (struct(created_at as order_creations_ts, o.order_id, o.status, oi.order_cost )) as user_orders
  from `bigquery-public-data.thelook_ecommerce.orders`  o
    join (select order_id, sum(sale_price) order_cost 
          from `bigquery-public-data.thelook_ecommerce.order_items` group by 1) oi
              on o.order_id = oi.order_id
          group by 1
)
select abt.*, case when extract(DAYOFWEEK from session_starting_ts) in (1,7) then 'WEEKEND' else 'WEEKDAY' end as day_of_week, extract(hour from session_starting_ts) hour_of_day
  , (select count(distinct uo.order_id) from unnest(user_orders) uo where uo.order_creations_ts < session_starting_ts and status in ('Shipped', 'Complete', 'Processing')  ) as number_of_successful_orders
  , IFNULL((select sum(distinct uo.order_cost) from unnest(user_orders) uo where uo.order_creations_ts < session_starting_ts and status in ('Shipped', 'Complete', 'Processing') ), 0) as sum_previous_orders
  , (select count(distinct uo.order_id) from unnest(user_orders) uo where uo.order_creations_ts < session_starting_ts and status in ('Cancelled', 'Returned')  ) as number_of_unsuccessful_orders
from abt 
  left join previous_orders pso 
    on abt.user_id = pso.user_id