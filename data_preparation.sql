BEGIN;

-- 0) DROP VIEWS FIRST (DEPENDENCIES)
DROP VIEW IF EXISTS vw_attendance_tableau;
DROP VIEW IF EXISTS vw_calls_tableau;


-- 1) DROP CLEAN TABLES
DROP TABLE IF EXISTS fact_volunteer_calls;
DROP TABLE IF EXISTS fact_volunteer_schedule;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_reason;
DROP TABLE IF EXISTS dim_volunteer;


-- 2) DIM TABLES

/* =========================
   DIM: REASON
   ========================= */
CREATE TABLE dim_reason (
  reason_id   INT PRIMARY KEY,
  reason_name TEXT NOT NULL
);

INSERT INTO dim_reason (reason_id, reason_name)
SELECT DISTINCT
  ABS(NULLIF(BTRIM(reason_id), '')::INT) AS reason_id,
  INITCAP(REGEXP_REPLACE(BTRIM(reason_name), '\s+', ' ', 'g')) AS reason_name
FROM raw_dim_call_reasons_v1
WHERE BTRIM(reason_id) ~ '^-?\d+$'
  AND NULLIF(BTRIM(reason_name), '') IS NOT NULL;


/* =========================
   DIM: VOLUNTEER
   ========================= */
CREATE TABLE dim_volunteer (
  volunteer_id      INT PRIMARY KEY,
  volunteer_name    TEXT NOT NULL,
  hire_date         DATE,
  resignation_date  DATE,
  status            TEXT,
  shift_type        TEXT
);

INSERT INTO dim_volunteer (
  volunteer_id, volunteer_name, hire_date, resignation_date, status, shift_type
)
SELECT DISTINCT
  ABS(NULLIF(BTRIM(volunteer_id), '')::INT) AS volunteer_id,
  INITCAP(REGEXP_REPLACE(BTRIM(volunteer_name), '\s+', ' ', 'g')) AS volunteer_name,

  CASE
    WHEN NULLIF(BTRIM(hire_date), '') IS NULL THEN NULL
    WHEN BTRIM(hire_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN BTRIM(hire_date)::date
    WHEN BTRIM(hire_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(BTRIM(hire_date), 'MM/DD/YYYY')
    WHEN BTRIM(hire_date) ~ '^\d{2}/\d{2}/\d{2}$' THEN TO_DATE(BTRIM(hire_date), 'MM/DD/YY')
    ELSE NULL
  END AS hire_date,

  CASE
    WHEN NULLIF(BTRIM(resignation_date), '') IS NULL THEN NULL
    WHEN BTRIM(resignation_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN BTRIM(resignation_date)::date
    WHEN BTRIM(resignation_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(BTRIM(resignation_date), 'MM/DD/YYYY')
    WHEN BTRIM(resignation_date) ~ '^\d{2}/\d{2}/\d{2}$' THEN TO_DATE(BTRIM(resignation_date), 'MM/DD/YY')
    ELSE NULL
  END AS resignation_date,

  INITCAP(REGEXP_REPLACE(NULLIF(BTRIM(status), ''), '\s+', ' ', 'g')) AS status,
  INITCAP(REGEXP_REPLACE(NULLIF(BTRIM(shift_type), ''), '\s+', ' ', 'g')) AS shift_type
FROM raw_dim_volunteers_v1
WHERE BTRIM(volunteer_id) ~ '^-?\d+$'
  AND NULLIF(BTRIM(volunteer_name), '') IS NOT NULL;


/* =========================
   DIM: DATE (CALENDAR)
   ========================= */
CREATE TABLE dim_date (
  date_key           DATE PRIMARY KEY,
  year               INT,
  month              INT,
  day_of_week        TEXT,
  is_weekend         BOOLEAN,
  is_federal_holiday BOOLEAN,
  program_is_open    BOOLEAN
);

INSERT INTO dim_date (
  date_key, year, month, day_of_week,
  is_weekend, is_federal_holiday, program_is_open
)
SELECT DISTINCT
  NULLIF(BTRIM(date), '')::date AS date_key,
  NULLIF(BTRIM(year), '')::int  AS year,
  NULLIF(BTRIM(month), '')::int AS month,
  INITCAP(REGEXP_REPLACE(BTRIM(day_of_week), '\s+', ' ', 'g')) AS day_of_week,

  CASE WHEN LOWER(BTRIM(is_weekend)) IN ('1','true','t','yes','y') THEN TRUE
       WHEN LOWER(BTRIM(is_weekend)) IN ('0','false','f','no','n') THEN FALSE
       ELSE NULL END AS is_weekend,

  CASE WHEN LOWER(BTRIM(is_federal_holiday)) IN ('1','true','t','yes','y') THEN TRUE
       WHEN LOWER(BTRIM(is_federal_holiday)) IN ('0','false','f','no','n') THEN FALSE
       ELSE NULL END AS is_federal_holiday,

  CASE WHEN LOWER(BTRIM(program_is_open)) IN ('1','true','t','yes','y') THEN TRUE
       WHEN LOWER(BTRIM(program_is_open)) IN ('0','false','f','no','n') THEN FALSE
       ELSE NULL END AS program_is_open
FROM raw_dim_calendar_v1
WHERE BTRIM(date) ~ '^\d{4}-\d{2}-\d{2}$';



-- 3) FACT: VOLUNTEER SCHEDULE
CREATE TABLE fact_volunteer_schedule (
  schedule_id     BIGSERIAL PRIMARY KEY,
  volunteer_id    INT NOT NULL,
  schedule_date   DATE NOT NULL,
  shift_type      TEXT NOT NULL,
  scheduled_hours INT NOT NULL,
  schedule_status TEXT NOT NULL,

  date_key        DATE NOT NULL
);

INSERT INTO fact_volunteer_schedule (
  volunteer_id, schedule_date, shift_type, scheduled_hours, schedule_status, date_key
)
SELECT
  ABS(NULLIF(BTRIM(volunteer_id), '')::INT)                    AS volunteer_id,
  NULLIF(BTRIM(schedule_date), '')::date                       AS schedule_date,
  INITCAP(REGEXP_REPLACE(BTRIM(shift_type), '\s+', ' ', 'g'))  AS shift_type,
  NULLIF(BTRIM(scheduled_hours), '')::int                      AS scheduled_hours,
  INITCAP(REGEXP_REPLACE(BTRIM(schedule_status), '\s+', ' ', 'g')) AS schedule_status,
  NULLIF(BTRIM(schedule_date), '')::date                       AS date_key
FROM raw_volunteer_schedule_v1
WHERE BTRIM(volunteer_id) ~ '^-?\d+$'
  AND BTRIM(schedule_date) ~ '^\d{4}-\d{2}-\d{2}$'
  AND NULLIF(BTRIM(shift_type), '') IS NOT NULL
  AND NULLIF(BTRIM(scheduled_hours), '') ~ '^\d+$'
  AND NULLIF(BTRIM(schedule_status), '') IS NOT NULL;


ALTER TABLE fact_volunteer_schedule
ADD CONSTRAINT uq_schedule UNIQUE (volunteer_id, schedule_date, shift_type);


-- 4) FACT: VOLUNTEER CALLS
CREATE TABLE fact_volunteer_calls (
  call_id               BIGINT PRIMARY KEY,
  call_date             DATE,
  time_recvd            TIME,
  time_left             TIME,
  call_duration_minutes INTEGER,

  volunteer_id          INT,
  reason_id             INT,

  volunteer_name_raw    TEXT,
  reason_name_raw       TEXT,

  date_key              DATE,
  cleaning_notes        TEXT
);

WITH base AS (
  SELECT
    NULLIF(BTRIM(call_id), '')         AS call_id_txt,
    NULLIF(BTRIM(date), '')            AS date_txt,
    NULLIF(BTRIM(time_recvd), '')      AS time_recvd_txt,
    NULLIF(BTRIM(time_left), '')       AS time_left_txt,
    NULLIF(BTRIM(date_key), '')        AS date_key_txt,

    NULLIF(BTRIM(volunteer_id), '')    AS volunteer_id_txt,
    NULLIF(BTRIM(reason_id), '')       AS reason_id_txt,

    REGEXP_REPLACE(BTRIM(volunteer_name), '\s+', ' ', 'g') AS volunteer_name_raw,
    REGEXP_REPLACE(BTRIM(reason_name), '\s+', ' ', 'g')    AS reason_name_raw
  FROM raw_volunteer_calls_v1
),
parsed AS (
  SELECT
    CASE
      WHEN call_id_txt ~ '^-?\d+(\.\d+)?$' THEN ABS(call_id_txt::numeric)::bigint
      WHEN call_id_txt ~ '^-?\d+$'         THEN ABS(call_id_txt::bigint)
      ELSE NULL
    END AS call_id,

    CASE
      WHEN date_txt ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(date_txt, 'YYYY-MM-DD')
      WHEN date_txt ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(date_txt, 'MM/DD/YYYY')
      WHEN date_txt ~ '^\d{2}/\d{2}/\d{2}$' THEN TO_DATE(date_txt, 'MM/DD/YY')
      ELSE NULL
    END AS call_date,

    CASE
      WHEN date_key_txt ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(date_key_txt, 'YYYY-MM-DD')
      WHEN date_key_txt ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(date_key_txt, 'MM/DD/YYYY')
      WHEN date_key_txt ~ '^\d{2}/\d{2}/\d{2}$' THEN TO_DATE(date_key_txt, 'MM/DD/YY')
      ELSE NULL
    END AS date_key,

    CASE
      WHEN time_recvd_txt ~ '^\d{1,2}:\d{2}$' THEN time_recvd_txt::time
      ELSE NULL
    END AS time_recvd,

    CASE
      WHEN time_left_txt ~ '^\d{1,2}:\d{2}$' THEN time_left_txt::time
      ELSE NULL
    END AS time_left,

    CASE WHEN volunteer_id_txt ~ '^-?\d+$' THEN ABS(volunteer_id_txt::int) ELSE NULL END AS volunteer_id,
    CASE WHEN reason_id_txt    ~ '^-?\d+$' THEN ABS(reason_id_txt::int)    ELSE NULL END AS reason_id,

    volunteer_name_raw,
    reason_name_raw,

    CONCAT_WS(' | ',
      CASE WHEN call_id_txt IS NULL OR call_id_txt !~ '^-?\d+(\.\d+)?$|^-?\d+$' THEN 'bad_call_id' END,
      CASE WHEN date_txt IS NULL THEN 'missing_date' END,
      CASE WHEN date_txt IS NOT NULL AND NOT (
          date_txt ~ '^\d{4}-\d{2}-\d{2}$'
       OR date_txt ~ '^\d{2}/\d{2}/\d{4}$'
       OR date_txt ~ '^\d{2}/\d{2}/\d{2}$'
      ) THEN 'bad_date_format' END,
      CASE WHEN time_recvd_txt IS NOT NULL AND time_recvd_txt !~ '^\d{1,2}:\d{2}$' THEN 'bad_time_recvd' END,
      CASE WHEN time_left_txt  IS NOT NULL AND time_left_txt  !~ '^\d{1,2}:\d{2}$' THEN 'bad_time_left' END,
      CASE WHEN volunteer_id_txt IS NOT NULL AND volunteer_id_txt !~ '^-?\d+$' THEN 'bad_volunteer_id' END,
      CASE WHEN reason_id_txt IS NOT NULL AND reason_id_txt !~ '^-?\d+$' THEN 'bad_reason_id' END
    ) AS cleaning_notes
  FROM base
),
finalized AS (
  SELECT
    call_id,
    call_date,
    time_recvd,
    time_left,
    CASE
      WHEN time_recvd IS NOT NULL
       AND time_left  IS NOT NULL
       AND time_left  >= time_recvd
      THEN (EXTRACT(EPOCH FROM (time_left - time_recvd)) / 60)::int
      ELSE NULL
    END AS call_duration_minutes,

    volunteer_id,
    reason_id,

    INITCAP(REGEXP_REPLACE(BTRIM(volunteer_name_raw), '\s+', ' ', 'g')) AS volunteer_name_raw,
    INITCAP(REGEXP_REPLACE(BTRIM(reason_name_raw), '\s+', ' ', 'g'))    AS reason_name_raw,

    COALESCE(date_key, call_date) AS date_key,
    cleaning_notes,

    (
      (CASE WHEN call_date IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN time_recvd IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN time_left IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN volunteer_id IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN reason_id IS NOT NULL THEN 1 ELSE 0 END)
    ) AS completeness_score
  FROM parsed
  WHERE call_id IS NOT NULL
),
deduped AS (
  SELECT *
  FROM (
    SELECT
      f.*,
      ROW_NUMBER() OVER (
        PARTITION BY call_id
        ORDER BY completeness_score DESC, call_date DESC NULLS LAST
      ) AS rn
    FROM finalized f
  ) x
  WHERE rn = 1
)
INSERT INTO fact_volunteer_calls (
  call_id, call_date, time_recvd, time_left, call_duration_minutes,
  volunteer_id, reason_id,
  volunteer_name_raw, reason_name_raw,
  date_key, cleaning_notes
)
SELECT
  call_id, call_date, time_recvd, time_left, call_duration_minutes,
  volunteer_id, reason_id,
  volunteer_name_raw, reason_name_raw,
  date_key, cleaning_notes
FROM deduped;


-- 5) BACKFILL IDs FROM NAMES (SAFETY NET)
UPDATE fact_volunteer_calls f
SET volunteer_id = dv.volunteer_id
FROM dim_volunteer dv
WHERE f.volunteer_id IS NULL
  AND f.volunteer_name_raw IS NOT NULL
  AND LOWER(TRIM(f.volunteer_name_raw)) = LOWER(TRIM(dv.volunteer_name));

UPDATE fact_volunteer_calls f
SET reason_id = dr.reason_id
FROM dim_reason dr
WHERE f.reason_id IS NULL
  AND f.reason_name_raw IS NOT NULL
  AND LOWER(TRIM(f.reason_name_raw)) = LOWER(TRIM(dr.reason_name));


-- 6) VIEW: CALLS (TABLEAU)
CREATE VIEW vw_calls_tableau AS
SELECT
  f.call_id,
  f.call_date,
  f.time_recvd,
  f.time_left,
  f.call_duration_minutes,

  f.volunteer_id,
  COALESCE(dv.volunteer_name, f.volunteer_name_raw) AS volunteer_name,
  dv.status,
  dv.shift_type,
  dv.hire_date,
  dv.resignation_date,

  CASE
    WHEN dv.resignation_date IS NULL THEN CURRENT_DATE
    ELSE dv.resignation_date
  END AS tenure_end_date,

  CASE
    WHEN dv.hire_date IS NOT NULL
     AND (dv.resignation_date IS NULL OR dv.resignation_date >= dv.hire_date)
    THEN (COALESCE(dv.resignation_date, CURRENT_DATE) - dv.hire_date)
    ELSE NULL
  END AS tenure_days,

  CASE
    WHEN dv.hire_date IS NOT NULL
     AND (dv.resignation_date IS NULL OR dv.resignation_date >= dv.hire_date)
    THEN ROUND(EXTRACT(EPOCH FROM AGE(COALESCE(dv.resignation_date, CURRENT_DATE), dv.hire_date)) / 2628000)::int
    ELSE NULL
  END AS tenure_months,

  CASE
    WHEN dv.hire_date IS NOT NULL
     AND (dv.resignation_date IS NULL OR dv.resignation_date >= dv.hire_date)
    THEN ROUND(EXTRACT(EPOCH FROM AGE(COALESCE(dv.resignation_date, CURRENT_DATE), dv.hire_date)) / 31557600, 1)
    ELSE NULL
  END AS tenure_years,

  f.reason_id,
  COALESCE(dr.reason_name, f.reason_name_raw) AS reason_name,

  f.date_key,
  dd.year,
  dd.month,
  dd.day_of_week,
  dd.is_weekend,
  dd.is_federal_holiday,
  dd.program_is_open,

  f.cleaning_notes
FROM fact_volunteer_calls f
LEFT JOIN dim_volunteer dv ON f.volunteer_id = dv.volunteer_id
LEFT JOIN dim_reason    dr ON f.reason_id = dr.reason_id
LEFT JOIN dim_date      dd ON f.date_key = dd.date_key
WHERE f.call_date IS NOT NULL
  AND f.call_duration_minutes BETWEEN 1 AND 40;


-- 7) VIEW: ATTENDANCE / NO-SHOW (TABLEAU)
CREATE VIEW vw_attendance_tableau AS
WITH calls_by_shift_day AS (
  SELECT
    f.volunteer_id,
    f.call_date,
    COUNT(*) AS calls_that_day,
    AVG(f.call_duration_minutes)::numeric(10,2) AS avg_call_duration_minutes
  FROM fact_volunteer_calls f
  WHERE f.call_date IS NOT NULL
    AND f.call_duration_minutes BETWEEN 1 AND 40
  GROUP BY f.volunteer_id, f.call_date
)
SELECT
  s.schedule_id,
  s.volunteer_id,
  dv.volunteer_name,
  dv.status,
  dv.shift_type AS volunteer_shift_pref,

  s.schedule_date,
  s.shift_type,
  s.scheduled_hours,
  s.schedule_status,

  CASE
    WHEN COALESCE(c.calls_that_day, 0) = 0 THEN TRUE
    ELSE FALSE
  END AS no_show_flag,

  COALESCE(c.calls_that_day, 0) AS calls_that_day,
  c.avg_call_duration_minutes,

  dd.year,
  dd.month,
  dd.day_of_week,
  dd.is_weekend,
  dd.is_federal_holiday,
  dd.program_is_open
FROM fact_volunteer_schedule s
LEFT JOIN calls_by_shift_day c
  ON c.volunteer_id = s.volunteer_id
 AND c.call_date    = s.schedule_date
LEFT JOIN dim_volunteer dv ON dv.volunteer_id = s.volunteer_id
LEFT JOIN dim_date dd      ON dd.date_key     = s.schedule_date
WHERE s.schedule_status = 'Scheduled';

COMMIT;

-- 8) QA CHECKS

-- Counts
SELECT
  (SELECT COUNT(*) FROM dim_date)               AS dim_date_rows,
  (SELECT COUNT(*) FROM dim_volunteer)          AS dim_volunteer_rows,
  (SELECT COUNT(*) FROM dim_reason)             AS dim_reason_rows,
  (SELECT COUNT(*) FROM fact_volunteer_schedule) AS schedule_rows,
  (SELECT COUNT(*) FROM fact_volunteer_calls)    AS call_rows,
  (SELECT COUNT(*) FROM vw_calls_tableau)        AS vw_calls_rows,
  (SELECT COUNT(*) FROM vw_attendance_tableau)   AS vw_attendance_rows;

-- Duplicate call_id check (should be 0 rows)
SELECT call_id, COUNT(*) AS cnt
FROM fact_volunteer_calls
GROUP BY call_id
HAVING COUNT(*) > 1;

-- Check schedule rule: volunteer once per week (should be 0 rows if generator enforced)
SELECT
  volunteer_id,
  EXTRACT(ISOYEAR FROM schedule_date) AS iso_year,
  EXTRACT(WEEK FROM schedule_date)    AS iso_week,
  COUNT(*) AS shifts_in_week
FROM fact_volunteer_schedule
GROUP BY volunteer_id, EXTRACT(ISOYEAR FROM schedule_date), EXTRACT(WEEK FROM schedule_date)
HAVING COUNT(*) > 1;

-- Attendance summary
SELECT
  COUNT(*) AS total_scheduled_assignments,
  COUNT(*) FILTER (WHERE no_show_flag) AS total_no_shows,
  ROUND(
    (COUNT(*) FILTER (WHERE NOT no_show_flag))::numeric / NULLIF(COUNT(*),0),
    4
  ) AS attendance_rate
FROM vw_attendance_tableau;
