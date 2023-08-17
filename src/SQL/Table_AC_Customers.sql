USE AC_Integrations
GO

/****** Object:  Table [dbo].[AC_Customers]    Script Date: 6/1/2023 12:32:13 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AC_Customers]') AND type in (N'U'))
DROP TABLE [dbo].[AC_Customers]
GO

	/*
	// Company:		Smithbucklin
	// By:			Antler Consulting
	// Description: Input table for creating customers in Epicor. 
	//				Data source will be NetSuite OpenAir.
	//				Source data will be populated in this table by SmithBucklin
	//				Stored Proc AC_CreateCust_sp will read this table to validate and process the data

	//REVISION HISTORY
	//
	//Rev-No	Date		Name		Description                                                           
	// ------	--------	-------		---------------------------------------------------------
	// 			20230601	AMAHARAJ	Created base table with required fields
	//									ProcessingStatus values: Pending, Errors, Complete
	//
	*/


/****** Object:  Table [dbo].[AC_Customers]    Script Date: 6/1/2023 12:32:13 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AC_Customers](
	[CustomerCode] [varchar](8) NULL,
	[CustomerName] [varchar](40) NULL,
	[ShortName] [varchar](10) NULL,
	[Addr1] [varchar](40) NULL,
	[Addr2] [varchar](40) NULL,
	[Addr3] [varchar](40) NULL,
	[Addr4] [varchar](40) NULL,
	[Addr5] [varchar](40) NULL,
	[Status] [smallint] NULL,
	[AttnName] [varchar](40) NULL,
	[AttnPhone] [varchar](30) NULL,
	[ContactName] [varchar](40) NULL,
	[ContactPhone] [varchar](30) NULL,
	[Fax] [varchar](30) NULL,
	[Phone1] [varchar](30) NULL,
	[Phone2] [varchar](30) NULL,
	[CompanyDB] [varchar](20) NULL,
	[City] [varchar](40) NULL,
	[State] [varchar](40) NULL,
	[Zip] [varchar](15) NULL,
	[Country] [varchar](40) NULL,
	[ProcessingStatus] [varchar](8) NULL,
	[DateAdded] [datetime] NULL,
	[DateProcessed] [datetime] NULL,
	[ErrorDesc] [varchar](128) NULL,
	[Comments1] [varchar](128) NULL,
	[Comments2] [varchar](128) NULL
) ON [PRIMARY]
GO


GRANT ALL ON AC_Customers TO public
GO



