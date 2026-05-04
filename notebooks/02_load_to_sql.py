"""
SQL Server Data Loading Script
Loads cleaned fire incidents data into FireIncidentsDB.fact_incidents table

Author: Data Analytics Pipeline
Date: 2026-04-20
"""

import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
import pyodbc
import sys

# Configuration
CSV_FILE = 'outputs/fire_incidents_cleaned.csv'
DB_CONNECTION_STRING = 'mssql+pyodbc://localhost/FireIncidentsDB?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
TABLE_NAME = 'fact_incidents'
CHUNK_SIZE = 500

# Global engine for cleanup
engine = None

# Helper function to check column schema
def check_column_schema():
    """
    Helper function to get table schema from SQL Server
    """
    if not engine:
        return None
    try:
        with engine.connect() as conn:
            # Query to get column info from SQL Server
            query = """
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = 'fact_incidents'
            ORDER BY ORDINAL_POSITION
            """
            result = conn.execute(text(query))
            return result.fetchall()
    except Exception:
        return None

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: LOAD CSV FILE
# ═══════════════════════════════════════════════════════════════════════════════
print("\n" + "="*80)
print("STEP 1: LOADING CSV FILE")
print("="*80)
print()

try:
    print("Loading CSV from:", CSV_FILE)
    df = pd.read_csv(CSV_FILE, dtype={'Incident_Station_Area': 'str'})  # Force string to preserve alphanumeric
    print(f"✓ CSV loaded successfully")
    print(f"  Shape: {df.shape[0]:,} rows × {df.shape[1]} columns")
    print()
    
except FileNotFoundError:
    print(f"✗ ERROR: File not found: {CSV_FILE}")
    sys.exit(1)
except Exception as e:
    print(f"✗ ERROR loading CSV: {str(e)}")
    sys.exit(1)


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: FIX COLUMN DATA TYPES
# ═══════════════════════════════════════════════════════════════════════════════
print("="*80)
print("STEP 2: FIXING COLUMN DATA TYPES")
print("="*80)
print()

try:
    print("Converting columns to appropriate data types...")
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Convert DATETIME columns
    # ─────────────────────────────────────────────────────────────────────────
    datetime_columns = [
        'TFS_Alarm_Time',
        'TFS_Arrival_Time',
        'Ext_agent_app_or_defer_time',
        'Fire_Under_Control_Time',
        'Last_TFS_Unit_Clear_Time'
    ]
    
    print(f"Converting {len(datetime_columns)} datetime columns:")
    for col in datetime_columns:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors='coerce')
            print(f"  ✓ {col:40s} → datetime64")
        else:
            print(f"  ⚠️  {col:40s} → NOT FOUND")
    
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Convert INT16 NULLABLE INTEGER columns
    # ─────────────────────────────────────────────────────────────────────────
    int16_columns = [
        'Incident_Ward',
        'Number_of_responding_apparatus',
        'Number_of_responding_personnel',
        'Count_of_Persons_Rescued',
        'TFS_Firefighter_Casualties',
        'Civilian_Casualties',
        'Estimated_Number_Of_Persons_Displaced',
        'year',
        'month',
        'hour_of_day',
        'day_of_week'
    ]
    
    print(f"Converting {len(int16_columns)} integer columns to Int16 (nullable):")
    for col in int16_columns:
        if col in df.columns:
            # First convert to numeric with errors='coerce', then to Int16
            df[col] = pd.to_numeric(df[col], errors='coerce')
            df[col] = df[col].astype('Int16')
            print(f"  ✓ {col:40s} → Int16 (nullable)")
        else:
            print(f"  ⚠️  {col:40s} → NOT FOUND")
    
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Convert FLOAT column (Estimated Dollar Loss)
    # ─────────────────────────────────────────────────────────────────────────
    if 'Estimated_Dollar_Loss' in df.columns:
        df['Estimated_Dollar_Loss'] = pd.to_numeric(df['Estimated_Dollar_Loss'], errors='coerce')
        df['Estimated_Dollar_Loss'] = df['Estimated_Dollar_Loss'].round(2)
        print(f"Converting 1 float column:")
        print(f"  ✓ Estimated_Dollar_Loss                 → float64 (rounded to 2 decimals)")
    else:
        print(f"⚠️  Estimated_Dollar_Loss not found")
    
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Convert _id to INT
    # ─────────────────────────────────────────────────────────────────────────
    if '_id' in df.columns:
        df['_id'] = pd.to_numeric(df['_id'], errors='coerce').astype('int')
        print(f"Converting 1 primary key column:")
        print(f"  ✓ _id                                   → int")
    else:
        print(f"⚠️  _id not found")
    
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Print data types summary
    # ─────────────────────────────────────────────────────────────────────────
    print("="*80)
    print("DATA TYPES AFTER CONVERSION:")
    print("="*80)
    print()
    
    # Group by dtype for summary
    dtype_summary = df.dtypes.astype(str).value_counts()
    print("Type distribution:")
    for dtype, count in dtype_summary.items():
        print(f"  {dtype:30s} {count:>3} columns")
    
    print()
    print(f"Total columns: {len(df.columns)}")
    print(f"Total rows:    {len(df):,}")
    print()
    
except Exception as e:
    print(f"✗ ERROR during data type conversion: {str(e)}")
    sys.exit(1)


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: CONNECT TO SQL SERVER
# ═══════════════════════════════════════════════════════════════════════════════
print("="*80)
print("STEP 3: CONNECTING TO SQL SERVER")
print("="*80)
print()

try:
    print("Connecting to SQL Server using SQLAlchemy...")
    print(f"Connection string: {DB_CONNECTION_STRING}")
    print()
    
    # Create engine
    engine = create_engine(DB_CONNECTION_STRING)
    
    # Test connection
    print("Testing connection...")
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        result.fetchone()
    
    print("✓ Connection successful")
    print(f"  Database: FireIncidentsDB")
    print(f"  Table: {TABLE_NAME}")
    print()
    
except Exception as e:
    print("✗ Could not connect to SQL Server — check ODBC driver and server name")
    print(f"  Error: {str(e)}")
    print()
    print("Troubleshooting:")
    print("  1. Ensure SQL Server is running")
    print("  2. Check ODBC Driver 17 for SQL Server is installed:")
    print("     Open ODBC Data Source Administrator and verify driver exists")
    print("  3. Verify server name: localhost")
    print("  4. Verify database exists: FireIncidentsDB")
    sys.exit(1)


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: LOAD DATA INTO SQL SERVER
# ═══════════════════════════════════════════════════════════════════════════════
print("="*80)
print("STEP 4: LOADING DATA INTO SQL SERVER")
print("="*80)
print()

try:
    total_rows = len(df)
    print(f"Loading {total_rows:,} rows into {TABLE_NAME}...")
    print(f"Using chunk size: {CHUNK_SIZE}")
    print()
    
    # Load with append mode (table already exists)
    print("Inserting data with mode='append'...")
    df.to_sql(
        TABLE_NAME,
        engine,
        if_exists='append',      # Append to existing table
        index=False,             # Don't write index
        chunksize=CHUNK_SIZE     # Insert in chunks (removes method='multi' to fix ODBC driver issue)
    )
    
    print()
    print(f"✓ All {total_rows:,} rows inserted successfully")
    print()
    
except Exception as e:
    print()
    print(f"✗ ERROR during data load: {str(e)}")
    print()
    print("DIAGNOSING SCHEMA MISMATCH...")
    print("─" * 80)
    
    # Try to show expected vs actual schema
    schema = check_column_schema()
    if schema:
        print("\nExpected columns in SQL Server fact_incidents table:")
        print(f"{'Column Name':<40} {'Data Type':<15} {'Nullable':<10}")
        print("─" * 80)
        for col_name, data_type, is_nullable, max_len in schema:
            nullable = "YES" if is_nullable == 'YES' else "NO"
            print(f"{col_name:<40} {data_type:<15} {nullable:<10}")
        
        print("\nActual data types in CSV:")
        print(f"{'Column Name':<40} {'Data Type':<15}")
        print("─" * 80)
        for col in df.columns:
            dtype_str = str(df[col].dtype)
            print(f"{col:<40} {dtype_str:<15}")
    
    print()
    print("Troubleshooting:")
    print("  1. MISMATCH DETECTED: Some columns in SQL Server table have different types than CSV")
    print("  2. Fix options:")
    print("     a) ALTER TABLE in SQL Server to match CSV column types")
    print("     b) Clean the CSV data to match SQL Server column types")
    print("  3. Common issue: Alphanumeric columns (like Incident_Station_Area='145P')")
    print("     should be VARCHAR, not INT in SQL Server")
    print("  4. Run this SQL in SQL Server to see current table structure:")
    print("     EXEC sp_help 'fact_incidents'")
    print()
    if engine:
        engine.dispose()
    sys.exit(1)


# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: VERIFY THE LOAD
# ═══════════════════════════════════════════════════════════════════════════════
print("="*80)
print("STEP 5: VERIFYING THE LOAD")
print("="*80)
print()

try:
    print("Running verification queries...")
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Query 1: Count total rows in fact_incidents
    # ─────────────────────────────────────────────────────────────────────────
    print("Verification Query 1: Row count in fact_incidents")
    print("-" * 80)
    
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) as row_count FROM fact_incidents"))
        row_count = result.scalar()
    
    print(f"  Total rows in fact_incidents: {row_count:,}")
    print()
    
    # ─────────────────────────────────────────────────────────────────────────
    # Query 2: Check if view works and sample data
    # ─────────────────────────────────────────────────────────────────────────
    print("Verification Query 2: Top 3 records from vw_ResponseSummary")
    print("-" * 80)
    
    try:
        with engine.connect() as conn:
            query = """
            SELECT TOP 3 
                Incident_Ward,
                avg_response_time_min
            FROM vw_ResponseSummary
            ORDER BY avg_response_time_min DESC
            """
            result = conn.execute(text(query))
            rows = result.fetchall()
        
        print("  Results:")
        for i, row in enumerate(rows, 1):
            ward = row[0] if row[0] is not None else "NULL"
            avg_time = row[1] if row[1] is not None else "NULL"
            print(f"    {i}. Ward: {ward:>3} | Avg Response Time: {avg_time}")
        
        print()
        print("✓ View query successful - views are working")
        
    except Exception as e:
        print(f"  Note: View query failed: {str(e)}")
        print("  (This is expected if vw_ResponseSummary doesn't exist yet)")
        print()
    
    print()
    
except Exception as e:
    print(f"✗ ERROR during verification: {str(e)}")
    if engine:
        engine.dispose()
    sys.exit(1)


# ═══════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
print("="*80)
print("✅ LOAD COMPLETE — FireIncidentsDB is ready for Power BI")
print("="*80)
print()
print("Summary:")
print(f"  • Rows loaded: {total_rows:,}")
print(f"  • Table: {TABLE_NAME}")
print(f"  • Database: FireIncidentsDB")
print(f"  • Load mode: APPEND (to existing table)")
print()
print("Next steps:")
print("  1. Open Power BI")
print("  2. Connect to FireIncidentsDB on localhost")
print("  3. Create visualizations from fact_incidents")
print()

# Cleanup
if engine:
    engine.dispose()
    print("Connection closed.")
    print()


