/* --Katty
You manage the Order Lifecycle and long-term customer relationships.

--> Fact Table: Create an Accumulating Snapshot Fact Table to track an order from placement to delivery.

--> Dimensions:

- Customer: Implement a Slowly Changing Dimension (SCD Type 2) to track changes in loyalty tiers or demographics over time.
- Date/Time: Develop Role-playing dimensions so the same Date table can represent "Order Date" and "Delivery Date".

Special Logic: Include a Bridge Table to handle many-to-many relationships, such as multiple customers sharing a single loyalty account.
*/