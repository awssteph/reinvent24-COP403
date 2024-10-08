--CUR Legacy

select line_item_usage_account_id, product_product_name, round(sum(line_item_unblended_cost),2) as cost
from cur
where month = '8' and year ='2024'
group by line_item_usage_account_id, product_product_name
order by cost DESC

--CUR 2.0
select line_item_usage_account_name, product['product_name'] as product_name, round(sum(line_item_unblended_cost),2) as cost 
from cur2
where SPLIT(billing_period,'-')[2] = '08'
group by product['product_name'], line_item_usage_account_name 
order by cost DESC


--FOCUS
SELECT
  ProviderName,
  ServiceName,
  round(SUM(BilledCost),2) AS TotalBilledCost
FROM "cid_data_export"."focus"
where SPLIT(billing_period,'-')[2] = '08'
GROUP BY
  ProviderName,
  ServiceName
ORDER BY TotalBilledCost DESC
