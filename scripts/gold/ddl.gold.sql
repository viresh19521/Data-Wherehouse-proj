/*===========================================================
  Gold Layer - Customer Dimension
  Combines CRM and ERP customer data into a single dimension.
===========================================================*/
CREATE VIEW [gold].[dim_customer] AS

SELECT
    -- Generate surrogate key
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    *
FROM
(
    SELECT DISTINCT
        ci.cst_id AS customer_id,
        ci.cst_key AS customer_number,
        ci.cst_firstname AS first_name,
        ci.cst_lastname AS last_name,
        la.cntry AS country,
        ci.cst_marital_status,

        -- Use CRM gender if available; otherwise use ERP gender
        CASE
            WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
            ELSE COALESCE(ca.gen, 'n/a')
        END AS gender,

        ci.cst_create_date,
        ca.bdate

    FROM silver.crm_cust_info AS ci

    -- Customer demographic information
    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid

    -- Customer location information
    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid

) AS t;


/*===========================================================
  Gold Layer - Product Dimension
  Combines product master data with category information.
===========================================================*/
CREATE VIEW gold.dim_products AS

SELECT
    -- Generate surrogate key
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key,
    *
FROM
(
    SELECT DISTINCT
        pn.prd_id AS product_id,
        pn.cat_id AS category_id,
        pn.prd_key AS product_number,
        pn.prd_nm AS product_name,
        pn.prd_cost AS cost,
        pn.prd_line AS product_line,
        pn.prd_start_dt AS start_date,
        pc.cat AS category,
        pc.subcat AS subcategory,
        pc.maintenance

    FROM [datawarehouse].[silver].[crm_prd_info] AS pn

    -- Join product category details
    LEFT JOIN [bronze].[erp_px_cat_g1v2] AS pc
        ON pn.cat_id = pc.id

    -- Include only active products
    WHERE prd_end_dt IS NULL

) AS t;


/*===========================================================
  Gold Layer - Sales Fact
  Creates the fact table by joining sales with
  customer and product dimensions.
===========================================================*/
CREATE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num,
    sd.sls_prd_key,
    pr.product_key,
    cu.customer_key,
    sd.sls_cust_id,
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price

FROM [datawarehouse].[silver].[crm_sales_details] AS sd

-- Join customer dimension
LEFT JOIN gold.dim_customer AS cu
    ON cu.customer_key = sd.sls_prd_key

-- Join product dimension
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_key;
