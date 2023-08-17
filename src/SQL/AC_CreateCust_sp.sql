USE AC_Integrations
GO


/****** Object:  StoredProcedure [dbo].[AC_CreateCust_sp]    Script Date: 6/15/2023 10:04:11 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AC_CreateCust_sp]') AND type in (N'P'))
DROP PROCEDURE [dbo].[AC_CreateCust_sp]
GO



	/*
	// Company:		Smithbucklin
	// By:			Antler Consulting
	// Description: Stored proc to validate the source data in AC_Customers table
					and import the valid customers into the sb0075 database. 
	//				Existing customers will be updated.
	//				
	//				

	//REVISION HISTORY
	//
	//Rev-No	Date		Name		Description                                                           
	// ------	--------	-------		---------------------------------------------------------
	// 			20230601	AMAHARAJ	Initial Stored Proc - DEVELOPMENT VERSION
	//
	*/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
/* ------ SUMMARY - Version 1.0.0.0 --------        
        
Input Variables        
@DBName - Database to import customers into         

select * from AC_Integrations..AC_Customers
select * from SB0075..arcust where customer_code in
(select customercode from AC_Integrations..AC_Customers)

EXEC AC_CreateCust_sp 'SB0075', 0      
 

*/        
        
CREATE PROCEDURE [dbo].[AC_CreateCust_sp] @DBName VARCHAR(100), @ErrorCount int OUTPUT        
AS        
    
BEGIN       
  
 DECLARE @SQL VARCHAR(8000), @SQL1 NVARCHAR(4000)  
   
   -- *** Common validation ***  
/*    
 -- Validate tax_code        
 SET @SQL = 'UPDATE AC_Customers SET ProcessingStatus = ErrorDesc = ErrorDesc + ' + ''' Missing/Invalid Tax Code - ''' + ' + TaxCode + ' + ''' | ''' + ' WHERE (TaxCode IS NULL) OR (TaxCode NOT IN (SELECT tax_code FROM  ' + @DBName + '..artax))'        
 EXEC (@SQL)      
    
 -- Validate terms_code        
 SET @SQL = 'UPDATE AC_Customers SET ErrorDesc = ErrorDesc + ' + ''' Missing/Invalid Payment Terms - ''' + ' + PaymentTerms + ' + ''' | ''' + ' WHERE PaymentTerms NOT IN ( SELECT terms_code FROM ' + @DBName + '..arterms )'        
 EXEC (@SQL)      
    
 -- Validate territory_code        
 SET @SQL = 'UPDATE AC_Customers SET ErrorDesc = ErrorDesc + ' + '''Missing/Invalid Territory Code - ''' + ' + TerritoryCode + ' + ''' | ''' + ' WHERE TerritoryCode NOT IN ( SELECT territory_code FROM ' + @DBName + '..arterr )'        
 EXEC (@SQL)     
  
 -- Validate duplicate Customer and Ship To Code combination  
 SET @SQL = 'UPDATE AC_Customers SET ErrorDesc = ErrorDesc + ' + '''  Duplicate Bill To and/or Ship To Code | ''' + ' WHERE CustomerCode + ShipToCode IN (select DISTINCT CustomerCode + ShipToCode from AC_Customers group by CustomerCode + ShipToCode having count
(*) > 1)'        
 EXEC (@SQL)    
 
 */
  --Update processing status
  /*
  UPDATE AC_Customers set ProcessingStatus = 'Errors' where LEN(RTRIM(ErrorDesc)) > 0
  AND ProcessingStatus = 'Pending'
 */


BEGIN TRAN   
  -- Check if there are any validation errrors       
  SET @ErrorCount = (SELECT COUNT(*) FROM AC_Customers WHERE LEN(RTRIM(ErrorDesc)) > 0)        
  IF (@ErrorCount > 0)     
   BEGIN       
   GOTO RETURN_ERROR_COUNT       
   END    
  ELSE    
   -- Insert to armaster_all    
  BEGIN   
    
    --Reset the error count to 0 for insert      
    SET @ErrorCount = 0     
    SET @SQL = 'ALTER TABLE ' + @DBName + '..armaster_all DISABLE TRIGGER armaster_all_ins_trg'        
    EXEC (@SQL)   
    


    IF (@@ERROR <> 0)      
    BEGIN       
  SET @ErrorCount = @ErrorCount + 1      
  GOTO RETURN_ERROR_COUNT       
    END      



  -- ********** Update customers **************  
  -- Update armaster_all   
  SET @SQL =         
  'Update ' + @DBName + '..armaster_all 
  SET              
  address_name = LEFT(ISNULL(CustomerName, ''''), 40), --address_name        
  short_name = LEFT(CustomerName,10), --short_name        
  addr1 = LEFT(ISNULL(CustomerName, ''''), 40), --addr1        
  addr2 = LEFT(ISNULL(c.Addr1, ''''), 40), --addr2        
  addr3 = LEFT(ISNULL(c.Addr2, ''''), 40), --addr3        
  addr4 = LEFT(ISNULL(c.Addr3, ''''), 40),  --addr4        
  addr5 = LEFT(ISNULL(c.Addr4, ''''), 40),  --addr5        
  addr6 = LEFT(ISNULL(c.Addr5, ''''), 40), --addr6      
  addr_sort1 = c.City, -- addr_sort1        
  addr_sort2 = c.State, -- addr_sort2          
  addr_sort3 = Zip, --addr_sort3        
  status_type = c.[Status], --status_type         
  attention_name = ISNULL(AttnName, ''''), --attention_name         
  attention_phone = ISNULL(AttnPhone, ''''), --attention_phone        
  contact_name = ISNULL(ContactName, ''''), --contact_name        
  contact_phone = ISNULL(ContactPhone, ''''), --contact_phone        
  tlx_twx = ISNULL(Fax, ''''), --tlx_twx        
  phone_1 = ISNULL(Phone1, ''''), --phone_1        
  phone_2 = ISNULL(Phone2, ''''), --phone_2        
  added_by_date = GETDATE(), --added_by_date        
  modified_by_user_name = ''sa'', --modified_by_user_name        
  modified_by_date = GETDATE(), --modified_by_date         
  city = ISNULL(LTRIM(RTRIM(c.City)), ''''), --city        
  state = ISNULL(LTRIM(RTRIM(c.State)), ''''), --state        
  postal_code = ISNULL(LTRIM(RTRIM(Zip)), ''''), --postal_code        
  country = c.Country, --country        
  country_code = c.Country --country_code
  FROM AC_Integrations..AC_Customers c,  ' + @DBName + '..armaster_all a   
  WHERE  c.CustomerCode = a.customer_code
  AND a.address_type = 0
  AND CustomerCode IN (SELECT customer_code FROM ' + @DBName + '..armaster_all WHERE address_type = 0)'  
  
 --PRINT @SQL            
  EXEC (@SQL) 

  -- Update Processing status   
  SET @SQL =         
  'Update AC_Integrations..AC_Customers 
  SET              
  ProcessingStatus = ''Complete'' 
  WHERE   
  CustomerCode IN (SELECT customer_code FROM ' + @DBName + '..armaster_all 
  WHERE address_type = 0
  AND ProcessingStatus = ''Pending'')'  
  
 --PRINT @SQL            
  EXEC (@SQL) 

  
  -- ********** Create new customers **************  
  -- Insert into armaster_all   
  SET @SQL =         
  'INSERT into ' + @DBName + '..armaster_all
  SELECT NULL,             
  CustomerCode,  --customer_code        
  '''', -- ship_to_code        
  LEFT(ISNULL(CustomerName, ''''), 40), --address_name        
  LEFT(CustomerName,10), --short_name        
  LEFT(ISNULL(CustomerName, ''''), 40), --addr1        
  LEFT(ISNULL(Addr1, ''''), 40), --addr2        
  LEFT(ISNULL(Addr2, ''''), 40), --addr3        
  LEFT(ISNULL(Addr3, ''''), 40),  --addr4        
  LEFT(ISNULL(Addr4, ''''), 40),  --addr5        
  LEFT(ISNULL(Addr5, ''''), 40), --addr6      
  City, -- addr_sort1        
  State, -- addr_sort2          
  Zip, --addr_sort3        
  0, --address_type  
  Status, --status_type         
  AttnName, --attention_name         
  AttnPhone, --attention_phone        
  ContactName, --contact_name        
  ContactPhone, --contact_phone        
  Fax, --tlx_twx        
  Phone1, --phone_1        
  Phone2, --phone_2        
  ''NOTAX'', --tax_code        
  ''30'', --terms_code        
  '''', --fob_code        
  '''', --freight_code         
  ''AR'', --posting_code         
  '''', --location_code        
  '''', --alt_location_code        
  '''', --dest_zone_code        
  ''CONTRACT'', --territory_code         
  '''', --salesperson_code         
  '''', --fin_chg_code         
  ''STANDARD'', --price_code         
  ''CHECK-CH'', --payment_code        
  '''', --vendor_code        
  '''', --affiliated_cust_code        
  1, --print_stmt_flag         
  '''', --stmt_cycle_code         
  '''', --inv_comment_code         
  ''NONE'', --stmt_comment_code         
  ''NONE'', --dunn_message_code         
  '''', --note        
  0, --trade_disc_percent        
  1, --invoice_copies        
  0, --iv_substitution        
  1, --ship_to_history        
  0, --check_credit_limit        
  0, --credit_limit        
  0, --check_aging_limit        
  1, --aging_limit_bracket        
  0, --bal_fwd_flag        
  0, --ship_complete_flag         
  '''', --resale_num        
  '''', --db_num        
  0, --db_date        
  '''', --db_credit_rating        
  0, --late_chg_type        
  1, --valid_payer_flag        
  1, --valid_soldto_flag        
  1, --valid_shipto_flag        
  '''', --payer_soldto_rel_code        
  0, --across_na_flag        
  DATEDIFF(dd, ''1/1/1753'', CONVERT(datetime, GETDATE())) + 639906, --date_opened        
  ''sa'', --added_by_user_name        
  GETDATE(), --added_by_date        
  '''', --modified_by_user_name        
  '''', --modified_by_date         
  ''BUY'', --rate_type_home        
  ''BUY'', --rate_type_oper        
  0, --limit_by_home        
  ''USD'', --nat_cur_code        
  0, --one_cur_cust        
  ISNULL(LTRIM(RTRIM(City)), ''''), --city        
  ISNULL(LTRIM(RTRIM(State)), ''''), --state        
  ISNULL(LTRIM(RTRIM(Zip)), ''''), --postal_code        
  Country, --country        
  '''', --remit_code        
  '''', --forwarder_code        
  '''', --freight_to_code        
  '''', --route_code        
  0, --route_no        
  '''', --url        
  '''', --special_instr        
  '''', --guid        
  1, --price_level        
  '''', --ship_via_code        
  '''', --ddid        
  '''', --so_priority_code        
  Country, --country_code        
  '''', --tax_id_num        
  '''', --ftp        
  '''', --attention_email        
  '''', --contact_email        
  '''', --dunning_group_id        
  0, --consolidated_invoices        
  ''DEFAULT'', --writeoff_code        
  0, --delivery_days        
  '''', --extended_name        
  0, --check_extendedname_flag        
  0 --check_display_comment        
  FROM AC_Customers    
  WHERE   
  CustomerCode NOT IN (SELECT customer_code FROM ' + @DBName + '..armaster_all WHERE address_type = 0)'  
  
  --PRINT @SQL  
  
 EXEC (@SQL)   
  IF (@@ERROR <> 0)      
  BEGIN       
  SET @ErrorCount = @ErrorCount + 1      
  GOTO RETURN_ERROR_COUNT       
  END       
  

  IF (@@ERROR <> 0)      
  BEGIN       
  SET @ErrorCount = @ErrorCount + 1      
  GOTO RETURN_ERROR_COUNT       
  END    
  

  -- Update Processing status   
  SET @SQL =         
  'Update AC_Integrations..AC_Customers 
  SET              
  ProcessingStatus = ''Complete'',
  DateProcessed = GETDATE()
  WHERE   
  CustomerCode IN (SELECT customer_code FROM ' + @DBName + '..armaster_all 
  WHERE address_type = 0
  AND ProcessingStatus = ''Pending'')'  
  
 -- PRINT @SQL            
  EXEC (@SQL) 
  
  SET @SQL = 'ALTER TABLE ' + @DBName + '..armaster_all ENABLE TRIGGER armaster_all_ins_trg'        
  EXEC (@SQL)        
  IF (@@ERROR <> 0)       
  BEGIN      
   SET @ErrorCount = @ErrorCount + 1      
   GOTO RETURN_ERROR_COUNT       
  END   
 END       
  
  IF (@@ERROR <> 0)       
  BEGIN      
   SET @ErrorCount = @ErrorCount + 1      
   GOTO RETURN_ERROR_COUNT       
  END    
  
   -- Commit transaction if there are no errors          
   IF @ErrorCount = 0  
   BEGIN            
   COMMIT TRAN    
   GOTO END_SP     
   END  
   ELSE    
   -- Else rollback transaction      
   BEGIN     
    RETURN_ERROR_COUNT:      
    ROLLBACK TRAN      
    GOTO END_SP       
   END     
    
   END_SP:   
   SELECT @ErrorCount   
END  

GO

GRANT ALL ON AC_CreateCust_sp TO public
GO