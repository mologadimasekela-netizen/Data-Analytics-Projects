-- Databricks notebook source
-- DBTITLE 1,Question 1.1
SELECT ProductID, ProductName, UnitPrice
FROM products
WHERE Category = 'Electronics'
ORDER BY UnitPrice DESC

-- COMMAND ----------

-- DBTITLE 1,Question 1.2
SELECT Region, COUNT(*) AS CustomerCount
FROM customers
GROUP BY Region

-- COMMAND ----------

-- DBTITLE 1,Question 1.3
SELECT OrderID, OrderDate, TotalSales
FROM sales
ORDER BY OrderDate
LIMIT 10

-- COMMAND ----------

-- DBTITLE 1,Questionn 1.4
Select ProductName, Category, UnitPrice
From products
where UnitPrice < 1000

-- COMMAND ----------

-- DBTITLE 1,Question 1.5
SELECT Satisfaction AS SatisfactionLevel, COUNT(*) AS FeedbackCount
FROM customer_feedback
GROUP BY Satisfaction
ORDER BY FeedbackCount DESC

-- COMMAND ----------

-- DBTITLE 1,Question 2.1
SELECT Category, SUM(TotalSales) AS TotalRevenue, SUM(Profit) AS TotalProfit
FROM sales
JOIN products p ON sales.ProductID = p.ProductID
GROUP BY Category
ORDER BY TotalRevenue DESC

-- COMMAND ----------

-- DBTITLE 1,Question 2.2
SELECT c.CustomerID, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName, SUM(s.TotalSales) AS TotalSpent
FROM customers c
JOIN sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC
LIMIT 5

-- COMMAND ----------

-- DBTITLE 1,Question 2.3
SELECT YEAR(OrderDate) AS Year, MONTH(OrderDate) AS Month, SUM(TotalSales) AS TotalSales
FROM sales
WHERE YEAR(OrderDate) = 2024
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month

-- COMMAND ----------

-- DBTITLE 1,Question 2.4
SELECT Channel, COUNT(OrderID) AS NumberOfOrders, AVG(TotalSales) AS AverageOrderValue, SUM(TotalSales) AS TotalRevenue
FROM sales
WHERE Channel IN ('Online', 'Store')
GROUP BY Channel

-- COMMAND ----------

-- DBTITLE 1,Question 2.5
SELECT ProductCategory AS Category, AVG(Rating) AS AverageRating, COUNT(*) AS NumberOfReviews
FROM customer_feedback
GROUP BY ProductCategory
HAVING COUNT(*) >= 50

-- COMMAND ----------

-- DBTITLE 1,Question 3.1
SELECT Category, ProductName, TotalRevenue
FROM ( SELECT p.Category, p.ProductName, SUM(s.TotalSales) AS TotalRevenue,
           RANK() OVER (PARTITION BY p.Category ORDER BY SUM(s.TotalSales) DESC) AS rank
    FROM sales s
    JOIN products p ON s.ProductID = p.ProductID
    GROUP BY p.Category, p.ProductName
) sub
WHERE rank = 1

-- COMMAND ----------

-- DBTITLE 1,Question 3.2
SELECT c.CustomerID, c.Region, c.Channel AS PrimaryChannel, SUM(s.TotalSales) AS TotalPurchases,
    COUNT(s.OrderID) AS NumberOfOrders,
    AVG(s.TotalSales) AS AverageOrderValue
FROM customers c
JOIN sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.Region, c.Channel
HAVING COUNT(s.OrderID) > 3
ORDER BY TotalPurchases DESC

-- COMMAND ----------

-- DBTITLE 1,Question 3.3
SELECT p.ProductName, p.Category, SUM(s.TotalSales) AS TotalSales, SUM(s.Profit) AS TotalProfit,
       (SUM(s.Profit) / SUM(s.TotalSales)) * 100 AS ProfitMarginPercent
FROM products p
JOIN sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductName, p.Category
ORDER BY ProfitMarginPercent DESC

-- COMMAND ----------

-- DBTITLE 1,Question 3.4
WITH yearly_Sales AS (
    SELECT YEAR(OrderDate) AS Year, SUM(TotalSales) AS TotalSales
    FROM sales
    WHERE YEAR(OrderDate) IN (2023, 2024)
    GROUP BY YEAR(OrderDate)
)
SELECT 
    y2023.TotalSales AS Sales2023,
    y2024.TotalSales AS Sales2024,
    ((y2024.TotalSales - y2023.TotalSales) / y2023.TotalSales) * 100 AS GrowthPercentage
FROM 
    (SELECT TotalSales FROM yearly_sales WHERE Year = 2023) y2023,
    (SELECT TotalSales FROM yearly_sales WHERE Year = 2024) y2024

-- COMMAND ----------

-- DBTITLE 1,Question 3.5
SELECT c.Region, SUM(s.TotalSales) AS TotalSales, COUNT(s.OrderID) AS TotalOrders,
       RANK() OVER (ORDER BY SUM(s.TotalSales) DESC) AS Rank
FROM sales s
JOIN customers c ON s.CustomerID = c.CustomerID
GROUP BY c.Region

-- COMMAND ----------

-- DBTITLE 1,question 4.1
SELECT
  CASE 
    WHEN cf.Rating BETWEEN 4 AND 5 THEN 'High Satisfaction'
    WHEN cf.Rating BETWEEN 1 AND 3 THEN 'Low Satisfaction'
    ELSE 'Other'
  END AS SatisfactionGroup,
  AVG(order_counts.NumOrders) AS AvgOrdersPerCustomer,
  COUNT(DISTINCT cf.CustomerID) AS TotalCustomers
FROM customer_feedback cf
JOIN (
    SELECT CustomerID, COUNT(OrderID) AS NumOrders
    FROM sales
    GROUP BY CustomerID
) order_counts ON cf.CustomerID = order_counts.CustomerID
WHERE cf.Rating BETWEEN 1 AND 5
GROUP BY SatisfactionGroup
ORDER BY SatisfactionGroup

------Business insight:
--From the below output, we can see that customers with high satisfaction tend to place slightly more orders on average, while customers with low satisfaction place fewer orders. This means the business should focus on improving thier service delivery and customer experience to increase sales thus increasing profits.

-- COMMAND ----------

-- DBTITLE 1,Question 4.2
SELECT
  CASE
    WHEN DiscountPercent = 0 THEN '0%'
    WHEN DiscountPercent BETWEEN 1 AND 10 THEN '1-10%'
    WHEN DiscountPercent BETWEEN 11 AND 20 THEN '11-20%'
    WHEN DiscountPercent BETWEEN 21 AND 30 THEN '21-30%'
    ELSE 'Other'
  END AS DiscountBand,
  SUM(TotalSales) AS TotalSales,
  SUM(Profit) AS TotalProfit,
  (SUM(Profit) / SUM(TotalSales)) * 100 AS ProfitMarginPercent
FROM sales
GROUP BY DiscountBand
ORDER BY DiscountBand

------------Business insight:
--Profit margins decline sharply as discounts increase. Sales also decrease with higher discounts, indicating that discounts are not effectively driving additional demand. Overall, the discount strategy appears ineffective, as it reduces profitability without generating sufficient sales growth.

-- COMMAND ----------

-- DBTITLE 1,Question 4.3
SELECT p.ProductID, p.ProductName, p.Category, SUM(s.TotalSales) AS TotalRevenue, SUM(s.Quantity) AS SalesVolume, (SUM(s.Profit) / NULLIF(SUM(s.TotalSales), 0)) * 100 AS ProfitMarginPercent,
    AVG(cf.Rating) AS AverageCustomerRating
FROM products p
JOIN sales s ON p.ProductID = s.ProductID
LEFT JOIN customer_feedback cf ON s.OrderID = cf.OrderID
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY TotalRevenue ASC
LIMIT 5


-----Business insights:
--The output suggests that there might be pricing issues for products such as the water bottle as it shows high sales but low revenue.Products such as the yoga mat and sunglasses perform well in both revenue and volume, making them key drivers of the business. The focus should be on scaling top performers, and improving or repositioning poor peforming items.

-- COMMAND ----------

-- DBTITLE 1,Part 5 - Section 1
SELECT
  SUM(CASE WHEN YEAR(OrderDate) IN (2023, 2024) THEN TotalSales ELSE 0 END) AS TotalRevenue_2023_2024,
  SUM(CASE WHEN YEAR(OrderDate) IN (2023, 2024) THEN Profit ELSE 0 END) AS TotalProfit_2023_2024,
  (SUM(CASE WHEN YEAR(OrderDate) IN (2023, 2024) THEN Profit ELSE 0 END) / NULLIF(SUM(CASE WHEN YEAR(OrderDate) IN (2023, 2024) THEN TotalSales ELSE 0 END), 0)) * 100 AS OverallProfitMarginPercent,
  COUNT(DISTINCT OrderID) AS TotalNumberOfOrders,
  COUNT(DISTINCT CustomerID) AS TotalNumberOfCustomers,
  AVG(TotalSales) AS AverageOrderValue
FROM sales
WHERE YEAR(OrderDate) IN (2023, 2024)

-- COMMAND ----------

-- DBTITLE 1,Part 5 - Section 2: Insight 1
    -- Insight 1: Revenue and Profit Growth Comparison (2023 vs 2024). The cost of running the business seems to be increasing faster year on year than the profit generated.
WITH yearly_sales AS (
    SELECT YEAR(OrderDate) AS Year, SUM(TotalSales) AS TotalRevenue, SUM(Profit) AS TotalProfit
    FROM sales
    WHERE YEAR(OrderDate) IN (2023, 2024)
    GROUP BY YEAR(OrderDate)
)
SELECT 
    y2023.TotalRevenue AS Revenue2023,
    y2024.TotalRevenue AS Revenue2024,
    ((y2024.TotalRevenue - y2023.TotalRevenue) / y2023.TotalRevenue) * 100 AS RevenueGrowthPercent,
    y2023.TotalProfit AS Profit2023,
    y2024.TotalProfit AS Profit2024,
    ((y2024.TotalProfit - y2023.TotalProfit) / y2023.TotalProfit) * 100 AS ProfitGrowthPercent
FROM 
    (SELECT TotalRevenue, TotalProfit FROM yearly_sales WHERE Year = 2023) y2023,
    (SELECT TotalRevenue, TotalProfit FROM yearly_sales WHERE Year = 2024) y2024;

-- COMMAND ----------

-- DBTITLE 1,Part 5 - section 2: Insight 2
-- Insight 2: Customer retention and order frequency for 2023 and 2024. There appears to be a slight increase between the two years.
SELECT
  YEAR(OrderDate) AS Year,
  COUNT(DISTINCT CustomerID) AS UniqueCustomers,
  COUNT(OrderID) AS TotalOrders,
  (COUNT(OrderID) / COUNT(DISTINCT CustomerID)) AS AvgOrdersPerCustomer
FROM
  sales
WHERE
  YEAR(OrderDate) IN (2023, 2024)
GROUP BY
  YEAR(OrderDate)
ORDER BY
  Year

-- COMMAND ----------

-- DBTITLE 1,Part 5 - section 2: Insight 3
----Insight 3: Profit Margin. Profit margins decreased slightly in 2024 in all 3 catergories.The business should consider reducing running costs and fixing their prcing strategy.
SELECT 
  YEAR(s.OrderDate) AS Year, p.Category, 
  SUM(s.TotalSales) AS CategoryRevenue, 
  SUM(s.Profit) AS CategoryProfit,
  (SUM(s.Profit) / NULLIF(SUM(s.TotalSales), 0)) * 100 AS CategoryProfitMarginPercent
FROM sales s
JOIN products p ON s.ProductID = p.ProductID
WHERE YEAR(s.OrderDate) IN (2023, 2024)
GROUP BY YEAR(s.OrderDate), p.Category
ORDER BY Year, CategoryProfitMarginPercent DESC

-- COMMAND ----------

-- DBTITLE 1,Part 5 - Section 3
----Recommendation 1: Reduce business running costs to improve profit margins.
---Action:
--1.Conduct a cost breakdown analysis.
--2.Renegotiate supplier contracts or optimize procurement.


----Recommendation 2: Optimize pricing strategy
---Action:
--1. Avoid unnecessary promotions on products.
--2. Test small price increases on less price-sensitive products.


----Recommendation 3: Increase customer retention and repeat purchases.
---Action:
--1. Introduce or improve customer loyalty programs.
--2. Target existing customers with cross-sell and upsell campaigns.