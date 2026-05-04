# Data Cleaning Log
**Generated:** 2026-04-20 01:48:51

## Summary Statistics
- **Original Row Count:** 36,564
- **Final Row Count:** 36,559
- **Rows Removed:** 5 (0.01%)
- **Original Columns:** 43
- **Final Columns:** 49

## Columns Added
The following derived and computed columns were added during cleaning:
- `response_time_min`: Response time in minutes (TFS_Arrival_Time - TFS_Alarm_Time)
  - Calculated as: (Arrival Time - Alarm Time) / 60 seconds per minute
  - Useful for analyzing emergency response efficiency
- `control_time_min`: Fire control time in minutes (Fire_Under_Control_Time - TFS_Alarm_Time)
  - Calculated as: (Fire Control Time - Alarm Time) / 60 seconds per minute
  - Useful for analyzing fire suppression effectiveness
- `year`: Year extracted from TFS_Alarm_Time (useful for trend analysis across years)
- `month`: Month extracted from TFS_Alarm_Time (useful for seasonal analysis)
- `hour_of_day`: Hour of day extracted from TFS_Alarm_Time (useful for temporal patterns)
- `day_of_week`: Day of week extracted from TFS_Alarm_Time (Monday=0, Sunday=6) (useful for weekly patterns)

## Datetime Columns Parsed
The following columns were converted from string to datetime format:
This allows for time-based calculations and temporal analysis on fire incidents.
- TFS_Alarm_Time (when the alarm was first triggered)
- TFS_Arrival_Time (when firefighters arrived at the scene)
- Ext_agent_app_or_defer_time (when external agent was applied or deferred)
- Fire_Under_Control_Time (when the fire was brought under control)
- Last_TFS_Unit_Clear_Time (when the last TFS unit cleared the scene)

## Categorical Columns Cleaned
The following columns had numeric code prefixes removed (e.g., "01 - Fire" → "Fire"):
This standardization improves readability and makes categorical analysis cleaner.
- Final_Incident_Type
- Initial_CAD_Event_Type
- Property_Use
- Area_of_Origin
- Possible_Cause
- Method_Of_Fire_Control
- Extent_Of_Fire
- Ignition_Source
- Material_First_Ignited
- Smoke_Alarm_at_Fire_Origin
- Sprinkler_System_Presence

## Nulls Filled

### Numeric Columns (Filled with 0)
These columns represent counts and casualties, so missing values logically represent zero occurrences:
- Civilian_Casualties (no civilians injured = 0)
- TFS_Firefighter_Casualties (no firefighters injured = 0)
- Count_of_Persons_Rescued (no persons rescued = 0)
- Estimated_Number_Of_Persons_Displaced (no persons displaced = 0)

### Other Numeric Columns
- Estimated_Dollar_Loss: Filled with median value
  - Reasoning: Loss amounts that are missing are imputed with the median to preserve statistical distribution
  - Median is preferred over mean to reduce impact of extreme outliers

### Categorical Columns
All remaining null values in categorical columns were filled with "Unknown"
This preserves row integrity while flagging where data was incomplete.

**Nulls Filled in Original Columns:** 115
**Nulls in Newly Added Columns:** 10,536 (from extracted temporal features)
**Net Change in Total Nulls:** -10,421

## High-Null Columns (> 40%)
The following columns had more than 40% null values in the original dataset:
These are flagged for awareness as they may have limited analytical value:
- **Exposures**: 69.52% null (25,418 of 36,564 rows)
- **Building_Status**: 50.55% null (18,483 of 36,564 rows)
- **Estimated_Number_Of_Persons_Displaced**: 50.56% null (18,485 of 36,564 rows)
- **Business_Impact**: 50.56% null (18,487 of 36,564 rows)
- **Level_Of_Origin**: 50.56% null (18,486 of 36,564 rows)
- **Extent_Of_Fire**: 50.56% null (18,487 of 36,564 rows)
- **Smoke_Spread**: 50.56% null (18,487 of 36,564 rows)
- **Smoke_Alarm_at_Fire_Origin**: 50.56% null (18,486 of 36,564 rows)
- **Smoke_Alarm_at_Fire_Origin_Alarm_Failure**: 50.56% null (18,486 of 36,564 rows)
- **Smoke_Alarm_at_Fire_Origin_Alarm_Type**: 50.56% null (18,486 of 36,564 rows)
- **Smoke_Alarm_Impact_on_Persons_Evacuating_Impact_on_Evacuation**: 50.56% null (18,486 of 36,564 rows)
- **Fire_Alarm_System_Presence**: 50.56% null (18,486 of 36,564 rows)
- **Fire_Alarm_System_Operation**: 50.56% null (18,486 of 36,564 rows)
- **Fire_Alarm_System_Impact_on_Evacuation**: 50.56% null (18,486 of 36,564 rows)
- **Sprinkler_System_Presence**: 50.56% null (18,486 of 36,564 rows)
- **Sprinkler_System_Operation**: 50.56% null (18,486 of 36,564 rows)

## Outliers Capped
Extreme values were capped at the 99th percentile to handle data entry errors or exceptional cases:

- **response_time_min**: Negative values capped to 0 (impossible negative response times); values above 99th percentile (11.79 min) capped
  - Reasoning: Response times should be non-negative. Extreme outliers may indicate data quality issues.

- **Estimated_Dollar_Loss**: Values above 99th percentile ($500,000.00) capped using 99th percentile method
  - Reasoning: Extreme loss values can skew statistical analyses. Capping preserves the value while preventing extreme influence.

## Geolocation Validation
Only records with coordinates within the Toronto city boundaries were retained:
- **Latitude Range:** 43.58 to 43.86
- **Longitude Range:** -79.64 to -79.12
- **Rows Dropped:** 5 (records with coordinates outside Toronto bounds)
- Reasoning: Removes out-of-jurisdiction incidents and potential data entry errors.

## Cleaning Completion
All data cleaning steps completed successfully!
Output saved to: `outputs/fire_incidents_cleaned.csv`
