-- CREATE DATABASE PapaGeorgioDimensionalModel;
use PapaGeorgioDimensionalModel;

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


-- Create the Date Dimension
CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY, -- e.g., 20240601 for June 1, 2024
    FullDate DATE NOT NULL,
    DayNumberOfWeek INT,
    DayNameOfWeek VARCHAR(20),
    DayNumberOfMonth INT,
    MonthNumber INT,
    MonthName VARCHAR(20),
    QuarterNumber INT,
    YearNumber INT,
    IsWeekend BIT,
    IsHoliday BIT
);

-- Create the Time Dimension
CREATE TABLE Dim_Time (
    TimeKey INT PRIMARY KEY, -- e.g., 1300 for 1:00 PM
    FullTime TIME NOT NULL,
    Hour24 INT,
    MinuteNumber INT,
    SecondNumber INT,
    AMPM VARCHAR(2),
    TimeOfDayBucket VARCHAR(20) -- e.g., 'Morning', 'Afternoon', 'Evening', 'Night'
);

-- Create the Customer Dimension with SCD Type 2
CREATE TABLE Dim_Customer (
    CustomerKey INT PRIMARY KEY IDENTITY(1,1), -- Surrogate Key
    CustomerID VARCHAR(20) NOT NULL, -- Natural Key from source system
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(25),
    Gender VARCHAR(20),
    BirthDate DATE,
    AgeGroup VARCHAR(20), -- e.g., '18-25', '26-35', '36-45', '46-60'
    City VARCHAR(50),
    State VARCHAR(50),
    ZipCode VARCHAR(10),
    LoyaltyTier VARCHAR(30), -- e.g., 'Bronze', 'Silver', 'Gold', 'Platinum'
    DemographicSegment VARCHAR(50), -- e.g., 'Student', 'Families', 'Retirees'

    -- SCD Type 2 Fields
    EffectiveStartDate DATE NOT NULL,
    EffectiveEndDate DATE NULL,
    IsCurrent BIT NOT NULL DEFAULT 1,

    CONSTRAINT UQ_DimCustomer UNIQUE (CustomerID, EffectiveStartDate)
);

-- Create the Loyalty Account Dimension
CREATE TABLE Dim_LoyaltyAccount (
    LoyaltyAccountKey INT PRIMARY KEY IDENTITY(1,1), -- Surrogate Key
    LoyaltyAccountID VARCHAR(20) NOT NULL, -- Natural Key
    AccountName VARCHAR(100), -- e.g., 'Smith Family Account', 'John Smith Personal Account'
    LoyaltyProgramName VARCHAR(100),
    EnrollmentDate DATE,
    AccountStatus VARCHAR(20), -- e.g., 'Active', 'Inactive', 'Closed'
    PointsBalance INT,
    CONSTRAINT UQ_DimLoyaltyAccount UNIQUE (LoyaltyAccountID)
);

-- Create the Location Dimension
-- Bridge table for many-to-many relationship between Customers and Loyalty Accounts
CREATE TABLE Bridge_LoyaltyAccount_Customer (
    LoyaltyAccountKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    RelationshipType VARCHAR(30), -- e.g., 'Primary Account Holder', 'Family Member', 'Friend'
    AllocationPercent DECIMAL(5,2) DEFAULT 100.00, -- For shared accounts, how points are allocated

    PRIMARY KEY (LoyaltyAccountKey, CustomerKey),

    CONSTRAINT FK_Bridge_LoyaltyAccount
        FOREIGN KEY (LoyaltyAccountKey) REFERENCES Dim_LoyaltyAccount(LoyaltyAccountKey),

    CONSTRAINT FK_Bridge_Customer
        FOREIGN KEY (CustomerKey) REFERENCES Dim_Customer(CustomerKey)
);

-- Create the Accumulating Snapshot Fact Table for Order Lifecycle
CREATE TABLE Fact_OrderLifecycle (
    OrderLifecycleKey BIGINT PRIMARY KEY IDENTITY(1,1),

    -- Natural business key for the order, e.g., receipt number or order ID
    OrderID VARCHAR(30) NOT NULL,

    -- Foreign Keys to Dimensions
    CustomerKey INT NOT NULL,
    LoyaltyAccountKey INT NULL,
    LocationKey INT NOT NULL,

    -- Role-playing Date Keys to track the lifecycle of an order
    OrderDateKey INT NOT NULL,
    PrepStartDateKey INT NULL,
    ReadyDateKey INT NULL,
    PickupDateKey INT NULL,
    DeliveryDateKey INT NULL,
    CancelDateKey INT NULL,

    -- Role-playing Time Keys to track the lifecycle of an order
    OrderTimeKey INT NOT NULL,
    PrepStartTimeKey INT NULL,
    ReadyTimeKey INT NULL,
    PickupTimeKey INT NULL,
    DeliveryTimeKey INT NULL,
    CancelTimeKey INT NULL,

    -- Order Details
    OrderChannel VARCHAR(20), -- e.g., 'Mobile App', 'Website', 'In-Person'
    OrderStatus VARCHAR(20), -- e.g., 'Placed', 'Preparing', 'Ready', 'Out for Delivery', 'Delivered', 'Cancelled'
    DeliveryType VARCHAR(20), -- e.g., 'Pickup', 'Delivery'

    -- Financial Metrics
    ItemCount INT,
    OrderSubtotal DECIMAL(18,2),
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    DeliveryFee DECIMAL(18,2) DEFAULT 0,
    OrderTotal DECIMAL(18,2),

    -- Time Metrics (in minutes)
    MinutesToPrepare INT NULL,
    MinutesToReady INT NULL,
    MinutesToPickup INT NULL,
    MinutesToDeliver INT NULL,
    TotalFulfillmentMinutes INT NULL,
    
    -- Flags to track order lifecycle stages
    IsDelivered BIT DEFAULT 0,
    IsPickedUp BIT DEFAULT 0,
    IsCancelled BIT DEFAULT 0,
    
    -- Constraints to ensure data integrity
    CONSTRAINT FK_FactOrderLifecycle_Customer FOREIGN KEY (CustomerKey) REFERENCES Dim_Customer(CustomerKey),

    CONSTRAINT FK_FactOrderLifecycle_LoyaltyAccount FOREIGN KEY (LoyaltyAccountKey) REFERENCES Dim_LoyaltyAccount(LoyaltyAccountKey),

    CONSTRAINT FK_FactOrderLifecycle_Location FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey),

    CONSTRAINT FK_FactOrderLifecycle_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES Dim_Date(DateKey),

    CONSTRAINT FK_FactOrderLifecycle_DeliveryDate FOREIGN KEY (DeliveryDateKey) REFERENCES Dim_Date(DateKey),

    CONSTRAINT FK_FactOrderLifecycle_OrderTime FOREIGN KEY (OrderTimeKey) REFERENCES Dim_Time(TimeKey),

    CONSTRAINT FK_FactOrderLifecycle_DeliveryTime FOREIGN KEY (DeliveryTimeKey) REFERENCES Dim_Time(TimeKey)
    
);

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
