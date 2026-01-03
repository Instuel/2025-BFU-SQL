/* ============================================================
   数据分析师业务扩展脚本
   - 光伏天气因子数据
   - 产线产量数据与能耗映射
   适用数据库：SQL Server
   ============================================================ */
USE SQL_BFU;
GO

SET NOCOUNT ON;

IF OBJECT_ID('dbo.PV_Weather_Daily', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PV_Weather_Daily (
        Weather_ID    BIGINT IDENTITY(1,1) PRIMARY KEY,
        Point_ID      BIGINT NOT NULL,
        Weather_Date  DATE NOT NULL,
        Cloud_Cover   INT NULL,
        Temperature  DECIMAL(5,2) NULL,
        Irradiance   DECIMAL(8,2) NULL,
        Weather_Desc NVARCHAR(100) NULL,

        CONSTRAINT FK_PVWeather_Point FOREIGN KEY (Point_ID) REFERENCES dbo.PV_Grid_Point(Point_ID)
    );
END;

IF OBJECT_ID('dbo.Production_Line', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Production_Line (
        Line_ID         BIGINT IDENTITY(1,1) PRIMARY KEY,
        Line_Name       NVARCHAR(50) NOT NULL,
        Factory_ID      BIGINT NOT NULL,
        Product_Type    NVARCHAR(50) NULL,
        Design_Capacity DECIMAL(12,2) NULL,
        Run_Status      NVARCHAR(10) DEFAULT '运行',

        CONSTRAINT FK_Line_Factory FOREIGN KEY (Factory_ID) REFERENCES dbo.Base_Factory(Factory_ID)
    );
END;

IF OBJECT_ID('dbo.Data_Line_Output', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Data_Line_Output (
        Output_ID  BIGINT IDENTITY(1,1) PRIMARY KEY,
        Line_ID    BIGINT NOT NULL,
        Stat_Date  DATE NOT NULL,
        Output_Qty DECIMAL(12,3) NULL,
        Unit       NVARCHAR(10) NULL,

        CONSTRAINT FK_Output_Line FOREIGN KEY (Line_ID) REFERENCES dbo.Production_Line(Line_ID)
    );
END;

IF OBJECT_ID('dbo.Energy_Line_Map', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Energy_Line_Map (
        Map_ID  BIGINT IDENTITY(1,1) PRIMARY KEY,
        Line_ID BIGINT NOT NULL,
        Meter_ID BIGINT NOT NULL,
        Weight DECIMAL(6,3) DEFAULT 1.000,

        CONSTRAINT FK_LineMap_Line FOREIGN KEY (Line_ID) REFERENCES dbo.Production_Line(Line_ID),
        CONSTRAINT FK_LineMap_Meter FOREIGN KEY (Meter_ID) REFERENCES dbo.Energy_Meter(Meter_ID)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_PVWeather_PointDate' AND object_id = OBJECT_ID('dbo.PV_Weather_Daily'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_PVWeather_PointDate
    ON dbo.PV_Weather_Daily (Point_ID, Weather_Date);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Line_Output_Date' AND object_id = OBJECT_ID('dbo.Data_Line_Output'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Line_Output_Date
    ON dbo.Data_Line_Output (Line_ID, Stat_Date);
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IDX_Line_Map' AND object_id = OBJECT_ID('dbo.Energy_Line_Map'))
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Line_Map
    ON dbo.Energy_Line_Map (Line_ID, Meter_ID);
END;
