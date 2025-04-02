-- Drop existing database if it exists
DROP DATABASE IF EXISTS AgricultureSupplyChain;
CREATE DATABASE AgricultureSupplyChain;
USE AgricultureSupplyChain;

-- Create Farmers Table with Constraints (First, no dependencies)
CREATE TABLE IF NOT EXISTS Farmers (
    FarmerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(50) NOT NULL UNIQUE, -- Ensure unique contact (email or phone)
    Location VARCHAR(100) NOT NULL CHECK (Location != '') -- Simplified check for non-empty location
);

-- Create Suppliers Table with Constraints 
CREATE TABLE IF NOT EXISTS Suppliers (
    SupplierID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE, -- Ensure unique supplier names
    Contact VARCHAR(50) NOT NULL UNIQUE, -- Ensure unique contact
    Location VARCHAR(100) NOT NULL CHECK (Location != '') -- Simplified check for non-empty location
);

-- Create Buyers Table with Constraints 
CREATE TABLE IF NOT EXISTS Buyers (
    BuyerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE, -- Ensure unique buyer names
    Contact VARCHAR(50) NOT NULL UNIQUE, -- Ensure unique contact
    Location VARCHAR(100) NOT NULL CHECK (Location != '') -- Simplified check for non-empty location
);

-- Create Products Table with Constraints (Depends on Farmers and Suppliers)
CREATE TABLE IF NOT EXISTS Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE, -- Ensure unique product names
    Quantity INT CHECK (Quantity >= 0),
    HarvestDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL, -- Removed cross-column check constraint
    PricePerKg DECIMAL(10,2) CHECK (PricePerKg >= 0),
    FarmerID INT,
    SupplierID INT,
    QualityRating ENUM('Poor', 'Fair', 'Good', 'Excellent') DEFAULT 'Good',
    Certification VARCHAR(100),
    FOREIGN KEY (FarmerID) REFERENCES Farmers(FarmerID) ON DELETE CASCADE,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE SET NULL
);

-- Create Orders Table with Constraints (Depends on Products and Buyers)
CREATE TABLE IF NOT EXISTS Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    ProductID INT,
    BuyerID INT,
    Quantity INT CHECK (Quantity > 0),
    OrderDate DATE NOT NULL, 
    Status ENUM('Pending', 'Shipped', 'Delivered', 'Cancelled') DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),
    PaymentStatus ENUM('Pending', 'Paid', 'Overdue') DEFAULT 'Pending',
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    FOREIGN KEY (BuyerID) REFERENCES Buyers(BuyerID) ON DELETE CASCADE
    -- Removed chk_order_quantity_enough due to complexity; handled by trigger instead
);

-- Disable foreign key checks for consistent table creation
SET FOREIGN_KEY_CHECKS=0;

-- Create Transportation Table with Constraints (Depends on Orders)
CREATE TABLE IF NOT EXISTS Transportation (
    TransportID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT,
    VehicleType VARCHAR(50) NOT NULL CHECK (VehicleType IN ('Pickup Truck', 'Lorry', 'Van', 'Container Truck', 'Refrigerated Truck')), -- Limit vehicle types
    DriverName VARCHAR(100) NOT NULL,
    ExpectedDelivery DATE NOT NULL, -- Removed future date check to handle historical data
    ActualDelivery DATE, -- Removed CHECK to allow NULL or any date after ExpectedDelivery (handled by trigger if needed)
    Status ENUM('In Transit', 'Delivered', 'Delayed') DEFAULT 'In Transit',
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE
);

-- Re-enabling foreign key checks
SET FOREIGN_KEY_CHECKS=1;

-- Creating AuditLog table
CREATE TABLE IF NOT EXISTS AuditLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50),
    Action VARCHAR(50),
    User VARCHAR(50),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Security and User Roles
-- Create Roles
CREATE ROLE IF NOT EXISTS farmer_role;
CREATE ROLE IF NOT EXISTS supplier_role;
CREATE ROLE IF NOT EXISTS buyer_role;

-- Granting Privileges to Roles
GRANT SELECT, INSERT, UPDATE ON Products TO farmer_role;
GRANT SELECT, INSERT, UPDATE ON Orders TO buyer_role;
GRANT SELECT ON Transportation TO supplier_role;

-- Creating Users
CREATE USER IF NOT EXISTS 'farmer'@'localhost' IDENTIFIED BY 'farmerpass';
CREATE USER IF NOT EXISTS 'supplier'@'localhost' IDENTIFIED BY 'supplierpass';
CREATE USER IF NOT EXISTS 'buyer'@'localhost' IDENTIFIED BY 'buyerpass';

-- Assigning Roles to Users
GRANT farmer_role TO 'farmer'@'localhost';
GRANT supplier_role TO 'supplier'@'localhost';
GRANT buyer_role TO 'buyer'@'localhost';

-- Setting Default Role for Users
SET DEFAULT ROLE farmer_role FOR 'farmer'@'localhost';
SET DEFAULT ROLE supplier_role FOR 'supplier'@'localhost';
SET DEFAULT ROLE buyer_role FOR 'buyer'@'localhost';

-- Enhancing Security
ALTER USER 'farmer'@'localhost' IDENTIFIED WITH mysql_native_password BY 'farmerpass';
ALTER USER 'supplier'@'localhost' IDENTIFIED WITH mysql_native_password BY 'supplierpass';
ALTER USER 'buyer'@'localhost' IDENTIFIED WITH mysql_native_password BY 'buyerpass';

-- Creating Triggers
DELIMITER //

-- Replacing check constraint for ExpiryDate >= HarvestDate with trigger
CREATE TRIGGER validate_product_dates
BEFORE INSERT ON Products
FOR EACH ROW
BEGIN
    IF NEW.ExpiryDate < NEW.HarvestDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Expiry date cannot be before harvest date';
    END IF;
END;
//

CREATE TRIGGER validate_product_dates_update
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
    IF NEW.ExpiryDate < NEW.HarvestDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Expiry date cannot be before harvest date';
    END IF;
END;
//

-- Replacing check constraint for OrderDate <= CURDATE() with trigger
CREATE TRIGGER validate_order_date
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    IF NEW.OrderDate > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order date cannot be in the future';
    END IF;
END;
//

CREATE TRIGGER validate_order_date_update
BEFORE UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.OrderDate > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order date cannot be in the future';
    END IF;
END;
//

-- Calculating TotalAmount when inserting orders (NEW)
CREATE TRIGGER before_order_insert
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE product_price DECIMAL(10,2);
    -- Get product price
    SELECT PricePerKg INTO product_price
    FROM Products
    WHERE ProductID = NEW.ProductID;
    -- Calculate total amount
    SET NEW.TotalAmount = NEW.Quantity * product_price;
END;
//

-- Updating product quantity after order
CREATE TRIGGER update_product_quantity
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    UPDATE Products SET Quantity = Quantity - NEW.Quantity
    WHERE ProductID = NEW.ProductID;
END;
//

-- Preventing negative quantity
CREATE TRIGGER prevent_negative_quantity
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
    IF NEW.Quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product quantity cannot be negative';
    END IF;
END;
//

-- Audit logging for order updates
CREATE TRIGGER after_order_update
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TableName, Action, User)
    VALUES ('Orders', 'UPDATE', CURRENT_USER());
END;
//

-- Validating ActualDelivery date if provided (NEW)
CREATE TRIGGER validate_delivery_dates
BEFORE INSERT ON Transportation
FOR EACH ROW
BEGIN
    IF NEW.ActualDelivery IS NOT NULL AND NEW.ActualDelivery < NEW.ExpectedDelivery THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Actual delivery date cannot be before expected delivery date';
    END IF;
END;
//

DELIMITER ;

-- Creating Stored Procedures
DELIMITER //

CREATE PROCEDURE GetProductAvailability(IN prodID INT)
BEGIN
    SELECT Name, Quantity FROM Products WHERE ProductID = prodID;
END;
//

CREATE PROCEDURE GetOrderDetails(IN orderID INT)
BEGIN
    SELECT o.OrderID, p.Name AS Product, b.Name AS Buyer, o.Quantity, o.OrderDate, o.Status,
           o.TotalAmount, o.PaymentStatus
    FROM Orders o
    JOIN Products p ON o.ProductID = p.ProductID
    JOIN Buyers b ON o.BuyerID = b.BuyerID
    WHERE o.OrderID = orderID;
END;
//

-- Safer backup procedure that creates a backup statement for DBA to run
CREATE PROCEDURE GenerateBackupScript()
BEGIN
    SELECT CONCAT('mysqldump -u [username] -p AgricultureSupplyChain > /backups/agriculture_backup_', 
           DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql') AS BackupCommand;
END;
//

DELIMITER ;

-- Create Views
CREATE VIEW FarmerProductOverview AS
SELECT f.FarmerID, f.Name AS FarmerName, f.Location, p.Name AS ProductName, p.Quantity, p.PricePerKg, p.QualityRating
FROM Farmers f
LEFT JOIN Products p ON f.FarmerID = p.FarmerID;

CREATE VIEW OrderStatusReport AS
SELECT o.OrderID, p.Name AS ProductName, b.Name AS BuyerName, o.Quantity, o.OrderDate, o.Status, 
       o.TotalAmount, o.PaymentStatus, t.Status AS TransportStatus
FROM Orders o
JOIN Products p ON o.ProductID = p.ProductID
JOIN Buyers b ON o.BuyerID = b.BuyerID
LEFT JOIN Transportation t ON o.OrderID = t.OrderID;

CREATE VIEW ProductSupplyChain AS
SELECT p.Name AS ProductName, f.Name AS FarmerName, s.Name AS SupplierName, p.Quantity, 
       p.HarvestDate, p.ExpiryDate, p.QualityRating, p.Certification
FROM Products p
JOIN Farmers f ON p.FarmerID = f.FarmerID
JOIN Suppliers s ON p.SupplierID = s.SupplierID;

CREATE VIEW TransportationDelays AS
SELECT t.TransportID, o.OrderID, p.Name AS ProductName, t.DriverName, t.ExpectedDelivery, t.ActualDelivery,
CASE 
    WHEN t.ActualDelivery > t.ExpectedDelivery THEN DATEDIFF(t.ActualDelivery, t.ExpectedDelivery)
    ELSE 0 
END AS DelayDays,
t.Status
FROM Transportation t
JOIN Orders o ON t.OrderID = o.OrderID
JOIN Products p ON o.ProductID = p.ProductID
WHERE t.ActualDelivery IS NOT NULL;

CREATE VIEW BuyerOrderSummary AS
SELECT b.BuyerID, b.Name AS BuyerName, b.Location, COUNT(o.OrderID) AS TotalOrders, 
       SUM(o.Quantity) AS TotalQuantity, AVG(o.Quantity) AS AvgOrderSize,
       SUM(o.TotalAmount) AS TotalSpent
FROM Buyers b
LEFT JOIN Orders o ON b.BuyerID = o.BuyerID
GROUP BY b.BuyerID, b.Name, b.Location;

-- Insert Farmers (10 entries)
INSERT INTO Farmers (Name, Contact, Location) VALUES
('James Kivumbi', 'james.kivumbi@ug.farm', 'Kampala, Central Region'),
('Grace Namazzi', 'grace.namazzi@ug.farm', 'Jinja, Eastern Region'),
('Peter Mugisa', 'peter.mugisa@ug.farm', 'Mbarara, Western Region'),
('Sarah Nambooze', 'sarah.nambooze@ug.farm', 'Lira, Northern Region'),
('Moses Byaruhanga', 'moses.byaruhanga@ug.farm', 'Gulu, Northern Region'),
('Esther Nakimuli', 'esther.nakimuli@ug.farm', 'Masaka, Central Region'),
('Samuel Tumwine', 'samuel.tumwine@ug.farm', 'Kabale, Western Region'),
('Ruth Katusiime', 'ruth.katusiime@ug.farm', 'Soroti, Eastern Region'),
('Isaac Muwanga', 'isaac.muwanga@ug.farm', 'Arua, Northern Region'),
('Jane Nakato', 'jane.nakato@ug.farm', 'Hoima, Western Region');

-- Insert Suppliers (10 entries)
INSERT INTO Suppliers (Name, Contact, Location) VALUES
('Uganda Agro Traders', 'sales@ugandagro.com', 'Kampala, Central Region'),
('Eastern Fresh Supplies', 'info@easternfresh.ug', 'Mbale, Eastern Region'),
('Western Farm Logistics', 'contact@westernfarm.ug', 'Fort Portal, Western Region'),
('Northern Agri Solutions', 'info@northernagri.ug', 'Lira, Northern Region'),
('Central Harvest Co.', 'sales@centralharvest.ug', 'Masaka, Central Region'),
('Southern Traders Ltd.', 'contact@southerntraders.ug', 'Mbarara, Western Region'),
('Eastern Agri Hub', 'contact@easternagri.ug', 'Soroti, Eastern Region'),
('Northern Supply Co.', 'sales@northernsupply.ug', 'Arua, Northern Region'),
('Western Logistics Ltd.', 'info@westernlogistics.ug', 'Hoima, Western Region'),
('Central Agro Services', 'support@centralagro.ug', 'Kampala, Central Region');

-- Insert Buyers (10 entries)
INSERT INTO Buyers (Name, Contact, Location) VALUES
('Kampala Market Ltd.', 'purchasing@kampalamarket.ug', 'Kampala, Central Region'),
('Jinja Co-operative', 'orders@jinjacoop.ug', 'Jinja, Eastern Region'),
('Export Uganda Ltd.', 'buying@exportuganda.com', 'Entebbe, Central Region'),
('Lira Fresh Market', 'purchasing@lirafresh.ug', 'Lira, Northern Region'),
('Masaka Traders', 'orders@masakatraders.ug', 'Masaka, Central Region'),
('Kabale Co-op', 'buying@kabalecoop.ug', 'Kabale, Western Region'),
('Soroti Market Hub', 'purchasing@sorotimarket.ug', 'Soroti, Eastern Region'),
('Arua Fresh Traders', 'orders@aruafresh.ug', 'Arua, Northern Region'),
('Hoima Co-op Ltd.', 'buying@hoimacoop.ug', 'Hoima, Western Region'),
('Entebbe Exports', 'sales@entebbeexports.ug', 'Entebbe, Central Region');

-- Insert Products (10 entries with updated dates)
INSERT INTO Products (Name, Quantity, HarvestDate, ExpiryDate, PricePerKg, FarmerID, SupplierID, QualityRating, Certification) VALUES
('Matoke (Bananas)', 1000, '2025-02-10', '2025-05-10', 1.50, 1, 1, 'Excellent', 'Organic'),
('Robusta Coffee', 600, '2025-01-01', '2025-07-01', 4.00, 2, 2, 'Good', 'Fair Trade'),
('Maize', 800, '2025-02-15', '2025-05-15', 0.80, 3, 3, 'Good', NULL),
('Fresh Vegetables', 500, '2025-03-01', '2025-04-01', 2.00, 4, 4, 'Excellent', 'Organic'),
('Sweet Potatoes', 600, '2025-02-20', '2025-05-20', 1.20, 5, 5, 'Good', NULL),
('Beans', 400, '2025-02-25', '2025-05-25', 2.50, 6, 6, 'Fair', NULL),
('Millet', 500, '2025-01-05', '2025-04-05', 1.00, 7, 7, 'Good', NULL),
('Groundnuts', 300, '2025-02-15', '2025-05-15', 3.00, 8, 8, 'Good', 'Local Certified'),
('Pineapples', 700, '2025-03-01', '2025-04-15', 2.00, 9, 9, 'Excellent', 'Organic'),
('Soya Beans', 450, '2025-02-15', '2025-06-15', 1.80, 10, 10, 'Good', NULL);

-- Inserting Orders
INSERT INTO Orders (ProductID, BuyerID, Quantity, OrderDate, Status, PaymentStatus) VALUES
(1, 1, 200, '2025-03-05', 'Shipped', 'Paid'),
(2, 3, 150, '2025-03-10', 'Pending', 'Pending'),
(3, 2, 300, '2025-03-07', 'Delivered', 'Paid'),
(4, 4, 100, '2025-03-11', 'Shipped', 'Pending'),
(5, 5, 100, '2025-03-12', 'Shipped', 'Pending'),
(6, 6, 80, '2025-03-15', 'Pending', 'Pending'),
(7, 7, 120, '2025-03-18', 'Delivered', 'Paid'),
(8, 8, 50, '2025-03-20', 'Shipped', 'Pending'),
(9, 9, 150, '2025-03-22', 'Pending', 'Pending'),
(10, 10, 90, '2025-03-25', 'Delivered', 'Paid');

-- Inserting Transportation
INSERT INTO Transportation (OrderID, VehicleType, DriverName, ExpectedDelivery, ActualDelivery, Status) VALUES
(1, 'Pickup Truck', 'Joseph Ssebugwawo', '2025-03-10', '2025-03-10', 'Delivered'),
(2, 'Container Truck', 'Aisha Nakato', '2025-03-16', NULL, 'In Transit'),
(3, 'Lorry', 'Tom Wilson', '2025-03-15', '2025-03-15', 'Delivered'),
(4, 'Van', 'Emma Davis', '2025-03-18', NULL, 'In Transit'),
(5, 'Pickup Truck', 'Pauline Atim', '2025-03-20', '2025-03-20', 'Delivered'),
(6, 'Lorry', 'Richard Odoi', '2025-03-25', NULL, 'In Transit'),
(7, 'Van', 'Margaret Namirembe', '2025-03-25', '2025-03-25', 'Delivered'),
(8, 'Container Truck', 'Charles Okello', '2025-03-28', NULL, 'In Transit'),
(9, 'Refrigerated Truck', 'Susan Nambi', '2025-03-28', '2025-03-28', 'Delivered'),
(10, 'Pickup Truck', 'George Wabwire', '2025-04-01', NULL, 'In Transit');

-- Adding Indexes for Performance
CREATE INDEX idx_products_farmer ON Products(FarmerID);
CREATE INDEX idx_orders_product ON Orders(ProductID);
CREATE INDEX idx_orders_buyer ON Orders(BuyerID);
CREATE INDEX idx_transportation_order ON Transportation(OrderID);
