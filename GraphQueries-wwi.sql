-------------------------------------------------------------------------------------
-- Simple MATCH query
-- Find all the customers who bought 'White chocolate snow balls 250g'
-------------------------------------------------------------------------------------
SELECT
	top 10 CustomerName,
	StockItemName
FROM
	StockItems,
	Customers,
	Bought
WHERE MATCH(Customers-(Bought)->StockItems)
AND StockItemName = 'White chocolate snow balls 250g'



-------------------------------------------------------------------------------------
-- Recommended items --
-- Thanks to Sergio Govonni for developing the recommendation scenario for us! 
-- You can read more about it here: https://aka.ms/X8324w 
-------------------------------------------------------------------------------------

-- Let's assume that a customer is looking at or has just bought 
-- 'White chocolate snow balls 250g'. Now, as the business owner we would
-- like to recommend similar products to this customer based on the 
-- behaviour of other customers.

-- Find products that are recommended for 'White chocolate snow balls 250g' 
-- using MATCH clause over nodes and edge
SELECT
  TOP 10 RecommendedItem.StockItemName,
  COUNT(*)
FROM
  StockItems AS Item,
  Customers AS C,
  Bought AS BoughtOther,
  Bought AS BoughtThis,
  StockItems AS RecommendedItem
WHERE
  Item.StockItemName LIKE 'White chocolate snow balls 250g'
  AND MATCH(RecommendedItem<-(BoughtOther)-C-(BoughtThis)->Item)
  AND (Item.StockItemName <> RecommendedItem.StockItemName)
  and C.customerID <> 88
GROUP BY
  RecommendedItem.StockItemName
ORDER BY COUNT(*) DESC;
GO

/*
-- Recommended items using relational approach

-- Find products that are recommended for 'White chocolate snow balls 250g'
-- using common JOIN operations
-- Identify the user and the product he/she is purchasing
WITH Current_Usr AS
(
  SELECT
    CustomerID = 88,
    StockItemID = 226,  -- 'White chocolate snow balls 250g'
    PurchasedCount = 1
) ,
-- Identify the other users who have also purchased the item he/she is looking for
Other_Usr AS
(
  SELECT
    C.CustomerID,
    P.StockItemID,
    Purchased_by_others = COUNT(*)
  FROM
    Sales.OrderLines AS OD
  JOIN
    Sales.Orders AS OH ON OH.OrderID=OD.OrderID
  JOIN
    Sales.Customers AS C ON OH.CustomerID=C.CustomerID
  JOIN
    Current_Usr AS P ON P.StockItemID=OD.StockItemID
  WHERE
    C.CustomerID<>P.CustomerID
  GROUP BY
    C.CustomerID, P.StockItemID
) , 
-- Find the other items which those other customers have also purchased
Other_Items AS
(
SELECT
    C.CustomerID,
    P.StockItemID,
    Other_purchased = COUNT(*)
  FROM
    Sales.OrderLines AS OD
  JOIN
    Sales.Orders AS OH ON OH.OrderID=OD.OrderID
  JOIN
    Other_Usr AS C ON OH.CustomerID=C.CustomerID
  JOIN
    Warehouse.StockItems AS P ON P.StockItemID=OD.StockItemID
  WHERE
    P.StockItemName<>'White chocolate snow balls 250g'
  GROUP BY
    C.CustomerID, P.StockItemID
)
-- Outer query
-- Recommend to the current user to the top items from those other items,
-- ordered by the number of times they were purchased
SELECT
  top 10 P.StockItemName,
  COUNT(Other_purchased)
FROM
  Other_Items
JOIN
  Warehouse.StockItems AS P ON P.StockItemID=Other_Items.StockItemID
GROUP BY
  P.StockItemName
ORDER BY
  COUNT(Other_purchased) DESC;
GO
*/

-------------------------------------------------------------------------------------
-- What are friends 1-3 hops away buying?
-- Traversing arbitrary number of hops in a graph
-------------------------------------------------------------------------------------
DECLARE @MaxHops Integer = 3;
WITH
Friends_somehops_away(CustomerName, FriendName, NumHops) AS
(
	SELECT C.CustomerName , 
		   F.CustomerName AS FriendName,
		   1 AS NumHops
	 FROM Customers C, Customers F, FriendOf FO
	WHERE MATCH(C-(FO)->F)
	  AND C.CustomerID = 11
	UNION ALL
	SELECT C1.CustomerName AS CustomerName, 
		   F1.CustomerName AS FriendName,
		   NumHops + 1 AS NumHops
	FROM Customers C1, Customers F1, FriendOf, Friends_somehops_away fsha
	WHERE MATCH(C1-(FriendOf)->F1) 
	AND fsha.FriendName = C1.CustomerName
	AND NumHops < @MaxHops
) 
SELECT * 
FROM Friends_somehops_away 


-------------------------------------------------------------------------------------
-- Shortest path between me (Tailspin Toys (Devault, PA)) and 
-- another (Tailspin Toys (Cortaro, AZ)) customer
-- Breadth first search algorithm for shortest path
-------------------------------------------------------------------------------------
CREATE TABLE #t (
    CustomerName VARCHAR (100)  COLLATE Latin1_General_100_CI_AS UNIQUE CLUSTERED ,
    level        INT           ,
    path         VARCHAR (8000)
);

CREATE INDEX il
    ON #t(level)
    INCLUDE(path);

DECLARE @OriginUser AS VARCHAR (100) = 'David Jaramillo';

DECLARE @DestUser AS VARCHAR (100) = 'Emma Salpa';

DECLARE @level AS INT = 0;

INSERT  #t
VALUES (@OriginUser, @level, @OriginUser);

WHILE @@rowcount > 0
      AND NOT EXISTS (SELECT *
                      FROM   #t
                      WHERE  CustomerName = @DestUser)
    BEGIN
        SET @level += 1;
        INSERT #t
        SELECT CustomerName,
               level,
               concat(path, ' -> ', CustomerName)
        FROM   (SELECT   u2.CustomerName,
                         @level AS level,
                        min(t1.path) AS path
                FROM     #t AS t1 WITH (FORCESEEK), Customers AS u1, FriendOf AS f, Customers AS u2
                WHERE    t1.level = @level - 1
                         AND t1.CustomerName = u1.CustomerName 
                         AND MATCH(u1-(f)->u2)
                         AND NOT EXISTS (SELECT *
                                         FROM   #t AS t2 WITH (FORCESEEK)
                                         WHERE  t2.CustomerName = u2.CustomerName)
                GROUP BY u2.CustomerName) AS q;
    END

SELECT *
FROM   #t
WHERE  CustomerName = @DestUser;

DROP TABLE #t;
GO

