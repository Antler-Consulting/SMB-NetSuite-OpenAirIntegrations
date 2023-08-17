USE  [AC_Integrations]
GO
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================  
-- Create date: 30 July, 2023  
-- Description:  
/*
--Need to insert into the following tables
batchctl_all - 1 record for 1 full run of transactions
arinpchg_all - Invoice header table. Need 1 record per InvoiceNum
arinpcdt - Invoice detail table. Need the detail line items for each invoice
arinpage - Invoice Aging table. need 1 record per InvoiceNum
arinptax - Invoice tax table. Need 1 record per tax code. Since we hard code the tax code, it will just be 1 record per Invoicenum
*/
-- ==========================================  
ALTER PROCEDURE [dbo].[AC_CreateInv_sp] (  
 -- Add the parameters for the stored procedure here  
@Transaction_Status   Int = -1 Output,  
@Transaction_Message  Varchar(500) = '' Output   
)  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Define this Block for Locating Exceptions are coming while Transactions are in Progress.  	  
 Begin Try  
  -- Begin Database Transactions.  
  Begin Transaction    

--Precheck condition   1
Update AI
	Set AI.ErrorDesc = ISNULL(ErrorDesc, '') + ' | ' + 'Invalid Customer'
From [dbo].[AC_Invoices]  AI 
Where  LEFT(AcctCode, 4) not in (Select customer_code from [SB0075].[dbo].[arcust]  with(nolock)  )  and ProcessingStatus = 'Pending'
 
--Precheck condition   2 
Update AI
	Set AI.ErrorDesc = ISNULL(errordesc, '') + ' | ' + 'Invoice Exists in Unposted table' ,
	AI.ProcessingStatus = 'Errors',
	AI.DateProcessed = Getdate()
From [dbo].[AC_Invoices]  AI 
Where 'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum) 
in (select doc_ctrl_num from [SB0075].[dbo].[arinpchg_all] where trx_type = 2031)  
and ProcessingStatus = 'Pending'
 
-- update the status 
Update AI
	Set AI.ProcessingStatus = 'Errors',
	AI.DateProcessed = Getdate()
From [dbo].[AC_Invoices]  AI 
Where  InvoiceNum in (select distinct InvoiceNum from [dbo].[AC_Invoices] with(nolock) 
where ProcessingStatus = 'Pending' and ErrorDesc is not null)
 
--Getting the IDs values to loop multiple Invoices
--Drop Table If Exists #InvoicesIDs
Select    
		ROW_NUMBER() OVER(  PARTITION BY  invoiceNum ORDER BY invoiceNum) AS  Sequence_id, 
		InvoiceNum , 
		InternalID,
		DENSE_RANK() OVER(ORDER BY invoiceNum) AS  ID
Into #InvoicesIDs
From [dbo].[AC_Invoices] where ProcessingStatus = 'Pending'
--Select * From #InvoicesIDs 
 
--Variables declaration 
DECLARE @ProcessStartID BIGINT = 1;
DECLARE @RowCount BIGINT = 0;

-- get a count of total invoices rows to process 
SELECT @RowCount = COUNT(Distinct ID) FROM #InvoicesIDs;

---Loop to process all invoices data
WHILE @ProcessStartID <= @RowCount
BEGIN
/*
			--Assigning the latest batch number  
			Declare @batch_code varchar(16)                            
			Set @batch_code=(SELECT SUBSTRING (mask,1,(SELECT  LEN(mask) - LEN(next_num) 
							FROM [sb0075].dbo.ewnumber with(nolock)  where num_type = 2100)) 
							+ CAST (next_num AS CHAR) FROM [sb0075].dbo.ewnumber with(nolock)  where num_type = 2100) 
			Set @batch_code = REPLACE(@batch_code,' ','') 

			--INSERT batchctl_all table rows with latest batch number 
			insert into [sb0075].[dbo].batchctl_all 
			(
			batch_ctrl_num, batch_description, start_date, start_time,completed_date,completed_time,                                         
			control_number,control_total,actual_number,actual_total,batch_type,document_name,hold_flag,posted_flag,void_flag,                                          
			selected_flag,number_held,date_posted,time_posted,start_user,completed_user,company_code,process_group_num,                                          
			posted_user,org_id,selected_user_id,date_applied
			) 
			Select 
					@batch_code,                    
					'Open Air Invoices'                    
					,(datediff(day,'1/1/1950',convert(datetime,                
					  convert(varchar( 8), (year(GETDATE()) * 10000) + (month(GETDATE()) * 100) + day(GETDATE())))  ) + 711858),                                                            
					0,0,0,0,0,0,0, 2010                  
					,'Standard Transaction',0,0,0,0,0,0,0,'sa',''
					,(select Company_code from dbo.glco with(nolock) ),'',                                          
					'',(select organization_id from dbo.organization_all with(nolock) ),0,
					(select top 1 (datediff(day,'1/1/1950',convert(datetime,convert(varchar( 8), (year(DateInv) * 10000) 
					+ (month(DateInv) * 100) + day(DateInv)))  ) + 711858) from [AC_Integrations].[dbo].[AC_Invoices] with(nolock) )  
 
			---Update the batch number by 1  
			Update dbo.ewnumber set next_num = next_num + 1 where num_type = 2100   
*/
			----------------------------------------------------------
			--Assigning the latest trx_ctrl_num
			Declare @trx_ctrl_num varchar(16)                            
			Set @trx_ctrl_num=(SELECT SUBSTRING (mask,1,(SELECT  LEN(mask) - LEN(next_num) 
								FROM dbo.ewnumber with(nolock)  where num_type = 2000)) 
								+ CAST (next_num AS CHAR)  FROM dbo.ewnumber with(nolock)  where num_type = 2000) 
			Set @trx_ctrl_num = REPLACE(@trx_ctrl_num,' ','') 
			--Select @trx_ctrl_num 

			--Update trx_ctrl_num value in  [dbo].[AC_Invoices] table columns Comments1
			Update AI
				Set AI.Comments1=@trx_ctrl_num 
			From [dbo].[AC_Invoices] AI 
			Where invoiceNum =  (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID) ----??condition added


			INSERT INTO [sb0075].[dbo].[arinpchg_all]
			([trx_ctrl_num],[doc_ctrl_num],[doc_desc],[apply_to_num],[apply_trx_type],[order_ctrl_num],[batch_code],[trx_type],[date_entered],[date_applied],[date_doc],[date_shipped]
			,[date_required],[date_due],[date_aging],[customer_code],[ship_to_code],[salesperson_code],[territory_code],[comment_code],[fob_code],[freight_code],[terms_code],[fin_chg_code]
			,[price_code],[dest_zone_code],[posting_code],[recurring_flag],[recurring_code],[tax_code],[cust_po_num],[total_weight],[amt_gross],[amt_freight],[amt_tax],[amt_tax_included]
			,[amt_discount],[amt_net],[amt_paid],[amt_due],[amt_cost],[amt_profit],[next_serial_id],[printed_flag],[posted_flag],[hold_flag],[hold_desc],[user_id],[customer_addr1],[customer_addr2]
			,[customer_addr3],[customer_addr4],[customer_addr5],[customer_addr6],[ship_to_addr1],[ship_to_addr2],[ship_to_addr3],[ship_to_addr4],[ship_to_addr5],[ship_to_addr6],[attention_name]
			,[attention_phone],[amt_rem_rev],[amt_rem_tax],[date_recurring],[location_code],[process_group_num],[source_trx_ctrl_num],[source_trx_type],[amt_discount_taken],[amt_write_off_given]
			,[nat_cur_code],[rate_type_home],[rate_type_oper],[rate_home],[rate_oper],[edit_list_flag],[ddid],[writeoff_code],[vat_prc],[org_id],[customer_country_code],[customer_city]
			,[customer_state],[customer_postal_code],[ship_to_country_code],[ship_to_city],[ship_to_state],[ship_to_postal_code]
			)

			SELECT	 DISTINCT @trx_ctrl_num	--[trx_ctrl_num]
					   ,'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum)		--[doc_ctrl_num]
					   ,''	--LEFT(ISNULL(InvLineDesc, ''), 40)		-- [doc_desc]
					   ,''		--[apply_to_num]
					   ,0		--[apply_trx_type]
					   ,''		--[order_ctrl_num]
					   ,''		--@batch_code --[batch_code]
					   ,2031		--[trx_type]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateCreated)) +639906		--[date_entered]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_applied]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_doc]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_shipped]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_required]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906 + 30	--[date_due]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_aging]
					   ,LEFT(AcctCode, 4)		--Customer_code
					   ,''			--[ship_to_code]
					   ,c.[salesperson_code]
					   ,c.[territory_code]
					   ,c.[inv_comment_code]
					   ,c.[fob_code]
					   ,c.[freight_code]
					   ,c.[terms_code]
					   ,c.[fin_chg_code]
					   ,c.[price_code]
					   ,c.[dest_zone_code]
					   ,c.[posting_code]
					   ,0			--[recurring_flag]
					   ,''		--[recurring_code]
					   ,c.[tax_code]
					   ,''		--[cust_po_num]
					   ,0		--[total_weight]
					   ,InvTotal			--[amt_gross]
					   ,0		--[amt_freight]
					   ,0		--[amt_tax]
					   ,0		--[amt_tax_included]
					   ,0		--[amt_discount]
					   ,InvTotal			--[amt_net]
					   ,0		--[amt_paid]
					   ,InvTotal			--[amt_due]
					   ,0		--[amt_cost]
					   ,0		--[amt_profit]
					   ,0		--[next_serial_id]
					   ,0		--[printed_flag]
					   ,0		--[posted_flag]
					   ,0		--[hold_flag]
					   ,''		--[hold_desc]
					   ,1		--[user_id]
					   ,c.[addr1]
					   ,c.addr2		--[customer_addr2]
					   ,c.addr3		--[customer_addr3]
					   ,c.addr4		--[customer_addr4]
					   ,c.addr5		--[customer_addr5]
					   ,c.addr6		--[customer_addr6]
					   ,''		--[ship_to_addr1]
					   ,''		--[ship_to_addr2]
					   ,''		--[ship_to_addr3]
					   ,''		--[ship_to_addr4]
					   ,''		--[ship_to_addr5]
					   ,''		--[ship_to_addr6]
					   ,c.[attention_name]
					   ,c.[attention_phone]
					   ,0		--[amt_rem_rev]
					   ,0		--[amt_rem_tax]
					   ,''		--[date_recurring]
					   ,''		--[location_code]
					   ,''		--[process_group_num]
					   ,''		--[source_trx_ctrl_num]
					   ,NULL		--[source_trx_type]
					   ,0		--[amt_discount_taken]
					   ,0		--[amt_write_off_given]
					   ,'USD'		--[nat_cur_code]
					   ,c.[rate_type_home]
					   ,c.[rate_type_oper]
					   ,1		--[rate_home]
					   ,1		--[rate_oper]
					   ,0		--[edit_list_flag]
					   ,NULL	--[ddid]
					   ,''		--c.[writeoff_code]
					   ,0		--[vat_prc]
					   ,(select organization_id from [SB0075].[dbo].Organization_all with(nolock) )		--[org_id]
					   ,c.[country_code]	
					   ,c.city		--[customer_city]
					   ,c.state		--[customer_state]
					   ,c.postal_code	--[customer_postal_code]
					   ,''		--[ship_to_country_code]
					   ,''		--[ship_to_city]
					   ,''		--[ship_to_state]
					   ,''		--[ship_to_postal_code]
			FROM [AC_Integrations].[dbo].AC_Invoices i  with(nolock) 
			INNER JOIN dbo.arcust c  with(nolock)  on LEFT(i.AcctCode, 4) = c.customer_code
			where ProcessingStatus = 'Pending'
			and invtotal >=0
			and invoiceNum in (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID and Sequence_id = 1)  ----??condition added


			---Update the trx number by 1  
			Update dbo.ewnumber set next_num = next_num + 1 where num_type = 2000 

			 --Select  * From #InvoicesIDs where ID=1
			 --Variables declaration 
			DECLARE @ProcessMultipleID BIGINT = 1;
			DECLARE @RowMultipleCount BIGINT = 0;

			-- get a count of total invoices rows to process 
			SELECT @RowMultipleCount = COUNT(Distinct Sequence_id) FROM #InvoicesIDs where ID = @ProcessStartID;



			---Loop to process all invoices data
			WHILE @ProcessMultipleID <= @RowMultipleCount
			BEGIN
 
			INSERT INTO [sb0075].[dbo].[arinpcdt]
			([trx_ctrl_num],[doc_ctrl_num],[sequence_id],[trx_type],[location_code],[item_code],[bulk_flag],[date_entered],[line_desc],[qty_ordered],[qty_shipped],[unit_code],[unit_price]
			,[unit_cost],[weight],[serial_id],[tax_code],[gl_rev_acct],[disc_prc_flag],[discount_amt],[commission_flag],[rma_num],[return_code],[qty_returned],[qty_prev_returned],[new_gl_rev_acct]
			,[iv_post_flag],[oe_orig_flag],[discount_prc],[extended_price],[calc_tax],[reference_code],[new_reference_code],[cust_po],[org_id])

			SELECT	@trx_ctrl_num		--[trx_ctrl_num]
					   ,''	--'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum)		--[doc_ctrl_num]
					   --,'see note for sequence_id'		--[sequence_id]
					   , (Select  sequence_id From #InvoicesIDs where ID = @ProcessStartID and Sequence_id = @ProcessMultipleID)  ----??condition added
					   ,2031	--[trx_type]
					   ,''		--[location_code]
					   ,''		--[item_code]
					   ,0		--[bulk_flag]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateCreated)) +639906		--[date_entered]
					   ,LEFT(ISNULL(InvLineDesc, ''), 40)		--[line_desc]
					   ,1		--[qty_ordered]
					   ,1		--[qty_shipped]
					   ,''	--[unit_code]
					   ,LineAmt		--[unit_price]
					   ,0		--[unit_cost]
					   ,0		--[weight]
					   ,0		--[serial_id]
					   ,c.[tax_code]
					   ,'007511023750000'	-- [gl_rev_acct]
					   ,0		--[disc_prc_flag]
					   ,0		--[discount_amt]
					   ,0		--[commission_flag]
					   ,''		--[rma_num]
					   ,''		--[return_code]
					   ,0		--[qty_returned]
					   ,0		--[qty_prev_returned]
					   ,''		--[new_gl_rev_acct]
					   ,0		--[iv_post_flag]
					   ,0		--[oe_orig_flag]
					   ,0		--[discount_prc]
					   ,LineAmt		--[extended_price]
					   ,0		--[calc_tax]
					   ,LEFT(AcctCode, 4)	--[reference_code]
					   ,''		--[new_reference_code]
					   ,''		--[cust_po]
					   ,(select organization_id from [SB0075].[dbo].Organization_all with(nolock) )	--[org_id]
			FROM [AC_Integrations].[dbo].AC_Invoices i with(nolock) 
			INNER JOIN dbo.arcust c  with(nolock)  on LEFT(i.AcctCode, 4) = c.customer_code
			where ProcessingStatus = 'Pending'
			and invtotal >=0
			and invoiceNum in (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID  
			and i.InternalID = #InvoicesIDs.InternalID and Sequence_id = @ProcessMultipleID)  ----??condition added
   
		   SET @ProcessMultipleID = @ProcessMultipleID + 1 
 
		END 

			INSERT INTO [sb0075].[dbo].[arinpage]
			([trx_ctrl_num],[sequence_id],[doc_ctrl_num],[apply_to_num],[apply_trx_type],[trx_type],[date_applied],[date_due],[date_aging],[customer_code]
			,[salesperson_code],[territory_code],[price_code],[amt_due])

			SELECT		DISTINCT @trx_ctrl_num	--[trx_ctrl_num]
					   ,1 --[sequence_id]
					   ,''	--'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum)		--[doc_ctrl_num]
					   ,''	--'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum)		--[apply_to_num]
					   ,0	--[apply_trx_type]
					   ,2031	--[trx_type]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_applied]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906 + 30		--[date_due]
					   ,datediff(dd,'1/1/1753',convert(datetime, DateInv)) +639906		--[date_aging]
					   ,LEFT(AcctCode, 4)	--[customer_code]
					   ,c.[salesperson_code]
					   ,c.[territory_code]
					   ,c.[price_code]
					   ,InvTotal			--[amt_due]
			FROM [AC_Integrations].[dbo].AC_Invoices i with(nolock) 
			INNER JOIN dbo.arcust c  with(nolock) on LEFT(i.AcctCode, 4) = c.customer_code
			where ProcessingStatus = 'Pending'
			and invtotal >=0
			and invoiceNum in (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID and Sequence_id = 1 )  ----??condition added

			INSERT INTO [sb0075].[dbo].[arinptax]
			([trx_ctrl_num],[trx_type],[sequence_id],[tax_type_code],[amt_taxable],[amt_gross],[amt_tax],[amt_final_tax])

			SELECT		DISTINCT @trx_ctrl_num	--[trx_ctrl_num]
					   ,2031	--[trx_type]
					   ,1	--[sequence_id]
					   ,'ZERO'	--[tax_type_code]
					   ,InvTotal	--[amt_taxable]
					   ,InvTotal	--[amt_gross]
					   ,0	--[amt_tax]
					   ,0	--[amt_final_tax]
			FROM [AC_Integrations].[dbo].AC_Invoices i with(nolock) 
			INNER JOIN dbo.arcust c  with(nolock) on LEFT(i.AcctCode, 4) = c.customer_code
			where ProcessingStatus = 'Pending'
			and invtotal >=0
			and invoiceNum in (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID and Sequence_id = 1 )  ----??condition added
			 -----------------------

			 --select * 	FROM [AC_Integrations].[dbo].AC_Invoices i with(nolock)  where invtotal >=0
			/*
			If the InvTotal is negative, then the insert will have to change. Below are the update statements for those. Based on this you can create your insert statement accordingly. 
			So you will have 1 insert for 5 tables for all the positive InvTotals. These are invoices.
			Then you will have a separate insert statement for 3 tables (no insert for arinpage and arinptax) for the negative amounts. These are called Credit Memos.
			These transactions will have their own batch code too.
			Trx_ctrl_num will have the same concept as above, but the num_type will be 2020
			 select    LEFT(mask, (LEN(mask) - LEN(next_num) +1) + next_num), *  from [dbo].[ewnumber]    where num_type = 2020
			*/

			----select * from dbo.arinpchg_all with(nolock) 
			----where trx_ctrl_num in ('CMTRX00599071523', 'CMTRX00000023962')

			----update dbo.batchctl_all set batch_type = 2030
			----where batch_ctrl_num = 'ARB#######'

			----update dbo.arinpchg_all set trx_ctrl_num = 'CMTRX00000023962', apply_to_num = '', batch_code = 'ARB#######', trx_type = 2032, recurring_flag = 1, amt_gross = amt_gross *-1,
			----amt_net = amt_net * -1

			----select * from dbo.arinpcdt with(nolock) 
			----where trx_ctrl_num in ('CMTRX00599071523', 'IVTRX00000081484')

			----update dbo.arinpcdt set trx_ctrl_num = 'CMTRX00000023962', trx_type = 2032, qty_ordered = 0, unit_price = unit_price * -1, 
			----qty_returned = 1, extended_price = extended_price * -1
			----where trx_ctrl_num in ('IVTRX00000081484')

			----select * from dbo.arinpage with(nolock) 
			----where trx_ctrl_num in ('CMTRX00599071523', 'IVTRX00000081484')
  
			----select * from dbo.arinptax
			----where trx_ctrl_num in ('CMTRX00599071523', 'IVTRX00000081484')
 

			/*
			After everything is processed successfully and committed, below are the additional updates that will be needed
			AC_Invoices.ProcessingStatus = 'Complete' /* If there are errors, then change the value to 'Errors' */
			If there are errors, then don't process that specific InvoiceNum, but the other InvoiceNum that don't have errors, can be processed through. 
			We should process all lines of a particular invoicenum. So if you have an error in one of the lines, the full InvoiceNum is marked as error
			AC_Invoices.ErrorDesc should have the error info. if more than 1 error, then separate by a pipe " | "
			AC_Invoices.Comments1 = populate this with the trx_ctrl_num that was used to create the transaction. 
			This will not be populated if that invoicenum has an error since we would not have inserted the recods in the final tables.
			*/

			--Update AC_Invoices.ProcessingStatus = 'Complete' 
			Update AI
				Set AI.ProcessingStatus = 'Complete' 
				,AI.DateProcessed = Getdate()
			From [dbo].[AC_Invoices] AI 
			Where invoiceNum =  (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID)  ----??condition added

   SET @ProcessStartID = @ProcessStartID + 1 
 
END    
 
  -- Commit Database Transactions.  
  Commit Transaction  
 End Try  
 Begin Catch  

		--Update AC_Invoices.ErrorDesc
		Update AI
			Set AI.ErrorDesc = 'Error No. ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(10) +   
                                 'Error Message : ' + ERROR_MESSAGE() + CHAR(10) +   
                                 'Error in Procedure : ' + ERROR_PROCEDURE() + CHAR(10) +   
                                 'Error Severity : ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(10) +   
                                 'Error Line No. ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(10) +   
                                 'Error State : ' + CAST(ERROR_STATE() AS VARCHAR(10))
		From [dbo].[AC_Invoices] AI 
		Where invoiceNum =  (Select DIstinct invoiceNum From #InvoicesIDs where ID = @ProcessStartID)  ----??condition added

  -- Getting If any Exception is coming while Transactions are in Progress.  
  Select @Transaction_Status = -1, @Transaction_Message = 'Error No. ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(10) +   
                                 'Error Message : ' + ERROR_MESSAGE() + CHAR(10) +   
                                 'Error in Procedure : ' + ERROR_PROCEDURE() + CHAR(10) +   
                                 'Error Severity : ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(10) +   
                                 'Error Line No. ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(10) +   
                                 'Error State : ' + CAST(ERROR_STATE() AS VARCHAR(10));  
  -- Roll back Database Transaction if any Error is coming.  
  Rollback Transaction  
 End Catch;   
 Return  
  
END  

GO

GRANT EXEC ON AC_CreateInv_sp TO public
GO
