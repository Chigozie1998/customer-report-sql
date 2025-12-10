/*
=========================================================================================================================
Customer Report
=========================================================================================================================
Purpose:
  - Consolidates key customer metrics and behaviors

Highlights:
  1. Gathers essential fields such as name, age, and transaction details
  2. Segments customers into categories (VIP, Regular, New) and Age groups
  3. Aggregates customer-level metrics:
       - Total orders
       - Total sales
       - Total quantity purchased
       - Total products
       - Lifespan (in months)
  4. Calculates valuable KPIs:
       - Recency (Months since last order)
       - Average order value
       - Average monthly spend
=========================================================================================================================
*/

CREATE VIEW CustomersReport AS

WITH BaseQuery AS (
    /*
    ---------------------------------------------------------------------------------------------------------------------
    1.) Base Query: Retrieves core columns from tables
    ---------------------------------------------------------------------------------------------------------------------
    */
    SELECT
        S.OrderNumber,
        S.ProductKey,
        S.OrderDate,
        CAST(S.OrderQuantity * P.ProductPrice AS DECIMAL(12,2)) AS SalesAmount,
        S.OrderQuantity,
        C.CustomerKey,
        CONCAT(C.FirstName, ' ', C.LastName) AS CustomerName,
        DATEDIFF(YEAR, C.BirthDate, GETDATE()) AS Age
    FROM Sales S
    LEFT JOIN Customers C
        ON S.CustomerKey = C.CustomerKey
    LEFT JOIN Products P
        ON S.ProductKey = P.ProductKey
    WHERE S.OrderDate IS NOT NULL
),

CustomerAggregation AS (
    /*
    ---------------------------------------------------------------------------------------------------------------------
    2.) Customer Aggregation: Summarizes key metrics at the customer level
    ---------------------------------------------------------------------------------------------------------------------
    */
    SELECT
        CustomerKey,
        CustomerName,
        Age,
        COUNT(DISTINCT OrderNumber) AS TotalOrders,
        SUM(SalesAmount) AS TotalSales,
        SUM(OrderQuantity) AS TotalQuantity,
        COUNT(DISTINCT ProductKey) AS TotalProduct,
        MAX(OrderDate) AS LastOrderDate,
        DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) AS Lifespan
    FROM BaseQuery
    GROUP BY
        CustomerKey,
        CustomerName,
        Age
)

SELECT
    CustomerKey,
    CustomerName,
    Age,
    -- Age Group
    CASE 
        WHEN Age < 20 THEN 'Under 20'
        WHEN Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and Above'
    END AS AgeGroup,
    
    -- Customer Segment
    CASE 
        WHEN Lifespan >= 12 AND TotalSales > 5000 THEN 'VIP'
        WHEN Lifespan > 12 AND TotalSales >= 5000 THEN 'Regular'
        ELSE 'New'
    END AS Customer_Segment,
    
    LastOrderDate,
    DATEDIFF(MONTH, LastOrderDate, GETDATE()) AS Recency,
    TotalOrders,
    TotalSales,
    TotalQuantity,
    TotalProduct,
    Lifespan,
    
    -- Compute Average Order Value (AOV)
    CASE 
        WHEN TotalOrders = 0 THEN 0
        ELSE TotalSales / TotalOrders
    END AS Avg_Order_Value,
    
    -- Compute Average Monthly Spend
    CASE 
        WHEN Lifespan = 0 THEN TotalSales
        ELSE TotalSales / Lifespan
    END AS Avg_Monthly_Spend

FROM CustomerAggregation;
