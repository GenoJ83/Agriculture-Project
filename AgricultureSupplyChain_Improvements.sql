-- Agriculture Supply Chain Database Improvements
USE AgricultureSupplyChain;

-- Add new tables
CREATE TABLE IF NOT EXISTS ProductCategories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS PaymentMethods (
    PaymentMethodID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS UserLogins (
    LoginID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    UserType ENUM('Farmer', 'Supplier', 'Buyer'),
    LoginTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    IPAddress VARCHAR(45),
    Status ENUM('Success', 'Failed')
);

-- Enhance existing tables
ALTER TABLE Products
ADD COLUMN CategoryID INT,
ADD FOREIGN KEY (CategoryID) REFERENCES ProductCategories(CategoryID);

ALTER TABLE Orders
ADD COLUMN PaymentMethodID INT,
ADD FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID);

-- Add new views
CREATE OR REPLACE VIEW SeasonalProductAvailability AS
SELECT p.Name, p.Quantity, p.HarvestDate, p.ExpiryDate, c.Name AS Category
FROM Products p
JOIN ProductCategories c ON p.CategoryID = c.CategoryID
WHERE p.HarvestDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 3 MONTH);

-- Add new stored procedures
DELIMITER //

CREATE PROCEDURE GetSeasonalProducts(IN season VARCHAR(20))
BEGIN
    SELECT p.Name, p.Quantity, p.PricePerKg, f.Name AS Farmer
    FROM Products p
    JOIN Farmers f ON p.FarmerID = f.FarmerID
    WHERE MONTH(p.HarvestDate) BETWEEN 
        CASE season
            WHEN 'Dry' THEN 1 AND 3
            WHEN 'Rainy' THEN 4 AND 6
            WHEN 'Harvest' THEN 7 AND 9
            WHEN 'Planting' THEN 10 AND 12
        END;
END //

-- Add procedure for tracking failed login attempts
CREATE PROCEDURE TrackFailedLogin(IN user_id INT, IN user_type VARCHAR(20), IN ip_address VARCHAR(45))
BEGIN
    INSERT INTO UserLogins (UserID, UserType, IPAddress, Status)
    VALUES (user_id, user_type, ip_address, 'Failed');
END //

-- Add procedure for seasonal price adjustment
CREATE PROCEDURE AdjustSeasonalPrices(IN season VARCHAR(20), IN adjustment_factor DECIMAL(3,2))
BEGIN
    UPDATE Products p
    SET p.PricePerKg = p.PricePerKg * adjustment_factor
    WHERE MONTH(p.HarvestDate) BETWEEN 
        CASE season
            WHEN 'Dry' THEN 1 AND 3
            WHEN 'Rainy' THEN 4 AND 6
            WHEN 'Harvest' THEN 7 AND 9
            WHEN 'Planting' THEN 10 AND 12
        END;
END //

DELIMITER ;

-- Insert sample data for new tables
INSERT INTO ProductCategories (Name, Description) VALUES
('Fruits', 'Fresh fruits and produce'),
('Grains', 'Cereals and grains'),
('Vegetables', 'Fresh vegetables'),
('Legumes', 'Beans and pulses'),
('Coffee', 'Coffee beans and products');

INSERT INTO PaymentMethods (Name, Description) VALUES
('Mobile Money', 'Payment through mobile money services'),
('Bank Transfer', 'Direct bank transfer'),
('Cash on Delivery', 'Payment upon delivery'),
('Credit Card', 'Payment via credit card'),
('Cheque', 'Payment by cheque');

-- Update existing products with categories
UPDATE Products SET CategoryID = 1 WHERE Name IN ('Matoke (Bananas)', 'Pineapples');
UPDATE Products SET CategoryID = 2 WHERE Name IN ('Maize', 'Millet');
UPDATE Products SET CategoryID = 3 WHERE Name = 'Fresh Vegetables';
UPDATE Products SET CategoryID = 4 WHERE Name IN ('Beans', 'Groundnuts', 'Soya Beans');
UPDATE Products SET CategoryID = 5 WHERE Name = 'Robusta Coffee';

-- Add new indexes for performance
CREATE INDEX idx_products_category ON Products(CategoryID);
CREATE INDEX idx_orders_payment ON Orders(PaymentMethodID);
CREATE INDEX idx_userlogins_user ON UserLogins(UserID, UserType);

-- Add new triggers for enhanced security
DELIMITER //

CREATE TRIGGER after_failed_login
AFTER INSERT ON UserLogins
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Failed' THEN
        -- Log the failed attempt
        INSERT INTO AuditLog (TableName, Action, User)
        VALUES ('UserLogins', 'Failed Login Attempt', CONCAT(NEW.UserType, ' ID: ', NEW.UserID));
    END IF;
END //

CREATE TRIGGER before_price_update
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
    IF NEW.PricePerKg < 0.1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Price per kg cannot be less than 0.1';
    END IF;
END //

DELIMITER ;

-- Add new views for business intelligence
CREATE VIEW ProductCategorySummary AS
SELECT 
    c.Name AS Category,
    COUNT(p.ProductID) AS ProductCount,
    SUM(p.Quantity) AS TotalQuantity,
    AVG(p.PricePerKg) AS AveragePrice
FROM ProductCategories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.Name;

CREATE VIEW PaymentMethodUsage AS
SELECT 
    pm.Name AS PaymentMethod,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalAmount
FROM PaymentMethods pm
LEFT JOIN Orders o ON pm.PaymentMethodID = o.PaymentMethodID
GROUP BY pm.PaymentMethodID, pm.Name;

-- Add new constraints
ALTER TABLE Products
ADD CONSTRAINT chk_min_price CHECK (PricePerKg >= 0.1);

ALTER TABLE UserLogins
ADD CONSTRAINT chk_valid_ip CHECK (IPAddress REGEXP '^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$'); 