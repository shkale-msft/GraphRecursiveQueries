-- Create StockItems node

DROP TABLE IF EXISTS StockItems;
GO
DROP TABLE IF EXISTS Customers;
GO
DROP TABLE IF EXISTS Bought;
GO
DROP TABLE IF EXISTS FriendOf;
GO


CREATE TABLE StockItems
(
  StockItemID INTEGER IDENTITY(1, 1) NOT NULL,
  StockItemName NVARCHAR(100) NOT NULL,
  Barcode NVARCHAR(50) NULL,
  Photo VARBINARY(MAX),
  LastEditedBy INTEGER NOT NULL
) AS NODE
GO

-- Create the Customers node
-- This node holds the main details of the Customer
CREATE TABLE Customers
(
  [CustomerID] INTEGER NOT NULL,
  [CustomerName] NVARCHAR(100) NOT NULL,
  [WebsiteURL] NVARCHAR(256) NOT NULL
) AS NODE
GO


-- Create the edge from nodes Customers and StockItems
CREATE TABLE Bought
(
  [PurchasedCount] BIGINT
)
AS EDGE;
GO


-- Create FriendOf edge, which connects each customer 
-- to 3 other customers as 'friends'
CREATE TABLE FriendOf AS EDGE
GO



-------------------------------------------------------------------------------------
---- Populate StockItems table. 
-------------------------------------------------------------------------------------
SET IDENTITY_INSERT StockItems ON;
GO
INSERT INTO StockItems
(
  StockItemID,
  StockItemName,
  LastEditedBy
) SELECT
  StockItemID,
  StockItemName,
  LastEditedBy
FROM
  Warehouse.StockItems;
GO
SET IDENTITY_INSERT StockItems OFF;
GO


-------------------------------------------------------------------------------------
---- Populate Customers table. 
-------------------------------------------------------------------------------------
INSERT INTO Customers
(
  [CustomerID],
  [CustomerName],
  [WebsiteURL]
) SELECT
  [CustomerID],
  [CustomerName],
  [WebsiteURL]
FROM
  Sales.Customers;
GO


-------------------------------------------------------------------------------------
---- Populate Bought edge table. 
-------------------------------------------------------------------------------------
INSERT INTO Bought
(
  $from_id,
  $to_id,
  [PurchasedCount]
)
SELECT
  C.$node_id,
  P.$node_id,
  PurchasedCount = COUNT(OD.OrderLineID)
FROM
  Sales.OrderLines AS OD
JOIN
  Sales.Orders AS OH ON OH.OrderID = OD.OrderID
JOIN
  Customers AS C ON C.CustomerID = OH.CustomerID
JOIN
  StockItems AS P ON P.StockItemID = OD.StockItemID
GROUP BY
  C.$node_id, P.$node_id
GO

-------------------------------------------------------------------------------------
---- Populate FriendOf edge table. 
-------------------------------------------------------------------------------------
DECLARE @j INTEGER;
DECLARE @lower INTEGER;
DECLARE @upper INTEGER;
DECLARE @i INTEGER;
DECLARE @random INTEGER;

SET @upper = 1061
SET @i = 1
WHILE (@i <= @upper)
BEGIN
       SET @j = 0
       WHILE (@j < 3)
       BEGIN
              SELECT @random = ROUND(((@Upper - @i) * RAND() + @j), 0)
			  
			  INSERT FriendOf($from_id, $to_id)
              SELECT C1.$node_id, C2.$node_id
                FROM Customers AS C1, Customers AS C2
               WHERE C2.CustomerID = @random --$to_id
                 AND C1.CustomerID = @i		 --$from_id
			     SET @j = @j + 1
       END
       SET @i = @i + 1
END;
GO


-- Insert some fixed records in FriendOf table,
-- to be used later in shortest path query
INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1037
and C2.customerID = 1040
GO

INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1040
and C2.customerID = 1042
GO

INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1042
and C2.customerID = 1028
GO

INSERT INTO FriendOf($from_id, $to_id)
SELECT C1.$node_id , C2.$node_id
FROM Customers C1, Customers C2
where C1.customerID = 1028
and C2.customerID = 1054
GO


