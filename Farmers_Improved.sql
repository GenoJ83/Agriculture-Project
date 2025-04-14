-- Agriculture Supply Chain Database 
DROP DATABASE IF EXISTS AgricultureSupplyChain;
CREATE DATABASE AgricultureSupplyChain;
USE AgricultureSupplyChain;

-- Create ProductCategories Table (First, no dependencies)
CREATE TABLE IF NOT EXISTS ProductCategories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create PaymentMethods Table
CREATE TABLE IF NOT EXISTS PaymentMethods (
    PaymentMethodID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create UserLogins Table
CREATE TABLE IF NOT EXISTS UserLogins (
    LoginID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    UserType ENUM('Farmer', 'Supplier', 'Buyer') NOT NULL,
    LoginTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Success', 'Failed') NOT NULL,
    DeviceInfo VARCHAR(255)
);

-- Create Farmers Table with Enhanced Constraints
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

-- Create Suppliers Table with Enhanced Constraints
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

-- Create Buyers Table with Enhanced Constraints
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

-- Create Products Table with Enhanced Constraints
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

-- Create Orders Table with Enhanced Constraints
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
    CONSTRAINT chk_positive_quantity CHECK (Quantity > 0)
);

-- Create Transportation Table with Enhanced Constraints
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
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes for Performance
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
SET DEFAULT ROLE farmer_role FOR 'farmer'@'localhost';
SET DEFAULT ROLE supplier_role FOR 'supplier'@'localhost';
SET DEFAULT ROLE buyer_role FOR 'buyer'@'localhost';
SET DEFAULT ROLE admin_role FOR 'admin'@'localhost';

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
    INSERT INTO AuditLog (TableName, Action, User, OldValue, NewValue)
    VALUES ('Products', 'UPDATE', CURRENT_USER(),
            JSON_OBJECT('ProductID', OLD.ProductID, 'Price', OLD.PricePerKg, 'Quantity', OLD.Quantity),
            JSON_OBJECT('ProductID', NEW.ProductID, 'Price', NEW.PricePerKg, 'Quantity', NEW.Quantity));
END //

-- Failed Login Tracking
CREATE TRIGGER track_failed_login
AFTER INSERT ON UserLogins
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Failed' THEN
        INSERT INTO AuditLog (TableName, Action, User)
        VALUES ('UserLogins', 'Failed Login', CONCAT(NEW.UserType, ' ID: ', NEW.UserID));
    END IF;
END //

-- Order Date Validation
CREATE TRIGGER validate_order_date
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    IF NEW.OrderDate > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order date cannot be in the future';
    END IF;
END //

CREATE TRIGGER validate_order_date_update
BEFORE UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.OrderDate > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order date cannot be in the future';
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

-- Insert Farmers with enhanced data
INSERT INTO Farmers (Name, Contact, Location, Email, Phone, RegistrationDate) VALUES
('James Kivumbi', 'james.kivumbi@ug.farm', 'Kampala, Central Region', 'james.kivumbi@ug.farm', '256701234567', '2024-01-01'),
('Grace Namazzi', 'grace.namazzi@ug.farm', 'Jinja, Eastern Region', 'grace.namazzi@ug.farm', '256702345678', '2024-01-02'),
('Peter Mugisa', 'peter.mugisa@ug.farm', 'Mbarara, Western Region', 'peter.mugisa@ug.farm', '256703456789', '2024-01-03'),
('Sarah Nambooze', 'sarah.nambooze@ug.farm', 'Lira, Northern Region', 'sarah.nambooze@ug.farm', '256704567890', '2024-01-04'),
('Moses Byaruhanga', 'moses.byaruhanga@ug.farm', 'Gulu, Northern Region', 'moses.byaruhanga@ug.farm', '256705678901', '2024-01-05'),
('Esther Nakimuli', 'esther.nakimuli@ug.farm', 'Masaka, Central Region', 'esther.nakimuli@ug.farm', '256706789012', '2024-01-06'),
('Samuel Tumwine', 'samuel.tumwine@ug.farm', 'Kabale, Western Region', 'samuel.tumwine@ug.farm', '256707890123', '2024-01-07'),
('Ruth Katusiime', 'ruth.katusiime@ug.farm', 'Soroti, Eastern Region', 'ruth.katusiime@ug.farm', '256708901234', '2024-01-08'),
('Isaac Muwanga', 'isaac.muwanga@ug.farm', 'Arua, Northern Region', 'isaac.muwanga@ug.farm', '256709012345', '2024-01-09'),
('Jane Nakato', 'jane.nakato@ug.farm', 'Hoima, Western Region', 'jane.nakato@ug.farm', '256700123456', '2024-01-10');

-- Insert Suppliers with enhanced data
INSERT INTO Suppliers (Name, Contact, Location, Email, Phone, RegistrationDate) VALUES
('Uganda Agro Traders', 'sales@ugandagro.com', 'Kampala, Central Region', 'sales@ugandagro.com', '256711234567', '2024-01-01'),
('Eastern Fresh Supplies', 'info@easternfresh.ug', 'Mbale, Eastern Region', 'info@easternfresh.ug', '256712345678', '2024-01-02'),
('Western Farm Logistics', 'contact@westernfarm.ug', 'Fort Portal, Western Region', 'contact@westernfarm.ug', '256713456789', '2024-01-03'),
('Northern Agri Solutions', 'info@northernagri.ug', 'Lira, Northern Region', 'info@northernagri.ug', '256714567890', '2024-01-04'),
('Central Harvest Co.', 'sales@centralharvest.ug', 'Masaka, Central Region', 'sales@centralharvest.ug', '256715678901', '2024-01-05'),
('Southern Traders Ltd.', 'contact@southerntraders.ug', 'Mbarara, Western Region', 'contact@southerntraders.ug', '256716789012', '2024-01-06'),
('Eastern Agri Hub', 'contact@easternagri.ug', 'Soroti, Eastern Region', 'contact@easternagri.ug', '256717890123', '2024-01-07'),
('Northern Supply Co.', 'sales@northernsupply.ug', 'Arua, Northern Region', 'sales@northernsupply.ug', '256718901234', '2024-01-08'),
('Western Logistics Ltd.', 'info@westernlogistics.ug', 'Hoima, Western Region', 'info@westernlogistics.ug', '256719012345', '2024-01-09'),
('Central Agro Services', 'support@centralagro.ug', 'Kampala, Central Region', 'support@centralagro.ug', '256710123456', '2024-01-10');

-- Insert Buyers with enhanced data
INSERT INTO Buyers (Name, Contact, Location, Email, Phone, RegistrationDate) VALUES
('Kampala Market Ltd.', 'purchasing@kampalamarket.ug', 'Kampala, Central Region', 'purchasing@kampalamarket.ug', '256721234567', '2024-01-01'),
('Jinja Co-operative', 'orders@jinjacoop.ug', 'Jinja, Eastern Region', 'orders@jinjacoop.ug', '256722345678', '2024-01-02'),
('Export Uganda Ltd.', 'buying@exportuganda.com', 'Entebbe, Central Region', 'buying@exportuganda.com', '256723456789', '2024-01-03'),
('Lira Fresh Market', 'purchasing@lirafresh.ug', 'Lira, Northern Region', 'purchasing@lirafresh.ug', '256724567890', '2024-01-04'),
('Masaka Traders', 'orders@masakatraders.ug', 'Masaka, Central Region', 'orders@masakatraders.ug', '256725678901', '2024-01-05'),
('Kabale Co-op', 'buying@kabalecoop.ug', 'Kabale, Western Region', 'buying@kabalecoop.ug', '256726789012', '2024-01-06'),
('Soroti Market Hub', 'purchasing@sorotimarket.ug', 'Soroti, Eastern Region', 'purchasing@sorotimarket.ug', '256727890123', '2024-01-07'),
('Arua Fresh Traders', 'orders@aruafresh.ug', 'Arua, Northern Region', 'orders@aruafresh.ug', '256728901234', '2024-01-08'),
('Hoima Co-op Ltd.', 'buying@hoimacoop.ug', 'Hoima, Western Region', 'buying@hoimacoop.ug', '256729012345', '2024-01-09'),
('Entebbe Exports', 'sales@entebbeexports.ug', 'Entebbe, Central Region', 'sales@entebbeexports.ug', '256720123456', '2024-01-10');

-- Insert Products with categories
INSERT INTO Products (Name, Quantity, HarvestDate, ExpiryDate, PricePerKg, FarmerID, SupplierID, CategoryID, QualityRating, Certification) VALUES
('Matoke (Bananas)', 1000, '2025-02-10', '2025-05-10', 1.50, 1, 1, 1, 'Excellent', 'Organic'),
('Robusta Coffee', 600, '2025-01-01', '2025-07-01', 4.00, 2, 2, 5, 'Good', 'Fair Trade'),
('Maize', 800, '2025-02-15', '2025-05-15', 0.80, 3, 3, 2, 'Good', NULL),
('Fresh Vegetables', 500, '2025-03-01', '2025-04-01', 2.00, 4, 4, 3, 'Excellent', 'Organic'),
('Sweet Potatoes', 600, '2025-02-20', '2025-05-20', 1.20, 5, 5, 3, 'Good', NULL),
('Beans', 400, '2025-02-25', '2025-05-25', 2.50, 6, 6, 4, 'Fair', NULL),
('Millet', 500, '2025-01-05', '2025-04-05', 1.00, 7, 7, 2, 'Good', NULL),
('Groundnuts', 300, '2025-02-15', '2025-05-15', 3.00, 8, 8, 4, 'Good', 'Local Certified'),
('Pineapples', 700, '2025-03-01', '2025-04-15', 2.00, 9, 9, 1, 'Excellent', 'Organic'),
('Soya Beans', 450, '2025-02-15', '2025-06-15', 1.80, 10, 10, 4, 'Good', NULL);

-- Insert Orders with payment methods
INSERT INTO Orders (ProductID, BuyerID, PaymentMethodID, Quantity, OrderDate, Status, PaymentStatus) VALUES
(1, 1, 1, 200, '2025-03-05', 'Shipped', 'Paid'),
(2, 3, 2, 150, '2025-03-10', 'Pending', 'Pending'),
(3, 2, 3, 300, '2025-03-07', 'Delivered', 'Paid'),
(4, 4, 1, 100, '2025-03-11', 'Shipped', 'Pending'),
(5, 5, 4, 100, '2025-03-12', 'Shipped', 'Pending'),
(6, 6, 5, 80, '2025-03-15', 'Pending', 'Pending'),
(7, 7, 1, 120, '2025-03-18', 'Delivered', 'Paid'),
(8, 8, 2, 50, '2025-03-20', 'Shipped', 'Pending'),
(9, 9, 3, 150, '2025-03-22', 'Pending', 'Pending'),
(10, 10, 4, 90, '2025-03-25', 'Delivered', 'Paid');

-- Insert Transportation with driver contacts
INSERT INTO Transportation (OrderID, VehicleType, DriverName, DriverContact, ExpectedDelivery, ActualDelivery, Status) VALUES
(1, 'Pickup Truck', 'Joseph Ssebugwawo', '256731234567', '2025-03-10', '2025-03-10', 'Delivered'),
(2, 'Container Truck', 'Aisha Nakato', '256732345678', '2025-03-16', NULL, 'In Transit'),
(3, 'Lorry', 'Tom Wilson', '256733456789', '2025-03-15', '2025-03-15', 'Delivered'),
(4, 'Van', 'Emma Davis', '256734567890', '2025-03-18', NULL, 'In Transit'),
(5, 'Pickup Truck', 'Pauline Atim', '256735678901', '2025-03-20', '2025-03-20', 'Delivered'),
(6, 'Lorry', 'Richard Odoi', '256736789012', '2025-03-25', NULL, 'In Transit'),
(7, 'Van', 'Margaret Namirembe', '256737890123', '2025-03-25', '2025-03-25', 'Delivered'),
(8, 'Container Truck', 'Charles Okello', '256738901234', '2025-03-28', NULL, 'In Transit'),
(9, 'Refrigerated Truck', 'Susan Nambi', '256739012345', '2025-03-28', '2025-03-28', 'Delivered'),
(10, 'Pickup Truck', 'George Wabwire', '256730123456', '2025-04-01', NULL, 'In Transit');

DELIMITER ; 