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

