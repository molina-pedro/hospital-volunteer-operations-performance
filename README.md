<img width="900" height="228" alt="Frame 2" src="https://github.com/user-attachments/assets/77f9c7eb-0d01-4d00-8331-344fde83bd45" />

# Hospital Volunteer Operations Performance

This project analyzes hospital volunteer call operations from 2021–2025 to evaluate staffing demand, workload distribution, attendance trends, and operational efficiency.

Using PostgreSQL and Tableau, the project transforms raw operational data into an interactive dashboard designed to support scheduling and staffing decisions in a hospital environment.

## Dashboard

<img width="8364" height="8588" alt="hospital volunteer operations dashboard" src="https://github.com/user-attachments/assets/10f1bc62-a42f-485b-9e07-4a13f6192c36" />

## Executive Summary

The analysis identified several operational patterns affecting volunteer coverage and workload distribution:

- Call demand increases significantly during winter months
- Peak call activity occurs between 9 AM and 10 AM
- A small group of volunteers handle a disproportionate share of calls
- Annual call volume steadily increased from 2021 to 2025
- Attendance rates indicate opportunities to improve scheduling reliability

These insights can help hospital coordinators better align volunteer staffing with operational demand.

## Business Questions

- Are volunteer shifts aligned with peak call demand?
- Is workload evenly distributed across volunteers?
- Which time periods experience the highest operational demand?
- Are attendance rates impacting volunteer coverage?
- How can staffing efficiency be improved?

## Key Findings

### Seasonal Call Trends
- Call activity follows a seasonal pattern, with demand increasing toward the end of the year and peaking during winter months.

<img width="2958" height="2097" alt="monthly call volume" src="https://github.com/user-attachments/assets/52668076-86a8-48e7-80c3-2f9c9ffb0afb" />

### Annual Growth in Call Volume
- Total yearly call volume increased consistently from 2021–2025, suggesting growing operational demand for volunteer support services.

<img width="2958" height="2097" alt="annual call volume" src="https://github.com/user-attachments/assets/7602305d-11fa-491b-95cb-9deb49d4813f" />

### Peak Hour Demand
- The highest concentration of calls occurs between 9 AM and 10 AM, indicating staffing coverage may need adjustment during morning hours.

<img width="3174" height="2460" alt="hourly call volume" src="https://github.com/user-attachments/assets/d2cc1579-aac2-4be8-826d-0a90688622ac" />

### Uneven Workload Distribution
- A small percentage of volunteers handled a large portion of total calls, creating potential dependency and burnout risk.

<img width="3174" height="2400" alt="volunteer calls handled" src="https://github.com/user-attachments/assets/a7444041-0fc6-4c05-a0ba-97e1be41203e" />

## Operational Recommendations

- Increase volunteer coverage during peak morning hours
- Improve staffing during high-demand winter months
- Redistribute call assignments more evenly across volunteers
- Monitor high-performing volunteers to reduce burnout risk
- Improve attendance tracking and scheduling processes

## Dataset Overview

This project uses a synthetic dataset designed to reflect realistic hospital front-desk volunteer operations.

### Dataset Includes
- Volunteer information and shift preferences
- Call logs with timestamps, duration, and call reasons
- Volunteer schedules and attendance records
- Seasonal demand patterns and operational variability

### Dataset Characteristics
- ~11,000+ call records
- ~70+ volunteers
- Realistic data quality issues including missing values, inconsistent formatting, and outliers

## Data Preparation & Modeling

The project used a structured PostgreSQL workflow to clean, organize, and model operational data for analysis and visualization.

### Data Model
The final model included:

- **fact_volunteer_calls** – call-level operational data
- **dim_volunteers** – volunteer details
- **dim_call_reasons** – call categories
- **dim_calendar** – date and time breakdowns

This structure improves query performance and supports scalable dashboard reporting.

### Raw / Messy Files
Date and time fields were initially stored as text to simulate real-world data cleaning scenarios.

<img width="2982" height="2532" alt="raw_files" src="https://github.com/user-attachments/assets/4b082c45-f850-476b-aa7a-c76096084b28" />

### Clean Files
Data was standardized with proper data types and structured relationships for SQL joins.

<img width="2982" height="2883" alt="clean_files" src="https://github.com/user-attachments/assets/4f47dbd1-97e5-4d23-af57-08c2431b91c7" />

### View Files
View tables were created to support Tableau dashboard reporting.

<img width="2982" height="2925" alt="view_files" src="https://github.com/user-attachments/assets/67e9ce5c-7074-4060-96ae-506525560393" />

## Tools & Methods

**Tools:** PostgreSQL, Tableau  
**Methods:** Data cleaning, SQL joins, data modeling, KPI design, workload analysis, dashboard reporting

## Link

[Next Project - RetailRocket E-commerce Conversion Rate Analysis](https://github.com/molina-pedro/retailrocket-ecommerce-analysis)
