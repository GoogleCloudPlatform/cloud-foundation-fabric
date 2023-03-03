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
