/*
===============================================================================
DDL Script: Create production Views
===============================================================================
Script Purpose:
    This script creates views for the Production layer in the data warehouse. 
    The Production layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Staging layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: production.dim_customers
-- =============================================================================
IF OBJECT_ID('production.dim_customers', 'V') IS NOT NULL
    DROP VIEW production.dim_customers;
GO

CREATE VIEW production.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Surrogate key
    ci.cst_id                          AS customer_id,
    ci.cst_key                         AS customer_number,
    ci.cst_firstname                   AS first_name,
    ci.cst_lastname                    AS last_name,
    la.cntry                           AS country,
    ci.cst_marital_status              AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(ca.gen, 'n/a')  			   -- Fallback to ERP data
    END                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
FROM staging.crm_cust_info ci
LEFT JOIN staging.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN staging.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Create Dimension: production.dim_products
-- =============================================================================
IF OBJECT_ID('production.dim_products', 'V') IS NOT NULL
    DROP VIEW production.dim_products;
GO

CREATE VIEW production.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM staging.crm_prd_info pn
LEFT JOIN staging.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Filter out all historical data
GO

-- =============================================================================
-- Create Fact Table: production.fact_sales
-- =============================================================================
IF OBJECT_ID('production.fact_sales', 'V') IS NOT NULL
    DROP VIEW production.fact_sales;
GO

CREATE VIEW production.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM staging.crm_sales_details sd
LEFT JOIN production.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN production.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
