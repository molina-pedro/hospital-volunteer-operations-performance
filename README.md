<img width="900" height="228" alt="Frame 2" src="https://github.com/user-attachments/assets/77f9c7eb-0d01-4d00-8331-344fde83bd45" />

## Executive Summary
This project analyzes hospital volunteer call operations to evaluate workload distribution, staffing efficiency, and call demand patterns.

## Business Questions
- Are volunteer shifts aligned with peak call demand?
- Is workload evenly distributed across volunteers?
- Are there periods of under- or over-staffing?
- How can volunteer scheduling be optimized to improve efficiency and coverage?

## Dataset Overview
This project uses a synthetic dataset designed to reflect realistic hospital front-desk volunteer operations.

### Data includes:
- Volunteer information (ID, shift type)
- Call logs (timestamp, duration, reason)
- Shift schedules and attendance
- Seasonal patterns and operational variability

### Dataset characteristics:
- ~11,000+ call records
- ~70+ volunteers
- Realistic data issues (missing values, inconsistent formatting, outliers)

## Data Preparation
- Cleaned inconsistent date and time formats
- Handled missing and null values in call records
- Standardized fields across multiple raw datasets
- Built structured tables for analysis (fact + dimension style model)

## Data Model
The dataset was structured to support analysis and visualization:

- **fact_volunteer_calls** – call-level data
- **dim_volunteer** – volunteer details
- **dim_reason** – call categories
- **dim_date** – date and time breakdown

This structure improves query performance and enables scalable analysis.

**Raw/Messy Files** </br>
Date type is set to text for clean up

<img width="2982" height="2532" alt="raw_files" src="https://github.com/user-attachments/assets/4b082c45-f850-476b-aa7a-c76096084b28" /></br></br>

**Clean Files** </br>
Proper data types ready to be joined

<img width="2982" height="2883" alt="clean_files" src="https://github.com/user-attachments/assets/4f47dbd1-97e5-4d23-af57-08c2431b91c7" /></br></br>

**View Files** </br>
Joined tables used for Tableu Dashboard

<img width="2982" height="2925" alt="view_files" src="https://github.com/user-attachments/assets/67e9ce5c-7074-4060-96ae-506525560393" /></br></br>

## Analysis Approach
- Calculated total call volume and trends over time
- Analyzed call distribution by hour of day
- Measured workload per volunteer
- Identified top-performing volunteers and workload concentration
- Evaluated attendance and shift coverage
- Assessed seasonal demand patterns

## Key Findings

### Call Volume Trends
- Call volume follows a seasonal pattern, with lower activity in spring and higher demand toward the end of the year
- Peak demand occurs in winter months, increasing operational pressure on volunteers
<img width="2958" height="2097" alt="monthly call volume" src="https://github.com/user-attachments/assets/52668076-86a8-48e7-80c3-2f9c9ffb0afb" />

### Annual Call Volume
- Call volume increases steadily from 2021 to 2025.
- The upward trend suggests growing demand for volunteer support.
<img width="2958" height="2097" alt="annual call volume" src="https://github.com/user-attachments/assets/7602305d-11fa-491b-95cb-9deb49d4813f" />

### Call Volume by Hour of Day
- Call activity is highest between 9 AM and 10 AM
- Indicates that current staffing may not be aligned with peak demand periods
<img width="3174" height="2460" alt="hourly call volume" src="https://github.com/user-attachments/assets/d2cc1579-aac2-4be8-826d-0a90688622ac" />

### Workload Distribution
- A small number of volunteers handle a large portion of total calls
- Creates dependency risk and potential burnout among high-performing volunteers
<img width="3174" height="2400" alt="volunteer calls handled" src="https://github.com/user-attachments/assets/a7444041-0fc6-4c05-a0ba-97e1be41203e" />

## Operational Recommendations
- Increase volunteer coverage during peak hours (9 AM – 11 AM)
- Redistribute call assignments to balance workload across volunteers
- Monitor high-performing volunteers to prevent burnout
- Adjust staffing levels during high-demand seasons (winter months)
- Improve attendance tracking and scheduling reliability

## Dashboard
<img width="8364" height="8588" alt="hospital volunteer operations dashboard" src="https://github.com/user-attachments/assets/10f1bc62-a42f-485b-9e07-4a13f6192c36" />

## Tools & Methods
**Tools:** PostgreSQL, Tableau <br>
**Methods:** Data cleaning, data modeling, KPI design, workload analysis, trend analysis

## Link
[Next Project - RetailRocket E-commerce Conversion Rate Analysis](https://github.com/molina-pedro/retailrocket-ecommerce-analysis)







