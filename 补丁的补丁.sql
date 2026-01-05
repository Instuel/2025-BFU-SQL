/* ============================================================
   Smart Energy Management System - Alarm/O&M Patch Pack
   Purpose:
     1) Fix "对象名 'Maintenance_Plan' 无效" by creating dbo.Maintenance_Plan
     2) Fix "列名 'Review_Feedback' 无效" by adding Work_Order.Review_Feedback
   Target DB: SQL_BFU
   Safe to run repeatedly (idempotent)
   ============================================================ */

USE SQL_BFU;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    /* ============================================================
       A) Fix: Work_Order missing column Review_Feedback
       ============================================================ */
    IF OBJECT_ID('dbo.Work_Order','U') IS NULL
        THROW 51001, 'Missing table dbo.Work_Order. Please run the base init script first.', 1;

    IF COL_LENGTH('dbo.Work_Order', 'Review_Feedback') IS NULL
    BEGIN
        ALTER TABLE dbo.Work_Order
        ADD Review_Feedback NVARCHAR(500) NULL;
        PRINT N'✓ Added column dbo.Work_Order.Review_Feedback';
    END
    ELSE
        PRINT N'✓ dbo.Work_Order.Review_Feedback already exists';

    /* ============================================================
       B) Fix: Missing table Maintenance_Plan
       Must match DAO-required columns:
         Plan_ID, Ledger_ID, Plan_Type, Plan_Content, Plan_Date,
         Owner_Name, Status, Created_At
       ============================================================ */
    IF OBJECT_ID('dbo.Maintenance_Plan','U') IS NULL
    BEGIN
        CREATE TABLE dbo.Maintenance_Plan (
            Plan_ID      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Maintenance_Plan PRIMARY KEY,
            Ledger_ID    BIGINT NULL,              -- FK to Device_Ledger(Ledger_ID), nullable for compatibility
            Plan_Type    NVARCHAR(50)  NULL,
            Plan_Content NVARCHAR(500) NULL,
            Plan_Date    DATE          NULL,
            Owner_Name   NVARCHAR(50)  NULL,
            Status       NVARCHAR(20)  NULL,
            Created_At   DATETIME2(0)  NULL
        );
        PRINT N'✓ Created table dbo.Maintenance_Plan';
    END
    ELSE
        PRINT N'✓ dbo.Maintenance_Plan already exists';

    /* Ensure missing columns are added if table existed but was incomplete */
    IF COL_LENGTH('dbo.Maintenance_Plan','Plan_ID') IS NULL
        THROW 51002, 'dbo.Maintenance_Plan exists but lacks Plan_ID. Please check table definition manually.', 1;

    IF COL_LENGTH('dbo.Maintenance_Plan','Ledger_ID') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Ledger_ID BIGINT NULL;

    IF COL_LENGTH('dbo.Maintenance_Plan','Plan_Type') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Plan_Type NVARCHAR(50) NULL;

    IF COL_LENGTH('dbo.Maintenance_Plan','Plan_Content') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Plan_Content NVARCHAR(500) NULL;

    IF COL_LENGTH('dbo.Maintenance_Plan','Plan_Date') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Plan_Date DATE NULL;

    IF COL_LENGTH('dbo.Maintenance_Plan','Owner_Name') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Owner_Name NVARCHAR(50) NULL;

    IF COL_LENGTH('dbo.Maintenance_Plan','Status') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Status NVARCHAR(20) NULL;

    IF COL_LENGTH('dbo.Maintenance_Plan','Created_At') IS NULL
        ALTER TABLE dbo.Maintenance_Plan ADD Created_At DATETIME2(0) NULL;

    /* Optional but recommended: FK to Device_Ledger (only if that table exists and FK not yet added) */
    IF OBJECT_ID('dbo.Device_Ledger','U') IS NOT NULL
       AND COL_LENGTH('dbo.Maintenance_Plan','Ledger_ID') IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = 'FK_MaintPlan_Ledger'
              AND parent_object_id = OBJECT_ID('dbo.Maintenance_Plan')
       )
    BEGIN
        ALTER TABLE dbo.Maintenance_Plan
        ADD CONSTRAINT FK_MaintPlan_Ledger
            FOREIGN KEY (Ledger_ID) REFERENCES dbo.Device_Ledger(Ledger_ID)
            ON DELETE SET NULL;
        PRINT N'✓ Added FK dbo.Maintenance_Plan(Ledger_ID) -> dbo.Device_Ledger(Ledger_ID)';
    END

    /* Index for fast lookup by Ledger_ID */
    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID('dbo.Maintenance_Plan')
          AND name = 'IX_MaintPlan_Ledger_PlanDate'
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_MaintPlan_Ledger_PlanDate
        ON dbo.Maintenance_Plan(Ledger_ID, Plan_Date, Plan_ID);
        PRINT N'✓ Created index IX_MaintPlan_Ledger_PlanDate';
    END
    ELSE
        PRINT N'✓ Index IX_MaintPlan_Ledger_PlanDate already exists';

    COMMIT TRAN;
    PRINT N'✅ Alarm/O&M patch pack applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;

    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @sev INT = ERROR_SEVERITY();
    DECLARE @sta INT = ERROR_STATE();

    RAISERROR(@msg, @sev, @sta);
END CATCH;
GO
