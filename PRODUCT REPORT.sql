/* 
=====================================================================================================================================
Product Report
=====================================================================================================================================
Purpose:
   - This report consolidates key products and metrics and behaivors.

Highlights:
   1. Gather essential fields such as prooduct name, Category, subcategory, and cost
   2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
   3. Aggregates product-level metrics:
      - total orders
	  - total sales
	  - total quantity sold
	  - tatal customers (unique)
	  - lifespan ( in months)
   4. caculates valuable KPIs
      - recency (months since last sale)
	  - average order revenue (AOR)
	  - average monthly revenue
======================================================================================================================================
*/
CREATE VIEW report_products AS
WITH base_query AS (
SELECT 
     S.OrderDate,
	 S.OrderNumber,
	 S.CustomerKey,
	 S.OrderQuantity,
	 CAST(P.ProductPrice * S.OrderQuantity AS DECIMAL(12,2)) AS SalesAmount,
	 P.ProductKey,
	 P.ModelName AS ProductName,
	 P.ProductSubcategoryKey,
	 CAST(P.ProductCost AS DECIMAL(12,2)) AS Cost
FROM SALES S
LEFT JOIN Products P
     ON S.ProductKey = P.ProductKey
WHERE OrderDate IS NOT NULL
),

products_aggregations AS (
SELECT 
     Productkey,
	 Productname,
	 ProductSubcategoryKey,
	 Cost,
	 DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) AS Lifespan,
	 MAX(OrderDate) AS LastOrder,
	 COUNT(DISTINCT OrderNumber) AS TotalOrders,
	 COUNT(DISTINCT CustomerKey) AS TotalCustomers,
	 SUM(SalesAmount) AS TotalSales,
	 SUM(OrderQuantity) AS TotalQuantity,
	 ROUND(AVG(CAST(SalesAmount AS FLOAT) / NULLIF(OrderQuantity, 0)), 1) AS avg_selling_price
FROM base_query
GROUP BY 
     Productkey,
	 Productname,
	 ProductSubcategoryKey,
	 Cost
)

SELECT 
     Productkey,
	 Productname,
	 ProductSubcategoryKey,
	 Cost,
	 LastOrder,
	 DATEDIFF(MONTH, LastOrder, GETDATE ()) AS Recency_in_months,
	 CASE 
	    WHEN TotalSales > 50000 THEN 'High perfomer'
		WHEN TotalSales >= 10000 THEN 'Mid Performer'
		ELSE 'Low Performer'
	END AS Produt_Segment,
	Lifespan,
	TotalOrders,
	TotalCustomers,
	TotalSales,
	TotalQuantity,
	avg_selling_price,
	CASE
	   WHEN TotalOrders = 0 THEN 0
	   ELSE TotalSales / TotalOrders
	END AS avg_order_revenue
FROM products_aggregations