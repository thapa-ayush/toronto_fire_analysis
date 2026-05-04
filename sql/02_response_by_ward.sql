-- Which wards have the slowest average response times?
-- Key metric for identifying under-resourced areas
SELECT
    Incident_Ward,
    COUNT(*)                            AS total_incidents,
    ROUND(AVG(response_time_min), 2)    AS avg_response_time_min,
    ROUND(MIN(response_time_min), 2)    AS min_response_time_min,
    ROUND(MAX(response_time_min), 2)    AS max_response_time_min,
    SUM(Civilian_Casualties)            AS total_civilian_casualties
FROM fact_incidents
WHERE response_time_min IS NOT NULL
GROUP BY Incident_Ward
ORDER BY avg_response_time_min DESC;