USE [MizanDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ALT].[FinancialItemDefinition](
	[FinancialItemDefinitionId] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](20) NULL,
	[ParentId] [int] NULL,
	[Name] [varchar](120) NULL,
	[NameInEnglish] [varchar](120) NULL,
	[Description] [varchar](1000) NULL,
	[SequenceNumber] [int] NULL,
	[Sign] [int] NULL,
	[IsLeaf] [int] NULL,
	[BalanceSheet] [tinyint] NOT NULL,
	[UserName] [varchar](10) NULL,
	[HostName] [varchar](20) NULL,
	[SystemDate] [datetime] NULL,
	[UpdateUserName] [varchar](10) NULL,
	[UpdateSystemDate] [datetime] NULL,
	[UpdateHostName] [varchar](20) NULL,
	[HostIP] [varchar](15) NULL,
	[Status] [tinyint] NOT NULL,
	[Description2] [varchar](1000) NULL,
	[Description3] [varchar](1000) NULL,
	[FinancialTableType] [int] NULL,
	CONSTRAINT [pk_FinancialItemDefinition] PRIMARY KEY CLUSTERED 
	(
		[FinancialItemDefinitionId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)
GO
CREATE TABLE [ALT].[CustomerFinancialItem](
	[CustomerFinancialItemId] [int] IDENTITY(1,1) NOT NULL,
	[FirmType] [tinyint] NOT NULL,
	[GroupNumber] [int] NOT NULL,
	[AccountNumber] [int] NOT NULL,
	[PeriodId] [int] NOT NULL,
	[FinancialItemDefinitionId] [int] NOT NULL,
	[OriginalValue] [numeric](22, 2) NOT NULL,
	[CorrectedValue] [numeric](22, 2) NOT NULL,
	[WorkflowInstanceId] [int] NULL,
	[UserName] [varchar](10) NULL,
	[HostName] [varchar](20) NULL,
	[SystemDate] [datetime] NULL,
	[UpdateUserName] [varchar](10) NULL,
	[UpdateSystemDate] [datetime] NULL,
	[UpdateHostName] [varchar](20) NULL,
	[HostIP] [varchar](15) NULL,
 CONSTRAINT [pk_CustomerFinancialItem] PRIMARY KEY CLUSTERED 
(
	[CustomerFinancialItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
) 
GO

CREATE TABLE [ALT].[CustomerDetailedTrialBalance](
	[CustomerDetailedTrialBalanceId] [int] IDENTITY(1,1) NOT NULL,
	[AccountNumber] [int] NOT NULL,
	[Period] [int] NOT NULL,
	[AccountCode] [varchar](50) NOT NULL,
	[AccountDescription] [varchar](500) NULL,
	[ParentAccountCode] [varchar](50) NULL,
	[Debit] [numeric](22, 2) NOT NULL,
	[Credit] [numeric](22, 2) NOT NULL,
	[DebitBalance] [numeric](22, 2) NULL,
	[CreditBalance] [numeric](22, 2) NULL,
	[WorkFlowInstanceId] [int] NULL,
	[UserName] [varchar](10) NULL,
	[HostName] [varchar](20) NULL,
	[SystemDate] [datetime] NULL,
	[UpdateUserName] [varchar](10) NULL,
	[UpdateHostName] [varchar](20) NULL,
	[UpdateSystemDate] [datetime] NULL,
	[HostIP] [varchar](15) NULL,
 CONSTRAINT [pkCustomerDetailedTrialBalance] PRIMARY KEY NONCLUSTERED 
(
	[CustomerDetailedTrialBalanceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
) 
GO

CREATE TABLE [ALT].[AutoTransferCleansing](
	[AutoTransferCleansingId] [int] IDENTITY(1,1) NOT NULL,
	[FirmType] [tinyint] NULL,
	[GroupNumber] [int] NULL,
	[AccountNumber] [int] NULL,
	[Period] [int] NOT NULL,
	[FinancialItemDefinitionId] [int] NULL,
	[OriginalValue] [numeric](22, 2) NOT NULL,
	[CorrectedValue] [numeric](22, 2) NOT NULL,
	[HostName] [varchar](20) NULL,
	[SystemDate] [datetime] NULL,
	[UpdateUserName] [varchar](10) NULL,
	[UpdateHostName] [varchar](20) NULL,
	[UpdateSystemDate] [datetime] NULL,
	[HostIP] [varchar](15) NULL,
	[UserName] [varchar](10) NULL,
 CONSTRAINT [pkAutoTransferCleansing] PRIMARY KEY NONCLUSTERED 
(
	[AutoTransferCleansingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
) 
GO

CREATE TABLE [ALT].[AutoTransferCleansingRuleDefinition](
	[AutoTransferCleansingRuleDefinitionId] [int] IDENTITY(1,1) NOT NULL,
	[RuleName] [varchar](4000) NULL,
	[SpName] [varchar](100) NULL,
	[ExecutionOrder] [int] NULL,
	[UserDescription] [varchar](1000) NULL,
	[Status] [int] NULL,
	[UserName] [varchar](10) NULL,
	[HostName] [varchar](20) NULL,
	[SystemDate] [datetime] NULL,
	[UpdateUserName] [varchar](10) NULL,
	[UpdateHostName] [varchar](20) NULL,
	[UpdateSystemDate] [datetime] NULL,
	[HostIP] [varchar](15) NULL,
 CONSTRAINT [pkAutoTransferCleansingRuleDefinition] PRIMARY KEY CLUSTERED 
(
	[AutoTransferCleansingRuleDefinitionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO
CREATE TABLE [ALT].[AutoTransferCleansingHistory](
	[AutoTransferCleansingHistoryId] [int] IDENTITY(1,1) NOT NULL,
	[AccountNumber] [int] NULL,
	[RuleId] [int] NULL,
	[Period] [int] NULL,
	[FinancialItemDefinitionId] [int] NOT NULL,
	[AccountCode] [varchar](50) NULL,
	[Amount] [numeric](22, 2) NULL,
	[TransactionType] [varchar](1) NULL,
	[Description] [varchar](4000) NULL,
	[UserName] [varchar](10) NULL,
	[HostName] [varchar](20) NULL,
	[SystemDate] [datetime] NULL,
	[UpdateUserName] [varchar](10) NULL,
	[UpdateHostName] [varchar](20) NULL,
	[UpdateSystemDate] [datetime] NULL,
	[HostIP] [varchar](15) NULL,
 CONSTRAINT [pkAutoTransferCleansingHistory] PRIMARY KEY CLUSTERED 
(
	[AutoTransferCleansingHistoryId] ASC,
	[FinancialItemDefinitionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

CREATE TABLE ALT.BDDKGroupMembers (
	GroupNumber int NOT NULL,
	FirmType tinyint NOT NULL,
	AccountNumber int NOT NULL,
	MemberName nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsPerson bit NOT NULL
);
GO
CREATE TABLE ALT.GreyListFirms (
	Id int IDENTITY(1,1) NOT NULL,
	FirmName nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CreatedAt datetime2 DEFAULT sysutcdatetime() NOT NULL,
	CreatedBy nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK__GreyList__3214EC0746FE001B PRIMARY KEY (Id)
);
CREATE NONCLUSTERED INDEX IX_GreyListFirms_FirmName ON ALT.GreyListFirms (FirmName);
