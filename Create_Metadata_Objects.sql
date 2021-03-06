USE [BIML]
GO
/****** Object:  Schema [BIML]    Script Date: 1/25/2018 8:42:16 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'BIML')
EXEC sys.sp_executesql N'CREATE SCHEMA [BIML]'
GO
/****** Object:  UserDefinedFunction [BIML].[RetrieveBusinessKey]    Script Date: 1/25/2018 8:42:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[RetrieveBusinessKey]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [BIML].[RetrieveBusinessKey]
(	
	@TableID int
)
RETURNS 
 @BusinessKeys TABLE 
(
	-- Add the column definitions for the TABLE variable here
	TableID int, 
	ColumnName varchar(100)
)
AS
BEGIN
	DECLARE @BKString VARCHAR(1000);

	-- retrieve concatened business key
	SELECT @BKString = [BusinessKey]
	FROM [BIML].[TableMetadata]
	WHERE [TableMetadataID] = @TableID;

	-- split string and insert into temp table
	INSERT INTO @BusinessKeys(TableID,ColumnName)
	SELECT
		 TableID =  @TableID
		,ColumnName = Item
	FROM  [dbo].[DelimitedSplit8K](@BKString,'','');
	
	RETURN 
END' 
END
GO
/****** Object:  UserDefinedFunction [dbo].[DelimitedSplit8K]    Script Date: 1/25/2018 8:42:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DelimitedSplit8K]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [dbo].[DelimitedSplit8K]
--===== Define I/O parameters
        (@pString VARCHAR(8000), @pDelimiter CHAR(1))
--WARNING!!! DO NOT USE MAX DATA-TYPES HERE!  IT WILL KILL PERFORMANCE!
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN
--===== "Inline" CTE Driven "Tally Table" produces values from 1 up to 10,000...
     -- enough to cover VARCHAR(8000)
  WITH E1(N) AS (
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                ),                          --10E+1 or 10 rows
       E2(N) AS (SELECT 1 FROM E1 a, E1 b), --10E+2 or 100 rows
       E4(N) AS (SELECT 1 FROM E2 a, E2 b), --10E+4 or 10,000 rows max
 cteTally(N) AS (--==== This provides the "base" CTE and limits the number of rows right up front
                     -- for both a performance gain and prevention of accidental "overruns"
                 SELECT TOP (ISNULL(DATALENGTH(@pString),0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4
                ),
cteStart(N1) AS (--==== This returns N+1 (starting position of each "element" just once for each delimiter)
                 SELECT 1 UNION ALL
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@pString,t.N,1) = @pDelimiter
                ),
cteLen(N1,L1) AS(--==== Return start and length (for use in substring)
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@pDelimiter,@pString,s.N1),0)-s.N1,8000)
                   FROM cteStart s
                )
--===== Do the actual split. The ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
 SELECT ItemNumber = ROW_NUMBER() OVER(ORDER BY l.N1),
        Item       = SUBSTRING(@pString, l.N1, l.L1)
   FROM cteLen l
;' 
END
GO
/****** Object:  Table [BIML].[ColumnMetadata]    Script Date: 1/25/2018 8:42:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[ColumnMetadata]') AND type in (N'U'))
BEGIN
CREATE TABLE [BIML].[ColumnMetadata](
	[ColumnMetadataID] [int] IDENTITY(1,1) NOT NULL,
	[TableID] [int] NOT NULL,
	[ColumnName] [varchar](100) NOT NULL,
	[ColumnDataType] [varchar](20) NOT NULL,
	[Nullable] [bit] NOT NULL,
	[SortOrder] [int] NOT NULL,
	[DataType] [varchar](20) NOT NULL,
	[Length] [varchar](20) NULL,
	[Precision] [tinyint] NULL,
	[Scale] [tinyint] NULL,
	[D_DT_I] [datetime] NOT NULL,
 CONSTRAINT [PK_ColumnMetadata] PRIMARY KEY CLUSTERED 
(
	[ColumnMetadataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [BIML].[DBTypeDataTypeMapping]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[DBTypeDataTypeMapping]') AND type in (N'U'))
BEGIN
CREATE TABLE [BIML].[DBTypeDataTypeMapping](
	[DBTypeMappingID] [int] IDENTITY(1,1) NOT NULL,
	[DBTypeDataType] [varchar](20) NOT NULL,
	[SQLServerDataType] [varchar](20) NOT NULL,
	[DefaultLength] [int] NULL,
	[D_DT_I] [datetime] NOT NULL,
 CONSTRAINT [PK_DBTypeDataTypeMapping] PRIMARY KEY CLUSTERED 
(
	[DBTypeMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [BIML].[OracleDataTypeMapping]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[OracleDataTypeMapping]') AND type in (N'U'))
BEGIN
CREATE TABLE [BIML].[OracleDataTypeMapping](
	[OracleMappingID] [int] IDENTITY(1,1) NOT NULL,
	[OracleDataType] [varchar](20) NOT NULL,
	[SQLServerDataType] [varchar](20) NOT NULL,
	[SpecifyLength] [bit] NOT NULL,
	[DefaultLength] [varchar](10) NULL,
	[DefaultPrecision] [tinyint] NULL,
	[DefaultScale] [tinyint] NULL,
	[D_DT_I] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [BIML].[TableMetadata]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[TableMetadata]') AND type in (N'U'))
BEGIN
CREATE TABLE [BIML].[TableMetadata](
	[TableMetadataID] [int] IDENTITY(1,1) NOT NULL,
	[SourceTableName] [varchar](100) NOT NULL,
	[SourceSchema] [varchar](100) NULL,
	[SourceDatabase] [varchar](100) NULL,
	[SourceServer] [varchar](100) NOT NULL,
	[DestinationTableName] [varchar](100) NOT NULL,
	[DestinationSchema] [varchar](100) NULL,
	[DestinationDatabase] [varchar](100) NOT NULL,
	[DestinationServer] [varchar](100) NULL,
	[HSADatabase] [varchar](100) NOT NULL,
	[HSAServer] [varchar](100) NOT NULL,
	[BusinessKey] [varchar](1000) NOT NULL,
	[AllColumns] [bit] NOT NULL,
	[ExcludedColumns] [varchar](1000) NULL,
	[AllRows] [bit] NOT NULL,
	[RowsFilter] [varchar](1000) NULL,
	[IncrementalLoadStaging] [bit] NOT NULL,
	[IncrementalLoadColumnStaging] [varchar](1000) NULL,
	[IncrementalLoadColumnDataType] [varchar](10) NULL,
	[IncludeDeleteHSA] [bit] NOT NULL,
	[Sequence] [int] NOT NULL,
	[Category] [varchar](100) NOT NULL,
	[MetadataRetrieved] [bit] NOT NULL,
	[StagingTableCreated] [bit] NOT NULL,
	[StagingPackageCreated] [bit] NOT NULL,
	[HSATableCreated] [bit] NOT NULL,
	[HSAPackageCreated] [bit] NOT NULL,
	[CalculateDelta] [bit] NOT NULL,
	[D_DT_I] [datetime] NOT NULL,
 CONSTRAINT [PK_TableMetadata] PRIMARY KEY CLUSTERED 
(
	[TableMetadataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MDSDomainBasedAttributes]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MDSDomainBasedAttributes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MDSDomainBasedAttributes](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EntityID] [int] NOT NULL,
	[AttributeName] [varchar](50) NOT NULL,
	[DBAEntity] [varchar](50) NULL,
	[JoinColumn] [varchar](50) NOT NULL,
 CONSTRAINT [PK_MDSDomainBasedAttributes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MDSEntities]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MDSEntities]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MDSEntities](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EntityName] [varchar](50) NOT NULL,
	[Migrate] [bit] NOT NULL,
	[Staging] [bit] NOT NULL,
	[BusinessKey] [varchar](500) NULL,
	[ViewName] [varchar](50) NULL,
 CONSTRAINT [PK_MDSEntities] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET IDENTITY_INSERT [BIML].[ColumnMetadata] ON 
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (1, 1, N'BusinessEntityID', N'int', 0, 1, N'int', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (2, 1, N'NationalIDNumber', N'nvarchar(15)', 0, 2, N'nvarchar', N'15', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (3, 1, N'LoginID', N'nvarchar(256)', 0, 3, N'nvarchar', N'256', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (4, 1, N'OrganizationLevel', N'smallint', 1, 5, N'smallint', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (5, 1, N'JobTitle', N'nvarchar(50)', 0, 6, N'nvarchar', N'50', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (6, 1, N'BirthDate', N'date', 0, 7, N'date', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (7, 1, N'MaritalStatus', N'nchar(1)', 0, 8, N'nchar', N'1', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (8, 1, N'Gender', N'nchar(1)', 0, 9, N'nchar', N'1', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (9, 1, N'HireDate', N'date', 0, 10, N'date', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (10, 1, N'SalariedFlag', N'bit', 0, 11, N'bit', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (11, 1, N'VacationHours', N'smallint', 0, 12, N'smallint', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (12, 1, N'SickLeaveHours', N'smallint', 0, 13, N'smallint', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (13, 1, N'CurrentFlag', N'bit', 0, 14, N'bit', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (14, 1, N'rowguid', N'uniqueidentifier', 0, 15, N'uniqueidentifier', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (15, 1, N'ModifiedDate', N'datetime', 0, 16, N'datetime', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.243' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (16, 2, N'ProductID', N'int', 0, 1, N'int', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (17, 2, N'Name', N'nvarchar(50)', 0, 2, N'nvarchar', N'50', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (18, 2, N'ProductNumber', N'nvarchar(25)', 0, 3, N'nvarchar', N'25', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (19, 2, N'MakeFlag', N'bit', 0, 4, N'bit', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (20, 2, N'FinishedGoodsFlag', N'bit', 0, 5, N'bit', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (21, 2, N'Color', N'nvarchar(15)', 1, 6, N'nvarchar', N'15', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (22, 2, N'SafetyStockLevel', N'smallint', 0, 7, N'smallint', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (23, 2, N'ReorderPoint', N'smallint', 0, 8, N'smallint', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (24, 2, N'StandardCost', N'money', 0, 9, N'money', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (25, 2, N'ListPrice', N'money', 0, 10, N'money', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (26, 2, N'Size', N'nvarchar(5)', 1, 11, N'nvarchar', N'5', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (27, 2, N'SizeUnitMeasureCode', N'nchar(3)', 1, 12, N'nchar', N'3', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (28, 2, N'WeightUnitMeasureCode', N'nchar(3)', 1, 13, N'nchar', N'3', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (29, 2, N'Weight', N'decimal(8,2)', 1, 14, N'decimal', N'', 8, 2, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (30, 2, N'DaysToManufacture', N'int', 0, 15, N'int', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (31, 2, N'ProductLine', N'nchar(2)', 1, 16, N'nchar', N'2', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (32, 2, N'Class', N'nchar(2)', 1, 17, N'nchar', N'2', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (33, 2, N'Style', N'nchar(2)', 1, 18, N'nchar', N'2', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (34, 2, N'ProductSubcategoryID', N'int', 1, 19, N'int', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (35, 2, N'ProductModelID', N'int', 1, 20, N'int', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (36, 2, N'SellStartDate', N'datetime', 0, 21, N'datetime', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (37, 2, N'SellEndDate', N'datetime', 1, 22, N'datetime', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (38, 2, N'DiscontinuedDate', N'datetime', 1, 23, N'datetime', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
INSERT [BIML].[ColumnMetadata] ([ColumnMetadataID], [TableID], [ColumnName], [ColumnDataType], [Nullable], [SortOrder], [DataType], [Length], [Precision], [Scale], [D_DT_I]) VALUES (39, 2, N'ModifiedDate', N'datetime', 0, 25, N'datetime', N'', NULL, NULL, CAST(N'2017-12-22T13:24:16.697' AS DateTime))
GO
SET IDENTITY_INSERT [BIML].[ColumnMetadata] OFF
GO
SET IDENTITY_INSERT [BIML].[DBTypeDataTypeMapping] ON 
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (1, N'Int64', N'BIGINT', NULL, CAST(N'2014-01-28T11:21:38.977' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (2, N'Binary', N'BINARY', NULL, CAST(N'2014-01-28T11:21:38.977' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (3, N'Boolean', N'BIT', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (4, N'AnsiString', N'CHAR', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (5, N'Date', N'DATE', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (6, N'DateTime', N'DATETIME', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (7, N'DateTime2', N'DATETIME2', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (8, N'DateTimeOffset', N'DATETIMEOFFSET', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (9, N'Decimal', N'DECIMAL', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (10, N'Double', N'FLOAT', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (11, N'Binary', N'IMAGE', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (12, N'Int32', N'INT', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (13, N'Decimal', N'MONEY', NULL, CAST(N'2014-01-28T11:21:38.980' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (14, N'String', N'NCHAR', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (15, N'String', N'NTEXT', 8000, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (16, N'Decimal', N'NUMERIC', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (17, N'String', N'NVARCHAR', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (18, N'Single', N'REAL', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (19, N'Binary', N'ROWVERSION', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (20, N'DateTime', N'SMALLDATETIME', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (21, N'Int16', N'SMALLINT', NULL, CAST(N'2014-01-28T11:21:38.983' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (22, N'Decimal', N'SMALLMONEY', NULL, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (23, N'Object', N'SQL_VARIANT', NULL, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (24, N'AnsiString', N'TEXT', 8000, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (25, N'Time', N'TIME', NULL, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (26, N'Binary', N'TIMESTAMP', NULL, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (27, N'Byte', N'TINYINT', NULL, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (28, N'Guid', N'UNIQUEIDENTIFIER', NULL, CAST(N'2014-01-28T11:21:38.987' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (29, N'Binary', N'VARBINARY', NULL, CAST(N'2014-01-28T11:21:38.990' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (30, N'AnsiString', N'VARCHAR', NULL, CAST(N'2014-01-28T11:21:38.990' AS DateTime))
GO
INSERT [BIML].[DBTypeDataTypeMapping] ([DBTypeMappingID], [DBTypeDataType], [SQLServerDataType], [DefaultLength], [D_DT_I]) VALUES (31, N'Xml', N'XML', NULL, CAST(N'2014-01-28T11:21:38.990' AS DateTime))
GO
SET IDENTITY_INSERT [BIML].[DBTypeDataTypeMapping] OFF
GO
SET IDENTITY_INSERT [BIML].[OracleDataTypeMapping] ON 
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (1, N'BFILE', N'VARBINARY', 1, N'MAX', NULL, NULL, CAST(N'2014-01-23T09:55:19.627' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (2, N'BLOB', N'VARBINARY', 1, N'MAX', NULL, NULL, CAST(N'2014-01-23T09:55:19.670' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (3, N'CHAR', N'CHAR', 1, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.670' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (4, N'CLOB', N'VARCHAR', 1, N'MAX', NULL, NULL, CAST(N'2014-01-23T09:55:19.670' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (5, N'DATE', N'DATETIME2', 1, N'3', NULL, NULL, CAST(N'2014-01-23T09:55:19.673' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (6, N'FLOAT', N'FLOAT', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.673' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (7, N'INT', N'NUMERIC', 1, NULL, 18, 0, CAST(N'2014-01-23T09:55:19.673' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (8, N'INTERVAL', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.673' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (9, N'LONG', N'VARCHAR', 1, N'MAX', NULL, NULL, CAST(N'2014-01-23T09:55:19.677' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (10, N'LONG RAW', N'IMAGE', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.677' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (11, N'NCHAR', N'NCHAR', 1, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.677' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (12, N'NCLOB', N'NVARCHAR', 1, N'MAX', NULL, NULL, CAST(N'2014-01-23T09:55:19.677' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (13, N'NUMBER', N'NUMERIC', 1, NULL, 18, 3, CAST(N'2014-01-23T09:55:19.677' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (14, N'NVARCHAR2', N'NVARCHAR', 1, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.680' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (15, N'RAW', N'VARBINARY', 1, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.680' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (16, N'REAL', N'FLOAT', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.680' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (17, N'ROWID', N'CHAR', 1, N'18', NULL, NULL, CAST(N'2014-01-23T09:55:19.680' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (18, N'TIMESTAMP', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.680' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (19, N'TIMESTAMP(0)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.680' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (20, N'TIMESTAMP(8)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.687' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (25, N'UROWID', N'CHAR', 1, N'18', NULL, NULL, CAST(N'2014-01-23T09:55:19.800' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (26, N'VARCHAR2', N'VARCHAR', 1, NULL, NULL, NULL, CAST(N'2014-01-23T09:55:19.800' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (27, N'TIMESTAMP(1)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:33:27.663' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (28, N'TIMESTAMP(2)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:33:57.120' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (29, N'TIMESTAMP(3)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:34:07.713' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (30, N'TIMESTAMP(4)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:34:30.777' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (31, N'TIMESTAMP(5)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:34:38.007' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (32, N'TIMESTAMP(6)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:34:45.167' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (33, N'TIMESTAMP(7)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:34:55.033' AS DateTime))
GO
INSERT [BIML].[OracleDataTypeMapping] ([OracleMappingID], [OracleDataType], [SQLServerDataType], [SpecifyLength], [DefaultLength], [DefaultPrecision], [DefaultScale], [D_DT_I]) VALUES (34, N'TIMESTAMP(9)', N'DATETIME', 0, NULL, NULL, NULL, CAST(N'2014-07-17T15:35:01.907' AS DateTime))
GO
SET IDENTITY_INSERT [BIML].[OracleDataTypeMapping] OFF
GO
SET IDENTITY_INSERT [BIML].[TableMetadata] ON 
GO
INSERT [BIML].[TableMetadata] ([TableMetadataID], [SourceTableName], [SourceSchema], [SourceDatabase], [SourceServer], [DestinationTableName], [DestinationSchema], [DestinationDatabase], [DestinationServer], [HSADatabase], [HSAServer], [BusinessKey], [AllColumns], [ExcludedColumns], [AllRows], [RowsFilter], [IncrementalLoadStaging], [IncrementalLoadColumnStaging], [IncrementalLoadColumnDataType], [IncludeDeleteHSA], [Sequence], [Category], [MetadataRetrieved], [StagingTableCreated], [StagingPackageCreated], [HSATableCreated], [HSAPackageCreated], [CalculateDelta], [D_DT_I]) VALUES (1, N'Employee', N'HumanResources', N'AdventureWorks2017', N'localhost', N'Employee', N'HumanResources', N'StagingDemoBIML', N'localhost', N'HSA', N'localhost', N'LoginID', 0, N'OrganizationNode', 1, NULL, 0, NULL, NULL, 0, 1, N'Staging', 0, 0, 0, 0, 0, 0, CAST(N'2017-12-22T09:45:51.967' AS DateTime))
GO
INSERT [BIML].[TableMetadata] ([TableMetadataID], [SourceTableName], [SourceSchema], [SourceDatabase], [SourceServer], [DestinationTableName], [DestinationSchema], [DestinationDatabase], [DestinationServer], [HSADatabase], [HSAServer], [BusinessKey], [AllColumns], [ExcludedColumns], [AllRows], [RowsFilter], [IncrementalLoadStaging], [IncrementalLoadColumnStaging], [IncrementalLoadColumnDataType], [IncludeDeleteHSA], [Sequence], [Category], [MetadataRetrieved], [StagingTableCreated], [StagingPackageCreated], [HSATableCreated], [HSAPackageCreated], [CalculateDelta], [D_DT_I]) VALUES (2, N'Product', N'Production', N'AdventureWorks2017', N'localhost', N'Product', N'Production', N'StagingDemoBIML', N'localhost', N'HSA', N'localhost', N'ProductNumber', 0, N'rowguid', 1, NULL, 0, NULL, NULL, 0, 2, N'Staging', 0, 0, 0, 0, 0, 0, CAST(N'2017-12-22T09:48:16.857' AS DateTime))
GO
SET IDENTITY_INSERT [BIML].[TableMetadata] OFF
GO
SET IDENTITY_INSERT [dbo].[MDSDomainBasedAttributes] ON 
GO
INSERT [dbo].[MDSDomainBasedAttributes] ([ID], [EntityID], [AttributeName], [DBAEntity], [JoinColumn]) VALUES (2, 2, N'Country', N'Country', N'Country_Code')
GO
SET IDENTITY_INSERT [dbo].[MDSDomainBasedAttributes] OFF
GO
SET IDENTITY_INSERT [dbo].[MDSEntities] ON 
GO
INSERT [dbo].[MDSEntities] ([ID], [EntityName], [Migrate], [Staging], [BusinessKey], [ViewName]) VALUES (1, N'Country', 1, 1, N'Code', NULL)
GO
INSERT [dbo].[MDSEntities] ([ID], [EntityName], [Migrate], [Staging], [BusinessKey], [ViewName]) VALUES (2, N'StateProvince', 1, 0, N'Code', N'ProvinceState')
GO
SET IDENTITY_INSERT [dbo].[MDSEntities] OFF
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[DF_ColumnMetadata_D_DT_I]') AND type = 'D')
BEGIN
ALTER TABLE [BIML].[ColumnMetadata] ADD  CONSTRAINT [DF_ColumnMetadata_D_DT_I]  DEFAULT (getdate()) FOR [D_DT_I]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[DF_DBTypeDataTypeMapping_D_DT_I]') AND type = 'D')
BEGIN
ALTER TABLE [BIML].[DBTypeDataTypeMapping] ADD  CONSTRAINT [DF_DBTypeDataTypeMapping_D_DT_I]  DEFAULT (getdate()) FOR [D_DT_I]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[DF_OracleDataTypeMapping_D_DT_I]') AND type = 'D')
BEGIN
ALTER TABLE [BIML].[OracleDataTypeMapping] ADD  CONSTRAINT [DF_OracleDataTypeMapping_D_DT_I]  DEFAULT (getdate()) FOR [D_DT_I]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[DF_TableMetadata_D_DT_I]') AND type = 'D')
BEGIN
ALTER TABLE [BIML].[TableMetadata] ADD  CONSTRAINT [DF_TableMetadata_D_DT_I]  DEFAULT (getdate()) FOR [D_DT_I]
END
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[BIML].[FK_ColumnMetadata_TableMetadata]') AND parent_object_id = OBJECT_ID(N'[BIML].[ColumnMetadata]'))
ALTER TABLE [BIML].[ColumnMetadata]  WITH CHECK ADD  CONSTRAINT [FK_ColumnMetadata_TableMetadata] FOREIGN KEY([TableID])
REFERENCES [BIML].[TableMetadata] ([TableMetadataID])
ON DELETE CASCADE
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[BIML].[FK_ColumnMetadata_TableMetadata]') AND parent_object_id = OBJECT_ID(N'[BIML].[ColumnMetadata]'))
ALTER TABLE [BIML].[ColumnMetadata] CHECK CONSTRAINT [FK_ColumnMetadata_TableMetadata]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MDSDomainBasedAttributes_MDSEntities]') AND parent_object_id = OBJECT_ID(N'[dbo].[MDSDomainBasedAttributes]'))
ALTER TABLE [dbo].[MDSDomainBasedAttributes]  WITH NOCHECK ADD  CONSTRAINT [FK_MDSDomainBasedAttributes_MDSEntities] FOREIGN KEY([EntityID])
REFERENCES [dbo].[MDSEntities] ([ID])
NOT FOR REPLICATION 
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MDSDomainBasedAttributes_MDSEntities]') AND parent_object_id = OBJECT_ID(N'[dbo].[MDSDomainBasedAttributes]'))
ALTER TABLE [dbo].[MDSDomainBasedAttributes] CHECK CONSTRAINT [FK_MDSDomainBasedAttributes_MDSEntities]
GO
/****** Object:  StoredProcedure [BIML].[GetColumnsMetadata]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[GetColumnsMetadata]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [BIML].[GetColumnsMetadata] AS' 
END
GO
ALTER PROCEDURE [BIML].[GetColumnsMetadata] (@TableID INT,@ExcludeBusinessKey BIT) AS

--DECLARE @ExcludeBusinessKey BIT = 1;
--DECLARE @TableID INT = 9;

IF (@ExcludeBusinessKey = 1)
BEGIN
	SELECT
		 [ColumnName]
		,[SQLServerDataType] = c.[DataType]
		,[DBTypeDataType]
		,[Length]
		,[DefaultLength]
		,[Precision]
		,[Scale]
	FROM [BIML].[ColumnMetadata]		c
	JOIN [BIML].[DBTypeDataTypeMapping]	d ON c.DataType = d.SQLServerDataType
	WHERE		[TableID] = @TableID
			AND [ColumnName] NOT IN (SELECT [ColumnName] FROM [BIML].[RetrieveBusinessKey](@TableID))
--			AND SortOrder IN (2,4)
	ORDER BY [SortOrder];
END
ELSE
BEGIN
	SELECT
		 [ColumnName]
		,[SQLServerDataType] = c.[DataType]
		,[DBTypeDataType]
		,[Length]
		,[DefaultLength]
		,[Precision]
		,[Scale]
	FROM [BIML].[ColumnMetadata]		c
	JOIN [BIML].[DBTypeDataTypeMapping]	d ON c.DataType = d.SQLServerDataType
	WHERE [TableID] = @TableID;
END
GO
/****** Object:  StoredProcedure [BIML].[GetCreateStagingTableStatements]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[GetCreateStagingTableStatements]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [BIML].[GetCreateStagingTableStatements] AS' 
END
GO
ALTER PROC [BIML].[GetCreateStagingTableStatements] AS
SELECT
	DestinationSchema, [DestinationTableName]
	,'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + [DestinationSchema] + '].[' + [DestinationTableName] + ']'') AND type IN (N''U''))' + CHAR(13) + CHAR(10)
	+ 'BEGIN' + CHAR(13) + CHAR(10)
	+
	'CREATE TABLE ' + [DestinationSchema] + '.' + [DestinationTableName] + CHAR(13) + CHAR(10) + '    ('
		+ STUFF(
			(	SELECT '    ,[' + c.[ColumnName] + '] ' + c.ColumnDataType + CASE WHEN c.[Nullable] = 1 THEN ' NULL' ELSE ' NOT NULL' END + CHAR(13) + CHAR(10)
				FROM [BIML].[ColumnMetadata] c
				WHERE f.[TableMetadataID] = c.[TableID]
				FOR XML PATH(''),TYPE).value('.','varchar(max)')
			,1,5,'')
		+ '    ,[D_PackageRunId] INT NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_DT_I] DATETIME NOT NULL' + CHAR(13) + CHAR(10)
		+ '    );' + CHAR(13) + CHAR(10)
	+ 'END'
	  AS CreateTableStatement
FROM [BIML].[TableMetadata] f
WHERE [StagingTableCreated] = 0
GROUP BY f.[TableMetadataID],[DestinationSchema],[DestinationTableName];

GO
/****** Object:  StoredProcedure [BIML].[GetHSAMetadata]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[GetHSAMetadata]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [BIML].[GetHSAMetadata] AS' 
END
GO
ALTER PROC [BIML].[GetHSAMetadata] AS
SELECT
	[TableMetadataID],DestinationSchema, [DestinationTableName]
	,SourceSelectStatement = 
		 'SELECT '
		+ STUFF(
				(	SELECT ',[' + c.[ColumnName] + ']'
					FROM [BIML].[ColumnMetadata] c
					WHERE f.[TableMetadataID] = c.[TableID]
					FOR XML PATH(''),TYPE).value('.','varchar(max)'
				) -- list of selected columns
			,1,1,'') -- remove first comma with STUFF
		+ ', [D_HashValue] = HASHBYTES(''SHA2_256'',CONCAT('
		+ STUFF(
				(	SELECT ',[' + c.[ColumnName] + ']' + ',''|'''
					FROM [BIML].[ColumnMetadata] c
					WHERE f.[TableMetadataID] = c.[TableID]
					FOR XML PATH(''),TYPE).value('.','varchar(max)'
				) -- list of selected columns
			,1,1,'') -- remove first comma with STUFF
		+ '))'
		+ ' FROM ' + DestinationSchema + '.' + [DestinationTableName] + ';'-- FROM clause
	,LookupStatement =
		  'SELECT [D_SK_HSA_' +  [DestinationTableName] + '],[D_HashValue_Old] = [D_HashValue],' + BusinessKey + CHAR(13) + CHAR(10)
		+ 'FROM ' + [DestinationSchema] + '.HSA_' + [DestinationTableName] + CHAR(13) + CHAR(10)
		+ 'WHERE  [D_CurrentFlag] = ''Y'';'
	,CreateUpdateTableStatement =
		  'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + [DestinationSchema] + '].[UPD_HSA_' + [DestinationTableName] + ']'') AND type IN (N''U''))' + CHAR(13) + CHAR(10)
		+ '    DROP TABLE ' + [DestinationSchema] + '.UPD_HSA_' + [DestinationTableName] + ';' + CHAR(13) + CHAR(10)
		+ 'GO'+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		+ 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + [DestinationSchema] + '].[UPD_HSA_' + [DestinationTableName] + ']'') AND type IN (N''U''))' + CHAR(13) + CHAR(10)
		+ 'BEGIN' + CHAR(13) + CHAR(10)
		+ '   CREATE TABLE ' + [DestinationSchema] + '.UPD_HSA_' + [DestinationTableName] + CHAR(13) + CHAR(10) + '    ('
		+ 'D_SK_UPD_HSA_' +   [DestinationTableName] + ' [bigint] NOT NULL' +  CHAR(13) + CHAR(10)
		+ STUFF(
			(	SELECT '    ,[' + c.[ColumnName] + '] ' + c.ColumnDataType + CASE WHEN c.[Nullable] = 1 THEN ' NULL' ELSE ' NOT NULL' END + CHAR(13) + CHAR(10)
				FROM [BIML].[ColumnMetadata] c
				WHERE f.[TableMetadataID] = c.[TableID]
				FOR XML PATH(''),TYPE).value('.','varchar(max)')
			,1,1,'')
		+ '    ,[D_DT_EffectiveTo] date NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_CurrentFlag] char(1) NOT NULL' + CHAR(13) + CHAR(10)
		+ '    );' + CHAR(13) + CHAR(10)
		+ 'END'
	,DropUpdateTableStatement =
		  'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + [DestinationSchema] + '].[UPD_HSA_' + [DestinationTableName] + ']'') AND type IN (N''U''))' + CHAR(13) + CHAR(10)
		+ '    DROP TABLE ' + [DestinationSchema] + '.UPD_HSA_' + [DestinationTableName]+ ';'
	,UpdateStatement =
		  'UPDATE hsa' + CHAR(13) + CHAR(10)
		+ 'SET  [D_CurrentFlag]	= upd.[D_CurrentFlag]' + CHAR(13) + CHAR(10)
		+ '	,[D_DT_EffectiveTo]	= upd.[D_DT_EffectiveTo]' + CHAR(13) + CHAR(10)
		+ 'FROM ' + [DestinationSchema] + '.HSA_' + [DestinationTableName] + '		hsa' + CHAR(13) + CHAR(10)
		+ 'JOIN ' + [DestinationSchema] + '.UPD_HSA_' + [DestinationTableName] + '	upd ON hsa.[D_SK_HSA_' +  [DestinationTableName] + '] = upd.[D_SK_UPD_HSA_' + [DestinationTableName]+ '];'  + CHAR(13) + CHAR(10)
	,SoftDeleteStatement =
		  '-- Declare variables (populated by SSIS):' + CHAR(13) + CHAR(10)
		+ 'DECLARE @PackageStartTime	DATETIME	= ?;' + CHAR(13) + CHAR(10)
		+ 'DECLARE @PackageRunID	INT	= ?;' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		+ '-- Clean-up'  + CHAR(13) + CHAR(10)
		+ 'IF OBJECT_ID(''Tempdb..#HSA_' + [DestinationTableName] + '_DELETED'') IS NOT NULL'  + CHAR(13) + CHAR(10)
		+ 'BEGIN'  + CHAR(13) + CHAR(10)
		+ '	DROP TABLE #HSA_' + [DestinationTableName] + '_DELETED;' + CHAR(13) + CHAR(10)
		+ 'END'  + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		+ '-- Find the SKs for all rows in the HSA table which have been deleted in the source.'  + CHAR(13) + CHAR(10)
		+ 'SELECT hsa.D_SK_HSA_' + [DestinationTableName] + CHAR(13) + CHAR(10)
		+ 'INTO #HSA_' + [DestinationTableName] + '_DELETED'  + CHAR(13) + CHAR(10)
		+ 'FROM ' + [DestinationSchema] + '.HSA_' + [DestinationTableName] + ' hsa'  + CHAR(13) + CHAR(10)
		+ 'WHERE		hsa.D_CurrentFlag = ''Y'' -- only check if the current version has been deleted in the source'  + CHAR(13) + CHAR(10)
		+ '		AND hsa.D_DeletedFlag = ''N'' -- don''t check if row is already deleted'  + CHAR(13) + CHAR(10)
		+ '		AND	NOT EXISTS'  + CHAR(13) + CHAR(10)
		+ '					('  + CHAR(13) + CHAR(10)
		+ '					SELECT 1 FROM ' + DestinationDatabase + '.' + [DestinationSchema] + '.' + [DestinationTableName] + ' stg'  + CHAR(13) + CHAR(10)
		+ '					WHERE		'
		+ STUFF(
				(SELECT '    AND hsa.[' + c.[ColumnName] + ']	= stg.[' + c.[ColumnName] + ']' + CHAR(13) + CHAR(10)
				FROM [BIML].[RetrieveBusinessKey](f.[TableMetadataID]) c
				FOR XML PATH(''),TYPE).value('.','varchar(max)')
			,1,8,'') -- create join clause on business keys
		+ '					);' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		+ '-- Retire those records by setting the EffectiveTo date and the CurrentFlag' + CHAR(13) + CHAR(10)
		+ 'UPDATE hsa' + CHAR(13) + CHAR(10)
		+ 'SET  [D_DT_EffectiveTo] = CONVERT(DATE,DATEADD(DD,-1,@PackageStartTime))' + CHAR(13) + CHAR(10)
		+ '	,[D_CurrentFlag]	= ''N''' + CHAR(13) + CHAR(10)
		+ 'FROM ' + [DestinationSchema]+ '.HSA_' + [DestinationTableName] + ' hsa' + CHAR(13) + CHAR(10)
		+ 'JOIN #HSA_' + [DestinationTableName] + '_DELETED tmp ON hsa.D_SK_HSA_' + [DestinationTableName] + ' = tmp.D_SK_HSA_' + [DestinationTableName] + ';' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		+ 'INSERT INTO ' + [DestinationSchema] + '.HSA_' + [DestinationTableName] + '(' + CHAR(13) + CHAR(10) + '    '
		+ STUFF( -- generate list of columns for INSERT clause
				(	SELECT '    ,[' + c.[ColumnName] + ']' + CHAR(13) + CHAR(10)
					FROM [BIML].[ColumnMetadata] c
					WHERE f.[TableMetadataID] = c.[TableID]
					FOR XML PATH(''),TYPE).value('.','varchar(max)'
				) -- list of selected columns
			,1,5,'') -- remove first comma with STUFF
		+ '	,[D_DT_EffectiveFrom]' + CHAR(13) + CHAR(10)
		+ '	,[D_DT_EffectiveTo]' + CHAR(13) + CHAR(10)
		+ '	,[D_DeletedFlag]' + CHAR(13) + CHAR(10)
		+ '	,[D_CurrentFlag]' + CHAR(13) + CHAR(10)
		+ '	,[D_FirstFlag]' + CHAR(13) + CHAR(10)
		+ '	,[D_HashValue]' + CHAR(13) + CHAR(10)
		+ '	,[D_PackageRunId])' + CHAR(13) + CHAR(10)
		+ 'SELECT' + CHAR(13) + CHAR(10) + '    '
		+ STUFF( -- generate list of columns for SELECT clause
				(	SELECT '    ,[' + c.[ColumnName] + ']' + CHAR(13) + CHAR(10)
					FROM [BIML].[ColumnMetadata] c
					WHERE f.[TableMetadataID] = c.[TableID]
					FOR XML PATH(''),TYPE).value('.','varchar(max)'
				) -- list of selected columns
			,1,5,'') -- remove first comma with STUFF
		+ '	,[D_DT_EffectiveFrom]			= @PackageStartTime' + CHAR(13) + CHAR(10)
		+ '	,[D_DT_EffectiveTo]				= ''2999-12-31''' + CHAR(13) + CHAR(10)
		+ '	,[D_DeletedFlag]				= ''Y''' + CHAR(13) + CHAR(10)
		+ '	,[D_CurrentFlag]				= ''Y''' + CHAR(13) + CHAR(10)
		+ '	,[D_FirstFlag]					= ''N''' + CHAR(13) + CHAR(10)
		+ '	,[D_HashValue]' + CHAR(13) + CHAR(10)
		+ '	,[D_PackageRunId]				= @PackageRunID' + CHAR(13) + CHAR(10)
		+ 'FROM ' + [DestinationSchema] + '.HSA_' + [DestinationTableName] + ' hsa' + CHAR(13) + CHAR(10)
		+ 'JOIN #HSA_' + [DestinationTableName] + '_DELETED tmp ON hsa.D_SK_HSA_' + [DestinationTableName] + ' = tmp.D_SK_HSA_' + [DestinationTableName] + ';'
	,CreateHSATableStatement = 
		  'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + [DestinationSchema] + '].[HSA_' + [DestinationTableName] + ']'') AND type IN (N''U''))' + CHAR(13) + CHAR(10)
		+ 'BEGIN' + CHAR(13) + CHAR(10)
		+ 'CREATE TABLE ' + [DestinationSchema] + '.HSA_' + [DestinationTableName] + CHAR(13) + CHAR(10) + '    ('
		+ 'D_SK_HSA_' +   [DestinationTableName] + '[bigint] IDENTITY(1,1) NOT NULL' +  CHAR(13) + CHAR(10)
		+ STUFF(
			(	SELECT '    ,[' + c.[ColumnName] + '] ' + c.ColumnDataType + CASE WHEN c.[Nullable] = 1 THEN ' NULL' ELSE ' NOT NULL' END + CHAR(13) + CHAR(10)
				FROM [BIML].[ColumnMetadata] c
				WHERE f.[TableMetadataID] = c.[TableID]
				FOR XML PATH(''),TYPE).value('.','varchar(max)')
			,1,1,'')
		+ '    ,[D_DT_EffectiveFrom] date NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_DT_EffectiveTo] date NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_DeletedFlag] char(1) NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_CurrentFlag] char(1) NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_FirstFlag] char(1) NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_HashValue] varbinary(1000) NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,[D_PackageRunId] INT NOT NULL' + CHAR(13) + CHAR(10)
		+ '    ,CONSTRAINT [PK_HSA_' + [DestinationTableName] + '] PRIMARY KEY CLUSTERED (D_SK_HSA_' + [DestinationTableName] + ' ASC)' + CHAR(13) + CHAR(10)
		+ '    ) WITH (DATA_COMPRESSION=PAGE);' + CHAR(13) + CHAR(10)
		+ 'END'
FROM [BIML].[TableMetadata] f
WHERE HSAPackageCreated = 0
GROUP BY f.[TableMetadataID],DestinationDatabase,[DestinationSchema],[DestinationTableName],BusinessKey;
GO
/****** Object:  StoredProcedure [BIML].[GetMDSStagingMetadata]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[GetMDSStagingMetadata]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [BIML].[GetMDSStagingMetadata] AS' 
END
GO
ALTER proc [BIML].[GetMDSStagingMetadata] AS
SELECT
	DestinationSchema, [DestinationTableName]
	,'"SELECT '
		+ STUFF(
				(	SELECT ',[' + c.[ColumnName] + ']' -- escape double quotes.
					FROM [BIML].[ColumnMetadata] c
					WHERE f.[TableMetadataID] = c.[TableID]
					FOR XML PATH(''),TYPE).value('.','varchar(max)'
				) -- list of selected columns
			,1,1,'') -- remove first comma with STUFF
		+ ' FROM ' + ISNULL(SourceSchema + '.','') + '" + @[System::PackageName] ' -- FROM clause
		+ CASE WHEN [AllRows] = 0 -- filter on rows is needed, so add WHERE CLAUSE to filter rows
				THEN '+ " WHERE ' + [RowsFilter] + ' "'
				ELSE ''  -- add empty string if a WHERE clause isn't needed
		  END
		-- add incremental load part. This piece of the WHERE clause is optional and is determined by a setting in the PackageList table
		+ CASE WHEN [AllRows] = 0 -- the first part of the WHERE clause is already added (see above), so we need AND and the incremental load expression
				THEN '+ (@[$Package::prm_SSISIncremental] == 1 ? " AND ' + ISNULL([IncrementalLoadColumnStaging],'') + ' > to_timestamp(''"+ @[$Package::prm_SSISIncrStartDate] +"'',''YYYY-MM-DD-HH24:MI:SS.FF'')" : "")'
				ELSE -- no filter is added yet, so we need WHERE clause and incremental load piece
					'+ (@[$Package::prm_SSISIncremental] == 1 ? " WHERE ' + ISNULL([IncrementalLoadColumnStaging],'') + ' > to_timestamp(''"+ @[$Package::prm_SSISIncrStartDate] +"'',''YYYY-MM-DD-HH24:MI:SS.FF'')" : "")'
		  END
		 AS SourceSelectStatement
	,[IncrementalLoadStaging]
	,MaxLastUpdate = '"SELECT MaxLastUpdate = ISNULL(CONVERT(VARCHAR(26),MAX(' + ISNULL([IncrementalLoadColumnStaging],'') + '),121),?) FROM " + @[System::PackageName] + ";"'
	,[Category]
	,[TableMetadataID]
FROM [BIML].[TableMetadata] f
WHERE StagingPackageCreated = 0
GROUP BY f.[TableMetadataID],SourceSchema,[DestinationSchema],[DestinationTableName],[AllRows],[IncrementalLoadStaging],[RowsFilter],[IncrementalLoadStaging],[IncrementalLoadColumnStaging],[Category];
GO
/****** Object:  StoredProcedure [BIML].[GetStagingMetadata]    Script Date: 1/25/2018 8:42:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[BIML].[GetStagingMetadata]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [BIML].[GetStagingMetadata] AS' 
END
GO
ALTER PROC [BIML].[GetStagingMetadata] AS
SELECT
	DestinationSchema, [DestinationTableName]
	,'"SELECT '
		+ STUFF(
				(	SELECT ',\"' + c.[ColumnName] + '\"' -- escape double quotes.
					FROM [BIML].[ColumnMetadata] c
					WHERE f.[TableMetadataID] = c.[TableID]
					FOR XML PATH(''),TYPE).value('.','varchar(max)'
				) -- list of selected columns
			,1,1,'') -- remove first comma with STUFF
		+ ' FROM ' + ISNULL(SourceDatabase + '.','') + ISNULL(SourceSchema + '.','') + [SourceTableName] + '"' -- FROM clause
		+ CASE WHEN [AllRows] = 0 -- filter on rows is needed, so add WHERE CLAUSE to filter rows
				THEN '+ " WHERE ' + [RowsFilter] + ' "'
				ELSE ''  -- add empty string if a WHERE clause isn't needed
		  END
		-- add incremental load part. This piece of the WHERE clause is optional and is determined by a setting in the PackageList table
		+ CASE WHEN [AllRows] = 0 -- the first part of the WHERE clause is already added (see above), so we need AND and the incremental load expression
				THEN '+ (@[$Package::prm_SSISIncremental] == 1 ? " AND ' 
						+ ISNULL([IncrementalLoadColumnStaging],'')
						+ IIF(
								 [IncrementalLoadColumnDataType] = 'datetime' -- otherwise INT
								,' > to_timestamp(''"+ @[$Package::prm_SSISIncrStartDate] +"'',''YYYY-MM-DD-HH24:MI:SS.FF'')" : "")'
								,' > " + (DT_WSTR,20)@[$Package::prm_SSISIncrStartInt] : "")'
							)
				ELSE -- no filter is added yet, so we need WHERE clause and incremental load piece
					'+ (@[$Package::prm_SSISIncremental] == 1 ? " WHERE ' + ISNULL([IncrementalLoadColumnStaging],'')
						+ IIF(
								 [IncrementalLoadColumnDataType] = 'datetime' -- otherwise INT
								,' > to_timestamp(''"+ @[$Package::prm_SSISIncrStartDate] +"'',''YYYY-MM-DD-HH24:MI:SS.FF'')" : "")'
								,' > " + (DT_WSTR,20)@[$Package::prm_SSISIncrStartInt] : "")'
							)
		  END
		 AS SourceSelectStatement
	,[IncrementalLoadStaging]
	,MaxLastUpdate = '"SELECT MaxLastUpdate = ISNULL(CONVERT(VARCHAR(26),MAX(' + ISNULL([IncrementalLoadColumnStaging],'') + '),121),?) FROM " + @[System::PackageName] + ";"'
	,[Category]
	,[TableMetadataID]
FROM [BIML].[TableMetadata] f
WHERE StagingPackageCreated = 0
GROUP BY f.[TableMetadataID],SourceDatabase,SourceSchema,[SourceTableName],[DestinationSchema],[DestinationTableName],[AllRows],[RowsFilter],[IncrementalLoadStaging],[IncrementalLoadColumnStaging],IncrementalLoadColumnDataType,[Category];
GO
USE [master]
GO
ALTER DATABASE [BIML] SET  READ_WRITE 
GO
