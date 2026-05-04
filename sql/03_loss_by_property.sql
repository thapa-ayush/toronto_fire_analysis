-- Which property types cause the most financial damage?
-- Useful for identifying high-risk building categories
SELECT
    Property_Use,
    COUNT(*)                                AS total_incidents,
    SUM(Estimated_Dollar_Loss)              AS total_dollar_loss,
    ROUND(AVG(Estimated_Dollar_Loss), 2)    AS avg_dollar_loss,
    SUM(Civilian_Casualties)                AS total_casualties
FROM fact_incidents
WHERE Property_Use != 'Unknown'
GROUP BY Property_Use
ORDER BY total_dollar_loss DESC;