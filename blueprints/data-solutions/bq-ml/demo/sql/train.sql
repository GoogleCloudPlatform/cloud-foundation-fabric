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

CREATE OR REPLACE MODEL `{project_id}.{dataset}.{model_name}`
OPTIONS(MODEL_TYPE='{model_type}',
        INPUT_LABEL_COLS=['has_purchased'],
        ENABLE_GLOBAL_EXPLAIN=TRUE,
        MODEL_REGISTRY='VERTEX_AI',
        DATA_SPLIT_METHOD = 'RANDOM',
        DATA_SPLIT_EVAL_FRACTION = {split_fraction}
        ) AS 
SELECT  * EXCEPT (session_id, session_starting_ts, user_id) 
FROM    `{project_id}.{dataset}.ecommerce_abt_table`
WHERE   extract(ISOYEAR FROM session_starting_ts) = 2022