create or replace model `{project_id}.{dataset}.{model_name}`
OPTIONS(model_type='{model_type}',
        input_label_cols=['has_purchased'],
        enable_global_explain=TRUE,
        MODEL_REGISTRY='VERTEX_AI',
        data_split_method = 'RANDOM',
        data_split_eval_fraction = {split_fraction}
        ) as 
select * except (session_id, session_starting_ts, user_id) 
from `{project_id}.{dataset}.ecommerce_abt_table`
where extract(ISOYEAR from session_starting_ts) = 2022