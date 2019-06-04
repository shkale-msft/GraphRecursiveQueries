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

---------------------------------------------------------------------------------------------------
--- Top Influencer - using page rank
---------------------------------------------------------------------------------------------------

---*******************************************************************************************
--- This page rank has logic to handle nodes which do not have any incoming links in
--- The code is commented. 
---*******************************************************************************************
-- compute page rank: formula from https://en.wikipedia.org/wiki/PageRank#Iterative
DROP TABLE if exists #t

-- get the total node count; exclude nodes with no outbound or no inbound edges
DECLARE @node_cnt int
SELECT @node_cnt = count(*)
FROM Customers u1
WHERE EXISTS (SELECT * FROM Customers u2o, FriendOf fo WHERE MATCH(u1-(fo)->u2o)) AND
       EXISTS (SELECT * FROM Customers u2i, FriendOf fi WHERE MATCH(u1<-(fi)-u2i))
SELECT '@node_cnt', @node_cnt

-- get all connected nodes; compute the outbound edge count and set the initial weight
DECLARE @initial_weight FLOAT = 1e0 / @node_cnt
CREATE TABLE #t (CustomerID VARCHAR(100) PRIMARY KEY CLUSTERED, out_edge_cnt INT, weight FLOAT, delta FLOAT)

INSERT #t
SELECT c1.CustomerID, count(*), @initial_weight, @initial_weight
FROM Customers c1, Customers c2o, FriendOf fo
WHERE MATCH(c1-(fo)->c2o)
AND EXISTS (SELECT * FROM Customers c2i, FriendOf fi WHERE MATCH(c1<-(fi)-c2i))
GROUP BY c1.CustomerID

-- iterate until weights converge; stop when delta is less than 1%
DECLARE @threshold FLOAT = 0.01
DECLARE @damping_factor FLOAT = 0.85
DECLARE @epsilon FLOAT = @initial_weight * @threshold
DECLARE @iterations INT = 0

-- Get the initial weights, should be equal to 1
SELECT 'sum(weight)', SUM(weight) FROM #t

WHILE EXISTS (SELECT * FROM #t WHERE delta > @epsilon)
BEGIN
	UPDATE #t
    SET WEIGHT = new_weight, delta = weight - new_weight
    FROM #t,
            (SELECT u2.CustomerID, (1 - @damping_factor) / @node_cnt + (@damping_factor * SUM(weight/out_edge_cnt)) AS new_weight
            FROM #t, Customers u1, Customers u2, FriendOf f
            WHERE #t.CustomerID = u1.CustomerID and MATCH(u1-(f)->u2)
			GROUP BY u2.CustomerID) q
    WHERE #t.CustomerID = q.CustomerID

    SET @iterations += 1
END
SELECT '@iterations', @iterations

-- Final sum should be nearly same as initial weight.
SELECT 'sum(weight)', SUM(weight) FROM #t

-- final results
SELECT * FROM #t ORDER BY weight DESC
GO


