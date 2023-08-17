USE AC_Integrations
GO

/****** Object:  Table [dbo].[AC_Invoices]     ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AC_Invoices]') AND type in (N'U'))
DROP TABLE [dbo].[AC_Invoices]
GO

	/*
	// Company:		Smithbucklin
	// By:			Antler Consulting
	// Description: Input table for creating AR Invoices in Epicor. 
	//				Data source will be NetSuite OpenAir.
	//				Source data will be populated in this table by SmithBucklin
	//				Stored Proc AC_CreateInv_sp will read this table to validate and process the data

	//REVISION HISTORY
	//
	//Rev-No	Date		Name		Description                                                           
	// ------	--------	-------		---------------------------------------------------------
	// 			20230611	AMAHARAJ	Created base table with required fields
	//
	*/


/****** Object:  Table [dbo].[AC_Invoices]    Script Date: 6/1/2023 12:32:13 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AC_Invoices](
	[InternalID] int NULL,
	[DateCreated] datetime NULL,
	[ClientExtID] int NULL,
	[Client] varchar(12) NULL,
	[InvIntID] int NULL,
	[InvoiceNum] int NULL,
	[DateInv] datetime NULL,
	[InvLineDesc] varchar(100) NULL,
	[AcctCode] varchar(32) NULL,
	[DateApplied] datetime NULL,
	[LineAmt] decimal (18,2) NULL,
	[Project] varchar(100) NULL,
	[TaskName] varchar(100) NULL,
	[UserName] varchar(50) NULL,
	[UserExtID] varchar(50) NULL,
	[Hours] decimal(18,2) NULL,
	[Rate] decimal(18,2) NULL,
	[Exported] int NULL,
	[ServiceCode] varchar(100) NULL,
	[ProcessingStatus] [varchar](8) NULL,
	[DateAdded] [datetime] NULL,
	[DateProcessed] [datetime] NULL,
	[ErrorDesc] [varchar](128) NULL,
	[Comments1] [varchar](128) NULL,
	[Comments2] [varchar](128) NULL
) ON [PRIMARY]
GO


GRANT ALL ON AC_Invoices TO public
GO



