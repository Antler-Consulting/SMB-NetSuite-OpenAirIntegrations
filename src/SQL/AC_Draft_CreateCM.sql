/*

Need to insert into the following tables for a credit memo (invTotal < 0)

arinpchg_all - Invoice header table. Need 1 record per InvoiceNum
arinpcdt - Invoice detail table. Need the detail line items for each CM
arinptax - Invoice tax table. Need 1 record per tax code. Since we hard code the tax code, it will just be 1 record per CM

*/

select * from ewnumber where num_type = 2020
--CMTRX00000023964
update ewnumber set next_num = next_num + 1 where num_type = 2020  

/*

INSERT for the arinpchg_all table

trx_ctrl_num: This is a unique transaction number for each InvoiceNum. The value is derived from the ewnumber table where num_type = 2000
LEFT(mask, (LEN(mask) - LEN(next_num) +1) + next_num

e.g. The value would be IVTRX00000081487 based on the data in the ewnumber table as it stands now. 

This would increment for every unique InvoiceNum in the source table. 

The ewnumber.next_num will need to increment by 1 after every use of that number. 

*/

USE [sb0075]
GO

INSERT INTO [dbo].[arinpchg_all]
           ([trx_ctrl_num]
           ,[doc_ctrl_num]
           ,[doc_desc]
           ,[apply_to_num]
           ,[apply_trx_type]
           ,[order_ctrl_num]
           ,[batch_code]
           ,[trx_type]
           ,[date_entered]
           ,[date_applied]
           ,[date_doc]
           ,[date_shipped]
           ,[date_required]
           ,[date_due]
           ,[date_aging]
           ,[customer_code]
           ,[ship_to_code]
           ,[salesperson_code]
           ,[territory_code]
           ,[comment_code]
           ,[fob_code]
           ,[freight_code]
           ,[terms_code]
           ,[fin_chg_code]
           ,[price_code]
           ,[dest_zone_code]
           ,[posting_code]
           ,[recurring_flag]
           ,[recurring_code]
           ,[tax_code]
           ,[cust_po_num]
           ,[total_weight]
           ,[amt_gross]
           ,[amt_freight]
           ,[amt_tax]
           ,[amt_tax_included]
           ,[amt_discount]
           ,[amt_net]
           ,[amt_paid]
           ,[amt_due]
           ,[amt_cost]
           ,[amt_profit]
           ,[next_serial_id]
           ,[printed_flag]
           ,[posted_flag]
           ,[hold_flag]
           ,[hold_desc]
           ,[user_id]
           ,[customer_addr1]
           ,[customer_addr2]
           ,[customer_addr3]
           ,[customer_addr4]
           ,[customer_addr5]
           ,[customer_addr6]
           ,[ship_to_addr1]
           ,[ship_to_addr2]
           ,[ship_to_addr3]
           ,[ship_to_addr4]
           ,[ship_to_addr5]
           ,[ship_to_addr6]
           ,[attention_name]
           ,[attention_phone]
           ,[amt_rem_rev]
           ,[amt_rem_tax]
           ,[date_recurring]
           ,[location_code]
           ,[process_group_num]
           ,[source_trx_ctrl_num]
           ,[source_trx_type]
           ,[amt_discount_taken]
           ,[amt_write_off_given]
           ,[nat_cur_code]
           ,[rate_type_home]
           ,[rate_type_oper]
           ,[rate_home]
           ,[rate_oper]
           ,[edit_list_flag]
           ,[ddid]
           ,[writeoff_code]
           ,[vat_prc]
           ,[org_id]
           ,[customer_country_code]
           ,[customer_city]
           ,[customer_state]
           ,[customer_postal_code]
           ,[ship_to_country_code]
           ,[ship_to_city]
           ,[ship_to_state]
           ,[ship_to_postal_code])

SELECT	   TrxNum		--[trx_ctrl_num]
           ,'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum)		--[doc_ctrl_num]
           ,LEFT(ISNULL(InvLineDesc, ''), 40)		-- [doc_desc]
           ,''		--[apply_to_num]
           ,0		--[apply_trx_type]
           ,''		--[order_ctrl_num]
           ,''	--[batch_code]
           ,2032		--[trx_type]
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
           ,1			--[recurring_flag]
           ,''		--[recurring_code]
           ,c.[tax_code]
           ,''		--[cust_po_num]
           ,0		--[total_weight]
           ,InvTotal * -1			--[amt_gross]
           ,0		--[amt_freight]
           ,0		--[amt_tax]
           ,0		--[amt_tax_included]
           ,0		--[amt_discount]
           ,InvTotal * -1			--[amt_net]
           ,0		--[amt_paid]
           ,0 			--[amt_due]
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
           ,null		--[source_trx_type]
           ,0		--[amt_discount_taken]
           ,0		--[amt_write_off_given]
           ,'USD'		--[nat_cur_code]
           ,c.[rate_type_home]
           ,c.[rate_type_oper]
           ,1		--[rate_home]
           ,1		--[rate_oper]
           ,0		--[edit_list_flag]
           ,NULL	--[ddid]
           ,c.[writeoff_code]
           ,0		--[vat_prc]
           ,(select organization_id from SB0075..Organization_all)		--[org_id]
           ,c.[country_code]	
           ,c.city		--[customer_city]
           ,c.state		--[customer_state]
           ,c.postal_code	--[customer_postal_code]
           ,''		--[ship_to_country_code]
           ,''		--[ship_to_city]
           ,''		--[ship_to_state]
           ,''		--[ship_to_postal_code]

		   FROM AC_Integrations..AC_Invoices i
		   INNER JOIN arcust c on LEFT(i.AcctCode, 4) = c.customer_code
		   where ProcessingStatus = 'Pending'
		   and SeqNum = 1 and InvTotal < 0


/*

Below is the insert for the invoice detail table
The important change would be the sequence_id column
This is a sequential line number for each invoice line. It resets to 1 for the next invoice.

e.g. If InvNum 108 has 3 rows, the sequence_id would start with 1 and increment by 1 until it reaches the end of that InvoiceNum. Below is how the invoiceNum and sequence will look like. 

108	1
108	2
108	3
109	1
110	1
110	2
110	3
110	4
110	5
110	6

*/

USE [sb0075]
GO

INSERT INTO [dbo].[arinpcdt]
           ([trx_ctrl_num]
           ,[doc_ctrl_num]
           ,[sequence_id]
           ,[trx_type]
           ,[location_code]
           ,[item_code]
           ,[bulk_flag]
           ,[date_entered]
           ,[line_desc]
           ,[qty_ordered]
           ,[qty_shipped]
           ,[unit_code]
           ,[unit_price]
           ,[unit_cost]
           ,[weight]
           ,[serial_id]
           ,[tax_code]
           ,[gl_rev_acct]
           ,[disc_prc_flag]
           ,[discount_amt]
           ,[commission_flag]
           ,[rma_num]
           ,[return_code]
           ,[qty_returned]
           ,[qty_prev_returned]
           ,[new_gl_rev_acct]
           ,[iv_post_flag]
           ,[oe_orig_flag]
           ,[discount_prc]
           ,[extended_price]
           ,[calc_tax]
           ,[reference_code]
           ,[new_reference_code]
           ,[cust_po]
           ,[org_id])

SELECT	TrxNum		--[trx_ctrl_num]
           ,'OA' + convert (varchar(3), '000') + convert(varchar(3), InvoiceNum)		--[doc_ctrl_num]
           ,SeqNum		--[sequence_id]
           ,2032	--[trx_type]
           ,''		--[location_code]
           ,''		--[item_code]
           ,0		--[bulk_flag]
           ,datediff(dd,'1/1/1753',convert(datetime, DateCreated)) +639906		--[date_entered]
           ,ISNULL(InvLineDesc, '')		--[line_desc]
           ,0		--[qty_ordered]
           ,0		--[qty_shipped]
           ,''	--[unit_code]
           ,LineAmt	* -1	--[unit_price]
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
           ,1		--[qty_returned]
           ,0		--[qty_prev_returned]
           ,''		--[new_gl_rev_acct]
           ,0		--[iv_post_flag]
           ,0		--[oe_orig_flag]
           ,0		--[discount_prc]
           ,LineAmt * -1		--[extended_price]
           ,0		--[calc_tax]
           ,LEFT(AcctCode, 4)	--[reference_code]
           ,''		--[new_reference_code]
           ,''		--[cust_po]
           ,(select organization_id from SB0075..Organization_all)	--[org_id]

			FROM AC_Integrations..AC_Invoices i
		   INNER JOIN arcust c on LEFT(i.AcctCode, 4) = c.customer_code
		   where ProcessingStatus = 'Pending'
		   and InvTotal < 0

USE [sb0075]
GO

INSERT INTO [dbo].[arinptax]
           ([trx_ctrl_num]
           ,[trx_type]
           ,[sequence_id]
           ,[tax_type_code]
           ,[amt_taxable]
           ,[amt_gross]
           ,[amt_tax]
           ,[amt_final_tax])

SELECT		TrxNum	--[trx_ctrl_num]
           ,2032	--[trx_type]
           ,1	--[sequence_id]
           ,'ZERO'	--[tax_type_code]
           ,InvTotal * -1	--[amt_taxable]
           ,InvTotal * -1	--[amt_gross]
           ,0	--[amt_tax]
           ,0	--[amt_final_tax]

		   FROM AC_Integrations..AC_Invoices i
		   INNER JOIN arcust c on LEFT(i.AcctCode, 4) = c.customer_code
		   where ProcessingStatus = 'Pending'
		   and SeqNum = 1 and InvTotal < 0

		   

-----------------------

/*

If the InvTotal is negative, then the insert will have to change. Below are the update statements for those. Based on this you can create your insert statement accordingly. 

So you will have 1 insert for 5 tables for all the positive InvTotals. These are invoices.
Then you will have a separate insert statement for 3 tables (no insert for arinpage and arinptax) for the negative amounts. These are called Credit Memos.
These transactions will have their own batch code too.

Trx_ctrl_num will have the same concept as above, but the num_type will be 2020

*/

select * from arinpchg_all
where trx_ctrl_num in ('CMTRX00599071523', 'CMTRX00000023962')

--update arinpchg_all set trx_ctrl_num = 'CMTRX00000023962', apply_to_num = '', batch_code = <'ARB#######'>, trx_type = 2032, recurring_flag = 1, amt_gross = amt_gross *-1,
amt_net = amt_net * -1


select * from arinpcdt
where trx_ctrl_num in ('CMTRX00599071523', 'IVTRX00000081484')

--update arinpcdt set trx_ctrl_num = 'CMTRX00000023962', trx_type = 2032, qty_ordered = 0, unit_price = unit_price * -1, 
qty_returned = 1, extended_price = extended_price * -1
where trx_ctrl_num in ('IVTRX00000081484')

select * from arinpage
where trx_ctrl_num in ('CMTRX00599071523', 'IVTRX00000081484')

--delete from arinpage
where trx_ctrl_num in ('IVTRX00000081484')

select * from arinptax
where trx_ctrl_num in ('CMTRX00599071523', 'IVTRX00000081484')

--delete from arinptax
where trx_ctrl_num in ('IVTRX00000081484')


/*

After everything is processed successfully and committed, below are the additional updates that will be needed

AC_Invoices.ProcessingStatus = 'Complete' /* If there are errors, then change the value to 'Errors' */

If there are errors, then don't process that specific InvoiceNum, but the other InvoiceNum that don't have errors, can be processed through. 
We should process all lines of a particular invoicenum. So if you have an error in one of the lines, the full InvoiceNum is marked as error

AC_Invoices.ErrorDesc should have the error info. if more than 1 error, then separate by a pipe " | "

AC_Invoices.Comments1 = populate this with the trx_ctrl_num that was used to create the transaction. 
This will not be populated if that invoicenum has an error since we would not have inserted the recods in the final tables.

*/

select * from 
AC_Integrations..AC_Invoices 
where ProcessingStatus = 'Pending'

update AC_Invoices set ProcessingStatus = 'Complete', DateProcessed = getdate(), Comments1 = TrxNum
where ProcessingStatus = 'Pending'


