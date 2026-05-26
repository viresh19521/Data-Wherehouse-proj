CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    -------------------------------------------------------------------
    -- Load CRM Customer Info
    -------------------------------------------------------------------

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )

    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,

        CASE
            WHEN cst_material_status = 'M' THEN 'Married'
            WHEN cst_material_status = 'S' THEN 'Single'
            ELSE 'n/a'
        END AS cst_marital_status,

        CASE
            WHEN cst_gender = 'F' THEN 'Female'
            WHEN cst_gender = 'M' THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY cst_id
                   ORDER BY cst_create_date DESC
               ) AS flag_last
        FROM bronze.crm_cust_info
    ) t
    WHERE flag_last = 1;



    -------------------------------------------------------------------
    -- Load CRM Product Info
    -------------------------------------------------------------------

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt,
        dwh_create_date
    )

    SELECT
        prd_id,

        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,

        SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,

        prd_nm,

        ISNULL(prd_cost,0) AS prd_cost,

        CASE
            WHEN prd_line = 'M' THEN 'Mountain'
            WHEN prd_line = 'R' THEN 'Road'
            WHEN prd_line = 'S' THEN 'Other Sales'
            WHEN prd_line = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        CAST(prd_start_dt AS DATE),

        CAST(
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            )
        AS DATE) AS prd_end_dt,

        GETDATE()

    FROM bronze.crm_prd_info;



    -------------------------------------------------------------------
    -- Load CRM Sales Details
    -------------------------------------------------------------------

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )

    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        TRY_CONVERT(DATE, CAST(sls_order_dt AS VARCHAR(8)), 112),

        TRY_CONVERT(DATE, CAST(sls_ship_dt AS VARCHAR(8)), 112),

        TRY_CONVERT(DATE, CAST(sls_due_dt AS VARCHAR(8)), 112),

        CASE
            WHEN sls_sales IS NULL
                 OR sls_sales <= 0
                 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)

            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,
        sls_price

    FROM bronze.crm_sales_info;



    -------------------------------------------------------------------
    -- Load ERP Customer
    -------------------------------------------------------------------

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )

    SELECT

        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
            ELSE cid
        END AS cid,

        CASE
            WHEN bdate > GETDATE() THEN NULL
            ELSE bdate
        END AS bdate,

        CASE
            WHEN gen LIKE 'F%' THEN 'Female'
            WHEN gen LIKE 'M%' THEN 'Male'
            ELSE gen
        END AS gen

    FROM bronze.erp_cust_az12;



    -------------------------------------------------------------------
    -- Load ERP Location
    -------------------------------------------------------------------

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )

    SELECT
        REPLACE(cid,'-','') AS cid,

        CASE
            WHEN cntry = 'DE' THEN 'Germany'
            WHEN cntry IN ('usa','us') THEN 'United States'
            ELSE cntry
        END AS cntry

    FROM bronze.erp_loc_a101;

END;
execute [silver].[load_silver]
