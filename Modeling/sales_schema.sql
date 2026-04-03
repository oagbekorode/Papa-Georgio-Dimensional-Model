/* Student:  Emmanuel 
Sales & Marketing Module (sales_schema.sql)
	You focus on the Who, What, Where, and Why of the core revenue process.

--> Fact Table: Create an Atomic Transaction Fact Table for individual sales transactions.

--> Dimensions:
- Product: Design a Snowflake schema for the product hierarchy (Category > Sub-category > Item).
- Promotion: Model this as the "Why" dimension to track holiday spikes and localized coupons.
- Location: Build a balanced hierarchy for Region, State, and Store.

Analysis Support: Ensure the model can compare food vs. non-food merchandise sales and calculate total revenue.
*/ 

-- Create the Sales Schema
-- CREATE DATABASE SandBox_PapaGeorgio_DW;

USE SandBox_PapaGeorgio_DW;

-- Snowflake Schema for Product Hierarchy
-- 1. Top Level: Category
CREATE TABLE Dim_Category (
    CategoryKey INT PRIMARY KEY,
    CategoryName VARCHAR(50) -- e.g., 'Food', 'Retail Merchandise'
);

-- 2. Middle Level: Sub-Category
CREATE TABLE Dim_SubCategory (
    SubCategoryKey INT PRIMARY KEY,
    CategoryKey INT,
    SubCategoryName VARCHAR(50), -- e.g., 'Pizza', 'Apparel'
    FOREIGN KEY (CategoryKey) REFERENCES Dim_Category(CategoryKey)
);

-- 3. Base Level: Product (The "What")
CREATE TABLE Dim_Product (
    ProductKey INT PRIMARY KEY,
    SubCategoryKey INT,
    ProductName VARCHAR(100),
    UnitPrice DECIMAL(10,2),
    IsFoodItem BIT, -- for Food vs. Non-Food analysis
    FOREIGN KEY (SubCategoryKey) REFERENCES Dim_SubCategory(SubCategoryKey)
); 

-- Promotion Dimension (The "Why")
CREATE TABLE Dim_Promotion (
    PromotionKey INT PRIMARY KEY, -- Surrogate Key
    PromotionID VARCHAR(20),       -- Natural Key from source system
    PromotionName VARCHAR(100),    -- e.g., 'BOGO Pizza', 'Grand Opening 20%'
    PromotionType VARCHAR(50),    -- e.g., 'Holiday', 'Manager Special', 'Coupon' [cite: 30]
    DiscountType VARCHAR(20),     -- e.g., 'Percentage', 'Fixed Amount'
    DiscountValue DECIMAL(10,2),
    StartDate DATE,
    EndDate DATE
);

-- Location Dimension (The "Where")
CREATE TABLE Dim_Location (
    LocationKey INT PRIMARY KEY, -- Surrogate Key for the Data Warehouse
    StoreID INT NOT NULL,        -- Natural Key from the source system
    StoreName VARCHAR(100),
    StoreType VARCHAR(20),       -- e.g., 'Kiosk', 'Full Restaurant'
    Address VARCHAR(255),
    City VARCHAR(50),
    State VARCHAR(50),
    ZipCode VARCHAR(10),
    Region VARCHAR(50),          -- e.g., 'Southeast', 'Midwest', 'West'
    Country VARCHAR(50) DEFAULT 'USA'
);

-- Fact Table: Sales Transactions
-- Atomic Transaction Fact Table: sales 
CREATE TABLE Fact_Sales (
    SalesKey BIGINT PRIMARY KEY IDENTITY(1,1), -- Unique ID for each sale
    -- Foreign Keys to Dimensions
    DateKey INT NOT NULL,          -- Links to Shared Date (When)
    ProductKey INT NOT NULL,       -- Links to Snowflake Product (What)
    LocationKey INT NOT NULL,      -- Links to Balanced Location (Where)
    PromotionKey INT NOT NULL,     -- Links to Promotion (Why)
    CustomerKey INT NOT NULL,      -- Links to Student 2's Customer (Who)
    
    -- Degenerate Dimension (Standard in Atomic Facts)
    TransactionID VARCHAR(50),     -- Receipt or Order Number [cite: 68]
    SalesChannel VARCHAR(20),      -- dine-in, delivery, online [cite: 17, 60]

    -- Additive Measures 
    Quantity INT NOT NULL,
    GrossRevenue DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    NetRevenue AS (GrossRevenue - DiscountAmount), -- Calculated Non-additive measure 
    TaxAmount DECIMAL(18,2),
    
    -- Constraints to ensure data integrity
    CONSTRAINT FK_FactSales_Product FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey),
    CONSTRAINT FK_FactSales_Location FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey),
    CONSTRAINT FK_FactSales_Promotion FOREIGN KEY (PromotionKey) REFERENCES Dim_Promotion(PromotionKey)
);