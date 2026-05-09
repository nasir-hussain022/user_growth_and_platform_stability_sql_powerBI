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
* **Volatility Analysis: 4.31 (Score)**
    * **Interpretation:** The platform exhibits **Moderate Volatility**. While growth is not perfectly smooth (due to seasonal or random spikes), the primary trend is consistently upward.
* **Interactive Visualization:** Developed a Power BI dashboard featuring a "Health KPI Card" that dynamically shifts colors based on the Quick Ratio to provide instant feedback to stakeholders.

---

## Strategic Conclusion
The platform has successfully scaled to **31.82k users** with a healthy **Quick Ratio of 1.04**. However, with **28k users currently inactive**, the next phase of operations should transition focus from expensive new acquisition toward **"Resurrection Campaigns"** to bring the loyal core (**14k+**) back into the weekly active pool.
