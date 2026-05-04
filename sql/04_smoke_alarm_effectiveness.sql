-- Do smoke alarms reduce civilian casualties and dollar loss?
-- Portfolio highlight: quantifies safety equipment impact
SELECT
    Smoke_Alarm_at_Fire_Origin                              AS smoke_alarm_status,
    COUNT(*)                                                AS total_incidents,
    SUM(Civilian_Casualties)                                AS total_casualties,
    ROUND(AVG(CAST(Civilian_Casualties AS FLOAT)), 4)       AS avg_casualties_per_incident,
    ROUND(AVG(Estimated_Dollar_Loss), 2)                    AS avg_dollar_loss
FROM fact_incidents
WHERE Smoke_Alarm_at_Fire_Origin != 'Unknown'
GROUP BY Smoke_Alarm_at_Fire_Origin
ORDER BY avg_casualties_per_incident DESC;