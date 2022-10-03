/*

   _____        _  _               _____          ____
  / ____|   /\ | || |             / ____|   /\   |___ \
 | |  __   /  \| || |_   ______  | |  __   /  \    __) |
 | | |_ | / /\ \__   _| |______| | | |_ | / /\ \  |__ <
 | |__| |/ ____ \ | |            | |__| |/ ____ \ ___) |
  \_____/_/ _  \_\|_|_____ _____  \_____/_/    \_\____/ _______     __
 |_   _| \ | | |  _ \_   _/ ____|  / __ \| |  | |  ____|  __ \ \   / /
   | | |  \| | | |_) || || |  __  | |  | | |  | | |__  | |__) \ \_/ /
   | | | . ` | |  _ < | || | |_ | | |  | | |  | |  __| |  _  / \   /
  _| |_| |\  | | |_) || || |__| | | |__| | |__| | |____| | \ \  | |
 |_____|_| \_| |____/_____\_____|  \___\_\\____/|______|_|  \_\ |_|


FIRST WRITTEN ON: 2022-09-15
BY: DATAMA - GUILLAUME@DATAMA.IO
LICENCE:MIT
NOTE: This query has been written for helping comparison between GA4 and GA3
      Please read more instructions on https://github.com/DataMa-Solutions/GA4-GA3
      DataMa is a SaaS tool that helps finding insights and generate business actions based on data.
      Contact us for further deep dive on possible expanations for gaps between GA4 and GA3
*/


--- Change Date Range below

with date_range as (
  select
    "2022-09-21" as start_date,
    "2022-09-27" as end_date)

------------------- GA4 -------------------------------
, GA4_event as (
  SELECT
   "event" as type_GA4
  , event_name as metric
  , count(*) as Value
  FROM `your_project.your_GA4_ID.events_20*`
  , date_range
  WHERE PARSE_DATE('%y%m%d',_table_suffix) BETWEEN  DATE(date_range.start_date) and DATE(date_range.end_date)
  GROUP BY 1, 2
  )

  , GA4_basic_metrics_pivoted as (
    SELECT
     count(distinct user_pseudo_id) as users
    , count((select value.int_value from unnest(event_params) where event_name = 'session_start' and key = 'ga_session_id')) as sessions
    , SUM((CASE WHEN event_name='ecommerce_purchase' THEN 1 ELSE 0 END)) + SUM((CASE WHEN event_name='purchase' THEN 1 ELSE 0 END)) as transactions
    , SUM(CAST (ecommerce.purchase_revenue_in_usd*1000000 AS INT)) as revenue_10E6_in_usd_GA4_and_global_currency_in_UA
    FROM `your_project.your_GA4_ID.events_20*`
    , date_range
  WHERE PARSE_DATE('%y%m%d',_table_suffix) BETWEEN  DATE(date_range.start_date) and DATE(date_range.end_date)
  )

  , GA4_basic_metrics as (
    SELECT "totals" as type_GA4
    , metric, Value FROM GA4_basic_metrics_pivoted
    UNPIVOT(Value FOR metric IN (users, sessions, transactions, revenue_10E6_in_usd_GA4_and_global_currency_in_UA))
  )

, GA4_for_join as (SELECT  * FROM GA4_event UNION ALL SELECT * FROM GA4_basic_metrics)

------------------- GA3 -------------------------------

, GA3_event as (
  SELECT "event" as type_GA3
  , hits.eventinfo.eventaction as metric -- depending on your set up and what's the GA3 equivalent of event_name in GA4, you might want to put hits.eventinfo.eventcategory here instead
  , count(*) as Value
  FROM `your_project.your_GA3_ID.ga_sessions_20*`
  , unnest(hits) as hits, date_range
  WHERE PARSE_DATE('%y%m%d',_table_suffix) BETWEEN  DATE(date_range.start_date) and DATE(date_range.end_date)
  GROUP BY 1,2
  )


  , GA3_basic_metrics_pivoted as (
    SELECT
      count(distinct fullvisitorid) as users
      , sum(totals.visits) as sessions
      , sum(totals.pageviews) as page_view
      , sum(totals.screenviews) as load_screen -- screen views in UA are the equivalent of load_screen event in GA4
      , sum(totals.transactions) as transactions
      , sum(totals.totalTransactionRevenue) as revenue_10E6_in_usd_GA4_and_global_currency_in_UA
     FROM `your_project.your_GA3_ID.ga_sessions_20*`
    , date_range
  WHERE PARSE_DATE('%y%m%d',_table_suffix) BETWEEN  DATE(date_range.start_date) and DATE(date_range.end_date)
  )

  , GA3_basic_metrics as (
    SELECT "totals" as type_GA3
    , metric, Value FROM GA3_basic_metrics_pivoted
    UNPIVOT(Value FOR metric IN (sessions, page_view, load_screen, transactions, revenue_10E6_in_usd_GA4_and_global_currency_in_UA))
  )

, GA3_for_join as (SELECT  * FROM GA3_event UNION ALL SELECT * FROM GA3_basic_metrics)

-------------------JOINING GA3 AND GA4 -------------------------------
/*
, unioned_table as (SELECT "GA4" as source,* from GA4_for_join
UNION ALL
SELECT "GA3" as source,* from GA3_for_join)

Select * from unioned_table
where metric="select_content"
order by 2,3, 4,5,1
*/

  , Joined_table AS (SELECT case when ga4.metric is NULL then ga3.metric else ga4.metric end as metric
    , type_GA3
    , type_GA4
    , ga3.Value as Value_GA3
    , ga4.Value as Value_GA4
  FROM GA4_for_join ga4
  FULL JOIN GA3_for_join ga3
  ON ga4.metric = ga3.metric
  )

  Select metric
  , STRING_AGG(DISTINCT type_GA4) type_GA4 -- using STRING_AGG here in case of NULL values before so that we don't miss lines in case of dimensions breakdown
  , STRING_AGG(DISTINCT type_GA3) type_GA3
  , sum(Value_GA4) AS Value_GA4
  , sum(Value_GA3) AS Value_GA3
  , (sum(Value_GA3)/sum(Value_GA4)-1)*100 Percent_gap_GA3_vs_GA4
  FROM Joined_table
  GROUP BY 1
  ORDER BY Value_GA4 DESC, Value_GA3 DESC
