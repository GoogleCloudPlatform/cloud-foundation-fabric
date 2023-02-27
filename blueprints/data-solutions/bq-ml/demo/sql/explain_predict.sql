select *
from ML.EXPLAIN_PREDICT(MODEL `{project-id}.{dataset}.{model-name}`,
  (select * except (session_id, session_starting_ts, user_id, has_purchased) 
  from `{project-id}.{dataset}.ecommerce_abt`
  where extract(ISOYEAR from session_starting_ts) = 2023
  ),
  STRUCT(5 AS top_k_features, 0.5 as threshold)
)