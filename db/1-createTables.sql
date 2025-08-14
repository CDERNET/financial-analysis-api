-- MizanDB.dbo.AutoTransferCleansing definition

-- Drop table

-- DROP TABLE MizanDB.dbo.AutoTransferCleansing;

CREATE TABLE MizanDB.dbo.AutoTransferCleansing (
	Id int IDENTITY(1,1) NOT NULL,
	FirmType tinyint NOT NULL,
	GroupNumber int NOT NULL,
	AccountNumber int NOT NULL,
	PeriodId int NOT NULL,
	FinancialItemDefinitionId int NOT NULL,
	OriginalValue numeric(22,2) NOT NULL,
	CorrectedValue numeric(22,2) NOT NULL,
	CONSTRAINT PK__FinancialItemAnalyze PRIMARY KEY (Id)
);


-- MizanDB.dbo.AutoTransferCleansingHistory definition

-- Drop table

-- DROP TABLE MizanDB.dbo.AutoTransferCleansingHistory;

CREATE TABLE MizanDB.dbo.AutoTransferCleansingHistory (
	Id int IDENTITY(1,1) NOT NULL,
	RuleId int NOT NULL,
	AccountNumber int NOT NULL,
	PeriodId int NOT NULL,
	FinancialItemDefinitionId int NOT NULL,
	AccountCode nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Amount decimal(18,2) NOT NULL,
	Process nvarchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	AuditTimestamp datetime2 DEFAULT sysdatetime() NOT NULL,
	Description nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__Financia__A17F2398C6D7DF3A PRIMARY KEY (Id)
);


-- MizanDB.dbo.AutoTransferCleansingRuleDefinition definition

-- Drop table

-- DROP TABLE MizanDB.dbo.AutoTransferCleansingRuleDefinition;

CREATE TABLE MizanDB.dbo.AutoTransferCleansingRuleDefinition (
	Id int NOT NULL,
	RuleName nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ProcedureName nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ExecutionOrder int NOT NULL,
	IsActive bit DEFAULT 1 NOT NULL,
	Description nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CreatedAt datetime2 DEFAULT sysdatetime() NOT NULL,
	UpdatedAt datetime2 NULL,
	CONSTRAINT PK__Financia__110458E287A6EA0E PRIMARY KEY (Id)
);


-- MizanDB.dbo.CustomerDetailedTrialBalance definition

-- Drop table

-- DROP TABLE MizanDB.dbo.CustomerDetailedTrialBalance;

CREATE TABLE MizanDB.dbo.CustomerDetailedTrialBalance (
	AccountCode nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	AccountName nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Debit decimal(18,2) NOT NULL,
	Credit decimal(18,2) NOT NULL,
	DebitBalance decimal(18,2) NOT NULL,
	CreditBalance decimal(18,2) NOT NULL,
	ParentAccountCode nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccountNumber int NOT NULL,
	PeriodId int NOT NULL
);