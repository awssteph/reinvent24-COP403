--CUR Legacy
SELECT 
  line_item_usage_account_id, 
  product_product_name, 
  ROUND(SUM(line_item_unblended_cost),2) AS cost
FROM 
  cur
WHERE 
  month = '8' 
  AND year ='2024'
GROUP BY 
  line_item_usage_account_id, 
  product_product_name
ORDER BY 
  cost DESC

--CUR 2.0
SELECT 
  line_item_usage_account_name, -- let's use account name
  product['product_name'] AS product_product_name, -- pull this value from the product map
  ROUND(SUM(line_item_unblended_cost),2) AS cost 
FROM 
  cur2
WHERE 
  billing_period = '2024-08' -- change year+month to billing_period
GROUP BY 
  line_item_usage_account_name, -- fix account name
  product['product_name'] -- fix product column name
ORDER BY 
  cost DESC

--FOCUS
SELECT
  subaccountname, 
  servicename,
  ROUND(SUM(BilledCost),2) AS cost
FROM 
  "cid_data_export"."focus"
WHERE 
  billing_period = '2024-08'
GROUP BY 
  subaccountname, 
  servicename
ORDER BY 
  cost DESC
