# Toronto Fire Incident Analysis (2011-2024)

A comprehensive data analysis of 36,559 fire incidents recorded by Toronto Fire Services, examining response times, financial losses, casualty patterns, and the impact of safety equipment on fire outcomes.

**Project Status:** Complete - Interactive Power BI dashboard deployed  
**Data Period:** 2011-2024  
**Last Updated:** May 2026

---

## Key Insights

- **54% Response Time Gap:** Ward 25 averages 6.44 minutes vs Ward 27 at 4.18 minutes — substantial disparities in emergency response coverage across Toronto's 44 wards.

- **Detached Dwellings Drive Losses:** Residential properties represent 27% of total dollar losses ($193.9M of $722.64M) despite only 12% of incidents — detached dwellings are the highest-risk category.

- **Sprinkler Systems Reduce Loss by 49%:** Properties with full sprinkler systems averaging $20,949 in losses compared to $41,069 for properties without — critical safety equipment impact quantified.

- **Casualties Down 55% Despite Rising Incidents:** Incidents nearly doubled post-2018 (1,753 to 3,633) but casualties fell from 183 in 2016 to 83 in 2024 — indicating improved public safety outcomes.

- **Evening Peak and Overnight Risk:** Highest incident volume occurs 18:00-21:00 (peak at 2,217 incidents at 6 PM). Overnight hours 1-3 AM show slower response times and higher casualty rates.

---

## Project Overview

This analysis combines three technical tools to extract actionable intelligence from fire service data:

- **Python** - Data ingestion, cleaning, and validation
- **SQL Server** - Enterprise data storage and analytical queries
- **Power BI** - Interactive visualization and executive dashboards

The pipeline processes raw City of Toronto open data into a production-ready SQL Server database, enabling rapid analysis and scalable reporting.

---

## Data Summary

| Metric | Value |
|--------|-------|
| Total Incidents | 36,559 |
| Total Dollar Loss | $722.64 Million |
| Average Response Time | 5.36 minutes |
| Total Casualties | 1,881 |
| Data Columns | 49 (43 original + 6 derived) |
| Date Range | 2011-2024 |

---

## Tech Stack

| Component | Tool | Version |
|-----------|------|---------|
| Data Cleaning | Python 3.x | pandas, numpy |
| Database | SQL Server | SSMS (localhost) |
| Visualization | Power BI | Desktop Edition |
| ORM | SQLAlchemy | pyodbc driver |
| Data Source | Toronto Open Data | Official fire incidents dataset |

---

## Project Structure

```
fire_analysis/
├── data/
│   └── fire_incidents_data.csv              Raw dataset from Toronto Open Data Portal
├── notebooks/
│   ├── 01_data_cleaning.ipynb              Exploration and data quality assessment
│   └── 02_load_to_sql.py                   Automated data load to SQL Server
├── sql/
│   ├── 01_create_schema.sql                Star schema and fact table setup
│   ├── 02_response_by_ward.sql             Ward-level response time analysis
│   ├── 03_loss_by_property.sql             Property type loss breakdown
│   ├── 04_smoke_alarm_effectiveness.sql    Safety equipment impact analysis
│   ├── 05_incidents_by_hour.sql            Temporal pattern queries
│   ├── 06_yearly_trend.sql                 Year-over-year incident tracking
│   ├── 07_sprinkler_effectiveness.sql      Sprinkler system impact on losses
│   └── 08_data_fixes.sql                   Post-load schema corrections
├── outputs/
│   ├── fire_incidents_cleaned.csv          Processed dataset (49 columns)
│   └── cleaning_log.md                     Data quality and transformation log
├── powerbi_exports/
│   └── Toronto_Fire_Analysis.pbix          4-page interactive dashboard
└── README.md                               This file
```

---

## Data Pipeline

### Phase 1: Data Ingestion
Raw CSV loaded from City of Toronto Open Data Portal via Python pandas. Initial shape: 36,559 rows × 43 columns.

### Phase 2: Data Cleaning
- Parsed 5 datetime columns (TFS_Alarm_Time, TFS_Arrival_Time, etc.)
- Computed derived fields: response_time_min, control_time_min, temporal features
- Stripped numeric prefixes from 12 categorical columns (e.g., "01 - Fire" → "Fire")
- Filled null values: casualties/counts with 0, dollar loss with median ($2,500)
- Applied outlier capping: response times >11.79 min and losses >$500,000 (99th percentile)
- Removed 5 rows with coordinates outside Toronto geographic bounds
- Flagged 16 high-null columns (>40% missing) for downstream analysis

### Phase 3: Storage
SQL Server database (FireIncidentsDB) with star-schema-inspired design:
- **fact_incidents table:** All 36,559 cleaned incidents with 49 columns
- **vw_ResponseSummary view:** Response time and casualties by ward
- **vw_WardRisk view:** Ward risk ranking with RANK() window function
- **vw_MonthlyTrend view:** Monthly incident and loss aggregations

### Phase 4: Analysis
Six SQL analytical queries examining response patterns, property losses, safety equipment effectiveness, and temporal trends.

### Phase 5: Visualization
Power BI Desktop dashboard with 4 pages: Home overview, Executive dashboard, Ward analysis map, and Safety equipment analysis.

---

## Running the Analysis

### Prerequisites
- Python 3.8+ with venv
- SQL Server 2019+ (running locally)
- ODBC Driver 17 for SQL Server
- Power BI Desktop (for dashboard viewing)

### Setup

1. Clone repository and activate virtual environment:
```powershell
git clone https://github.com/thapa-ayush/toronto_fire_analysis.git
cd fire_analysis
.\venv\Scripts\Activate.ps1
```

2. Install Python dependencies:
```powershell
pip install pandas numpy sqlalchemy pyodbc
```

3. Create SQL Server database:
```powershell
# Connect to SQL Server and run:
sqlcmd -S localhost -E -i sql/01_create_schema.sql
```

4. Load cleaned data:
```powershell
python notebooks/02_load_to_sql.py
```

5. Execute analytical queries (optional):
```powershell
# Review any of the SQL scripts in sql/ folder
sqlcmd -S localhost -E -i sql/02_response_by_ward.sql
```

6. Open Power BI dashboard:
```powershell
# Open in Power BI Desktop
powerbi_exports/Toronto_Fire_Analysis.pbix
```

---

## Key Analysis Findings

### Response Time by Ward
Ward 25 has the slowest average response at 6.44 minutes vs Ward 27 at 4.18 minutes (54% gap). Ward 13 handles the highest incident volume (2,556) while maintaining 4.50 min average response — indicating good station coverage in that region.

**Slowest Wards:**
- Ward 25: 6.44 min (988 incidents, 23 casualties)
- Ward 42: 6.17 min (272 incidents, 22 casualties)
- Ward 2: 6.08 min (1,068 incidents, 63 casualties)

### Dollar Loss by Property Type
Detached dwellings dominate financial impact at $193.9M (27% of total loss) despite representing only 12% of incidents. Average loss per detached dwelling: $52,470.

**Top Loss Categories:**
- Detached Dwelling: $193.9M (4,271 incidents)
- Multi-Unit Dwelling (>12 units): $65.8M (5,207 incidents)
- Semi-Detached Dwelling: $51.2M (1,242 incidents)
- Motor Vehicle Repair Garage: $88,883 avg per incident (highest per-incident average)

### Safety Equipment Impact

**Sprinkler Systems:**
- No sprinkler: $41,069 avg loss, 0.144 casualties/incident
- Full system: $20,949 avg loss, 0.059 casualties/incident
- Reduction: 49% lower losses, 59% fewer casualties

**Smoke Alarms** (analysis limited to 50% of incidents with recorded data):
- No alarm: 1.39 casualty rate per incident
- Floor/suite alarm operated: 0.12 casualty rate — 91% reduction

### Temporal Patterns
- Peak hours: 18:00-21:00 (evening incidents dominate)
- Highest single hour: 18:00 with 2,217 incidents
- Overnight vulnerability: 1-3 AM shows 0.7 min slower response and highest casualty rates

### Year-Over-Year Trend
Incidents nearly doubled from 2017 (1,753) to 2018 (3,330), likely reflecting expanded data recording scope. Post-2018 shows consistent upward trend:
- 2018: 3,330 incidents
- 2020: 3,472 incidents
- 2022: 3,564 incidents
- 2024: 3,633 incidents (record)

Despite incident growth, casualties declined 55% from 2016 peak (183) to 2024 (83).

---

## Power BI Dashboard

Four-page interactive dashboard with amber/fire color theme:

**Page 1 - Home:** Project overview with firefighter illustration and navigation buttons

![Home Page](img/home.png)

**Page 2 - Executive Overview:** 
- 4 KPI cards (total incidents, dollar loss, avg response, casualties)
- Dual-axis trend line (incidents vs dollar loss)
- Property type bar chart
- Incident distribution by hour

![Dollar Loss Analysis](img/dollar%20loss.png)

![Casualties Insight](img/casualty.png)

![Response Time KPI](img/time.png)

**Page 3 - Ward Analysis:**
- Bing map of Toronto with incident density
- Slowest wards bar chart
- Ward risk ranking table with RANK() function

![Menu Navigation](img/menu.png)

**Page 4 - Safety Analysis:**
- Smoke alarm effectiveness matrix
- Sprinkler system impact charts
- Key findings and recommendations

![Fire Alarm Effectiveness](img/fire-alarm.png)

---

## Data Limitations

- **High null rate:** 16 columns exceed 40% missing data. Smoke and sprinkler system analysis covers only 50% of incidents (18,486 rows).
- **Dollar loss estimates:** Capped at $500,000 per incident (99th percentile). Actual major fire losses may be higher.
- **2018 data scope change:** Incident spike from 1,753 (2017) to 3,330 (2018) likely reflects recording methodology change, not actual surge. Pre/post-2018 comparisons should account for this.
- **Ward coding:** Ward 999 (153 incidents) and Ward 0 (6 incidents) represent missing/invalid assignments — excluded from ward-level analysis.

---

## Recommendations

1. **Response Time Equity:** Investigate fire station coverage in Ward 25, 42, and 2 where response exceeds 6 minutes consistently.

2. **Residential Risk:** Prioritize smoke alarm and sprinkler system inspection programs for detached dwellings (highest loss category with 382 casualties).

3. **Data Quality:** Address 50% null rate in smoke/sprinkler columns to enable robust safety equipment analysis.

4. **Reporting Consistency:** Investigate 2018 data scope change and standardize collection methodology for reliable year-over-year tracking.

---

## Technical Implementation Notes

### SQL Server Schema
- Fact table: 36,559 rows × 49 columns
- Three pre-aggregated views for performance optimization
- Indexes on incident_ward, property_use, year, month for query speed
- Post-load schema corrections applied (Incident_Station_Area to VARCHAR, Estimated_Dollar_Loss to FLOAT)

### Power BI Design Decisions
- No table relationships between views and fact table: Pre-aggregated views avoid many-to-many ambiguity
- Each view used independently in its own set of charts
- Standard pattern for SQL view-based Power BI reporting

### Python Data Loading
- Uses SQLAlchemy ORM with pyodbc driver
- Chunked insert (500 rows/chunk) to prevent connection timeouts
- Comprehensive data type conversion before load
- Built-in schema validation and error diagnostics

---

## Contact & Attribution

Analysis prepared by: Ayush Thapa, Data Analyst  
Data source: City of Toronto Open Data Portal  
Project repository: https://github.com/thapa-ayush/toronto_fire_analysis

---

## License

This project uses publicly available data from the City of Toronto. Analysis and derivative works follow the Toronto Open Data license terms.
