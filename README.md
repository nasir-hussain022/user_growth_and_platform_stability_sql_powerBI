# User Growth & Platform Stability 

This report combines key performance metrics with the technical methodology used during the data analysis of the 56-week user growth period.

---

<img width="1127" height="630" alt="dashboard" src="https://github.com/user-attachments/assets/13230458-3239-4d6b-9fb8-2e0719754aac" />

## 1. Core User Base & Acquisition
* **Total Historical Users: 31.82k**
    * **What:** The unique count of every device that has interacted with the platform over 56 weeks.
    * **Why:** This establishes the total "Market Reach" of the product.
    * **How:** Cleaned and de-duplicated the `device_id` column to ensure non-breaking spaces and nulls didn't inflate the count.
* **Net Growth: 28k**
    * **What:** The total increase in the active user base from the start of the observation period to the end.
    * **Insight:** This reflects a massive scaling phase, proving the product has high "top-of-funnel" attraction.

## 2. Engagement & Activity Benchmarks
* **Total Average WAU: 568.29**
    * **What:** The mean number of active users per week.
    * **Why:** While the total user base is 31k, this number indicates how many users are active in a typical week, assisting with server capacity and resource planning.
* **Peak Engagement (W41): 4.01k Active Users**
    * **Observation:** Week 41 stands as the record high for platform engagement.
* **Trough Engagement (W2): 1,654 Active Users**
    * **Observation:** The lowest point occurred very early, indicating a successful recovery and consistent growth trajectory since the project's inception.

## 3. Growth Accounting & Sustainability
* **Average Quick Ratio: 1.04**
    * **What:** A metric comparing Acquisition (New + Resurrected) to Churn (Lost users).
    * **Why:** A ratio $> 1.0$ is the "Growth Threshold." At 1.04, the platform is growing sustainably, though it remains in a "tight" zone where churn nearly matches acquisition.
    * **How:** Utilized complex DAX and SQL Window functions to segment users into New vs. Returning categories week-over-week.

## 4. User Loyalty & Permanent Churn
* **Unique Retained Users: 14,779**
    * **What:** Users who remained active for at least two consecutive weeks.
    * **Insight:** **46%** of the total user base shows "loyal" behavior. This is the core audience driving the platform's value.
* **Permanent Churn: 28,127**
    * **What:** Users who were active in the past but were not present in the final reporting week.
    * **Business Why:** This represents a "dormant audience." It is more cost-effective to re-acquire these users through "Win-back" campaigns than to acquire entirely new users.

## 5. Analytical Rigor (The Technical "How")
* **Data Sanitization:** Performed `REGEXP` filtering to remove "ghost" records and invisible whitespace that would have caused an estimated 8% error in growth reporting.
* **Volatility Analysis: 6.75 (Score)**
    * **Interpretation:** The platform exhibits **High Volatility**. This score ($>5$) indicates that growth patterns are relatively random or inconsistent, potentially driven by aggressive marketing spikes or irregular user behavior rather than a steady baseline.
* **Interactive Visualization:** Developed a Power BI dashboard featuring a "Health KPI Card" that dynamically shifts colors based on the Quick Ratio to provide instant feedback to stakeholders.

---

## Conclusion
The platform has successfully scaled to **31.82k users** with a healthy **Quick Ratio of 1.04**. However, the **High Volatility (6.75)** suggests that growth is sensitive and unpredictable. With **28k users currently inactive**, the next phase of operations should transition focus from expensive new acquisition toward **"Resurrection Campaigns"** to stabilize the growth pattern and bring the loyal core (**14k+**) back into the weekly active pool.

---

```sql
-- 1. Weekly active users.
SELECT
    concat('w', week_int) as week_name,
    COUNT(DISTINCT device_id) AS wau
FROM weekly_devices
GROUP BY week_int
ORDER BY week_int asc;
```
<img width="183" height="110" alt="image" src="https://github.com/user-attachments/assets/fea67f57-3be1-43fa-b15e-3b9c0cb99267" />

```sql
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

```
<img width="187" height="108" alt="image" src="https://github.com/user-attachments/assets/bddcd894-4626-45ee-840f-d6e6cafa13c9" />

```sql
-- 3. Which Weeks had highest active users?    
SELECT 
    concat('week',week_int) as weeks, COUNT(DISTINCT device_id) AS highest_active_users
FROM
    weekly_devices
GROUP BY week_int
ORDER BY highest_active_users DESC
LIMIT 1;
```
<img width="204" height="44" alt="image" src="https://github.com/user-attachments/assets/fc0deff5-a2cf-440f-9016-e80136a67f8b" />

```sql
-- 4. Which Weeks had lowest active users? 
SELECT 
    CONCAT('week', week_int) AS weeks,
    COUNT(DISTINCT device_id) AS lowest_active_users
FROM
    weekly_devices
GROUP BY week_int
ORDER BY lowest_active_users ASC
LIMIT 1;
```
<img width="194" height="68" alt="image" src="https://github.com/user-attachments/assets/5f4a3b4c-f21b-41d2-823a-e7dc92969abb" />

```sql
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
```
<img width="195" height="105" alt="image" src="https://github.com/user-attachments/assets/ec5328e3-19ac-4e99-92a2-508d909e7c07" />

```sql
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
```
<img width="178" height="112" alt="image" src="https://github.com/user-attachments/assets/d28f9674-88dc-4ba0-adf3-a68e5383bd2b" />

```sql
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
```
<img width="232" height="109" alt="image" src="https://github.com/user-attachments/assets/54ab4423-5677-4397-a6c4-3b8ed78beef6" />

```sql
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
```
<img width="222" height="111" alt="image" src="https://github.com/user-attachments/assets/93eb2139-61fe-4b07-aabe-98533595d394" />

```sql
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

```
<img width="497" height="122" alt="image" src="https://github.com/user-attachments/assets/697fe8cf-c542-49cb-973b-3b5723674918" />

```sql
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

```
<img width="414" height="117" alt="image" src="https://github.com/user-attachments/assets/e0163706-88f3-4d8d-a3e6-5a9fa1017367" />

```sql
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

```
<img width="397" height="111" alt="image" src="https://github.com/user-attachments/assets/4d18f269-f8e9-41f3-8ea3-21fbfe6eb0ab" />

```sql
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

```
<img width="367" height="106" alt="image" src="https://github.com/user-attachments/assets/18676471-e4a8-43aa-9c47-4bb4a18939c7" />

```sql
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

```
<img width="386" height="113" alt="image" src="https://github.com/user-attachments/assets/3d174522-bdb2-4f6b-b107-ce48dfac199b" />

```sql
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
```
<img width="146" height="46" alt="image" src="https://github.com/user-attachments/assets/9422925a-5ef5-492d-a08b-695790bccd27" />

---

- **Instagram**: [Follow me on instagram for daily tips](https://www.instagram.com/bca_wale022/)
- **LinkedIn**: [Connect with me on linkedIn](https://www.linkedin.com/in/nasir-hussain022)
- **Contact**: [Send me an email](mailto:nasirhussainnk172@gmail.com)
