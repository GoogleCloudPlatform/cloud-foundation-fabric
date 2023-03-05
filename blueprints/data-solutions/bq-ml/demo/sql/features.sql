/*
* Copyright 2023 Google LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License. 
*/

CREATE VIEW if NOT EXISTS `{project_id}.{dataset}.ecommerce_abt` AS
WITH abt AS (
  SELECT   user_id,
           session_id,
           city,
           postal_code,
           browser,
           traffic_source,
           min(created_at) AS session_starting_ts,
           sum(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) has_purchased
  FROM     `bigquery-public-data.thelook_ecommerce.events` 
  GROUP BY user_id,
           session_id,
           city,
           postal_code,
           browser,
           traffic_source
), previous_orders AS (
  SELECT   user_id,
           array_agg (struct(created_at AS order_creations_ts,
                             o.order_id,
                             o.status,
                             oi.order_cost)) as user_orders
  FROM     `bigquery-public-data.thelook_ecommerce.orders`  o
  JOIN (SELECT  order_id,
                sum(sale_price) order_cost 
        FROM    `bigquery-public-data.thelook_ecommerce.order_items`
        GROUP BY 1) oi
  ON o.order_id = oi.order_id
  GROUP BY 1
)
SELECT    abt.*,
          CASE WHEN extract(DAYOFWEEK FROM session_starting_ts) IN (1,7)
          THEN 'WEEKEND' 
          ELSE 'WEEKDAY'
          END AS day_of_week,
          extract(HOUR FROM session_starting_ts) hour_of_day,
          (SELECT count(DISTINCT uo.order_id) 
          FROM unnest(user_orders) uo 
          WHERE uo.order_creations_ts < session_starting_ts 
          AND status IN ('Shipped', 'Complete', 'Processing')) AS number_of_successful_orders,
          IFNULL((SELECT sum(DISTINCT uo.order_cost) 
                  FROM   unnest(user_orders) uo 
                  WHERE  uo.order_creations_ts < session_starting_ts 
                  AND    status IN ('Shipped', 'Complete', 'Processing')), 0) AS sum_previous_orders,
          (SELECT count(DISTINCT uo.order_id) 
          FROM   unnest(user_orders) uo 
          WHERE  uo.order_creations_ts < session_starting_ts 
          AND    status IN ('Cancelled', 'Returned')) AS number_of_unsuccessful_orders
FROM      abt 
LEFT JOIN previous_orders pso 
ON        abt.user_id = pso.user_id
