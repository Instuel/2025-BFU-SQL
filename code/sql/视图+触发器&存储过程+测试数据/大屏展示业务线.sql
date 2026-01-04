/* =====================================================================
   Businessline5 Exec Dashboard - Supplemental Patch v8
   Fix: previous v7 referenced non-existing column Module_Code in Dashboard_Config.
        This patch:
         1) Ensures minimal columns exist (Config_Code, Refresh_Unit, Refresh_Interval)
         2) Forces Refresh_Unit = NULL for our test configs (passes CK because Refresh_Unit IS NULL is allowed)
         3) Inserts any missing EXEC_DASH_01..23 rows using ONLY columns that actually exist in your table
            (dynamic intersection insert; idempotent)
   Target DB: current database
   SQL Server: 2012+
   ===================================================================== */

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    /* 0) Pre-check */
    IF OBJECT_ID('dbo.Dashboard_Config','U') IS NULL
        THROW 51000, 'Missing table dbo.Dashboard_Config. Please run the base scripts or FULL patch first.', 1;

    /* 1) Ensure minimal columns exist (added safely) */
    IF COL_LENGTH('dbo.Dashboard_Config','Config_Code') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Config_Code NVARCHAR(30) NULL;');

    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Unit') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Refresh_Unit NVARCHAR(10) NULL;');

    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Interval') IS NULL
        EXEC(N'ALTER TABLE dbo.Dashboard_Config ADD Refresh_Interval INT NULL;');

    /* 2) Make our configs CK-safe: Refresh_Unit = NULL (allowed by your CK) */
    EXEC(N'
        UPDATE dbo.Dashboard_Config
        SET Refresh_Unit = NULL
        WHERE Config_Code LIKE ''EXEC_DASH_%'';
    ');

    /* 3) Prepare desired 23 config rows (superset columns; we will insert intersection only) */
    IF OBJECT_ID('tempdb..#cfg') IS NOT NULL DROP TABLE #cfg;
    CREATE TABLE #cfg(
        Config_Code       NVARCHAR(30)  NOT NULL,
        Module_Name       NVARCHAR(50)  NULL,
        Module_Code       NVARCHAR(50)  NULL,
        Module_Url        NVARCHAR(200) NULL,
        Refresh_Rate      NVARCHAR(20)  NULL,
        Refresh_Interval  INT           NULL,
        Refresh_Unit      NVARCHAR(10)  NULL,
        Sort_Rule         NVARCHAR(50)  NULL,
        Display_Fields    NVARCHAR(1000) NULL,
        Auth_Level        NVARCHAR(20)  NULL,
        Created_At        DATETIME2(0)  NULL,
        Updated_At        DATETIME2(0)  NULL
    );

    DECLARE @i INT = 1;
    WHILE @i <= 23
    BEGIN
        INSERT INTO #cfg(
            Config_Code, Module_Name, Module_Code, Module_Url,
            Refresh_Rate, Refresh_Interval, Refresh_Unit,
            Sort_Rule, Display_Fields, Auth_Level, Created_At, Updated_At
        )
        VALUES(
            CONCAT('EXEC_DASH_', RIGHT('00' + CAST(@i AS VARCHAR(2)), 2)),
            N'企业管理层大屏', N'EXEC', N'/exec/dashboard',
            N'1h', 1, NULL,              -- Refresh_Unit kept NULL to pass CK
            N'default',
            N'Total_Consumption_Kwh,Water_Consumption,Steam_Consumption,Gas_Consumption,Pv_Generation,Alarm_High,Alarm_Medium,Alarm_Low,Alarm_Unhandled',
            N'exec_user',
            SYSUTCDATETIME(), SYSUTCDATETIME()
        );
        SET @i += 1;
    END

    /* 4) Build dynamic INSERT with only existing target columns (intersection) */
    DECLARE
        @insertCols NVARCHAR(MAX) = N'',
        @selectCols NVARCHAR(MAX) = N'';

    /* helper macro (manual IFs) */
    IF COL_LENGTH('dbo.Dashboard_Config','Config_Code') IS NOT NULL BEGIN
        SET @insertCols += N',[Config_Code]';
        SET @selectCols += N',c.[Config_Code]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Module_Name') IS NOT NULL BEGIN
        SET @insertCols += N',[Module_Name]';
        SET @selectCols += N',c.[Module_Name]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Module_Code') IS NOT NULL BEGIN
        SET @insertCols += N',[Module_Code]';
        SET @selectCols += N',c.[Module_Code]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Module_Url') IS NOT NULL BEGIN
        SET @insertCols += N',[Module_Url]';
        SET @selectCols += N',c.[Module_Url]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Rate') IS NOT NULL BEGIN
        SET @insertCols += N',[Refresh_Rate]';
        SET @selectCols += N',c.[Refresh_Rate]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Interval') IS NOT NULL BEGIN
        SET @insertCols += N',[Refresh_Interval]';
        SET @selectCols += N',c.[Refresh_Interval]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Refresh_Unit') IS NOT NULL BEGIN
        SET @insertCols += N',[Refresh_Unit]';
        SET @selectCols += N',c.[Refresh_Unit]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Sort_Rule') IS NOT NULL BEGIN
        SET @insertCols += N',[Sort_Rule]';
        SET @selectCols += N',c.[Sort_Rule]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Display_Fields') IS NOT NULL BEGIN
        SET @insertCols += N',[Display_Fields]';
        SET @selectCols += N',c.[Display_Fields]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Auth_Level') IS NOT NULL BEGIN
        SET @insertCols += N',[Auth_Level]';
        SET @selectCols += N',c.[Auth_Level]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Created_At') IS NOT NULL BEGIN
        SET @insertCols += N',[Created_At]';
        SET @selectCols += N',c.[Created_At]';
    END
    IF COL_LENGTH('dbo.Dashboard_Config','Updated_At') IS NOT NULL BEGIN
        SET @insertCols += N',[Updated_At]';
        SET @selectCols += N',c.[Updated_At]';
    END

    /* strip leading comma */
    SET @insertCols = STUFF(@insertCols, 1, 1, N'');
    SET @selectCols = STUFF(@selectCols, 1, 1, N'');

    IF @insertCols IS NULL OR LTRIM(RTRIM(@insertCols)) = N''
        THROW 51001, 'No compatible columns found to insert into dbo.Dashboard_Config.', 1;

    DECLARE @sql NVARCHAR(MAX) = N'
        INSERT INTO dbo.Dashboard_Config(' + @insertCols + N')
        SELECT ' + @selectCols + N'
        FROM #cfg c
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Dashboard_Config t
            WHERE t.Config_Code = c.Config_Code
        );
    ';

    EXEC sp_executesql @sql;

    COMMIT;
    PRINT 'Supplemental Patch v8 applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @line INT = ERROR_LINE();
    RAISERROR('Supplemental Patch v8 failed at line %d: %s', 16, 1, @line, @msg);
END CATCH;
