-- Drop existing database if it exists
DROP DATABASE IF EXISTS AgricultureSupplyChain;
CREATE DATABASE AgricultureSupplyChain;
USE AgricultureSupplyChain;

-- Creating 
ProductCategories Table (First, no dependencies)
CREATE TABLE IF NOT EXISTS ProductCategories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Creating PaymentMethods Table
CREATE TABLE IF NOT EXISTS PaymentMethods (
    PaymentMethodID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Creating UserLogins Table
CREATE TABLE IF NOT EXISTS UserLogins (
    LoginID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    UserType ENUM('Farmer', 'Supplier', 'Buyer') NOT NULL,
    LoginTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    IPAddress VARCHAR(45),
    Status ENUM('Success', 'Failed') NOT NULL,
    DeviceInfo VARCHAR(255),
    CONSTRAINT chk_valid_ip CHECK (IPAddress REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$')
);

-- Creating Farmers Table with Enhanced Constraints
CREATE TABLE IF NOT EXISTS Farmers (
    FarmerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(50) NOT NULL UNIQUE,
    Location VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(20) UNIQUE,
    RegistrationDate DATE NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_farmer_valid_email CHECK (Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_farmer_valid_phone CHECK (Phone REGEXP '^[0-9]{10,15}$'),
    CONSTRAINT chk_farmer_valid_location CHECK (Location != '')
);

-- Creating Suppliers Table with Enhanced Constraints
CREATE TABLE IF NOT EXISTS Suppliers (
    SupplierID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Contact VARCHAR(50) NOT NULL UNIQUE,
    Location VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(20) UNIQUE,
    RegistrationDate DATE NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_supplier_valid_email CHECK (Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_supplier_valid_phone CHECK (Phone REGEXP '^[0-9]{10,15}$'),
    CONSTRAINT chk_supplier_valid_location CHECK (Location != '')
);

-- Creating Buyers Table with Enhanced Constraints
CREATE TABLE IF NOT EXISTS Buyers (
    BuyerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Contact VARCHAR(50) NOT NULL UNIQUE,
    Location VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(20) UNIQUE,
    RegistrationDate DATE NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_buyer_valid_email CHECK (Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_buyer_valid_phone CHECK (Phone REGEXP '^[0-9]{10,15}$'),
    CONSTRAINT chk_buyer_valid_location CHECK (Location != '')
);

-- Creating Products Table with Enhanced Constraints
CREATE TABLE IF NOT EXISTS Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Quantity INT NOT NULL DEFAULT 0,
    HarvestDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    PricePerKg DECIMAL(10,2) NOT NULL,
    FarmerID INT,
    SupplierID INT,
    CategoryID INT,
    QualityRating ENUM('Poor', 'Fair', 'Good', 'Excellent') DEFAULT 'Good',
    Certification VARCHAR(100),
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (FarmerID) REFERENCES Farmers(FarmerID) ON DELETE CASCADE,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE SET NULL,
    FOREIGN KEY (CategoryID) REFERENCES ProductCategories(CategoryID),
    CONSTRAINT chk_min_price CHECK (PricePerKg >= 0.1),
    CONSTRAINT chk_non_negative_quantity CHECK (Quantity >= 0),
    CONSTRAINT chk_valid_dates CHECK (ExpiryDate >= HarvestDate)
);

-- Creating Orders Table with Enhanced Constraints
CREATE TABLE IF NOT EXISTS Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    ProductID INT,
    BuyerID INT,
    PaymentMethodID INT,
    Quantity INT NOT NULL,
    OrderDate DATE NOT NULL,
    Status ENUM('Pending', 'Shipped', 'Delivered', 'Cancelled', 'Partially Fulfilled') DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),
    PaymentStatus ENUM('Pending', 'Paid', 'Overdue', 'Partially Paid') DEFAULT 'Pending',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    FOREIGN KEY (BuyerID) REFERENCES Buyers(BuyerID) ON DELETE CASCADE,
    FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID),
    CONSTRAINT chk_positive_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_valid_order_date CHECK (OrderDate <= CURDATE())
);

-- Creating Transportation Table with Enhanced Constraints
CREATE TABLE IF NOT EXISTS Transportation (
    TransportID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT,
    VehicleType VARCHAR(50) NOT NULL,
    DriverName VARCHAR(100) NOT NULL,
    DriverContact VARCHAR(20),
    ExpectedDelivery DATE NOT NULL,
    ActualDelivery DATE,
    Status ENUM('In Transit', 'Delivered', 'Delayed', 'Cancelled') DEFAULT 'In Transit',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT chk_valid_vehicle_type CHECK (VehicleType IN ('Pickup Truck', 'Lorry', 'Van', 'Container Truck', 'Refrigerated Truck')),
    CONSTRAINT chk_valid_driver_contact CHECK (DriverContact REGEXP '^[0-9]{10,15}$'),
    CONSTRAINT chk_valid_delivery_dates CHECK (ActualDelivery IS NULL OR ActualDelivery >= ExpectedDelivery)
);

-- Create AuditLog Table with Enhanced Fields
CREATE TABLE IF NOT EXISTS AuditLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50) NOT NULL,
    Action VARCHAR(50) NOT NULL,
    User VARCHAR(50) NOT NULL,
    OldValue JSON,
    NewValue JSON,
    IPAddress VARCHAR(45),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_valid_ip CHECK (IPAddress REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$')
);

-- Creating Indexes for Performance
CREATE INDEX idx_products_farmer ON Products(FarmerID);
CREATE INDEX idx_products_supplier ON Products(SupplierID);
CREATE INDEX idx_products_category ON Products(CategoryID);
CREATE INDEX idx_orders_product ON Orders(ProductID);
CREATE INDEX idx_orders_buyer ON Orders(BuyerID);
CREATE INDEX idx_orders_payment ON Orders(PaymentMethodID);
CREATE INDEX idx_transportation_order ON Transportation(OrderID);
CREATE INDEX idx_userlogins_user ON UserLogins(UserID, UserType);
CREATE INDEX idx_products_dates ON Products(HarvestDate, ExpiryDate);
CREATE INDEX idx_orders_dates ON Orders(OrderDate);
CREATE INDEX idx_transportation_dates ON Transportation(ExpectedDelivery, ActualDelivery);

-- Create Security and User Roles
CREATE ROLE IF NOT EXISTS farmer_role;
CREATE ROLE IF NOT EXISTS supplier_role;
CREATE ROLE IF NOT EXISTS buyer_role;
CREATE ROLE IF NOT EXISTS admin_role;

-- Grant Privileges to Roles
GRANT SELECT, INSERT, UPDATE ON Products TO farmer_role;
GRANT SELECT, INSERT, UPDATE ON Orders TO buyer_role;
GRANT SELECT ON Transportation TO supplier_role;
GRANT ALL PRIVILEGES ON AgricultureSupplyChain.* TO admin_role;

-- Create Users with Enhanced Security
CREATE USER IF NOT EXISTS 'farmer'@'localhost' IDENTIFIED WITH mysql_native_password BY 'farmerpass';
CREATE USER IF NOT EXISTS 'supplier'@'localhost' IDENTIFIED WITH mysql_native_password BY 'supplierpass';
CREATE USER IF NOT EXISTS 'buyer'@'localhost' IDENTIFIED WITH mysql_native_password BY 'buyerpass';
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED WITH mysql_native_password BY 'adminpass';

-- Assign Roles to Users
GRANT farmer_role TO 'farmer'@'localhost';
GRANT supplier_role TO 'supplier'@'localhost';
GRANT buyer_role TO 'buyer'@'localhost';
GRANT admin_role TO 'admin'@'localhost';

-- Set Default Roles
SET DEFAULT ROLE farmer_role TO 'farmer'@'localhost';
SET DEFAULT ROLE supplier_role TO 'supplier'@'localhost';
SET DEFAULT ROLE buyer_role TO 'buyer'@'localhost';
SET DEFAULT ROLE admin_role TO 'admin'@'localhost';

-- Create Enhanced Triggers
DELIMITER //

-- Product Date Validation
CREATE TRIGGER validate_product_dates
BEFORE INSERT ON Products
FOR EACH ROW
BEGIN
    IF NEW.ExpiryDate < NEW.HarvestDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Expiry date cannot be before harvest date';
    END IF;
END //

-- Order Validation
CREATE TRIGGER validate_order
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE available_quantity INT;
    SELECT Quantity INTO available_quantity
    FROM Products
    WHERE ProductID = NEW.ProductID;
    
    IF NEW.Quantity > available_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order quantity exceeds available product quantity';
    END IF;
END //

-- Price Update Validation
CREATE TRIGGER validate_price_update
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
    IF NEW.PricePerKg < 0.1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Price per kg cannot be less than 0.1';
    END IF;
END //

-- Quantity Update Validation
CREATE TRIGGER validate_quantity_update
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
    IF NEW.Quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product quantity cannot be negative';
    END IF;
END //

-- Audit Logging
CREATE TRIGGER audit_product_changes
AFTER UPDATE ON Products
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, Action, User, OldValue, NewValue, IPAddress)
    VALUES ('Products', 'UPDATE', CURRENT_USER(),
            JSON_OBJECT('ProductID', OLD.ProductID, 'Price', OLD.PricePerKg, 'Quantity', OLD.Quantity),
            JSON_OBJECT('ProductID', NEW.ProductID, 'Price', NEW.PricePerKg, 'Quantity', NEW.Quantity),
            SUBSTRING_INDEX(USER(), '@', 1));
END //

-- Failed Login Tracking
CREATE TRIGGER track_failed_login
AFTER INSERT ON UserLogins
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Failed' THEN
        INSERT INTO AuditLog (TableName, Action, User, IPAddress)
        VALUES ('UserLogins', 'Failed Login', CONCAT(NEW.UserType, ' ID: ', NEW.UserID), NEW.IPAddress);
    END IF;
END //

DELIMITER ;

-- Create Enhanced Stored Procedures
DELIMITER //

-- Get Seasonal Products
CREATE PROCEDURE GetSeasonalProducts(IN season VARCHAR(20))
BEGIN
    SELECT p.Name, p.Quantity, p.PricePerKg, f.Name AS Farmer, c.Name AS Category
    FROM Products p
    JOIN Farmers f ON p.FarmerID = f.FarmerID
    JOIN ProductCategories c ON p.CategoryID = c.CategoryID
    WHERE MONTH(p.HarvestDate) BETWEEN 
        CASE season
            WHEN 'Dry' THEN 1 AND 3
            WHEN 'Rainy' THEN 4 AND 6
            WHEN 'Harvest' THEN 7 AND 9
            WHEN 'Planting' THEN 10 AND 12
        END;
END //

-- Adjust Seasonal Prices
CREATE PROCEDURE AdjustSeasonalPrices(IN season VARCHAR(20), IN adjustment_factor DECIMAL(3,2))
BEGIN
    START TRANSACTION;
    UPDATE Products p
    SET p.PricePerKg = p.PricePerKg * adjustment_factor
    WHERE MONTH(p.HarvestDate) BETWEEN 
        CASE season
            WHEN 'Dry' THEN 1 AND 3
            WHEN 'Rainy' THEN 4 AND 6
            WHEN 'Harvest' THEN 7 AND 9
            WHEN 'Planting' THEN 10 AND 12
        END;
    COMMIT;
END //

-- Process Bulk Order
CREATE PROCEDURE ProcessBulkOrder(
    IN product_ids JSON,
    IN quantities JSON,
    IN buyer_id INT,
    IN payment_method_id INT
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE product_count INT;
    DECLARE current_product_id INT;
    DECLARE current_quantity INT;
    
    SET product_count = JSON_LENGTH(product_ids);
    
    START TRANSACTION;
    
    WHILE i < product_count DO
        SET current_product_id = JSON_EXTRACT(product_ids, CONCAT('$[', i, ']'));
        SET current_quantity = JSON_EXTRACT(quantities, CONCAT('$[', i, ']'));
        
        INSERT INTO Orders (ProductID, BuyerID, PaymentMethodID, Quantity, OrderDate)
        VALUES (current_product_id, buyer_id, payment_method_id, current_quantity, CURDATE());
        
        SET i = i + 1;
    END WHILE;
    
    COMMIT;
END //

-- Generate Backup Script
CREATE PROCEDURE GenerateBackupScript()
BEGIN
    SELECT CONCAT('mysqldump -u [username] -p AgricultureSupplyChain > /backups/agriculture_backup_', 
           DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql') AS BackupCommand;
END //

DELIMITER ;

-- Create Enhanced Views
CREATE VIEW ProductCategorySummary AS
SELECT 
    c.Name AS Category,
    COUNT(p.ProductID) AS ProductCount,
    SUM(p.Quantity) AS TotalQuantity,
    AVG(p.PricePerKg) AS AveragePrice,
    MIN(p.HarvestDate) AS EarliestHarvest,
    MAX(p.ExpiryDate) AS LatestExpiry
FROM ProductCategories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.Name;

CREATE VIEW OrderStatusReport AS
SELECT 
    o.OrderID,
    p.Name AS ProductName,
    b.Name AS BuyerName,
    o.Quantity,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    o.PaymentStatus,
    t.Status AS TransportStatus,
    t.ExpectedDelivery,
    t.ActualDelivery
FROM Orders o
JOIN Products p ON o.ProductID = p.ProductID
JOIN Buyers b ON o.BuyerID = b.BuyerID
LEFT JOIN Transportation t ON o.OrderID = t.OrderID;

CREATE VIEW PaymentMethodUsage AS
SELECT 
    pm.Name AS PaymentMethod,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalAmount,
    AVG(o.TotalAmount) AS AverageAmount
FROM PaymentMethods pm
LEFT JOIN Orders o ON pm.PaymentMethodID = o.PaymentMethodID
GROUP BY pm.PaymentMethodID, pm.Name;

-- Insert Sample Data
-- Product Categories
INSERT INTO ProductCategories (Name, Description) VALUES
('Fruits', 'Fresh fruits and produce'),
('Grains', 'Cereals and grains'),
('Vegetables', 'Fresh vegetables'),
('Legumes', 'Beans and pulses'),
('Coffee', 'Coffee beans and products');

-- Payment Methods
INSERT INTO PaymentMethods (Name, Description) VALUES
('Mobile Money', 'Payment through mobile money services'),
('Bank Transfer', 'Direct bank transfer'),
('Cash on Delivery', 'Payment upon delivery'),
('Credit Card', 'Payment via credit card'),
('Cheque', 'Payment by cheque');

-- Rest of the sample data remains the same...
