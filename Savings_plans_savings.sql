-- PART 1
-- How do you find the savings from savings plan in a given month 

SELECT round(
		sum(
			CASE
				WHEN "line_item_line_item_type" = 'SavingsPlanCoveredUsage' then "savings_plan_savings_plan_effective_cost" - "line_item_unblended_cost" Else 0
			END
		),
		2
	) as sum_savings
FROM "cid_data_export"."cur2"
where SPLIT(billing_period, '-') [ 2 ] = '09'

----------------------------------------------------------------------------------------------------------------------------------------

--Part 2 Getting the rest of the info

    --1. Get resource tags for finops
SELECT resource_tags [ 'user_fin_ops' ] as user_fin_ops,
	SPLIT(billing_period, '-') [ 2 ] as month,
	SPLIT(billing_period, '-') [ 1 ] as year,
	--2. get unblnded costs 
	sum(line_item_unblended_cost) as sum_line_item_unblended_cost,
	--3. get tagged spend as in what will the proportion of spend be without the untagged spend
	sum(
		CASE
			WHEN resource_tags [ 'user_fin_ops' ] is not null then line_item_unblended_cost ELSE 0
		END
	) as sum_tagged_spend,
	--4. Savings we got from savings plans
	round(
		sum(
			CASE
				WHEN "line_item_line_item_type" = 'SavingsPlanCoveredUsage' then "savings_plan_savings_plan_effective_cost" - "line_item_unblended_cost" Else 0
			END
		),
		2
	) as sum_savings
FROM "cid_data_export"."cur2"
WHERE SPLIT(billing_period, '-') [ 2 ] = '09'
GROUP BY 1,
	2,
	3


----------------------------------------------------------------------------------------------------------------------------------------


-- PART 3 redistribution
with unblended as (
    --1. Get resource tags for finops
	SELECT resource_tags [ 'user_fin_ops' ] as user_fin_ops,
		SPLIT(billing_period, '-') [ 2 ] as month,
		SPLIT(billing_period, '-') [ 1 ] as year,
    --2. get unblnded costs 

		sum(line_item_unblended_cost) as sum_line_item_unblended_cost,
    --3. get tagged spend as in what will the proportion of spend be without the untagged spend
		sum(		CASE WHEN resource_tags [ 'user_fin_ops' ] is not null then line_item_unblended_cost ELSE 0 END ) as sum_tagged_spend,
    --4. Savings we got from savings plans

		round(
			sum(
				CASE
					WHEN "line_item_line_item_type" = 'SavingsPlanCoveredUsage' then "savings_plan_savings_plan_effective_cost" - "line_item_unblended_cost" Else 0
				END
			),
			2
		) as sum_savings
	FROM "cid_data_export"."cur2"
	group by 1,
		2,
		3
)
SELECT *,
-- * Make the total savings per tag. The over is going to what you are splitting by. aka Per month savings 


	sum(sum_savings) over (partition by month, year) as total_savings,
	sum(sum_tagged_spend) over (partition by month, year) as total_spend,
	CASE
		WHEN user_fin_ops is not null then sum_line_item_unblended_cost / sum(sum_tagged_spend) over (partition by month, year) ELSE 0
	END as percentage_spend,
	CASE
		WHEN user_fin_ops is not null then sum_line_item_unblended_cost / sum(sum_tagged_spend) over (partition by month, year) ELSE 0
	END *
	sum(sum_savings) over (partition by month, year) + sum_line_item_unblended_cost as charge_amount
	
	
	
FROM unblended
where month = '09'