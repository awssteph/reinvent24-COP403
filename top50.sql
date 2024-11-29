-- PART 1
-- let's find the daily unblended cost per resource from 3 days ago

SELECT 
  line_item_resource_id,
  line_item_usage_account_name,
  product [ 'product_name' ] AS "product_product_name",
  DATE_FORMAT(line_item_usage_start_date, '%Y-%m-%d') AS day_line_item_usage_start_date,
  SUM(line_item_unblended_cost) AS cost
FROM 
  "cid_data_export"."cur2"
WHERE 
  line_item_resource_id <> '' -- we don't want usage that doesn't have a resourceid
  AND line_item_usage_start_date = CURRENT_DATE - INTERVAL '3' DAY -- 3 days ago from today
GROUP BY 1,2,3,4

------------------------------------------------------------------------------------------

-- PART 2
-- let's copy and paste PART 1, but change the date filter to two days ago

SELECT 
  line_item_resource_id,
  line_item_usage_account_name,
  product [ 'product_name' ] AS "product_product_name",
  DATE_FORMAT(line_item_usage_start_date, '%Y-%m-%d') AS day_line_item_usage_start_date,
  SUM(line_item_unblended_cost) AS cost
FROM 
  "cid_data_export"."cur2"
WHERE 
  line_item_resource_id <> ''
  AND line_item_usage_start_date = CURRENT_DATE - INTERVAL '2' DAY -- changed the interval here
GROUP BY 1,2,3,4

------------------------------------------------------------------------------------------

-- PART 3
-- wrap these queries with WITH in prep to join them up

WITH three_days_ago AS (
  SELECT 
    line_item_resource_id,
    line_item_usage_account_name,
    product [ 'product_name' ] AS "product_product_name",
    DATE_FORMAT(line_item_usage_start_date, '%Y-%m-%d') AS day_line_item_usage_start_date,
    sum(line_item_unblended_cost) AS cost
  FROM 
    "cid_data_export"."cur2"
  WHERE 
    line_item_resource_id <> ''
    AND line_item_usage_start_date = CURRENT_DATE - INTERVAL '3' DAY
  GROUP BY 1,2,3,4
),

two_days_ago AS (
  SELECT 
    line_item_resource_id,
    line_item_usage_account_name,
    product [ 'product_name' ] AS "product_product_name",
    DATE_FORMAT(line_item_usage_start_date, '%Y-%m-%d') AS day_line_item_usage_start_date,
    SUM(line_item_unblended_cost) AS cost
  FROM 
    "cid_data_export"."cur2"
  WHERE 
    line_item_resource_id <> ''
    AND line_item_usage_start_date = CURRENT_DATE - INTERVAL '2' DAY
  GROUP BY 1,2,3,4
)

------------------------------------------------------------------------------------------

-- PART 4
-- Writing the final query, where we join the two result sets, calculate the cost delta and percent delta

WITH three_days_ago AS (
  SELECT 
    line_item_resource_id,
    line_item_usage_account_name,
    product [ 'product_name' ] AS "product_product_name",
    DATE_FORMAT(line_item_usage_start_date, '%Y-%m-%d') AS day_line_item_usage_start_date,
    SUM(line_item_unblended_cost) AS cost
  FROM 
    "cid_data_export"."cur2"
  WHERE 
    line_item_resource_id <> ''
    AND line_item_usage_start_date = CURRENT_DATE - INTERVAL '3' DAY
  GROUP BY 1,2,3,4
),

two_days_ago AS (
  SELECT 
    line_item_resource_id,
    line_item_usage_account_name,
    product [ 'product_name' ] AS "product_product_name",
    DATE_FORMAT(line_item_usage_start_date, '%Y-%m-%d') AS day_line_item_usage_start_date,
    SUM(line_item_unblended_cost) AS cost
  FROM 
    "cid_data_export"."cur2"
  WHERE 
    line_item_resource_id <> ''
    AND line_item_usage_start_date = CURRENT_DATE - INTERVAL '2' DAY
  GROUP BY 1,2,3,4
)

SELECT 
  three_days_ago.*,
  two_days_ago.*,
  (two_days_ago.cost - three_days_ago.cost) AS cost_delta,
  (
    (two_days_ago.cost - three_days_ago.cost) / three_days_ago.cost * 100
  ) AS percent_delta
FROM 
  three_days_ago
  FULL OUTER JOIN two_days_ago ON three_days_ago.line_item_resource_id = two_days_ago.line_item_resource_id
ORDER BY 
  cost_delta DESC,
  percent_delta DESC
LIMIT 50;

------------------------------------------------------------------------------------------
