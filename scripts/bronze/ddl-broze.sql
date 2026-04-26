CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_start_time DATETIME,
            @batch_end_time DATETIME,
            @table_name NVARCHAR(100),
            @row_count INT;

    BEGIN TRY

        -- Start time
        SET @batch_start_time = GETDATE();
        PRINT '===== BRONZE LOAD STARTED =====';
        PRINT 'Start Time: ' + CAST(@batch_start_time AS NVARCHAR);

        --------------------------------------------------
        -- Load CRM Customer Info
        --------------------------------------------------
        SET @table_name = 'crm_cust_info';
        PRINT 'Loading table: ' + @table_name;

        SELECT * FROM [bronze].[crm_cust_info];
        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows from ' + @table_name;

        --------------------------------------------------
        -- Load CRM Product Info
        --------------------------------------------------
        SET @table_name = 'crm_prd_info';
        PRINT 'Loading table: ' + @table_name;

        SELECT * FROM [bronze].[crm_prd_info];
        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows from ' + @table_name;

        --------------------------------------------------
        -- Load CRM Sales Info
        --------------------------------------------------
        SET @table_name = 'crm_sales_info';
        PRINT 'Loading table: ' + @table_name;

        SELECT * FROM [bronze].[crm_sales_info];
        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows from ' + @table_name;

        --------------------------------------------------
        -- ERP Tables
        --------------------------------------------------
        SET @table_name = 'erp_cust_az12';
        PRINT 'Loading table: ' + @table_name;

        SELECT * FROM [bronze].[erp_cust_az12];
        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows from ' + @table_name;

        SET @table_name = 'erp_loc_a101';
        PRINT 'Loading table: ' + @table_name;

        SELECT * FROM [bronze].[erp_loc_a101];
        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows from ' + @table_name;

        SET @table_name = 'erp_px_cat_g1v2';
        PRINT 'Loading table: ' + @table_name;

        SELECT * FROM [bronze].[erp_px_cat_g1v2];
        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows from ' + @table_name;

        --------------------------------------------------
        -- End time
        --------------------------------------------------
        SET @batch_end_time = GETDATE();

        PRINT 'End Time: ' + CAST(@batch_end_time AS NVARCHAR);

        PRINT 'Total Time: ' + 
              CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) 
              + ' sec';

        PRINT '===== BRONZE LOAD COMPLETED SUCCESSFULLY =====';

    END TRY
    BEGIN CATCH

        PRINT '===== ERROR OCCURRED =====';
        PRINT ERROR_MESSAGE();

    END CATCH

END;
execute [bronze].[load_bronze]
