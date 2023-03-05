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

SELECT  *
FROM    ML.EXPLAIN_PREDICT(MODEL `{project-id}.{dataset}.{model-name}`,
        (SELECT   * EXCEPT (session_id, session_starting_ts, user_id, has_purchased) 
         FROM `{project-id}.{dataset}.ecommerce_abt`
         WHERE extract(ISOYEAR FROM session_starting_ts) = 2023),
        STRUCT(5 AS top_k_features, 0.5 AS threshold))
LIMIT   100
