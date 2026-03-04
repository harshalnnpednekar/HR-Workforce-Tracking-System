-- ============================================================
-- HR Workforce Tracking System — Users Table
-- Target: Microsoft SQL Server
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        Id          NVARCHAR(50)   PRIMARY KEY,
        Name        NVARCHAR(100)  NOT NULL,
        Email       NVARCHAR(150)  NOT NULL UNIQUE,
        Role        NVARCHAR(20)   NOT NULL DEFAULT 'employee',
        Password    NVARCHAR(255)  NOT NULL,
        CreatedAt   DATETIME2      NOT NULL DEFAULT GETDATE()
    );
END
GO

-- Seed default admin (skip if already exists)
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@hr.com')
BEGIN
    INSERT INTO Users (Id, Name, Email, Role, Password)
    VALUES ('admin-1', 'System Admin', 'admin@hr.com', 'admin', 'password123');
END
GO
