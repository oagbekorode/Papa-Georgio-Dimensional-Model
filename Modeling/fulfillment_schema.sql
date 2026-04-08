/* --Katty
You manage the Order Lifecycle and long-term customer relationships.

--> Fact Table: Create an Accumulating Snapshot Fact Table to track an order from placement to delivery.

--> Dimensions:

- Customer: Implement a Slowly Changing Dimension (SCD Type 2) to track changes in loyalty tiers or demographics over time.
- Date/Time: Develop Role-playing dimensions so the same Date table can represent "Order Date" and "Delivery Date".

Special Logic: Include a Bridge Table to handle many-to-many relationships, such as multiple customers sharing a single loyalty account.
*/

-- Create the Fulfillment Schema
-- CREATE DATABASE SandBox_PapaGeorgio_DW;
USE SandBox_PapaGeorgio_DW;

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