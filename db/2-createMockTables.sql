-- MizanDB.ALT.BDDKGroupMembers definition

-- Drop table

-- DROP TABLE MizanDB.ALT.BDDKGroupMembers;

CREATE TABLE MizanDB.ALT.BDDKGroupMembers (
	GroupNumber int NOT NULL,
	FirmType tinyint NOT NULL,
	AccountNumber int NOT NULL,
	MemberName nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsPerson bit NOT NULL
);


-- MizanDB.ALT.CustomerFinancialItem definition

-- Drop table

-- DROP TABLE MizanDB.ALT.CustomerFinancialItem;

CREATE TABLE MizanDB.ALT.CustomerFinancialItem (
	CustomerFinancialItemId int IDENTITY(1,1) NOT NULL,
	FirmType tinyint NOT NULL,
	GroupNumber int NOT NULL,
	AccountNumber int NOT NULL,
	PeriodId int NOT NULL,
	FinancialItemDefinitionId int NOT NULL,
	OriginalValue numeric(22,2) NOT NULL,
	CorrectedValue numeric(22,2) NOT NULL,
	CONSTRAINT PK_CustomerFinancialItem PRIMARY KEY (CustomerFinancialItemId)
);


-- MizanDB.ALT.FinancialItemDefinition definition

-- Drop table

-- DROP TABLE MizanDB.ALT.FinancialItemDefinition;

CREATE TABLE MizanDB.ALT.FinancialItemDefinition (
	FinancialItemDefinitionId int NOT NULL,
	Code nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ParentId int NULL,
	Name nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Description nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SequenceNumber int NULL,
	Sign nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	IsLeaf bit NOT NULL,
	BalanceSheet bit NOT NULL,
	Status nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);


-- MizanDB.ALT.GreyListFirms definition

-- Drop table

-- DROP TABLE MizanDB.ALT.GreyListFirms;

CREATE TABLE MizanDB.ALT.GreyListFirms (
	Id int IDENTITY(1,1) NOT NULL,
	FirmName nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CreatedAt datetime2 DEFAULT sysutcdatetime() NOT NULL,
	CreatedBy nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__GreyList__3214EC0746FE001B PRIMARY KEY (Id)
);
CREATE NONCLUSTERED INDEX IX_GreyListFirms_FirmName ON MizanDB.ALT.GreyListFirms (FirmName);