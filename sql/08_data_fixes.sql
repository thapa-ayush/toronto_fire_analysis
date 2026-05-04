USE FireIncidentsDB;
GO

-- ─────────────────────────────────────────────────────────────
-- Check null values in Incident_Ward before applying fixes
-- ─────────────────────────────────────────────────────────────
SELECT COUNT(*) 
FROM fact_incidents 
WHERE Incident_Ward IS NULL;

-- ============================================================
-- FILE: sql/08_data_fixes.sql
-- PURPOSE: Post-load data quality fixes applied to fact_incidents
-- RUN IN: SSMS connected to FireIncidentsDB
-- NOTE: Run this ONCE after initial load — do not re-run
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- FIX 1: Replace NULL Incident_Ward with 999
-- Reason: Power BI drops NULLs silently from visuals and shows
-- blank entries in slicers. 999 is safe — Toronto only has
-- wards 1-44. Affects 153 rows.
-- ─────────────────────────────────────────────────────────────
UPDATE fact_incidents
SET Incident_Ward = 999
WHERE Incident_Ward IS NULL;
GO

-- Verify
SELECT COUNT(*) AS remaining_nulls
FROM fact_incidents
WHERE Incident_Ward IS NULL;
-- Expected: 0
GO


-- ─────────────────────────────────────────────────────────────
-- FIX 2: Update vw_ResponseSummary to label ward 999 as Unknown
-- ─────────────────────────────────────────────────────────────
ALTER VIEW vw_ResponseSummary AS
SELECT
    CASE
        WHEN Incident_Ward = 999 THEN 'Unknown'
        ELSE CAST(Incident_Ward AS NVARCHAR(10))
    END                                                     AS Ward_Label,
    Incident_Ward,
    COUNT(*)                                                AS total_incidents,
    ROUND(AVG(response_time_min), 2)                        AS avg_response_time_min,
    ROUND(AVG(CAST(Civilian_Casualties AS FLOAT)), 3)       AS avg_civilian_casualties
FROM fact_incidents
GROUP BY Incident_Ward;
GO


-- ─────────────────────────────────────────────────────────────
-- FIX 3: Update vw_WardRisk to label ward 999 as Unknown
-- ─────────────────────────────────────────────────────────────
ALTER VIEW vw_WardRisk AS
SELECT
    CASE
        WHEN Incident_Ward = 999 THEN 'Unknown'
        ELSE CAST(Incident_Ward AS NVARCHAR(10))
    END                                                     AS Ward_Label,
    Incident_Ward,
    COUNT(*)                                                AS total_incidents,
    SUM(Estimated_Dollar_Loss)                              AS total_dollar_loss,
    SUM(Civilian_Casualties)                                AS total_casualties,
    ROUND(AVG(response_time_min), 2)                        AS avg_response_time_min,
    RANK() OVER (ORDER BY SUM(Estimated_Dollar_Loss) DESC)  AS risk_rank
FROM fact_incidents
GROUP BY Incident_Ward;
GO

-- ─────────────────────────────────────────────────────────────
-- FIX 4: Update tp show "Unknown" for ward 0 as well
-- ─────────────────────────────────────────────────────────────
ALTER VIEW vw_WardRisk AS
SELECT
    CASE
        WHEN Incident_Ward = 999 THEN 'Unknown'
        WHEN Incident_Ward = 0 THEN 'Unknown (0)'
        ELSE CAST(Incident_Ward AS NVARCHAR(10))
    END                                                     AS Ward_Label,
    Incident_Ward,
    COUNT(*)                                                AS total_incidents,
    SUM(Estimated_Dollar_Loss)                              AS total_dollar_loss,
    SUM(Civilian_Casualties)                                AS total_casualties,
    ROUND(AVG(response_time_min), 2)                        AS avg_response_time_min,
    RANK() OVER (ORDER BY SUM(Estimated_Dollar_Loss) DESC)  AS risk_rank
FROM fact_incidents
GROUP BY Incident_Ward;
GO

ALTER VIEW vw_ResponseSummary AS
SELECT
    CASE
        WHEN Incident_Ward = 999 THEN 'Unknown'
        WHEN Incident_Ward = 0 THEN 'Unknown (0)'
        ELSE CAST(Incident_Ward AS NVARCHAR(10))
    END                                                     AS Ward_Label,
    Incident_Ward,
    COUNT(*)                                                AS total_incidents,
    ROUND(AVG(response_time_min), 2)                        AS avg_response_time_min,
    ROUND(AVG(CAST(Civilian_Casualties AS FLOAT)), 3)       AS avg_civilian_casualties
FROM fact_incidents
GROUP BY Incident_Ward;
GO


-- ─────────────────────────────────────────────────────────────
-- VERIFICATION
-- ─────────────────────────────────────────────────────────────
SELECT Ward_Label, Incident_Ward, total_incidents
FROM vw_WardRisk
WHERE Incident_Ward = 999;
-- Expected: Unknown | 999 | 153
GO

