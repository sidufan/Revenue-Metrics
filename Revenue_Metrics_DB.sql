-----------------All Important Columns for Further Obtaining Important Information-------------------------
WITH games_payments_info AS (
	SELECT
		gp.user_id
		, gp.game_name 
		, DATE_TRUNC('MONTH', gp.payment_date) AS month
		, gp.revenue_amount_usd
		, gpu.language
		, gpu.has_older_device_model
		, gpu.age
	FROM project.games_payments AS gp 
	LEFT JOIN project.games_paid_users AS gpu
		ON gpu.user_id  = gp.user_id
),
-------------Data for Further Obtaining Important Information Related to Monthly Revenue (MR)-------------
	monthly_revenue AS (
		SELECT 
			month
			, user_id
			, game_name
			, language
			, has_older_device_model
			, age
			, SUM(revenue_amount_usd) AS month_revenue	
		FROM games_payments_info
		GROUP BY month, user_id, game_name, language, has_older_device_model, age
	),
-------------------regular customers (for MRR) that made purchase more 2 months--------------------------
		regular_users AS (
			SELECT 
				user_id
			FROM games_payments_info
			GROUP BY user_id
			HAVING count(DISTINCT month) >= 2
		),
-------Data for Further Obtaining Important Information Related to Monthly Recurring Revenue (MRR)-------
		recurring_customers_revenue AS (
			SELECT 
				mr.month
				, ru.user_id
				, mr.month_revenue AS monthly_recurring_revenue
			FROM regular_users AS ru
			LEFT JOIN monthly_revenue AS mr
				ON ru.user_id = mr.user_id
		),
--------------------------------first and last action by user-------------------------------------------
			first_last_payment AS (
				SELECT
					user_id
					, MIN(month) AS first_payment_month
					, MAX(month) AS last_payment_month
				FROM games_payments_info
				GROUP BY user_id	
			),
---------Data for Further Obtaining Important Information Related to New Month Recurring Revenue--------
				new_customers_revenue AS (
					SELECT 
			 			mr.month
			 			, mr.user_id
						, mr.month_revenue AS new_month_recurring_revenue
					FROM first_last_payment AS flp
					LEFT JOIN monthly_revenue AS mr
						ON mr.month = flp.first_payment_month
						AND mr.user_id = flp.user_id
				),
----------Data for Further Obtaining Important Information Related to Churned Users, Rate etc-----------
					churned_users_and_month AS (
						SELECT 
							CASE WHEN EXTRACT(MONTH FROM last_payment_month) < 12 
								THEN DATE_TRUNC('MONTH', last_payment_month + INTERVAL '1 month') END AS churn_month
							, CASE WHEN EXTRACT(MONTH FROM last_payment_month) < 12 
								THEN user_id END AS churned_user_id
							FROM first_last_payment
					)
--------------------All Important Columns for Further Visualization in Tableau--------------------------
						SELECT
							mr.month
							, mr.user_id
							, mr.game_name
							, mr.language
							, mr.has_older_device_model
							, mr.age
							, mr.month_revenue
							, rcr.monthly_recurring_revenue
							, ncr.new_month_recurring_revenue 
							, cuam.churned_user_id
							, cuam.churn_month
							, CASE WHEN cuam.churned_user_id = mr.user_id THEN mr.month_revenue END AS churned_revenue
							, CASE WHEN LAG(rcr.monthly_recurring_revenue, 1) OVER (ORDER BY mr.user_id, mr.MONTH ) < rcr.monthly_recurring_revenue 
								THEN rcr.monthly_recurring_revenue END AS expansion_mrr
							, CASE WHEN LAG(rcr.monthly_recurring_revenue, 1) OVER (ORDER BY mr.user_id, mr.MONTH ) > rcr.monthly_recurring_revenue 
								THEN rcr.monthly_recurring_revenue END AS contraction_mrr
						FROM monthly_revenue AS mr
						LEFT JOIN recurring_customers_revenue AS rcr
							ON rcr.user_id = mr.user_id
							AND rcr.month = mr.MONTH
						LEFT JOIN new_customers_revenue AS ncr
							ON ncr.user_id = mr.user_id
							AND ncr.month = mr.MONTH
						LEFT JOIN churned_users_and_month AS cuam
							ON cuam.churned_user_id = mr.user_id
							AND cuam.churn_month = mr.MONTH + INTERVAL '1 month'
						ORDER BY user_id, MONTH
						

						
-----------General Query for Further Obtaining Important Information Related to LTV and LT-------------
SELECT
	gp.user_id
	, gp.game_name 
	, DATE_TRUNC('MONTH', gp.payment_date) AS month
	, gp.revenue_amount_usd
	, gpu.language
	, gpu.has_older_device_model
	, gpu.age
FROM project.games_payments AS gp 
LEFT JOIN project.games_paid_users AS gpu
	ON gpu.user_id  = gp.user_id


					
					
					
					
					
					
					
					
					