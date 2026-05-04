-- What time of day do the most serious incidents occur?
-- Staffing and resource planning implications
SELECT
    hour_of_day,
    COUNT(*)                            AS total_incidents,
    SUM(Civilian_Casualties)            AS total_casualties,
    ROUND(AVG(response_time_min), 2)    AS avg_response_time_min
FROM fact_incidents
GROUP BY hour_of_day
ORDER BY hour_of_day;