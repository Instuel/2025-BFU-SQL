-- 能源管理员功能扩展：数据复核、排查任务、优化方案

IF OBJECT_ID('Energy_Data_Review', 'U') IS NULL
BEGIN
    CREATE TABLE Energy_Data_Review (
        Review_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Data_ID BIGINT NOT NULL,
        Review_Status NVARCHAR(10) DEFAULT '待复核',
        Reviewer NVARCHAR(50),
        Review_Remark NVARCHAR(200),
        Review_Time DATETIME2(0),

        CONSTRAINT FK_EnergyReview_Data FOREIGN KEY (Data_ID) REFERENCES Data_Energy(Data_ID),
        CONSTRAINT CK_EnergyReview_Status CHECK (Review_Status IN ('待复核','已复核','异常确认'))
    );
END
GO

IF OBJECT_ID('Energy_Investigation', 'U') IS NULL
BEGIN
    CREATE TABLE Energy_Investigation (
        Investigation_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Factory_ID BIGINT NOT NULL,
        Energy_Type NVARCHAR(10) NOT NULL,
        Level NVARCHAR(10) DEFAULT '重点排查',
        Issue_Desc NVARCHAR(200) NOT NULL,
        Status NVARCHAR(10) DEFAULT '进行中',
        Owner NVARCHAR(50),
        Create_Time DATETIME2(0),

        CONSTRAINT FK_EnergyInvestigation_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
        CONSTRAINT CK_EnergyInvestigation_Level CHECK (Level IN ('重点排查','持续观察')),
        CONSTRAINT CK_EnergyInvestigation_Status CHECK (Status IN ('进行中','已完成'))
    );
END
GO

IF OBJECT_ID('Energy_Optimization_Plan', 'U') IS NULL
BEGIN
    CREATE TABLE Energy_Optimization_Plan (
        Plan_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Factory_ID BIGINT NOT NULL,
        Energy_Type NVARCHAR(10) NOT NULL,
        Plan_Title NVARCHAR(100) NOT NULL,
        Plan_Action NVARCHAR(200) NOT NULL,
        Start_Date DATE NOT NULL,
        Target_Reduction DECIMAL(5,2),
        Actual_Reduction DECIMAL(5,2),
        Status NVARCHAR(10) DEFAULT '执行中',
        Owner NVARCHAR(50),

        CONSTRAINT FK_EnergyPlan_Factory FOREIGN KEY (Factory_ID) REFERENCES Base_Factory(Factory_ID),
        CONSTRAINT CK_EnergyPlan_Status CHECK (Status IN ('执行中','已完成','待启动'))
    );
END
GO
