-- ============================================================
-- FILE: sql/01_create_schema.sql
-- PROJECT: Toronto Fire Incident Analysis
-- PURPOSE: Create database, fact table, views, and indexes
-- RUN IN: SSMS connected to localhost
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- STEP 1: CREATE DATABASE
-- ─────────────────────────────────────────────────────────────
CREATE DATABASE FireIncidentsDB;
GO

USE FireIncidentsDB;
GO


-- ─────────────────────────────────────────────────────────────
-- STEP 2: CREATE FACT TABLE
-- All 49 columns from the cleaned CSV.
-- Data types chosen to match pandas output from 02_load_to_sql.py
-- Schema fixes already applied here (VARCHAR, FLOAT) to avoid
-- the ALTER TABLE steps that were needed on first attempt.
-- ─────────────────────────────────────────────────────────────
CREATE TABLE fact_incidents (
    _id                                                          INT             PRIMARY KEY,
    Incident_Number                                              VARCHAR(20),
    Initial_CAD_Event_Type                                       NVARCHAR(255),
    Final_Incident_Type                                          NVARCHAR(255),
    Exposures                                                    FLOAT,
    Incident_Station_Area                                        VARCHAR(50),     -- VARCHAR not INT: values like '145P'
    Incident_Ward                                                SMALLINT,
    Intersection                                                 NVARCHAR(255),
    Latitude                                                     FLOAT,
    Longitude                                                    FLOAT,
    Property_Use                                                 NVARCHAR(255),
    Building_Status                                              NVARCHAR(255),
    TFS_Alarm_Time                                               DATETIME2,
    TFS_Arrival_Time                                             DATETIME2,
    Ext_agent_app_or_defer_time                                  DATETIME2,
    Fire_Under_Control_Time                                      DATETIME2,
    Last_TFS_Unit_Clear_Time                                     DATETIME2,
    Number_of_responding_apparatus                               SMALLINT,
    Number_of_responding_personnel                               SMALLINT,
    Count_of_Persons_Rescued                                     SMALLINT,
    TFS_Firefighter_Casualties                                   SMALLINT,
    Civilian_Casualties                                          SMALLINT,
    Estimated_Number_Of_Persons_Displaced                        SMALLINT,
    Estimated_Dollar_Loss                                        FLOAT,           -- FLOAT not DECIMAL: matches pandas float64
    Business_Impact                                              NVARCHAR(255),
    Status_of_Fire_On_Arrival                                    NVARCHAR(255),
    Method_Of_Fire_Control                                       NVARCHAR(255),
    Area_of_Origin                                               NVARCHAR(255),
    Level_Of_Origin                                              NVARCHAR(255),
    Extent_Of_Fire                                               NVARCHAR(255),
    Smoke_Spread                                                 NVARCHAR(255),
    Ignition_Source                                              NVARCHAR(255),
    Material_First_Ignited                                       NVARCHAR(255),
    Possible_Cause                                               NVARCHAR(255),
    Smoke_Alarm_at_Fire_Origin                                   NVARCHAR(255),
    Smoke_Alarm_at_Fire_Origin_Alarm_Failure                     NVARCHAR(255),
    Smoke_Alarm_at_Fire_Origin_Alarm_Type                        NVARCHAR(255),
    Smoke_Alarm_Impact_on_Persons_Evacuating_Impact_on_Evacuation NVARCHAR(255),
    Fire_Alarm_System_Presence                                   NVARCHAR(255),
    Fire_Alarm_System_Operation                                  NVARCHAR(255),
    Fire_Alarm_System_Impact_on_Evacuation                       NVARCHAR(255),
    Sprinkler_System_Presence                                    NVARCHAR(255),
    Sprinkler_System_Operation                                   NVARCHAR(255),
    response_time_min                                            FLOAT,
    control_time_min                                             FLOAT,
    year                                                         SMALLINT,
    month                                                        SMALLINT,
    hour_of_day                                                  SMALLINT,
    day_of_week                                                  SMALLINT
);
GO


-- ─────────────────────────────────────────────────────────────
-- STEP 3: CREATE VIEWS
-- These 3 views are what Power BI connects to directly.
-- Run each block separately to catch errors one at a time.
-- ─────────────────────────────────────────────────────────────

-- View 1: Average response time, total incidents, avg casualties per ward
CREATE VIEW vw_ResponseSummary AS
SELECT
    Incident_Ward,
    COUNT(*)                                            AS total_incidents,
    ROUND(AVG(response_time_min), 2)                    AS avg_response_time_min,
    ROUND(AVG(CAST(Civilian_Casualties AS FLOAT)), 3)   AS avg_civilian_casualties
FROM fact_incidents
GROUP BY Incident_Ward;
GO

-- View 2: Monthly incident count and total dollar loss trend
CREATE VIEW vw_MonthlyTrend AS
SELECT
    year,
    month,
    COUNT(*)                    AS total_incidents,
    SUM(Estimated_Dollar_Loss)  AS total_dollar_loss
FROM fact_incidents
GROUP BY year, month;
GO

-- View 3: Ward risk ranking by total dollar loss (used for Power BI map)
CREATE VIEW vw_WardRisk AS
SELECT
    Incident_Ward,
    COUNT(*)                                        AS total_incidents,
    SUM(Estimated_Dollar_Loss)                      AS total_dollar_loss,
    SUM(Civilian_Casualties)                        AS total_casualties,
    ROUND(AVG(response_time_min), 2)                AS avg_response_time_min,
    RANK() OVER (ORDER BY SUM(Estimated_Dollar_Loss) DESC) AS risk_rank
FROM fact_incidents
GROUP BY Incident_Ward;
GO


-- ─────────────────────────────────────────────────────────────
-- STEP 4: CREATE INDEXES
-- Improves Power BI query performance on common filter columns
-- ─────────────────────────────────────────────────────────────
CREATE INDEX idx_ward  ON fact_incidents (Incident_Ward);
CREATE INDEX idx_alarm ON fact_incidents (TFS_Alarm_Time);
CREATE INDEX idx_type  ON fact_incidents (Final_Incident_Type);
CREATE INDEX idx_year  ON fact_incidents (year);
GO


-- ─────────────────────────────────────────────────────────────
-- STEP 5: VERIFY EVERYTHING WAS CREATED
-- ─────────────────────────────────────────────────────────────
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'FireIncidentsDB';
-- Expected: fact_incidents, vw_ResponseSummary, vw_MonthlyTrend, vw_WardRisk
GO

-- ─────────────────────────────────────────────────────────────
-- Fix 1 — Incident_Station_Area
-- The CSV contains alphanumeric values like '145P' but the column was created as INT.
-- ─────────────────────────────────────────────────────────────
ALTER TABLE fact_incidents
ALTER COLUMN Incident_Station_Area VARCHAR(50) NULL;

-- ─────────────────────────────────────────────────────────────
-- Fix 2 — Estimated_Dollar_Loss
-- The CSV has float64 values but the column was created as DECIMAL. Changed to FLOAT for compatibility.
-- ─────────────────────────────────────────────────────────────
ALTER TABLE fact_incidents
ALTER COLUMN Estimated_Dollar_Loss FLOAT NULL;