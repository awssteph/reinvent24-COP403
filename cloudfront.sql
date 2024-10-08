WITH cloudfront_requests as (
SELECT 
  DATE_FORMAT(date,'%Y-%m-01') AS month,
  CASE 
    WHEN x_edge_location LIKE 'AMS%' THEN 'Amsterdam'
    WHEN x_edge_location LIKE 'ARN%' THEN 'Stockholm'
    WHEN x_edge_location LIKE 'ATL%' THEN 'Atlanta'
    WHEN x_edge_location LIKE 'CDG%' THEN 'Paris'
    WHEN x_edge_location LIKE 'DUB%' THEN 'Dublin'
    WHEN x_edge_location LIKE 'FRA%' THEN 'Frankfurt'
    WHEN x_edge_location LIKE 'HIO%' THEN 'Portland'
    WHEN x_edge_location LIKE 'IAD%' THEN 'Washington DC'
    WHEN x_edge_location LIKE 'JFK%' THEN 'New York'
    WHEN x_edge_location LIKE 'MIA%' THEN 'Miami'
    WHEN x_edge_location LIKE 'LAX%' THEN 'Los Angelos'
    WHEN x_edge_location LIKE 'LHR%' THEN 'London'
    WHEN x_edge_location LIKE 'ORD%' THEN 'Chicago'
    WHEN x_edge_location LIKE 'QRO%' THEN 'Mexico City'
    WHEN x_edge_location LIKE 'SEA%' THEN 'Seattle'
    WHEN x_edge_location LIKE 'SFO%' THEN 'San Francisco'
    WHEN x_edge_location LIKE 'TLV%' THEN 'Tel Aviv'
    WHEN x_edge_location LIKE 'YVR%' THEN 'Vancouver'
    ELSE x_edge_location
  END as customer_location,
  SUM(CASE WHEN sc_status = 200 THEN 1 ELSE 0 END) as successful_requests,
  SUM(CASE WHEN sc_status = 301 THEN 1 ELSE 0 END) as redirect_requests,
  SUM(CASE WHEN sc_status NOT IN (200,301) THEN 1 ELSE 0 END) as unsuccessful_requests,
  COUNT(x_edge_request_id) as count_requests
FROM 
  "default"."cloudfront_standard_logs"
GROUP BY
  DATE_FORMAT(date,'%Y-%m-01'),
  2
ORDER BY
  COUNT(x_edge_request_id) DESC
)
,

unblended_costs AS (
SELECT
  DATE_FORMAT(line_item_usage_start_date,'%Y-%m-01') AS month_line_item_usage_start_date,
  SUM(line_item_unblended_cost) AS sum_line_item_unblended_cost
FROM 
  default.jrmarkscur
GROUP BY
  DATE_FORMAT(line_item_usage_start_date,'%Y-%m-01')
)
,
  
cost_per_successful_request AS (
SELECT
  cloudfront_requests.month as month,
  unblended_costs.sum_line_item_unblended_cost AS sum_line_item_unblended_cost,
  SUM(cloudfront_requests.successful_requests) AS sum_successful_requests,
  (unblended_costs.sum_line_item_unblended_cost / COALESCE(SUM(cloudfront_requests.successful_requests),0)) AS monthly_cost_per_successful_request
FROM 
  cloudfront_requests JOIN unblended_costs on cloudfront_requests.month=unblended_costs.month_line_item_usage_start_date
GROUP BY
  cloudfront_requests.month,
  unblended_costs.sum_line_item_unblended_cost
ORDER BY
  cloudfront_requests.month DESC
)

SELECT 
  cloudfront_requests.month,
  cloudfront_requests.customer_location,
  cloudfront_requests.successful_requests,
  cloudfront_requests.redirect_requests,
  cloudfront_requests.unsuccessful_requests,
  (cloudfront_requests.successful_requests * cost_per_successful_request.monthly_cost_per_successful_request) AS total_location_cost
FROM 
  cloudfront_requests JOIN cost_per_successful_request on cloudfront_requests.month=cost_per_successful_request.month