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
    IsFoodItem BIT, -- Crucial for 'Food vs Non-Food' analysis requirement
    FOREIGN KEY (SubCategoryKey) REFERENCES Dim_SubCategory(SubCategoryKey)
);