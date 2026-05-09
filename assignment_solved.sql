create database assignment;
use assignment;

create table weekly_devices(
week_num varchar(10),
device_id varchar(120),
week_int int
);

create index idx_device on weekly_devices(device_id);
create index idx_week_num on weekly_devices(week_num);
create index idx_week_int on weekly_devices(week_int);
show index from weekly_devices;

set global local_infile = 1;

load data local infile "D:/NH projects/Book1.csv"
into table weekly_devices
fields terminated by ','
lines terminated by '\n'
ignore 1 rows;

-- Insert data into a new column 'week_int' (1,2,3...) from 'week_num' (w1, w2,w3..)
update weekly_devices
set week_int = cast(replace(week_num, 'w', '') as unsigned);

-- Check Empty, Null, Tab, New Line, or a Non-Breaking Space.
SELECT 
    device_id, 
    LENGTH(device_id) AS char_count
FROM weekly_devices
-- This finds strings that look empty but have a length > 0
WHERE (device_id != '' AND device_id IS NOT NULL) 
  AND device_id REGEXP '^[[:space:]]+$';
  
  
 -- Delete Empty, Null, Tab, New Line, or a Non-Breaking Space. 
 DELETE FROM weekly_devices
WHERE device_id IS NULL 
   OR device_id = '' 
   OR device_id REGEXP '^[[:space:]]+$';


-- Analysis
-- 1. Weekly active users.
SELECT
    concat('w', week_int) as week_name,
    COUNT(DISTINCT device_id) AS wau
FROM weekly_devices
GROUP BY week_int
ORDER BY week_int asc;

-- 2. Total AVG Users.
SELECT 
    CONCAT('week', week_int) AS `weeks`,
    ROUND(AVG(weekly_user_count), 2) AS total_avg_users
FROM
    (SELECT 
        week_int, COUNT(DISTINCT device_id) AS weekly_user_count
    FROM
        weekly_devices
    GROUP BY week_int) AS weekly_summary
GROUP BY week_int;


-- 3. Which Weeks had highest active users?    
SELECT 
    concat('week',week_int) as weeks, COUNT(DISTINCT device_id) AS highest_active_users
FROM
    weekly_devices
GROUP BY week_int
ORDER BY highest_active_users DESC
LIMIT 1;


-- 4. Which Weeks had lowest active users? 
SELECT 
    CONCAT('week', week_int) AS weeks,
    COUNT(DISTINCT device_id) AS lowest_active_users
FROM
    weekly_devices
GROUP BY week_int
ORDER BY lowest_active_users ASC
LIMIT 1;


-- 5. New Users(Who came for the first time).
select 
    first_week AS week_num,
    COUNT(device_id) AS new_users
    from
(select device_id, min(week_int) as first_week
from weekly_devices
group by device_id) t
group by first_week
order by week_num asc;


-- 6. Retained Users(Users who were active in previous week and active in current week too).
SELECT 
    curr.week_int, 
    COUNT(DISTINCT curr.device_id) AS retained_users
FROM (SELECT DISTINCT device_id, week_int FROM weekly_devices) AS curr
INNER JOIN (SELECT DISTINCT device_id, week_int FROM weekly_devices) AS prv 
    ON prv.device_id = curr.device_id 
    AND prv.week_int = curr.week_int - 1
GROUP BY curr.week_int
ORDER BY curr.week_int;


-- 7. Churned Users(Users who were active in previous week but not current week).
SELECT 
    prv.week_int + 1 AS week_of_churn,
    COUNT(DISTINCT prv.device_id) AS churned_users
FROM
    (SELECT DISTINCT
        device_id, week_int
    FROM
        weekly_devices) AS prv
        LEFT JOIN
    (SELECT DISTINCT
        device_id, week_int
    FROM
        weekly_devices) AS curr ON prv.device_id = curr.device_id
        AND curr.week_int = prv.week_int + 1
WHERE
    curr.device_id IS NULL
GROUP BY prv.week_int
ORDER BY week_of_churn;


-- 8. Resurrected Users(Users who were inactive last week but came back)
SELECT 
    week_int, 
    COUNT(device_id) AS resurrected_users
FROM (
    SELECT 
        device_id, 
        week_int,
        LAG(week_int) OVER (PARTITION BY device_id ORDER BY week_int) AS last_seen_week
    FROM (SELECT DISTINCT device_id, week_int FROM weekly_devices) AS unique_entries
) AS activity_history
WHERE last_seen_week IS NOT NULL       -- They have been here before
  AND last_seen_week < week_int - 1    -- But the last time wasn't "last week" (there was a gap)
GROUP BY week_int
ORDER BY week_int;


-- 9. Quick Ratio,  (New user + resurrected user) / Churned user
WITH unique_activity AS (
    -- Deduplicate / Unique users
    SELECT DISTINCT device_id, week_int FROM weekly_devices
),
user_history AS (
    -- Determine if a user is New, Retained, or Resurrected
    SELECT 
        device_id,
        week_int,
        LAG(week_int) OVER (PARTITION BY device_id ORDER BY week_int) AS prev_week,
        MIN(week_int) OVER (PARTITION BY device_id) AS first_week
    FROM unique_activity
),
growth_metrics AS (
    -- Aggregate New and Resurrected per week
    SELECT 
        week_int,
        COUNT(CASE WHEN week_int = first_week THEN 1 END) AS new_users,
        COUNT(CASE WHEN week_int > first_week AND prev_week < week_int - 1 THEN 1 END) AS resurrected_users
    FROM user_history
    GROUP BY week_int
),
churn_metrics AS (
    -- Calculate Churn (Users from last week not in this week)
    SELECT 
        prv.week_int + 1 AS week_int,
        COUNT(DISTINCT prv.device_id) AS churned_users
    FROM unique_activity AS prv
    LEFT JOIN unique_activity AS curr 
        ON prv.device_id = curr.device_id 
        AND curr.week_int = prv.week_int + 1
    WHERE curr.device_id IS NULL
    GROUP BY prv.week_int
)
-- Final Output: Combine everything to calculate the Quick Ratio
SELECT 
    g.week_int AS week,
    g.new_users,
    g.resurrected_users,
    COALESCE(c.churned_users, 0) AS churned_users,
    ROUND((g.new_users + g.resurrected_users) / NULLIF(c.churned_users, 0), 2) AS quick_ratio,
    CASE 
        WHEN (g.new_users + g.resurrected_users) / NULLIF(c.churned_users, 0) >= 1 THEN 'Healthy Growth'
        WHEN (g.new_users + g.resurrected_users) / NULLIF(c.churned_users, 0) < 1 THEN 'Declining'
        ELSE 'N/A'
    END AS growth_status
FROM growth_metrics g
LEFT JOIN churn_metrics c ON g.week_int = c.week_int
WHERE g.week_int > 1 -- Week 1 doesn't have a ratio yet
ORDER BY g.week_int;


-- 10. Net Growth
WITH unique_activity AS (
    -- Deduplicate users per week
    SELECT DISTINCT device_id, week_int FROM weekly_devices
),
user_history AS (
    -- Identify the status of each user
    SELECT 
        device_id,
        week_int,
        LAG(week_int) OVER (PARTITION BY device_id ORDER BY week_int) AS prev_week,
        MIN(week_int) OVER (PARTITION BY device_id) AS first_week
    FROM unique_activity
),
growth_components AS (
    -- Calculate New and Resurrected
    SELECT 
        week_int,
        COUNT(CASE WHEN week_int = first_week THEN 1 END) AS new_users,
        COUNT(CASE WHEN week_int > first_week AND prev_week < week_int - 1 THEN 1 END) AS resurrected_users
    FROM user_history
    GROUP BY week_int
),
churn_component AS (
    -- Calculate Churn (Users from last week who didn't show up this week)
    SELECT 
        prv.week_int + 1 AS week_int,
        COUNT(DISTINCT prv.device_id) AS churned_users
    FROM unique_activity AS prv
    LEFT JOIN unique_activity AS curr 
        ON prv.device_id = curr.device_id 
        AND curr.week_int = prv.week_int + 1
    WHERE curr.device_id IS NULL
    GROUP BY prv.week_int
)
SELECT 
    g.week_int AS week,
    g.new_users,
    g.resurrected_users,
    COALESCE(c.churned_users, 0) AS churned_users,
    -- The Net Growth Formula
    (g.new_users + g.resurrected_users - COALESCE(c.churned_users, 0)) AS net_growth
FROM growth_components g
LEFT JOIN churn_component c ON g.week_int = c.week_int
ORDER BY g.week_int;


-- 11. Retention Rate.  Formula: (retained users / prev week active users)
WITH weekly_stats AS (
    -- Get unique users count for every week
    SELECT 
        week_int, 
        COUNT(DISTINCT device_id) AS total_users
    FROM weekly_devices
    GROUP BY week_int
),
retained_stats AS (
    -- Get count of users who were here last week AND this week
    SELECT 
        curr.week_int, 
        COUNT(DISTINCT curr.device_id) AS retained_users
    FROM (SELECT DISTINCT device_id, week_int FROM weekly_devices) AS curr
    INNER JOIN (SELECT DISTINCT device_id, week_int FROM weekly_devices) AS prv 
        ON prv.device_id = curr.device_id 
        AND prv.week_int = curr.week_int - 1
    GROUP BY curr.week_int
)
-- Combine and calculate the percentage
SELECT 
    r.week_int AS week,
    s.total_users AS users_last_week,
    r.retained_users,
    ROUND((r.retained_users / s.total_users) * 100, 2) AS retention_rate_percentage
FROM retained_stats r
JOIN weekly_stats s ON r.week_int = s.week_int + 1
ORDER BY r.week_int;


-- 12. Week-over-Week growth percentage (WOW).
WITH weekly_counts AS (
    -- Calculate unique users (WAU) per week
    SELECT 
        week_int, 
        COUNT(DISTINCT device_id) AS active_users
    FROM weekly_devices
    GROUP BY week_int
),
comparison AS (
    -- Get the previous week's count using LAG
    SELECT 
        week_int,
        active_users,
        LAG(active_users) OVER (ORDER BY week_int) AS prev_users
    FROM weekly_counts
)
-- Apply the WOW formula: ((Current - Prev) / Prev) * 100
SELECT 
    week_int AS `week`,
    active_users,
    prev_users,
    ROUND(((active_users - prev_users) / NULLIF(prev_users, 0)) * 100, 2) AS wow_growth_percentage
FROM comparison
ORDER BY week_int;


-- 13. Is growth consistent or random?
WITH active_users_per_week AS (
    SELECT 
        week_int, 
        COUNT(DISTINCT device_id) AS active_users
    FROM weekly_devices
    GROUP BY week_int
),
comparison AS (
    SELECT 
        week_int, 
        active_users, 
        LAG(active_users) OVER (ORDER BY week_int) AS prev_users
    FROM active_users_per_week
),

-- The following SELECT must be run as part of the block above
Wow AS (
SELECT 
    week_int, 
    active_users, 
    prev_users, 
    ROUND(((active_users - prev_users) / NULLIF(prev_users, 0)) * 100, 2) AS WoW_Percentage
FROM comparison
)

select 
 week_int, 
    active_users, 
    prev_users, 
 WoW_Percentage,
 case
 when WoW_Percentage > 0 then "Growth"
when WoW_Percentage < 0 then "Decline"
when WoW_Percentage = 0 then "Flat"
else "N/A"
end as trend from Wow;


-- 14. Volatility
 /*
 Score < 2: Low Volatility (Stable/Consistent growth).
Score 2 - 5: Moderate Volatility.
Score > 5: High Volatility (Random/Inconsistent growth).
 */
WITH active_users_per_week AS (
    SELECT 
        week_int, 
        COUNT(DISTINCT device_id) AS active_users
    FROM weekly_devices
    GROUP BY week_int
),
comparison AS (
    SELECT 
        week_int, 
        active_users, 
        LAG(active_users) OVER (ORDER BY week_int) AS prev_users
    FROM active_users_per_week
),

-- The following SELECT must be run as part of the block above
Wow AS (
SELECT 
    week_int, 
    active_users, 
    prev_users, 
    ROUND(((active_users - prev_users) / NULLIF(prev_users, 0)) * 100, 2) AS WoW_Percentage
FROM comparison
)
                -- Volitility
SELECT 
    ROUND(STDDEV(WoW_Percentage), 2) AS volatility_score
FROM Wow;  
    

    


    
