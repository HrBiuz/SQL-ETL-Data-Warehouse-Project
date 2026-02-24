/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    Builds the 'DataWarehouse' database with 'landing', 'staging', and 'production' schemas.
    Removes existing database if present before creating a fresh instance.
	
WARNING:
    Running this deletes all data in 'DataWarehouse' permanently. 
    Back up your data first.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA landing;
GO

CREATE SCHEMA staging;
GO

CREATE SCHEMA production;
GO
