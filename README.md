# GraphRecursiveQueries
SQL Server 2017 and Azure SQL Database now let you create a graph database, to hold your entities and complex many to many relationships. There are several examples on github which demonstrate how the new graph features work. This example is an extension to [Recommendation System](https://github.com/Microsoft/sql-server-samples/tree/master/samples/demos/sql-graph/recommendation-system) example developed by [Sergio Govoni](https://mvp.microsoft.com/it-it/PublicProfile/4029181?fullName=Sergio%20Govoni). This sample demonstrates:

 - How you can write recursive queries in SQL Graph
 - How you can find shortest path between 2 entities in your graph

To demonstrate the functionality, we will be using WideWorldImporters as our sample database.  

## Contents
[About this sample](#about-this-sample)
[Before you begin](#before-you-begin)
[Run this sample](#run-this-sample)  
[Disclaimers](#disclaimers)  
[Related links](#related-links)

## About this sample
1.  **Applies to:**
    -   Azure SQL Database v12 (or higher)
    -   SQL Server 2017 (or higher)
2.  **Demos:**
    -   Build and populate graph node and edge tables
    -   Friends of Friends query or arbitrary number of hops query in SQL Graph
    -   Finding shortest path between 2 entities in SQL Graph
3.  **Workload:**  Queries executed on  [WideWorldImporters](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0)
4.  **Programming Language:**  T-SQL
5.  **Author:**  Shreya Verma

## Before you begin
To run these demo scripts, you need the following prerequisites.

**Account and Software prerequisites:**

1.  Either
    -   Azure SQL Database v12 (or higher)
    -   SQL Server 2017 (or higher)
2.  SQL Server Management Studio 17.x (or higher)

**Azure prerequisites:**

1.  An Azure subscription. If you don't already have an Azure subscription, you can get one for free here:  [get Azure free trial](https://azure.microsoft.com/en-us/free/)
    
2.  When your Azure subscription is ready to use, you have to create an Azure SQL Database, to do that, you must have completed the first three steps explained in  [Design your first Azure SQL database](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-design-first-database)

## Run This Sample

### Setup
#### Azure SQL Database Setup

1.  Download the  **WideWorldImporters-Standard.bacpac**  from the WideWorldImporters database  [page](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0)
    
2.  Import the  **WideWorldImporters-Standard.bacpac**  bacpac file to your Azure subscription. [This document](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-import) describes how you can restore a bacpac file to your Azure SQL Database.
    
3.  Launch SQL Server Management Studio and connect to the newly created WideWorldImporters database
    

#### SQL Server Setup

1.  Download  [**WideWorldImporters-Full.bak**](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0)
    
2.  Launch SQL Server Management Studio, connect to your SQL Server instance (2017) and restore  **WideWorldImporters-Full.bak**.  This document describes how to [Restore a Database Backup Using SSMS](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-database-backup-using-ssms). 

Once the database is restore, run the [setup file](https://github.com/shkale-msft/GraphRecursiveQueries/blob/master/setup-wwi-graph.sql) to create the necessary graph node and edge tables. We will be using these tables to run our sample queries. The setup file creates the following graph schema

![Recursive Query Schema](https://github.com/shkale-msft/GraphRecursiveQueries/blob/master/media/GraphRecursiveQueriesSchema.png)


Run the [GraphQueries-wwi.sql](https://github.com/shkale-msft/GraphRecursiveQueries/blob/master/GraphQueries-wwi.sql) file to run the recursive and shortest path queries. This script file has 3 example quereis:

 1. A simple MATCH query, which demonstrates how MATCH works in SQL Graph
 2. A query which does arbitrary number of hops to find friend-of-friend. It will find friends of a customer (in this case customer# 11) upto 3 hops away. If you set the @MaxHops to 5 or 10, it will find the friends up to 5 or 10 hops away, respectively.
 3. The third query is a simple implementation of Dijkastra's Breadth First Search Algorithm, using T-SQL. It uses the MATCH syntax for finding immediate friends of a person. In this query, we are trying to find shortest path  between 2 people (Emma and David) in the graph. We start with David, find immediate friends of David and check if Emma is in the list. If not, we store the first level friends in a temporary table and in the next loop, find the immediate friends of these people. We continue searching until we find Emma. As soon as Emma is found in the graph, we break from the loop and return the results to the user.
