# GA4-GA3 Big Query audit
A Big Query SQL request to simplify audit of GA4 migration from GA3

As most Google Analytics 3 (aka Universal Analytics) users are migrating to Google Analytics 4, once first implementation is done, it is important to understand what are the gaps between the two tools

This query is intended to help in finding and fixing those gaps

Here is a step by step guide on how to use it

0. Make sure you have connected both GA3 and GA4 to Big Query
   You can find tutorials on those links: [connect GA3 to BigQuery](https://support.google.com/analytics/answer/3416092?hl=en#zippy=%2Cin-this-article) (only for Google 360 clients) and [connect GA4 to BigQuery](https://support.google.com/analytics/answer/9823238?hl=en#zippy=%2Cin-this-article) (for all clients)
   
1. Copy Paste the file ga4-ga3.sql in a Big Query SQL environment (or if you are familiar with git, clone it on desired place)
2. Specify the proper dates for analysis in the query by replacing with your own dates if need be - that would be typically the last week
3. Find and replace the name of the GA3 and GA4 tables with the proper names of your table in the whole query
4. Run the query
5. Save results in Gsheet and analyse it
