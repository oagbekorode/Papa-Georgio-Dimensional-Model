/* -- Rijesh 
You focus on Efficiency and Resource Management at specific points in time.
 
--> Fact Table: Create a Periodic Snapshot Fact Table that captures inventory levels or staffing status at the end of each day/week.
 
--> Dimensions:
- Employee: Implement a Slowly Changing Dimension (SCD Type 1) to track employee performance and service speed.
- Organization: Model an Unbalanced Hierarchy for the company's internal management reporting structure.
 
Metric Grain: Ensure this fact table has a different grain (e.g., daily summary) than the transaction-level tables used by the other students.
*/
 
-- Create the Inventory/Operations Schema
-- CREATE DATABASE SandBox_PapaGeorgio_DW;
USE SandBox_PapaGeorgio_DW;
 
 
-- ============================================================
-- EMPLOYEE DIMENSION (SCD Type 1)
-- Tracks employee info and performance metrics.
-- SCD Type 1: overwrite old values, no history kept.
-- ============================================================
CREATE TABLE Dim_Employee (
    EmployeeKey INT PRIMARY KEY IDENTITY(1,1),  -- Surrogate Key
    EmployeeID VARCHAR(20) NOT NULL,             -- Natural Key from source system
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(25),
    JobTitle VARCHAR(50),         -- e.g., 'Cook', 'Cashier', 'Delivery Driver', 'Manager'
    EmploymentType VARCHAR(20),   -- e.g., 'Full-Time', 'Part-Time'
    HireDate DATE,
    TerminationDate DATE NULL,    -- NULL if still employed
    IsActive BIT DEFAULT 1,
    LocationKey INT,              -- Which store this employee is assigned to
 
    -- Performance Metrics (SCD Type 1 -- overwritten in place when updated)
    AvgServiceSpeedMinutes DECIMAL(5,2),  -- Average time to fulfill an order
    CustomerSatisfactionScore DECIMAL(3,2), -- e.g., 4.75 out of 5.00
    TotalOrdersHandled INT DEFAULT 0,
 
    CONSTRAINT UQ_DimEmployee UNIQUE (EmployeeID),
 
    CONSTRAINT FK_DimEmployee_Location
        FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey)
);
 
 
-- ============================================================
-- ORGANIZATION DIMENSION (Unbalanced Hierarchy)
-- Models the internal management reporting structure.
-- Unbalanced because not every node is at the same depth --
-- e.g., some stores report directly to a regional manager,
-- others go through an area supervisor first.
-- Uses a self-referencing ParentOrgKey for flexibility.
-- ============================================================
CREATE TABLE Dim_Organization (
    OrgKey INT PRIMARY KEY IDENTITY(1,1),   -- Surrogate Key
    OrgID VARCHAR(20) NOT NULL,             -- Natural Key
    OrgName VARCHAR(100),                   -- e.g., 'Corporate HQ', 'Southeast Region', 'Store #14'
    OrgLevel VARCHAR(30),                   -- e.g., 'Corporate', 'Region', 'Area', 'Store'
    OrgLevelNumber INT,                     -- e.g., 1=Corporate, 2=Region, 3=Area, 4=Store
    ParentOrgKey INT NULL,                  -- Self-referencing FK -- NULL for top-level (Corporate)
    ManagerEmployeeID VARCHAR(20) NULL,     -- Natural Key of the manager at this org node
    IsLeafNode BIT DEFAULT 0,              -- 1 if this is a store (bottom of hierarchy)
 
    CONSTRAINT UQ_DimOrganization UNIQUE (OrgID),
 
    CONSTRAINT FK_DimOrganization_Parent
        FOREIGN KEY (ParentOrgKey) REFERENCES Dim_Organization(OrgKey)
);
 
 
-- ============================================================
-- PERIODIC SNAPSHOT FACT TABLE
-- Grain: One row per store per day capturing end-of-day
-- inventory levels and staffing counts.
-- This is intentionally a daily summary grain -- different
-- from the transaction-level grain in Fact_Sales and 
-- the order-level grain in Fact_OrderLifecycle.
-- ============================================================
CREATE TABLE Fact_DailyOperationsSnapshot (
    SnapshotKey BIGINT PRIMARY KEY IDENTITY(1,1),
 
    -- Foreign Keys to Dimensions
    DateKey INT NOT NULL,           -- End-of-day snapshot date (links to Dim_Date)
    LocationKey INT NOT NULL,       -- Which store this snapshot is for
    OrgKey INT NOT NULL,            -- Organization node this store belongs to
 
    -- Staffing Metrics (Semi-Additive -- meaningful to sum across stores, not across time)
    TotalEmployeesScheduled INT,
    TotalEmployeesPresent INT,
    FullTimeCount INT,
    PartTimeCount INT,
    NoShowCount INT,
 
    -- Inventory Metrics (Semi-Additive)
    TotalInventoryItemsOnHand INT,
    FoodItemsOnHand INT,
    NonFoodItemsOnHand INT,
    ItemsWasted INT,                -- Food waste count for the day
    ItemsRestocked INT,             -- Items added to inventory during the day
 
    -- Operational Metrics (Additive -- can be summed across stores and time)
    TotalOrdersPlaced INT,
    TotalOrdersCompleted INT,
    TotalOrdersCancelled INT,
    TotalOrdersRefunded INT,
    PeakHourOrderCount INT,         -- Max orders in any single hour that day
 
    -- Financial Metrics (Additive)
    TotalLaborCostForDay DECIMAL(18,2),
    TotalInventoryCostForDay DECIMAL(18,2),
    EstimatedWasteCost DECIMAL(18,2),   -- Cost of wasted food items
 
    -- Non-Additive Metrics (ratios -- do not sum these)
    InventoryTurnoverRate DECIMAL(8,4),     -- Items sold / avg items on hand
    StaffUtilizationRate DECIMAL(5,2),      -- Present / Scheduled * 100
    OrderCompletionRate DECIMAL(5,2),       -- Completed / Placed * 100
 
    -- Constraints
    CONSTRAINT FK_DailyOps_Date
        FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
 
    CONSTRAINT FK_DailyOps_Location
        FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey),
 
    CONSTRAINT FK_DailyOps_Org
        FOREIGN KEY (OrgKey) REFERENCES Dim_Organization(OrgKey),
 
    -- Each store should only have one snapshot per day
    CONSTRAINT UQ_DailyOps_StoreDate UNIQUE (DateKey, LocationKey)
);
