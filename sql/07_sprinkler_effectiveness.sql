-- Do sprinkler systems reduce dollar loss and casualties?
-- Pairs with smoke alarm query for a full safety equipment analysis
SELECT
    Sprinkler_System_Presence,
    Sprinkler_System_Operation,
    COUNT(*)                                            AS total_incidents,
    ROUND(AVG(Estimated_Dollar_Loss), 2)                AS avg_dollar_loss,
    ROUND(AVG(CAST(Civilian_Casualties AS FLOAT)), 4)   AS avg_casualties
FROM fact_incidents
WHERE Sprinkler_System_Presence != 'Unknown'
GROUP BY Sprinkler_System_Presence, Sprinkler_System_Operation
ORDER BY avg_dollar_loss DESC;