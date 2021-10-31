-- Create a view to store the data needed with the total weight for each order
CREATE OR ALTER VIEW company_table AS
	WITH tab as(
		SELECT o.ExternOrderNo as order_num,o.[Order Qty], s.[Weight (g)], cv.Zone,cv.[Type of Shipment],(o.[Order Qty]*s.[Weight (g)])/1000 as total_weight
		FROM Order_Report as o
		INNER JOIN SKU_Master as s
		ON o.SKU = s.SKU
		LEFT JOIN courier_invoice as cv
		ON o.ExternOrderNo = cv.[Order ID])
	SELECT order_num, Zone, [Type of Shipment], sum(total_weight) as total_weight 
	FROM tab
	GROUP BY order_num, Zone, [Type of Shipment]


--Create a VIEW for the correct prices 
CREATE OR ALTER VIEW Billing_amount AS
SELECT  *, 
		CASE
			-- Forward Charges Only
			WHEN ROUND(total_weight,1) <= 0.5 AND Zone = 'b' AND [Type of Shipment] = 'Forward charges' 
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_b_fixed')
			WHEN ROUND(total_weight,1) <= 0.5 AND Zone = 'd' AND [Type of Shipment] = 'Forward charges' 
				THEN (SELECT RATE FROM Courier_rates WHERE Zone = 'fwd_d_fixed')

			WHEN ROUND(total_weight,1) > 0.5 AND zone = 'b' AND [Type of Shipment] = 'Forward Charges' 
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_b_fixed') 
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_b_additional') * (CEILING(ROUND(total_weight,1)/0.5)- 1))
			WHEN ROUND(total_weight,1) > 0.5 AND zone = 'd' AND [Type of Shipment] = 'Forward Charges'
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_d_fixed') 
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_d_additional') * (CEILING(ROUND(total_weight,1)/0.5)- 1))


			----------------------------------------------------------------------------------------------------------------------------------------------------

			--Forward and RTO Charges
			WHEN ROUND(total_weight,1) <= 0.5 AND Zone = 'b' AND [Type of Shipment] = 'Forward and RTO charges' 
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_b_fixed') + (SELECT Rate FROM Courier_rates WHERE Zone = 'rto_b_fixed')
			WHEN ROUND(total_weight,1) <= 0.5 AND Zone = 'd' AND [Type of Shipment] = 'Forward and RTO charges' 
				THEN (SELECT RATE FROM Courier_rates WHERE Zone = 'fwd_d_fixed') + (SELECT Rate FROM Courier_rates WHERE Zone = 'rto_d_fixed')
			WHEN ROUND(total_weight,1) <= 0.5 AND Zone = 'e' AND [Type of Shipment] = 'Forward and RTO charges' 
				THEN (SELECT RATE FROM Courier_rates WHERE Zone = 'fwd_e_fixed') + (SELECT Rate FROM Courier_rates WHERE Zone = 'rto_e_fixed')

			WHEN ROUND(total_weight,1) > 0.5 AND zone = 'b' AND [Type of Shipment] = 'Forward and RTO charges' 
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_b_fixed') + (SELECT Rate FROM Courier_rates WHERE Zone = 'rto_b_fixed')
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_b_additional') * (CEILING(ROUND(total_weight,1)/0.5)- 1)) 
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'rto_b_fixed') * (CEILING(ROUND(total_weight,1)/0.5)- 1))
			WHEN ROUND(total_weight,1) > 0.5 AND zone = 'd' AND [Type of Shipment] = 'Forward and RTO charges'
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_d_fixed') + (SELECT Rate FROM Courier_rates WHERE Zone = 'rto_d_fixed')
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_d_additional') * (CEILING(ROUND(total_weight,1)/0.5)- 1)) 
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'rto_d_fixed') * (CEILING(ROUND(total_weight,1)/0.5)- 1))
			WHEN ROUND(total_weight,1) > 0.5 AND zone = 'e' AND [Type of Shipment] = 'Forward and RTO charges' 
				THEN (SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_e_fixed') + (SELECT Rate FROM Courier_rates WHERE Zone = 'rto_e_fixed')
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'fwd_e_additional') * (CEILING(ROUND(total_weight,1)/0.5)- 1)) 
						+ ((SELECT Rate FROM Courier_rates WHERE Zone = 'rto_e_fixed') * (CEILING(ROUND(total_weight,1)/0.5)- 1))

		END AS Billing_Amount
		
FROM company_table

			----------------------------------------------------------------------------------------------------------------------------------------------------

-- Getting the final table that the company need
CREATE OR ALTER VIEW Final_result AS  
	SELECT b.order_num, b.total_weight as company_weight, b.Billing_Amount as company_amount,
			c.[Charged Weight] as courier_weight, c.[Billing Amount ] as courier_amount
	FROM Billing_amount as b
	RIGHT JOIN courier_invoice as c
	ON b.order_num = c.[Order ID]



