/* -- Rijesh 
You focus on Efficiency and Resource Management at specific points in time.

--> Fact Table: Create a Periodic Snapshot Fact Table that captures inventory levels or staffing status at the end of each day/week.

--> Dimensions:
- Employee: Implement a Slowly Changing Dimension (SCD Type 1) to track employee performance and service speed.
- Organization: Model an Unbalanced Hierarchy for the company’s internal management reporting structure.

Metric Grain: Ensure this fact table has a different grain (e.g., daily summary) than the transaction-level tables used by the other students.
*/