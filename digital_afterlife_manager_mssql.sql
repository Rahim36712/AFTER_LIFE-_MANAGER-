-- =============================================================
-- DIGITAL AFTERLIFE MANAGER
-- Full SQL Implementation for Microsoft SQL Server (SSMS 22)
-- Department of Computer & Software Engineering, NUST
-- Team: M.Rahim Jamil, Ahsan Javed, Alina, Naeemullah Aziz
-- Submitted To: Dr. Shahzad
-- =============================================================

-- =============================================================
-- SECTION 1: DATABASE CREATION & SCHEMA DEFINITION
-- =============================================================

USE master;
GO

IF DB_ID('DigitalAfterlifeManager') IS NOT NULL
BEGIN
    ALTER DATABASE DigitalAfterlifeManager SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DigitalAfterlifeManager;
END
GO

CREATE DATABASE DigitalAfterlifeManager;
GO

USE DigitalAfterlifeManager;
GO

-- =============================================================
-- TABLE: [USER]
-- Core entity representing asset owners
-- =============================================================
CREATE TABLE [USER] (
    ID          INT             IDENTITY(1,1) NOT NULL,
    Name        VARCHAR(255)    NOT NULL,
    Email       VARCHAR(255)    NOT NULL UNIQUE,
    Password    VARCHAR(255)    NOT NULL,
    Phone       VARCHAR(20),
    DOB         DATE            NOT NULL,
    PRIMARY KEY (ID)
);

-- =============================================================
-- TABLE: TRIGGER_EVENT
-- Records events (e.g., death verification) that activate transfers
-- =============================================================
CREATE TABLE TRIGGER_EVENT (
    ID          INT             IDENTITY(1,1) NOT NULL,
    EventType   VARCHAR(100)    NOT NULL,
    Status      VARCHAR(50)     NOT NULL DEFAULT 'Pending'
                                CHECK (Status IN ('Pending', 'Verified', 'Rejected')),
    EventDate   DATE            NOT NULL,
    USER_ID     INT             NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (USER_ID) REFERENCES [USER](ID) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: LEGAL_AUTHORITY
-- Entities authorized to verify trigger events
-- =============================================================
CREATE TABLE LEGAL_AUTHORITY (
    ID                  INT             IDENTITY(1,1) NOT NULL,
    Name                VARCHAR(255)    NOT NULL,
    Organization        VARCHAR(255)    NOT NULL,
    ContactInfo         VARCHAR(255),
    TRIGGER_EVENT_ID    INT,
    PRIMARY KEY (ID),
    -- Changed to NO ACTION to avoid multiple cascade paths issue in SQL Server
    FOREIGN KEY (TRIGGER_EVENT_ID) REFERENCES TRIGGER_EVENT(ID) ON DELETE NO ACTION
);

-- =============================================================
-- TABLE: ACCESS_POLICY
-- Defines access control rules for digital assets
-- =============================================================
CREATE TABLE ACCESS_POLICY (
    ID                  INT             IDENTITY(1,1) NOT NULL,
    PolicyDetail        VARCHAR(MAX)    NOT NULL,
    AccessLevel         VARCHAR(50)     NOT NULL
                                        CHECK (AccessLevel IN ('Read', 'Write', 'Full', 'Restricted')),
    PRIMARY KEY (ID)
);

-- =============================================================
-- TABLE: BENEFICIARY
-- People designated to receive digital assets
-- =============================================================
CREATE TABLE BENEFICIARY (
    ID                  INT             IDENTITY(1,1) NOT NULL,
    Name                VARCHAR(255)    NOT NULL,
    Email               VARCHAR(255)    NOT NULL,
    Phone               VARCHAR(255)    NOT NULL,
    Access_Policy_ID    INT,
    PRIMARY KEY (ID),
    FOREIGN KEY (Access_Policy_ID) REFERENCES ACCESS_POLICY(ID) ON DELETE SET NULL
);

-- =============================================================
-- TABLE: DIGITAL_ASSET (Superclass / Generalization)
-- Base entity for all digital asset types
-- =============================================================
CREATE TABLE DIGITAL_ASSET (
    ID              INT             IDENTITY(1,1) NOT NULL,
    Name            VARCHAR(255)    NOT NULL,
    Type            VARCHAR(255)    NOT NULL
                                    CHECK (Type IN ('Financial', 'CloudStorage', 'SocialMedia')),
    Value           FLOAT,
    Created_at      DATETIME2       NOT NULL DEFAULT GETDATE(),
    USER_ID         INT             NOT NULL,
    Access_Policy_ID INT,
    PRIMARY KEY (ID),
    FOREIGN KEY (USER_ID) REFERENCES [USER](ID) ON DELETE CASCADE,
    FOREIGN KEY (Access_Policy_ID) REFERENCES ACCESS_POLICY(ID) ON DELETE NO ACTION
);

-- =============================================================
-- TABLE: FINANCIAL_ASSET (Specialization of DIGITAL_ASSET)
-- =============================================================
CREATE TABLE FINANCIAL_ASSET (
    Digital_Asset_ID    INT             NOT NULL,
    AccountNumber       INT             NOT NULL UNIQUE,
    BankName            VARCHAR(255)    NOT NULL,
    Balance             INT             NOT NULL DEFAULT 0,
    PRIMARY KEY (Digital_Asset_ID),
    FOREIGN KEY (Digital_Asset_ID) REFERENCES DIGITAL_ASSET(ID) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: CLOUD_STORAGE_ASSET (Specialization of DIGITAL_ASSET)
-- =============================================================
CREATE TABLE CLOUD_STORAGE_ASSET (
    Digital_Asset_ID    INT             NOT NULL,
    StorageProvider     VARCHAR(255)    NOT NULL,
    StorageSize         INT             NOT NULL, -- Size in MB
    FileCount           INT             NOT NULL DEFAULT 0,
    PRIMARY KEY (Digital_Asset_ID),
    FOREIGN KEY (Digital_Asset_ID) REFERENCES DIGITAL_ASSET(ID) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: SOCIAL_MEDIA_ASSET (Specialization of DIGITAL_ASSET)
-- =============================================================
CREATE TABLE SOCIAL_MEDIA_ASSET (
    Digital_Asset_ID    INT             NOT NULL,
    PlatformName        VARCHAR(255)    NOT NULL,
    Username            VARCHAR(255)    NOT NULL,
    ProfileLink         VARCHAR(255),
    PRIMARY KEY (Digital_Asset_ID),
    FOREIGN KEY (Digital_Asset_ID) REFERENCES DIGITAL_ASSET(ID) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: DIGITAL_ASSET_BENEFICIARY (Many-to-Many)
-- =============================================================
CREATE TABLE DIGITAL_ASSET_BENEFICIARY (
    Digital_Asset_ID    INT     NOT NULL,
    BeneficiaryID       INT     NOT NULL,
    PRIMARY KEY (Digital_Asset_ID, BeneficiaryID),
    FOREIGN KEY (Digital_Asset_ID) REFERENCES DIGITAL_ASSET(ID) ON DELETE CASCADE,
    FOREIGN KEY (BeneficiaryID)    REFERENCES BENEFICIARY(ID) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: ASSET_TRANSFER
-- Records transfer of digital assets to beneficiaries
-- =============================================================
CREATE TABLE ASSET_TRANSFER (
    ID                  INT             IDENTITY(1,1) NOT NULL,
    Status              VARCHAR(255)    NOT NULL DEFAULT 'Pending'
                                        CHECK (Status IN ('Pending', 'Completed', 'Failed')),
    Transfer_Date       DATE,
    Digital_Asset_ID    INT             NOT NULL,
    BeneficiaryID       INT             NOT NULL,
    TRIGGER_EVENT_ID    INT             NOT NULL,
    Legal_Authority_ID  INT,
    PRIMARY KEY (ID),
    FOREIGN KEY (Digital_Asset_ID)  REFERENCES DIGITAL_ASSET(ID)    ON DELETE CASCADE,
    -- Prevent multiple cascade paths
    FOREIGN KEY (BeneficiaryID)     REFERENCES BENEFICIARY(ID)       ON DELETE NO ACTION,
    FOREIGN KEY (TRIGGER_EVENT_ID)  REFERENCES TRIGGER_EVENT(ID)     ON DELETE NO ACTION,
    FOREIGN KEY (Legal_Authority_ID) REFERENCES LEGAL_AUTHORITY(ID)  ON DELETE NO ACTION
);

-- =============================================================
-- TABLE: ACCESS_LOG (Weak Entity)
-- =============================================================
CREATE TABLE ACCESS_LOG (
    ID          INT             IDENTITY(1,1) NOT NULL,
    Action      VARCHAR(255)    NOT NULL,
    Timestamp   DATETIME2       NOT NULL DEFAULT GETDATE(),
    USER_ID     INT             NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (USER_ID) REFERENCES [USER](ID) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: MEMORY_DATA (Weak Entity)
-- =============================================================
CREATE TABLE MEMORY_DATA (
    ID          INT             IDENTITY(1,1) NOT NULL,
    Content     VARCHAR(MAX)    NOT NULL,
    UploadDate  DATE            NOT NULL,
    USER_ID     INT             NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (USER_ID) REFERENCES [USER](ID) ON DELETE CASCADE
);
GO

-- =============================================================
-- SECTION 2: INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================
CREATE INDEX idx_user_email ON [USER](Email);
CREATE INDEX idx_asset_user ON DIGITAL_ASSET(USER_ID);
CREATE INDEX idx_asset_type ON DIGITAL_ASSET(Type);
CREATE INDEX idx_transfer_status ON ASSET_TRANSFER(Status);
CREATE INDEX idx_trigger_status ON TRIGGER_EVENT(Status);
CREATE INDEX idx_log_user ON ACCESS_LOG(USER_ID);
GO

-- =============================================================
-- SECTION 3: VIEWS FOR REPORTING & ABSTRACTION
-- =============================================================
CREATE VIEW vw_PendingTransfers AS
SELECT
    at.ID           AS TransferID,
    u.Name          AS AssetOwner,
    da.Name         AS AssetName,
    da.Type         AS AssetType,
    b.Name          AS BeneficiaryName,
    b.Email         AS BeneficiaryEmail,
    te.EventType    AS TriggerEvent,
    te.EventDate    AS EventDate,
    la.Name         AS LegalAuthority,
    at.Status       AS TransferStatus
FROM ASSET_TRANSFER at
JOIN DIGITAL_ASSET   da ON at.Digital_Asset_ID = da.ID
JOIN [USER]          u ON da.USER_ID           = u.ID
JOIN BENEFICIARY      b ON at.BeneficiaryID     = b.ID
JOIN TRIGGER_EVENT   te ON at.TRIGGER_EVENT_ID  = te.ID
LEFT JOIN LEGAL_AUTHORITY la ON at.Legal_Authority_ID = la.ID
WHERE at.Status = 'Pending';
GO

CREATE VIEW vw_UserAssetInventory AS
SELECT
    u.ID        AS UserID,
    u.Name      AS UserName,
    u.Email     AS UserEmail,
    da.ID       AS AssetID,
    da.Name     AS AssetName,
    da.Type     AS AssetType,
    da.Value    AS AssetValue,
    da.Created_at AS CreatedAt
FROM [USER] u
JOIN DIGITAL_ASSET da ON u.ID = da.USER_ID;
GO

CREATE VIEW vw_BeneficiaryAccess AS
SELECT
    b.ID        AS BeneficiaryID,
    b.Name      AS BeneficiaryName,
    b.Email     AS BeneficiaryEmail,
    da.Name     AS AssetName,
    da.Type     AS AssetType,
    ap.PolicyDetail AS Policy,
    ap.AccessLevel  AS AccessLevel
FROM BENEFICIARY b
JOIN DIGITAL_ASSET_BENEFICIARY dab ON b.ID = dab.BeneficiaryID
JOIN DIGITAL_ASSET da ON dab.Digital_Asset_ID = da.ID
LEFT JOIN ACCESS_POLICY ap ON b.Access_Policy_ID = ap.ID;
GO

-- =============================================================
-- SECTION 4: TRIGGERS FOR AUTOMATED ACTIONS
-- =============================================================
CREATE TRIGGER trg_LogUserRegistration
ON [USER]
AFTER INSERT
AS
BEGIN
    INSERT INTO ACCESS_LOG (Action, Timestamp, USER_ID)
    SELECT 'User registered: ' + i.Name, GETDATE(), i.ID
    FROM inserted i;
END;
GO

CREATE TRIGGER trg_AutoCompleteTransfers
ON TRIGGER_EVENT
AFTER UPDATE
AS
BEGIN
    -- Only act if status changed to 'Verified'
    IF UPDATE(Status)
    BEGIN
        UPDATE at
        SET at.Status = 'Completed',
            at.Transfer_Date = CAST(GETDATE() AS DATE)
        FROM ASSET_TRANSFER at
        JOIN inserted i ON at.TRIGGER_EVENT_ID = i.ID
        JOIN deleted d ON i.ID = d.ID
        WHERE i.Status = 'Verified' AND d.Status != 'Verified' AND at.Status = 'Pending';

        INSERT INTO ACCESS_LOG (Action, Timestamp, USER_ID)
        SELECT 'Trigger event verified: ' + i.EventType + '. Transfers completed.', GETDATE(), i.USER_ID
        FROM inserted i
        JOIN deleted d ON i.ID = d.ID
        WHERE i.Status = 'Verified' AND d.Status != 'Verified';
    END
END;
GO

CREATE TRIGGER trg_PreventAssetDeletion
ON DIGITAL_ASSET
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM ASSET_TRANSFER at
        JOIN deleted d ON at.Digital_Asset_ID = d.ID
        WHERE at.Status = 'Pending'
    )
    BEGIN
        RAISERROR('Cannot delete asset with pending transfers.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM DIGITAL_ASSET WHERE ID IN (SELECT ID FROM deleted);
    END
END;
GO

-- =============================================================
-- SECTION 5: SAMPLE DATA INSERTION
-- =============================================================
-- Insert users (Using CONVERT to simulate hash for passwords)
INSERT INTO [USER] (Name, Email, Password, Phone, DOB) VALUES
('Ahmed Khan',       'ahmed.khan@email.com',       CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'pass123'), 2),  '0300-1234567', '1985-03-15'),
('Sara Malik',       'sara.malik@email.com',       CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'sara456'), 2),  '0311-2345678', '1990-07-22'),
('Bilal Hussain',    'bilal.h@email.com',          CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'bilal789'), 2), '0333-3456789', '1978-11-05'),
('Hina Noor',        'hina.noor@email.com',        CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'hina321'), 2),  '0321-4567890', '1995-01-30'),
('Omar Farooq',      'omar.farooq@email.com',      CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'omar654'), 2),  '0345-5678901', '1982-09-14'),
('Fatima Zahra',     'fatima.z@email.com',         CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'fatima99'), 2), '0301-6789012', '1988-06-18'),
('Usman Ali',        'usman.ali@email.com',        CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'usman11'), 2),  '0312-7890123', '1975-12-25'),
('Zainab Rauf',      'zainab.r@email.com',         CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'zainab22'), 2), '0322-8901234', '1992-04-08'),
('Tariq Mehmood',    'tariq.m@email.com',          CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'tariq33'), 2),  '0344-9012345', '1968-08-20'),
('Amna Sheikh',      'amna.sheikh@email.com',      CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'amna44'), 2),   '0302-0123456', '1997-02-14');

INSERT INTO ACCESS_POLICY (PolicyDetail, AccessLevel) VALUES
('Full access to all financial records after death verification',       'Full'),
('Read-only access to social media accounts',                           'Read'),
('Restricted access — requires dual beneficiary approval',              'Restricted'),
('Full access to cloud storage files',                                  'Full'),
('Write access to edit profile information',                            'Write'),
('Read access to memory data only',                                     'Read');

INSERT INTO BENEFICIARY (Name, Email, Phone, Access_Policy_ID) VALUES
('Ali Khan',         'ali.khan@email.com',       '0300-1111111', 1),
('Sana Malik',       'sana.m@email.com',         '0311-2222222', 2),
('Hassan Hussain',   'hassan.h@email.com',       '0333-3333333', 4),
('Maryam Noor',      'maryam.n@email.com',       '0321-4444444', 3),
('Imran Farooq',     'imran.f@email.com',        '0345-5555555', 5),
('Nadia Zahra',      'nadia.z@email.com',        '0301-6666666', 2),
('Kamran Ali',       'kamran.a@email.com',       '0312-7777777', 1),
('Rabia Rauf',       'rabia.r@email.com',        '0322-8888888', 6),
('Danish Mehmood',   'danish.m@email.com',       '0344-9999999', 4),
('Kiran Sheikh',     'kiran.s@email.com',        '0302-0000000', 3);

INSERT INTO TRIGGER_EVENT (EventType, Status, EventDate, USER_ID) VALUES
('Death Certificate Submission', 'Verified',  '2026-01-10', 1),
('Medical Report Verification',  'Pending',   '2026-02-14', 2),
('Legal Affidavit',              'Verified',  '2025-12-05', 3),
('Court Order',                  'Rejected',  '2026-03-01', 4),
('Death Certificate Submission', 'Pending',   '2026-04-01', 5),
('Medical Report Verification',  'Verified',  '2025-11-20', 6),
('Legal Affidavit',              'Pending',   '2026-03-15', 7),
('Death Certificate Submission', 'Verified',  '2026-01-25', 8),
('Court Order',                  'Verified',  '2025-10-10', 9),
('Death Certificate Submission', 'Pending',   '2026-04-10', 10);

INSERT INTO LEGAL_AUTHORITY (Name, Organization, ContactInfo, TRIGGER_EVENT_ID) VALUES
('Judge Arif Shah',     'Islamabad High Court',         'arif.shah@court.gov.pk',     1),
('Dr. Naseem Ahmed',    'PIMS Hospital',                'naseem@pims.gov.pk',          2),
('Notary Khalid Iqbal', 'Federal Notary Office',        'khalid.notary@gov.pk',        3),
('Magistrate Farida',   'District Court Rawalpindi',    'farida.m@court.gov.pk',       5),
('Dr. Sobia Tariq',     'Services Hospital Lahore',     'sobia.t@services.gov.pk',     6),
('Notary Rashid',       'Karachi Notary Bureau',        'rashid.notary@gov.pk',        8),
('Judge Noman Asif',    'Lahore High Court',            'noman.asif@court.gov.pk',     9),
('Magistrate Zubia',    'Peshawar District Court',      'zubia.mag@court.gov.pk',      10);

INSERT INTO DIGITAL_ASSET (Name, Type, Value, USER_ID) VALUES
('HBL Savings Account',         'Financial',      250000.00, 1),
('Facebook Profile',            'SocialMedia',    NULL,      1),
('Google Drive Storage',        'CloudStorage',   NULL,      2),
('Meezan Bank Account',         'Financial',      500000.00, 3),
('Instagram Account',           'SocialMedia',    NULL,      4),
('Dropbox Cloud',               'CloudStorage',   NULL,      5),
('UBL Current Account',         'Financial',      120000.00, 6),
('Twitter/X Account',           'SocialMedia',    NULL,      7),
('OneDrive Storage',            'CloudStorage',   NULL,      8),
('Allied Bank Account',         'Financial',      750000.00, 9),
('LinkedIn Profile',            'SocialMedia',    NULL,      2),
('iCloud Storage',              'CloudStorage',   NULL,      3),
('MCB Bank Account',            'Financial',      300000.00, 5),
('YouTube Channel',             'SocialMedia',    NULL,      6),
('Mega Cloud Storage',          'CloudStorage',   NULL,      1);

INSERT INTO FINANCIAL_ASSET (Digital_Asset_ID, AccountNumber, BankName, Balance) VALUES
(1,  12345001, 'HBL',          250000),
(4,  12345002, 'Meezan Bank',  500000),
(7,  12345003, 'UBL',          120000),
(10, 12345004, 'Allied Bank',  750000),
(13, 12345005, 'MCB',          300000);

INSERT INTO CLOUD_STORAGE_ASSET (Digital_Asset_ID, StorageProvider, StorageSize, FileCount) VALUES
(3,  'Google Drive', 15360,  2340),
(6,  'Dropbox',       8192,   980),
(9,  'OneDrive',     51200,  5670),
(12, 'iCloud',       51200,  3200),
(15, 'Mega',         51200,  7890);

INSERT INTO SOCIAL_MEDIA_ASSET (Digital_Asset_ID, PlatformName, Username, ProfileLink) VALUES
(2,  'Facebook',    'ahmed.khan.official',  'https://facebook.com/ahmed.khan.official'),
(5,  'Instagram',   'hina_noor95',          'https://instagram.com/hina_noor95'),
(8,  'Twitter/X',   'usman_ali_tweets',     'https://twitter.com/usman_ali_tweets'),
(11, 'LinkedIn',    'sara-malik-dev',       'https://linkedin.com/in/sara-malik-dev'),
(14, 'YouTube',     'FatimaZahraVlogs',     'https://youtube.com/FatimaZahraVlogs');

INSERT INTO DIGITAL_ASSET_BENEFICIARY (Digital_Asset_ID, BeneficiaryID) VALUES
(1,  1), (1,  2),
(2,  1),
(3,  3),
(4,  4), (4,  5),
(5,  4),
(6,  5),
(7,  6),
(8,  7),
(9,  8),
(10, 9), (10, 1),
(11, 3),
(12, 4),
(13, 5), (13, 6),
(14, 7),
(15, 8);

INSERT INTO ASSET_TRANSFER (Status, Transfer_Date, Digital_Asset_ID, BeneficiaryID, TRIGGER_EVENT_ID, Legal_Authority_ID) VALUES
('Completed', '2026-01-15', 1,  1,  1, 1),
('Completed', '2026-01-15', 2,  1,  1, 1),
('Pending',   NULL,         3,  3,  2, 2),
('Completed', '2025-12-10', 4,  4,  3, 3),
('Pending',   NULL,         5,  4,  4, NULL),
('Pending',   NULL,         6,  5,  5, 4),
('Completed', '2025-11-25', 7,  6,  6, 5),
('Pending',   NULL,         8,  7,  7, NULL),
('Completed', '2026-01-30', 9,  8,  8, 6),
('Completed', '2025-10-15', 10, 9,  9, 7),
('Pending',   NULL,         11, 3,  2, NULL),
('Completed', '2025-12-12', 12, 4,  3, 3),
('Pending',   NULL,         13, 5,  5, 4),
('Completed', '2025-11-28', 14, 7,  6, 5),
('Pending',   NULL,         15, 8,  10, NULL);

INSERT INTO MEMORY_DATA (Content, UploadDate, USER_ID) VALUES
('Wedding photos and videos from 2010',             '2024-01-10', 1),
('Personal diary entries 2015-2020',                '2024-03-22', 1),
('Family trip photos to Turkey',                    '2023-08-15', 2),
('Business documents and contracts',                '2024-02-01', 3),
('Audio recordings of family gatherings',           '2023-12-25', 4),
('Video messages for children',                     '2024-04-05', 5),
('Scanned certificates and awards',                 '2024-01-30', 6),
('Personal letters and correspondence',             '2023-11-10', 7),
('Research papers and publications',                '2024-03-01', 8),
('Property documents scans',                        '2024-04-10', 9),
('Memorial videos',                                 '2024-02-14', 10);

INSERT INTO ACCESS_LOG (Action, Timestamp, USER_ID) VALUES
('Asset HBL Account accessed',          '2026-01-10 09:15:00', 1),
('Beneficiary assignment updated',      '2026-01-11 14:30:00', 1),
('Trigger event submitted',             '2026-02-14 10:00:00', 2),
('Asset transfer initiated',            '2025-12-05 11:45:00', 3),
('Access policy modified',              '2026-03-01 16:20:00', 4),
('Memory data uploaded',                '2026-04-01 08:00:00', 5),
('Legal authority notified',            '2025-11-20 13:15:00', 6),
('Transfer status checked',             '2026-03-15 17:00:00', 7),
('Profile updated',                     '2026-01-25 12:30:00', 8),
('Failed access attempt blocked',       '2026-04-10 03:22:00', 9);
GO

-- =============================================================
-- SECTION 6: SQL QUERIES
-- =============================================================

-- Query 1
SELECT
    u.ID,
    u.Name,
    u.Email,
    COUNT(da.ID)        AS TotalAssets,
    COALESCE(SUM(da.Value), 0) AS TotalAssetValue
FROM [USER] u
LEFT JOIN DIGITAL_ASSET da ON u.ID = da.USER_ID
GROUP BY u.ID, u.Name, u.Email
ORDER BY TotalAssetValue DESC;

-- Query 2
SELECT TOP 5
    u.Name          AS AssetOwner,
    SUM(fa.Balance) AS TotalBankBalance
FROM [USER] u
JOIN DIGITAL_ASSET  da ON u.ID = da.USER_ID
JOIN FINANCIAL_ASSET fa ON da.ID = fa.Digital_Asset_ID
GROUP BY u.ID, u.Name
ORDER BY TotalBankBalance DESC;

-- Query 3
SELECT
    at.ID           AS TransferID,
    u.Name          AS AssetOwner,
    da.Name         AS AssetName,
    da.Type         AS AssetType,
    b.Name          AS Beneficiary,
    te.EventType    AS TriggerType,
    te.EventDate    AS EventDate,
    at.Status
FROM ASSET_TRANSFER at
JOIN DIGITAL_ASSET   da ON at.Digital_Asset_ID = da.ID
JOIN [USER]          u ON da.USER_ID           = u.ID
JOIN BENEFICIARY      b ON at.BeneficiaryID     = b.ID
JOIN TRIGGER_EVENT   te ON at.TRIGGER_EVENT_ID  = te.ID
WHERE at.Status = 'Pending';

-- Query 4
SELECT
    b.ID,
    b.Name          AS BeneficiaryName,
    b.Email,
    COUNT(dab.Digital_Asset_ID) AS AssignedAssets
FROM BENEFICIARY b
JOIN DIGITAL_ASSET_BENEFICIARY dab ON b.ID = dab.BeneficiaryID
GROUP BY b.ID, b.Name, b.Email
HAVING COUNT(dab.Digital_Asset_ID) > 1
ORDER BY AssignedAssets DESC;

-- Query 5
SELECT
    u.ID,
    u.Name,
    u.Email
FROM [USER] u
WHERE u.ID NOT IN (
    SELECT DISTINCT da.USER_ID
    FROM DIGITAL_ASSET da
    JOIN DIGITAL_ASSET_BENEFICIARY dab ON da.ID = dab.Digital_Asset_ID
);

-- Query 6
SELECT
    YEAR(EventDate)     AS Year,
    MONTH(EventDate)    AS Month,
    DATENAME(month, EventDate) AS MonthName,
    COUNT(*)            AS EventCount,
    SUM(CASE WHEN Status = 'Verified' THEN 1 ELSE 0 END)  AS Verified,
    SUM(CASE WHEN Status = 'Pending'  THEN 1 ELSE 0 END)  AS Pending,
    SUM(CASE WHEN Status = 'Rejected' THEN 1 ELSE 0 END)  AS Rejected
FROM TRIGGER_EVENT
GROUP BY YEAR(EventDate), MONTH(EventDate), DATENAME(month, EventDate)
ORDER BY Year, Month;

-- Query 7
SELECT
    da.ID,
    da.Name,
    da.Type,
    da.Value,
    u.Name AS Owner
FROM DIGITAL_ASSET da
JOIN [USER] u ON da.USER_ID = u.ID
WHERE da.Value > (
    SELECT AVG(Value) FROM DIGITAL_ASSET WHERE Value IS NOT NULL
)
ORDER BY da.Value DESC;

-- Query 8
SELECT
    al.ID,
    al.Action,
    al.Timestamp,
    u.Name AS UserName
FROM ACCESS_LOG al
JOIN [USER] u ON al.USER_ID = u.ID
WHERE al.USER_ID = 1
ORDER BY al.Timestamp DESC;

-- Query 9
SELECT
    Type,
    COUNT(*)                            AS AssetCount,
    ROUND(AVG(COALESCE(Value, 0)), 2)   AS AvgValue,
    SUM(COALESCE(Value, 0))             AS TotalValue
FROM DIGITAL_ASSET
GROUP BY Type;

-- Query 10
SELECT
    b.ID,
    b.Name,
    b.Email
FROM BENEFICIARY b
WHERE b.ID NOT IN (
    SELECT DISTINCT BeneficiaryID
    FROM ASSET_TRANSFER
    WHERE Status = 'Completed'
);

-- Query 11
SELECT
    da.Name         AS AssetName,
    u.Name          AS Owner,
    csa.StorageProvider,
    csa.StorageSize AS StorageMB,
    csa.FileCount
FROM CLOUD_STORAGE_ASSET csa
JOIN DIGITAL_ASSET da ON csa.Digital_Asset_ID = da.ID
JOIN [USER] u ON da.USER_ID = u.ID
WHERE csa.FileCount > 3000
ORDER BY csa.FileCount DESC;

-- Query 12
SELECT
    la.Name             AS LegalAuthority,
    la.Organization,
    COUNT(at.ID)        AS TotalAssigned,
    SUM(CASE WHEN at.Status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
    ROUND(
        100.0 * SUM(CASE WHEN at.Status = 'Completed' THEN 1 ELSE 0 END) / COUNT(at.ID), 2
    ) AS CompletionRate
FROM LEGAL_AUTHORITY la
LEFT JOIN ASSET_TRANSFER at ON la.ID = at.Legal_Authority_ID
GROUP BY la.ID, la.Name, la.Organization
ORDER BY CompletionRate DESC;

-- Query 13
SELECT DISTINCT
    u.ID,
    u.Name,
    u.Email
FROM [USER] u
WHERE u.ID IN (
    SELECT USER_ID FROM MEMORY_DATA
)
AND u.ID IN (
    SELECT da.USER_ID
    FROM DIGITAL_ASSET da
    JOIN ASSET_TRANSFER at ON da.ID = at.Digital_Asset_ID
    WHERE at.Status = 'Pending'
);

-- Query 14
SELECT
    u.Name                  AS UserName,
    COUNT(da.ID)            AS TotalAssets,
    SUM(CASE WHEN da.Type = 'Financial'    THEN 1 ELSE 0 END) AS FinancialAssets,
    SUM(CASE WHEN da.Type = 'SocialMedia'  THEN 1 ELSE 0 END) AS SocialAssets,
    SUM(CASE WHEN da.Type = 'CloudStorage' THEN 1 ELSE 0 END) AS CloudAssets,
    COALESCE(SUM(fa.Balance), 0)                               AS TotalBankBalance,
    COUNT(md.ID)            AS MemoryItems
FROM [USER] u
LEFT JOIN DIGITAL_ASSET    da  ON u.ID = da.USER_ID
LEFT JOIN FINANCIAL_ASSET  fa  ON da.ID = fa.Digital_Asset_ID
LEFT JOIN MEMORY_DATA      md  ON u.ID = md.USER_ID
GROUP BY u.ID, u.Name
ORDER BY TotalBankBalance DESC;

-- Query 15
SELECT
    da.ID,
    da.Name,
    da.Type,
    u.Name AS Owner
FROM DIGITAL_ASSET da
JOIN [USER] u ON da.USER_ID = u.ID
WHERE da.Access_Policy_ID IS NULL;

-- Query 16
SELECT
    u.Name          AS OwnerName,
    sma.PlatformName,
    sma.Username,
    sma.ProfileLink,
    b.Name          AS BeneficiaryName,
    ap.AccessLevel  AS AccessLevel
FROM SOCIAL_MEDIA_ASSET sma
JOIN DIGITAL_ASSET   da  ON sma.Digital_Asset_ID = da.ID
JOIN [USER]          u  ON da.USER_ID            = u.ID
JOIN DIGITAL_ASSET_BENEFICIARY dab ON da.ID = dab.Digital_Asset_ID
JOIN BENEFICIARY      b  ON dab.BeneficiaryID     = b.ID
LEFT JOIN ACCESS_POLICY ap ON b.Access_Policy_ID  = ap.ID;

-- Query 17
SELECT
    u.ID,
    u.Name,
    COUNT(al.ID)    AS AccessCount
FROM ACCESS_LOG al
JOIN [USER] u ON al.USER_ID = u.ID
WHERE al.Timestamp >= DATEADD(day, -90, GETDATE())
GROUP BY u.ID, u.Name
HAVING COUNT(al.ID) >= 1
ORDER BY AccessCount DESC;

-- Query 18
SELECT
    at.ID           AS TransferID,
    da.Name         AS AssetName,
    b.Name          AS Beneficiary,
    te.Status       AS TriggerStatus,
    at.Status       AS TransferStatus
FROM ASSET_TRANSFER at
JOIN DIGITAL_ASSET  da ON at.Digital_Asset_ID = da.ID
JOIN BENEFICIARY     b ON at.BeneficiaryID    = b.ID
JOIN TRIGGER_EVENT  te ON at.TRIGGER_EVENT_ID = te.ID
WHERE te.Status = 'Verified' AND at.Status = 'Pending';
GO

-- =============================================================
-- SECTION 7: DATA MANIPULATION OPERATIONS
-- =============================================================
UPDATE TRIGGER_EVENT
SET Status = 'Verified'
WHERE ID = 5 AND Status = 'Pending';

UPDATE BENEFICIARY
SET Access_Policy_ID = 1
WHERE ID = 4;

UPDATE FINANCIAL_ASSET
SET Balance = 280000
WHERE Digital_Asset_ID = 1;

DELETE FROM TRIGGER_EVENT
WHERE Status = 'Rejected' AND ID NOT IN (
    SELECT TRIGGER_EVENT_ID FROM ASSET_TRANSFER WHERE Status = 'Pending'
);

INSERT INTO [USER] (Name, Email, Password, Phone, DOB)
VALUES ('Hamza Baig', 'hamza.baig@email.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'hamzapass'), 2), '0303-1122334', '2000-06-06');

DECLARE @NewUserID INT = SCOPE_IDENTITY();

INSERT INTO DIGITAL_ASSET (Name, Type, Value, USER_ID)
VALUES ('JS Bank Account', 'Financial', 95000, @NewUserID);

DECLARE @NewAssetID INT = SCOPE_IDENTITY();

INSERT INTO FINANCIAL_ASSET (Digital_Asset_ID, AccountNumber, BankName, Balance)
VALUES (@NewAssetID, 99988877, 'JS Bank', 95000);
GO

-- =============================================================
-- SECTION 8: VERIFY VIEWS
-- =============================================================
SELECT * FROM vw_PendingTransfers;
SELECT * FROM vw_UserAssetInventory;
SELECT * FROM vw_BeneficiaryAccess;
GO
