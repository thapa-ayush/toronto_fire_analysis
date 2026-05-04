-- Are Toronto fire incidents increasing or decreasing since 2018?
-- Core trend analysis for the executive overview page
SELECT
    year,
    COUNT(*)                            AS total_incidents,
    SUM(Estimated_Dollar_Loss)          AS total_dollar_loss,
    SUM(Civilian_Casualties)            AS total_casualties,
    ROUND(AVG(response_time_min), 2)    AS avg_response_time_min
FROM fact_incidents
WHERE year IS NOT NULL
GROUP BY year
ORDER BY year;