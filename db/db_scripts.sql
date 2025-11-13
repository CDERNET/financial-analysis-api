USE [BOA]
GO

/****** Object:  Table [ALT].[AutoTransferCleansing]    Script Date: 13/11/2025 9:12:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
 CONSTRAINT [pkAutoTransferCleansing] PRIMARY KEY CLUSTERED 
(
	[AutoTransferCleansingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [BOA_DATA]
) ON [BOA_DATA]
GO


USE [BOA]
GO

/****** Object:  Table [ALT].[AutoTransferCleansingHistory]    Script Date: 13/11/2025 9:12:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [BOA_DATA]
) ON [BOA_DATA]
GO
USE [BOA]
GO

/****** Object:  Table [ALT].[AutoTransferCleansingRuleDefinition]    Script Date: 13/11/2025 9:13:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [BOA_DATA]
) ON [BOA_DATA]
GO

USE BOA
GO


INSERT INTO ALT.AutoTransferCleansingRuleDefinition(RuleName, SpName, ExecutionOrder, UserDescription, Status, UserName, HostName, SystemDate, UpdateUserName, UpdateHostName, UpdateSystemDate, HostIP) VALUES
('Aktarım Arındırma Data Aktarım CustomerFinancialItem to AutoTransferCleansing', 'ALT.upd_ATC_ApplyRule_00', 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Fiktif kasa bakiyesi', 'ALT.upd_ATC_ApplyRule_01', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('101 hesabının 121 hesabına aktarımı', 'ALT.upd_ATC_ApplyRule_02', 3, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '102 hesabında takip edilen çek-senetler', 'ALT.upd_ATC_ApplyRule_03', 4, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '103 hesabının 321 hesabına aktarımı', 'ALT.upd_ATC_ApplyRule_04', 5, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '120 hesaplarındaki ters bakiyelerin bilançoya ekletilmesi', 'ALT.upd_ATC_ApplyRule_05', 6, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '120 ve 320 hesaplarında aynı firmaların bulunması', 'ALT.upd_ATC_ApplyRule_06', 7, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Birebir şüpheli ticari alacak veya diğer alacak karşılığı ayırma', 'ALT.upd_ATC_ApplyRule_07', 8, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Kısa vadeli donuk ticari alacak ve diğer alacak kontrolü', 'ALT.upd_ATC_ApplyRule_08', 9, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Gri listede yer alan firmaların şüpheli alacak hesabına aktarılması', 'ALT.upd_ATC_ApplyRule_09', 10, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '101 hesabındaki karşılıksız çek ve 121 hesabındaki protestolu senet', 'ALT.upd_ATC_ApplyRule_10', 11, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'BDDK risk grubunda veya firma ortaklık yapılarında yer alan kişilerden ve firmalardan alacaklar', 'ALT.upd_ATC_ApplyRule_11', 12, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '131/231-Ortaklardan Alacakların Özkaynaktan düşülmesi', 'ALT.upd_ATC_ApplyRule_12', 13, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '180-280 hesaplarındaki faiz giderlerinin 30’lu ve 40’lı hesaplar ile mahsuplaştırılması', 'ALT.upd_ATC_ApplyRule_13', 14, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '191 ve 391 hesaplarının karşılıklı mahsuplaştırılması', 'ALT.upd_ATC_ApplyRule_14', 15, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '192 ve 392 hesaplarının karşılıklı mahsuplaştırılması', 'ALT.upd_ATC_ApplyRule_15', 16, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Peşin ödenen vergi ve karşılığının ayrılması', 'ALT.upd_ATC_ApplyRule_16', 17, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Bağlı Menkul Kıymetler, İştirakler ve Bağlı Ortaklıklar hesabındaki şerefiye bakiyesi', 'ALT.upd_ATC_ApplyRule_17', 18, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '262-Kuruluş ve Örgütlenme Giderleri, 263-Araştırma ve Geliştirme Giderleri, 264-Özel Maliyetler, 271-Arama Giderleri, 272-Hazırlık ve Geliştirme Giderleri, 277-Diğer Özel Tükenmeye Tabi Varlıklar, 279-Verilen Avanslar hesaplarındaki bakiyelerinin özkaynaklardan düşülmesi', 'ALT.upd_ATC_ApplyRule_18', 19, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '296-Geçici Hesap’ta matrah arttırımı', 'ALT.upd_ATC_ApplyRule_19', 20, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Satıcılar hesabında takip edilen faktoring borçlarının doğru hesaba aktarılması', 'ALT.upd_ATC_ApplyRule_20', 21, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Memzuç düzenlemesinin yapılması', 'ALT.upd_ATC_ApplyRule_21', 22, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '320 hesaplarındaki ters bakiyelerin bilançoya ekletilmesi', 'ALT.upd_ATC_ApplyRule_22', 23, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '331 hesabının 431 hesabına aktarımı', 'ALT.upd_ATC_ApplyRule_23', 24, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Sadece 2023 yılsonu mali verilerde olmak üzere gelir tablosundaki dönem net karı veya zararı ile bilançodaki dönem net karı veya zararı arasında farklılık', 'ALT.upd_ATC_ApplyRule_24', 25, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Gelir tablosundaki 648 ve 658 bakiyelerindeki tutarların özkaynaklara aktarımı', 'ALT.upd_ATC_ApplyRule_25', 26, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Bilanço-Gelir Tablosu arasında kar-zarar farkının bulunması', 'ALT.upd_ATC_ApplyRule_26', 27, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'İlave aktarma arındırma kuralı', 'ALT.upd_ATC_ApplyRule_27', 28, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Aktarım Arındırma Data Aktarım AutoTransferCleansing to CustomerFinancialItem', 'ALT.upd_ATC_ApplyRule_SendData', 29, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Tenzilat Data Aktarım CustomerFinancialItem to AutoTransferCleansing', 'ALT.upd_ATC_Discount_00', 1, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '240/242/245 hesaplarının 500 hesabı ile tenzilatı', 'ALT.upd_ATC_Discount_01', 2, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( '241/243/246/247 hesaplarının 501 hesabı ile tenzilatı', 'ALT.upd_ATC_Discount_02', 3, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Ticari Alacak (120, 127, 220)+Diğer Alacak (131, 132, 133, 136, 231, 232, 233, 236) hesaplarındaki grup içi bakiyenin karşı firmanın Ticari Borçlar (320, 329, 420, 429)+Diğer Borç (331, 332, 333, 336, 431, 432, 433, 436) bakiyesi ile tenzil edilmesi ', 'ALT.upd_ATC_Discount_03', 4, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
( 'Tenzilat Data Aktarım AutoTransferCleansing to CustomerFinancialItem', 'ALT.upd_ATC_Discount_SendData', 5, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

USE [BOA]
GO

/****** Object:  UserDefinedFunction [ALT].[fGetDetailedTrialBalanceLeafSums_ATC]    Script Date: 13/11/2025 9:24:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [ALT].[fGetDetailedTrialBalanceLeafSums_ATC]  
(  
      @AccountNumber INT  
    , @Period        INT  
    , @RootCode      NVARCHAR(50)  
    , @ExcludeRoot   BIT = 1  -- 1: kök hariç (alt kırılımlar), 0: kök dahil (kök de yapraksa)
    , @DescContains  NVARCHAR(200) = NULL  -- Yalnızca açıklamasında bu ifadeyi içerenler toplama dahil edilsin
)  
RETURNS TABLE  
AS  
RETURN  
WITH Mode AS  
(
    SELECT CASE WHEN EXISTS
    (
        SELECT 1
        FROM ALT.CustomerDetailedTrialBalance r WITH (NOLOCK)
        WHERE r.AccountNumber = @AccountNumber
          AND r.Period        = @Period
          AND r.AccountCode   = @RootCode
    ) THEN 1 ELSE 0 END AS RootExists
),
-- Klasik ağaç (kök mevcutsa)
Tree AS
(
    SELECT
        p.AccountCode,
        p.ParentAccountCode,
        p.AccountDescription,
        CAST(p.DebitBalance  AS DECIMAL(22,2)) AS DebitBalance,
        CAST(p.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
    FROM ALT.CustomerDetailedTrialBalance p WITH (NOLOCK)
    WHERE p.AccountNumber = @AccountNumber
      AND p.Period        = @Period
      AND p.AccountCode   = @RootCode

    UNION ALL
    SELECT
        c.AccountCode,
        c.ParentAccountCode,
        c.AccountDescription,
        CAST(c.DebitBalance  AS DECIMAL(22,2)) AS DebitBalance,
        CAST(c.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
    FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
    JOIN Tree t
      ON  c.AccountNumber     = @AccountNumber
      AND c.Period            = @Period
      AND c.ParentAccountCode = t.AccountCode
),
Leaves_Classical AS
(
    SELECT t.*
    FROM Tree t
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM ALT.CustomerDetailedTrialBalance x WITH (NOLOCK)
        WHERE x.AccountNumber     = @AccountNumber
          AND x.Period            = @Period
          AND x.ParentAccountCode = t.AccountCode
    )
),
-- Prefix modu (kök yoksa)
PrefixSet AS
(
    SELECT
        c.AccountCode,
        c.ParentAccountCode,
        c.AccountDescription,
        CAST(c.DebitBalance  AS DECIMAL(22,2)) AS DebitBalance,
        CAST(c.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
    FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
    WHERE c.AccountNumber = @AccountNumber
      AND c.Period        = @Period
      AND c.AccountCode LIKE @RootCode + '%'
),
Leaves_Prefix AS
(
    SELECT s.*
    FROM PrefixSet s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM ALT.CustomerDetailedTrialBalance x WITH (NOLOCK)
        WHERE x.AccountNumber     = @AccountNumber
          AND x.Period            = @Period
          AND x.ParentAccountCode = s.AccountCode
          AND x.AccountCode LIKE @RootCode + '%'
    )
),
FinalSet AS
(
    SELECT l.*
    FROM Leaves_Classical l
    CROSS JOIN Mode m
    WHERE m.RootExists = 1

    UNION ALL

    SELECT p.*
    FROM Leaves_Prefix p
    CROSS JOIN Mode m
    WHERE m.RootExists = 0
)
SELECT
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE DebitBalance  END) AS DECIMAL(22,2)) AS DebitSum_Leaves,
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE CreditBalance END) AS DECIMAL(22,2)) AS CreditSum_Leaves,
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE (DebitBalance - CreditBalance) END) AS DECIMAL(22,2)) AS NetSum_Leaves
FROM FinalSet
WHERE
    -- Açıklama filtresi: NULL ise devre dışı, doluysa '%değer%' ile LIKE
    (@DescContains IS NULL
     OR AccountDescription LIKE N'%' + @DescContains + N'%'
     -- Gerekirse belirli bir collation: 
     -- COLLATE SQL_Latin1_General_CP1_CI_AS
    );
GO




USE [BOA]
GO

/****** Object:  StoredProcedure [ALT].[ins_ATC_History]    Script Date: 13/11/2025 9:23:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE   PROCEDURE [ALT].[ins_ATC_History]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,
    @AccountCode   NVARCHAR(10),
    @Amount        DECIMAL(22,2),
    @TransactionType CHAR(1),                 -- '+' veya '-'
    @Description   NVARCHAR(4000),
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ALT.AutoTransferCleansingHistory
    (RuleId, AccountNumber, Period, FinancialItemDefinitionId, AccountCode, Amount, TransactionType, Description, UserName, HostName, HostIP, SystemDate)
    VALUES
    (@RuleId, @AccountNumber, @Period, @FinancialItemDefinitionId, @AccountCode, @Amount, @TransactionType, @Description, @UserName, @HostName, @HostIP, GETDATE());


END
GO

/****** Object:  StoredProcedure [ALT].[ins_ATC_HistoryCorrection]    Script Date: 13/11/2025 9:23:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE   PROCEDURE [ALT].[ins_ATC_HistoryCorrection]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,
    @AccountCode   NVARCHAR(10),
    @Amount        DECIMAL(22,2),
    @TransactionType CHAR(1),                 -- '+' veya '-'
    @Description   NVARCHAR(4000),
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

       -- Sabitler (dışarıdan alınmıyor)
        DECLARE @CorrectionType     TINYINT = 0;   -- talebiniz: 0
        DECLARE @IsAutoCorrection   TINYINT = 1;   -- talebiniz: 1
        DECLARE @SequenceNumber     INT     = 0;   -- talebiniz: 0

		DECLARE @Sign TINYINT = CASE WHEN @TransactionType='+' THEN 1 WHEN @TransactionType='-' THEN 2 ELSE 0 END;
        -- 1) MASTER: her çağrıda yeni master oluştur
		DECLARE @MasterId INT;
		SELECT @MasterId = ficm.FinancialItemCorrectionMasterId
		  FROM boa.ALT.FinancialItemCorrectionMaster ficm WITH(NOLOCK)
		 WHERE ficm.AccountNumber = @AccountNumber
		   AND ficm.PeriodId = @Period
		   AND ficm.IsAutoCorrection = 1
		IF @MasterId IS NULL  
		BEGIN  
        	INSERT INTO ALT.FinancialItemCorrectionMaster
			(CorrectionType, AccountNumber, PeriodId, [Description], UserName, HostName, SystemDate, HostIP, IsAutoCorrection)
			VALUES
			(
				@CorrectionType,
				@AccountNumber,
				@Period,
				'Otomatik aktarım arındırma sistemi',  -- tablo VARCHAR(200); uzun metinler kırpılabilir
				@UserName,
				@HostName,
				GETDATE(),
				@HostIP,
				@IsAutoCorrection
			);
			 SET @MasterId = SCOPE_IDENTITY(); 

        END
        INSERT INTO ALT.FinancialItemCorrection
        (FinancialItemCorrectionMasterId, FinancialItemDefinitionId, SequenceNumber, [Sign], Amount)
        VALUES
        (@MasterId, @FinancialItemDefinitionId, @SequenceNumber, @Sign, @Amount);


END
GO

/****** Object:  StoredProcedure [ALT].[ins_ATC_HistoryDiscount]    Script Date: 13/11/2025 9:23:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : tenzilat history spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
 

CREATE   PROCEDURE [ALT].[ins_ATC_HistoryDiscount]
(
    @AccountNumber INT,
    @GroupNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,
    @AccountCode   NVARCHAR(10),
    @Amount        DECIMAL(22,2),
    @TransactionType CHAR(1),                 -- '+' veya '-'
    @Description   NVARCHAR(4000),
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
SET NOCOUNT ON;

       
        DECLARE @SequenceNumber     INT     = 0;
		DECLARE @Sign TINYINT = CASE WHEN @TransactionType='+' THEN 1 WHEN @TransactionType='-' THEN 2 ELSE 0 END;
        -- 1) MASTER: her çağrıda yeni master oluştur
		DECLARE @MasterId INT;
		SELECT @MasterId = ficm.FinancialDiscountMasterId
		  FROM boa.ALT.FinancialDiscountMaster ficm WITH (NOLOCK)
		 WHERE ficm.GroupNumber = @GroupNumber
		   AND ficm.PeriodId = @Period

		IF @MasterId IS NULL
		BEGIN
			INSERT INTO ALT.FinancialDiscountMaster (GroupNumber,
													 PeriodId,
													 [Description],
													 UserName,
													 HostName,
													 SystemDate,
													 HostIP)
			VALUES (@GroupNumber, @Period, 'Otomatik tenzilat sistemi',  -- tablo VARCHAR(200); uzun metinler kırpılabilir
			@UserName, @HostName, GETDATE(), @HostIP);
			SET @MasterId = SCOPE_IDENTITY();
 

		END
		INSERT INTO ALT.FinancialDiscount (FinancialDiscountMasterId,
										   FinancialItemDefinitionId,
										   SequenceNumber,
										   [Sign],
										   Amount,
										   AccountNumber)
		VALUES (@MasterId, @FinancialItemDefinitionId, @SequenceNumber, @Sign, @Amount, @AccountNumber);


END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_AddDeltaWithAncestors]    Script Date: 13/11/2025 9:23:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
 *  ALT.upd_ATC_AddDeltaWithAncestors
 *  Amaç: Verilen FI kalemi ve tüm atalarında CorrectedValue'yu @Delta kadar aynı yönde güncellemek.
 *  Not: Sadece UPDATE; satır yoksa dokunulmaz (insert yok).
 */


CREATE PROCEDURE [ALT].[upd_ATC_AddDeltaWithAncestors]
(
    @RuleId        INT = NULL,
    @AccountNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,   -- taban kalem
    @Amount                     DECIMAL(22,2), -- +/-
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
 
BEGIN
   SET NOCOUNT ON;
   DECLARE @BaseCode NVARCHAR(200),@BaseSign INT, @BaseFID INT ,@BaseParentId INT,@pCode NVARCHAR(2000),@pParentid INT, @pOrd INT = 1 , @pFID INT,@pSign INT,@cCode NVARCHAR(2000),@cParentid INT , @cFID INT,@cSign INT;
  

	SELECT @BaseCode = f.Code,
		   @BaseSign = f.Sign,
		   @BaseFID = f.FinancialItemDefinitionId,
		   @BaseParentId = f.ParentId
	  FROM ALT.FinancialItemDefinition f WITH (NOLOCK)
	 WHERE f.FinancialItemDefinitionId = @FinancialItemDefinitionId
	   AND f.Status = 1;

	IF @BaseCode IS NULL
	BEGIN
		RAISERROR ('Geçersiz FinancialItemDefinitionId.', 16, 1);
		RETURN;
	END
	/* 1) Hedef + Atalar listesi (önce taban, sonra atalar: 100→10→1) */
	IF OBJECT_ID('tempdb..#Targets') IS NOT NULL
		DROP TABLE #Targets;
    CREATE TABLE #Targets (Ord INT NOT NULL, Code NVARCHAR(20) NOT NULL,FID INT NOT NULL,[Sign] INT NOT NULL); 
	INSERT INTO #Targets (Ord,Code,FID,[Sign]) VALUES( 0,@BaseCode,@BaseFID,@BaseSign)

	SET @pParentid  = @BaseParentId;
	 
	WHILE @pParentid IS NOT NULL 
	BEGIN
		/* Ebeveyn kaydı: hem değerleri hem de bir sonraki ParentId’yi tek seferde al */
		
		SELECT @pCode=f.Code,@pFID=f.FinancialItemDefinitionId,@pParentid=f.ParentId,@pSign=f.Sign
		  FROM ALT.FinancialItemDefinition AS f WITH (NOLOCK)
		 WHERE f.FinancialItemDefinitionId = @pParentid
		   AND f.Status = 1;
         INSERT INTO #Targets (Ord,Code,FID,[Sign]) VALUES (@pOrd,@pCode,@pFID,@pSign)
		 IF @@ROWCOUNT = 0
			BREAK;  
		 SET @pOrd += 1;
	END 
	  /* 2) Mevcut satırlar için delta uygula (taban + tüm atalar) */
	 
	DECLARE @CorrectedValue decimal(22,2)=0;
	DECLARE @newValue decimal(22,2)=0;
	
	DECLARE cur CURSOR FAST_FORWARD FOR
		SELECT Code,FID,[Sign] FROM #Targets ORDER BY Ord ASC; -- önce taban, sonra atalar

	OPEN cur;
	FETCH NEXT FROM cur INTO @cCode, @cFID,@cSign;
	WHILE @@FETCH_STATUS = 0
	BEGIN 
	        UPDATE a
			   SET a.CorrectedValue = a.CorrectedValue + CASE WHEN @cSign = @BaseSign THEN @Amount ELSE -1 * @Amount END
			  FROM ALT.AutoTransferCleansing a
			WHERE a.AccountNumber = @AccountNumber
			  AND a.[Period] = @Period
			  AND a.FinancialItemDefinitionId = @cFID; 

			FETCH NEXT FROM cur INTO @cCode, @cFID,@cSign;
	END

		CLOSE cur;
		DEALLOCATE cur;

END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_00]    Script Date: 13/11/2025 9:23:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_00] (
	@RuleId INT,
	@AccountNumber INT,
	@Period INT,
	@UserName VARCHAR(10) = NULL,
	@HostName VARCHAR(20) = NULL,
	@HostIP VARCHAR(15) = NULL)
AS
BEGIN
			SET NOCOUNT ON;
			-- Mevcut kayıtları sil (aynı müşteri + dönem)
			DELETE FROM ALT.AutoTransferCleansing
			 WHERE AccountNumber = @AccountNumber
			   AND Period = @Period;
			-- Insert işlemi

			INSERT INTO ALT.AutoTransferCleansing (FirmType,
												   GroupNumber,
												   AccountNumber,
												   Period,
												   FinancialItemDefinitionId,
												   OriginalValue,
												   CorrectedValue,
												   UserName,
												   HostName,
												   HostIP,
												   SystemDate)
			SELECT 1,
				   0,
				   @AccountNumber,
				   @Period,
				   F.FinancialItemDefinitionId,
				   0 AS OriginalValue,
				   0 AS CorrectedValue,
				   @UserName,
				   @HostName,
				   @HostIP,
				   GETDATE()
			  FROM ALT.FinancialItemDefinition F WITH (NOLOCK)
			 WHERE F.BalanceSheet = 1
			   AND NOT EXISTS (SELECT 1 FROM ALT.CustomerFinancialItem C WITH (NOLOCK) WHERE C.FirmType = 1
					  AND C.GroupNumber = 0
					  AND C.AccountNumber = @AccountNumber
					  AND C.PeriodId = @Period
					  AND C.FinancialItemDefinitionId = F.FinancialItemDefinitionId);

			-- 3. Mevcut olanlar için değerli insert
			INSERT INTO ALT.AutoTransferCleansing (FirmType,
												   GroupNumber,
												   AccountNumber,
												   Period,
												   FinancialItemDefinitionId,
												   OriginalValue,
												   CorrectedValue,
												   UserName,
												   HostName,
												   HostIP,
												   SystemDate)
			SELECT FirmType,
				   GroupNumber,
				   AccountNumber,
				   PeriodId,
				   FinancialItemDefinitionId,
				   OriginalValue,
				   OriginalValue,
				   @UserName,
				   @HostName,
				   @HostIP,
				   GETDATE()
			  FROM ALT.CustomerFinancialItem WITH (NOLOCK)
			 WHERE FirmType = 1
			   AND GroupNumber = 0
			   AND AccountNumber = @AccountNumber
			   AND PeriodId = @Period;




			DECLARE @MasterId INT
			SELECT @MasterId = ficm.FinancialItemCorrectionMasterId
			  FROM boa.ALT.FinancialItemCorrectionMaster ficm WITH (NOLOCK)
			 WHERE ficm.AccountNumber = @AccountNumber
			   AND ficm.PeriodId = @Period
			   AND ficm.IsAutoCorrection = 1
			IF @MasterId IS NOT NULL
			BEGIN
			DELETE FROM ALT.FinancialItemCorrection
			 WHERE FinancialItemCorrectionMasterId = @MasterId
			DELETE FROM ALT.FinancialItemCorrectionMaster
			 WHERE FinancialItemCorrectionMasterId = @MasterId
			END

			IF NOT EXISTS (SELECT TOP 1 1 FROM boa.ALT.PCAutoCorrection pc WITH (NOLOCK) WHERE pc.AccountNumber = @AccountNumber
				   AND pc.PeriodId = @Period)
			BEGIN
			INSERT INTO ALT.PCAutoCorrection (PowerCurveCallId,
											  AccountNumber,
											  PeriodId,
											  UserName,
											  SystemDate)
			VALUES (0, @AccountNumber, @Period, @UserName, GETDATE());

			END


END;
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_01]    Script Date: 13/11/2025 9:23:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 
CREATE     PROCEDURE [ALT].[upd_ATC_ApplyRule_01]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period      INT,
	@UserName VARCHAR(10) = NULL,  
	@HostName VARCHAR(20) = NULL,  
	@HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
   

        DECLARE @FID100 INT, @FID600 INT, @FID563 INT;

		SELECT @FID100 = NULLIF(MAX(CASE
							 WHEN Code = '100' THEN FinancialItemDefinitionId
							 ELSE 0 END), 0),
			   @FID600 = NULLIF(MAX(CASE
							 WHEN Code = '600' THEN FinancialItemDefinitionId
							 ELSE 0 END), 0),
			   @FID563 = NULLIF(MAX(CASE
							 WHEN Code = '563' THEN FinancialItemDefinitionId
							 ELSE 0 END), 0)
		  FROM ALT.FinancialItemDefinition WITH (NOLOCK)
		 WHERE Code IN ('100', '600', '563')

		IF @FID100 IS NULL
		OR @FID600 IS NULL
		OR @FID563 IS NULL
		BEGIN
			RAISERROR ('Gerekli FinancialItemDefinition (100, 600, 563) bulunamadı.', 16, 1);
			RETURN
		END


			DECLARE @V100 DECIMAL(22, 2) = 0,
					@V600 DECIMAL(22, 2) = 0,
					@V563 DECIMAL(22, 2) = 0;

			-- Artık CorrectedValue üzerinden çalışıyoruz
			SELECT @V100 = COALESCE(SUM(CorrectedValue), 0)
			  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
			 WHERE AccountNumber = @AccountNumber
			   AND Period = @Period
			   AND FinancialItemDefinitionId = @FID100;

			SELECT @V600 = COALESCE(SUM(CorrectedValue), 0)
			  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
			 WHERE AccountNumber = @AccountNumber
			   AND Period = @Period
			   AND FinancialItemDefinitionId = @FID600;

			SELECT @V563 = COALESCE(SUM(CorrectedValue), 0)
			  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
			 WHERE AccountNumber = @AccountNumber
			   AND Period = @Period
			   AND FinancialItemDefinitionId = @FID563;

			DECLARE @Cap	  DECIMAL(22, 2),
					@Delta	  DECIMAL(22, 2),
					@DeltaNeg DECIMAL(22, 2);

			SET @Cap = CASE
									WHEN (@V600 * 0.02) < 5000000 THEN CAST(@V600 * 0.02 AS DECIMAL(22, 2))
									ELSE CAST(5000000 AS DECIMAL(22, 2)) END;

			SET @Delta = CASE
									  WHEN @V100 > @Cap THEN CAST(@V100 - @Cap AS DECIMAL(22, 2))
									  ELSE CAST(0 AS DECIMAL(22, 2)) END;
			SET @DeltaNeg = -@Delta;

			DECLARE @Mesaj varchar(4000) =CONCAT(N'Rule1: Fiktif kasa üst sınır (', CONVERT(NVARCHAR(50), @Cap), N') fazlası çıkarıldı.')
			EXEC ALT.ins_ATC_History @RuleId = @RuleId,
									 @AccountNumber = @AccountNumber,
									 @Period = @Period,
									 @FinancialItemDefinitionId = @FID100,
									 @AccountCode = N'100',
									 @Amount = @Delta,
									 @TransactionType = '-',
									 @Description = @Mesaj,
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;

			EXEC ALT.ins_ATC_History @RuleId = @RuleId,
									 @AccountNumber = @AccountNumber,
									 @Period = @Period,
									 @FinancialItemDefinitionId = @FID563,
									 @AccountCode = N'563',
									 @Amount = @Delta,
									 @TransactionType = '+',
									 @Description = N'Rule1: Fiktif kasa fazlası 563 hesabına aktarıldı.',
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;

			/* Delta yoksa güncelleme yapmadan çık */
			IF @Delta > 0
			BEGIN
			/* Delta > 0 ise CorrectedValue güncelle */
			-- 100
					EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID100,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

					/* 563 için +Δ, 563→56→5 aynı yönde artar */
					EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID563,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;


					EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
													   @AccountNumber = @AccountNumber,
													   @Period = @Period,
													   @FinancialItemDefinitionId = @FID100,
													   @AccountCode = N'100',
													   @Amount = @Delta,
													   @TransactionType = '-',
													   @Description = @Mesaj,
													   @UserName = @UserName,
													   @HostName = @HostName,
													   @HostIP = @HostIP;

					EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
													   @AccountNumber = @AccountNumber,
													   @Period = @Period,
													   @FinancialItemDefinitionId = @FID563,
													   @AccountCode = N'563',
													   @Amount = @Delta,
													   @TransactionType = '+',
													   @Description = N'Rule1: Fiktif kasa fazlası 563 hesabına aktarıldı.',
													   @UserName = @UserName,
													   @HostName = @HostName,
													   @HostIP = @HostIP;


			END

END;
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_02]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_02]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    /* 0) FID'leri yakala (101, 121) */
    DECLARE @FID101 INT, @FID121 INT;

    SELECT
        @FID101 = NULLIF(MAX(CASE WHEN Code = N'101' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = NULLIF(MAX(CASE WHEN Code = N'121' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
	WHERE Code IN ('101','121')

    IF @FID101 IS NULL OR @FID121 IS NULL
	BEGIN
	 RAISERROR('Gerekli FinancialItemDefinition (101, 121) bulunamadı.', 16, 1);
    	RETURN
    END
       

    /* 1) Mevcut düzeltilmiş değerleri oku */
    DECLARE
        @V101 DECIMAL(22,2) = 0,
        @V121 DECIMAL(22,2) = 0;

    SELECT @V101 = COALESCE(SUM(CorrectedValue), 0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period=@Period
      AND FinancialItemDefinitionId=@FID101;

    SELECT @V121 = COALESCE(SUM(CorrectedValue), 0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period=@Period
      AND FinancialItemDefinitionId=@FID121;

    /* 2) Delta hesapla */
    DECLARE @Delta DECIMAL(22,2) = @V101;

    /* 3) History kayıtları (Delta olsa da olmasa da) - yeni yardımcı SP ile */
    DECLARE @Desc101 NVARCHAR(4000),
            @Desc121 NVARCHAR(4000);

    IF @Delta > 0
    BEGIN
        SET @Desc101 = N'101 hesabındaki tutar 121 hesabına aktarılmak üzere çıkarıldı.';
        SET @Desc121 = N'101 hesabındaki tutar 121 hesabına eklendi.';
    END
    ELSE
    BEGIN
        SET @Desc101 = N'101 hesabında bakiye yok, transfer yapılmadı.';
        SET @Desc121 = N'101 hesabında bakiye yok, 121 hesabına ekleme yapılmadı.';
    END

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID101, @AccountCode=N'101',
         @Amount=@Delta, @TransactionType='-',
         @Description=@Desc101,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
         @Amount=@Delta, @TransactionType='+',
         @Description=@Desc121,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    /* 4) Delta <= 0 ise erken çık */
    IF @Delta > 0
    BEGIN
        /* 5) Yeni değerler */
        DECLARE
            @DeltaNeg DECIMAL(22,2) = -@Delta
           


		    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID101,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID121,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

	
			  EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID101, @AccountCode=N'101',
				 @Amount=@Delta, @TransactionType='-',
				 @Description=@Desc101,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
				 @Amount=@Delta, @TransactionType='+',
				 @Description=@Desc121,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_03]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_03]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE  @SearchTerms   NVARCHAR(4000) = N'Çek,Senet'  -- virgülle ayrılmış kelimeler
   

    /* 1) FID (102, 121) */
    DECLARE @FID102 INT, @FID121 INT;

    SELECT
        @FID102 = NULLIF(MAX(CASE WHEN Code = N'102' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = NULLIF(MAX(CASE WHEN Code = N'121' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK);

    IF @FID102 IS NULL OR @FID121 IS NULL
	BEGIN
	    RAISERROR('Gerekli FinancialItemDefinition (102, 121) bulunamadı.', 16, 1);
        RETURN
	END
       
    /* 2) Mevcut düzeltilmiş değerler */
    DECLARE @V102 DECIMAL(22,2) = 0,
            @V121 DECIMAL(22,2) = 0;

    SELECT @V102 = COALESCE(SUM(CorrectedValue), 0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period=@Period
      AND FinancialItemDefinitionId=@FID102;

    SELECT @V121 = COALESCE(SUM(CorrectedValue), 0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period=@Period
      AND FinancialItemDefinitionId=@FID121;

    /* 3) @SearchTerms -> @Terms */
    DECLARE @Terms TABLE (Pattern NVARCHAR(200));
    DECLARE @Pos INT = 1, @NextPos INT, @Len INT;
    SET @Len = LEN(@SearchTerms + ',');

    WHILE @Pos < @Len
    BEGIN
        SET @NextPos = CHARINDEX(',', @SearchTerms + ',', @Pos);
        INSERT INTO @Terms(Pattern)
        VALUES (N'%' + LTRIM(RTRIM(SUBSTRING(@SearchTerms, @Pos, @NextPos - @Pos))) + N'%');
        SET @Pos = @NextPos + 1;
    END

    /* 4) DeltaBase hesapla */
    DECLARE @DeltaBase DECIMAL(22,2) = 0;
    SELECT @DeltaBase =
               COALESCE(SUM(
                   CASE
                       WHEN ISNULL(DebitBalance,0)  > 0 THEN DebitBalance
                       WHEN ISNULL(CreditBalance,0) > 0 THEN CreditBalance
                       ELSE 0
                   END
               ), 0)
        FROM ALT.CustomerDetailedTrialBalance d WITH (NOLOCK)
        WHERE d.AccountNumber = @AccountNumber
          AND d.Period      = @Period
          AND d.AccountCode   LIKE N'102%' COLLATE SQL_Latin1_General_CP1_CI_AS
          AND EXISTS (SELECT 1 FROM @Terms t
              WHERE d.AccountDescription LIKE t.Pattern COLLATE SQL_Latin1_General_CP1_CI_AS);

    DECLARE @Delta DECIMAL(22,2) =
        CASE WHEN @DeltaBase > 0 THEN CAST(@DeltaBase AS DECIMAL(22,2)) ELSE 0 END;

    /* 5) History açıklamaları (yardımcı SP ile log) */
    DECLARE @Desc102 NVARCHAR(4000) =
        N'Rule3: 102 alt kalemlerinden [' + ISNULL(@SearchTerms,N'') + N'] filtrelendi, Toplam=' + CONVERT(NVARCHAR(50), @DeltaBase);
    DECLARE @Desc121 NVARCHAR(4000) =
        N'Rule3: 102 alt kalemlerinden [' + ISNULL(@SearchTerms,N'') + N'] aktarılan tutar eklendi, Toplam=' + CONVERT(NVARCHAR(50), @DeltaBase);

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID102, @AccountCode=N'102',
         @Amount=@Delta, @TransactionType='-',
         @Description=@Desc102,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
         @Amount=@Delta, @TransactionType='+',
         @Description=@Desc121,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    /* 6) Delta <= 0 ise çık */
    IF @Delta > 0
    BEGIN
        /* 7) Yeni değerler */
        DECLARE @DeltaNeg DECIMAL(22,2) = - @Delta;


				EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID102,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
				 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID121,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

        

				 EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID102, @AccountCode=N'102',
				 @Amount=@Delta, @TransactionType='-',
				 @Description=@Desc102,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

				 EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
				 @Amount=@Delta, @TransactionType='+',
				 @Description=@Desc121,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_04]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_04]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    /* 0) FID'leri yakala (103, 321) */
    DECLARE @FID103 INT, @FID321 INT;

    SELECT
        @FID103 = NULLIF(MAX(CASE WHEN Code = N'103' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID321 = NULLIF(MAX(CASE WHEN Code = N'321' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK);

    IF @FID103 IS NULL OR @FID321 IS NULL
	BEGIN
	   RAISERROR('Gerekli FinancialItemDefinition (103, 321) bulunamadı.', 16, 1);
	   RETURN
	END
        

    /* 1) Mevcut düzeltilmiş değerler */
    DECLARE @V103 DECIMAL(22,2) = 0,
            @V321 DECIMAL(22,2) = 0;

    SELECT @V103 = COALESCE(SUM(CorrectedValue), 0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period = @Period
      AND FinancialItemDefinitionId=@FID103;

    SELECT @V321 = COALESCE(SUM(CorrectedValue), 0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period = @Period
      AND FinancialItemDefinitionId=@FID321;

    /* 2) Delta: 103’ün tamamı */
    DECLARE @Delta DECIMAL(22,2) = @V103;

    /* 3) History açıklamaları (yardımcı SP ile log) */
    DECLARE @Desc103 NVARCHAR(4000) =
        CASE WHEN @Delta > 0
             THEN N'103 hesabındaki tüm tutar 321 hesabına aktarıldı.'
             ELSE N'103 hesabında bakiye yok, transfer yapılmadı.'
        END;

    DECLARE @Desc321 NVARCHAR(4000) =
        CASE WHEN @Delta > 0
             THEN N'103 hesabından gelen tutar 321 hesabına eklendi.'
             ELSE N'103 hesabında bakiye yok, 321 hesabına ekleme yapılmadı.'
        END;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID103, @AccountCode=N'103',
         @Amount=@Delta, @TransactionType='-',
         @Description=@Desc103,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID321, @AccountCode=N'321',
         @Amount=@Delta, @TransactionType='+',
         @Description=@Desc321,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    /* 4) Delta <= 0 ise erken çık */
    IF @Delta > 0
    BEGIN
        /* 5) Yeni değerler */
        DECLARE @DeltaNeg DECIMAL(22,2) = -@Delta;

				EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID103,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

				EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID321,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

				 EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
													@AccountNumber = @AccountNumber,
													@Period = @Period,
													@FinancialItemDefinitionId = @FID103,
													@AccountCode = N'103',
													@Amount = @Delta,
													@TransactionType = '-',
													@Description = @Desc103,
													@UserName = @UserName,
													@HostName = @HostName,
													@HostIP = @HostIP;

				 EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
													@AccountNumber = @AccountNumber,
													@Period = @Period,
													@FinancialItemDefinitionId = @FID321,
													@AccountCode = N'321',
													@Amount = @Delta,
													@TransactionType = '+',
													@Description = @Desc321,
													@UserName = @UserName,
													@HostName = @HostName,
													@HostIP = @HostIP;
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_05]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_05]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP   VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @RootCode    NVARCHAR(50) = N'120',
        @TargetCode  NVARCHAR(50) = N'340',
        @FIDRoot     INT,
        @FIDTarget   INT,
        @LeafCredit  DECIMAL(22,2),
        @RootCredit  DECIMAL(22,2),
        @Delta       DECIMAL(22,2);

    /* FID'leri bul */
    SELECT
        @FIDRoot   = NULLIF(MAX(CASE WHEN Code = @RootCode   THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FIDTarget = NULLIF(MAX(CASE WHEN Code = @TargetCode THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
	 WHERE code IN (@RootCode,@TargetCode)

    IF @FIDRoot IS NULL OR @FIDTarget IS NULL
	BEGIN
	    RAISERROR('Gerekli FinancialItemDefinition (120, 340) bulunamadı.', 16, 1);
		RETURN
    END
       

    /* 120 alt kırılımlardaki alacak bakiyesi toplamı (kök hariç) */
    SELECT @LeafCredit = CreditSum_Leaves
    FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, @RootCode, 1,null);

    /* 120 ana kalemin alacak bakiyesi (mizan) */
    SELECT @RootCredit = COALESCE(SUM(CreditBalance), 0)
    FROM ALT.CustomerDetailedTrialBalance WITH (NOLOCK)
    WHERE AccountNumber = @AccountNumber
      AND Period        = @Period
      AND AccountCode   = @RootCode COLLATE SQL_Latin1_General_CP1_CI_AS;

    /* Delta = (alt kalem alacak toplamı) - (ana kalem alacak) */
    SET @Delta = ISNULL(@LeafCredit,0) - ISNULL(@RootCredit,0);

    /* History açıklamaları + işlem tipi */
    DECLARE @TxnType CHAR(1) = CASE WHEN @Delta >= 0 THEN '+' ELSE '-' END;

    DECLARE @DescRoot NVARCHAR(4000) =
        N'Rule5: 120 yaprak alacak toplamı (' + CONVERT(NVARCHAR(50), ISNULL(@LeafCredit,0)) +
        N') - ana alacak (' + CONVERT(NVARCHAR(50), ISNULL(@RootCredit,0)) +
        N') = ' + CONVERT(NVARCHAR(50), ISNULL(@Delta,0)) + N'.';

    DECLARE @DescTarget NVARCHAR(4000) =
        N'Rule5: 120 ters bakiyesi kadar 340 hesabı güncellendi.';

    /* History (ins_ATC_History ile) */
    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FIDRoot, @AccountCode=@RootCode,
         @Amount= @Delta, @TransactionType=@TxnType,
         @Description=@DescRoot,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FIDTarget, @AccountCode=@TargetCode,
         @Amount= @Delta, @TransactionType=@TxnType,
         @Description=@DescTarget,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    /* Delta pozitif ise CorrectedValue güncelle */
    IF @Delta > 0
    BEGIN
					EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDRoot,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

					EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDTarget,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;




					EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
													   @AccountNumber = @AccountNumber,
													   @Period = @Period,
													   @FinancialItemDefinitionId = @FIDRoot,
													   @AccountCode = @RootCode,
													   @Amount = @Delta,
													   @TransactionType = @TxnType,
													   @Description = @DescRoot,
													   @UserName = @UserName,
													   @HostName = @HostName,
													   @HostIP = @HostIP;

					EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
													   @AccountNumber = @AccountNumber,
													   @Period = @Period,
													   @FinancialItemDefinitionId = @FIDTarget,
													   @AccountCode = @TargetCode,
													   @Amount = @Delta,
													   @TransactionType = @TxnType,
													   @Description = @DescTarget,
													   @UserName = @UserName,
													   @HostName = @HostName,
													   @HostIP = @HostIP;

    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_06]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_06]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FID120 INT, @FID320 INT;

    -- FID değerlerini filtreli al
    SELECT
        @FID120 = NULLIF(MAX(CASE WHEN Code = N'120' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID320 = NULLIF(MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('120', '320');

    IF @FID120 IS NULL OR @FID320 IS NULL
	BEGIN
    	RAISERROR('Gerekli FinancialItemDefinition (120, 320) bulunamadı.', 16, 1);
		RETURN
    END
        

    -- 120 ve 320 alt kalemlerini çek
    DECLARE @T120 TABLE (
        NormTitle   NVARCHAR(255),
        Amount      DECIMAL(22,2),
        AccountCode NVARCHAR(50)
    );

    DECLARE @T320 TABLE (
        NormTitle   NVARCHAR(255),
        Amount      DECIMAL(22,2),
        AccountCode NVARCHAR(50)
    );

    INSERT INTO @T120
	   SELECT
		 ALT.fGetNormalizeTitle_ATC(AccountDescription), 
		 ISNULL(DebitBalance, 0) AS Amount,
		 AccountCode
	FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
	WHERE t.AccountNumber = @AccountNumber
	  AND t.Period        = @Period
	  AND (t.AccountCode LIKE '120%')
	  AND NOT EXISTS (   -- alt kırılımı olmayan (yaprak) seçimi
			SELECT 1
			FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
			WHERE c.AccountNumber = t.AccountNumber
			  AND c.Period        = t.Period
			  AND c.ParentAccountCode = t.AccountCode
	  )

		

 
    INSERT INTO @T320
	   SELECT
			 ALT.fGetNormalizeTitle_ATC(AccountDescription), 
			 ISNULL(CreditBalance, 0) AS Amount,
			 AccountCode
		FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
		WHERE t.AccountNumber = @AccountNumber
		  AND t.Period        = @Period
		  AND (t.AccountCode LIKE '320%')
		  AND NOT EXISTS (   -- alt kırılımı olmayan (yaprak) seçimi
				SELECT 1
				FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
				WHERE c.AccountNumber = t.AccountNumber
				  AND c.Period        = t.Period
				  AND c.ParentAccountCode = t.AccountCode
		  ) 


	   

    -- Eşleşen unvanlar üzerinden dön
    DECLARE @Title NVARCHAR(255),
            @Amt120 DECIMAL(22,2),
            @Amt320 DECIMAL(22,2),
            @Delta  DECIMAL(22,2),
			@DeltaNeg  DECIMAL(22,2),
            @AccCode120 NVARCHAR(50),
            @AccCode320 NVARCHAR(50),
            @Desc NVARCHAR(4000);

			 IF NOT exists( SELECT TOP 1 1
					FROM @T120 t120
					INNER JOIN @T320 t320 ON t120.NormTitle = t320.NormTitle)
		BEGIN  
     	 EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID120, @AccountCode=@AccCode120,
             @Amount= 0, @TransactionType='-',
             @Description='Rule6: eşleşen kayıt bulunamadı',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        END

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT t120.NormTitle, t120.Amount, t320.Amount, t120.AccountCode, t320.AccountCode
        FROM @T120 t120
        INNER JOIN @T320 t320 ON t120.NormTitle = t320.NormTitle;

    OPEN cur;
    FETCH NEXT FROM cur INTO @Title, @Amt120, @Amt320, @AccCode120, @AccCode320;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Küçük olanı Delta olarak belirle
        SET @Delta = CASE WHEN @Amt120 <= @Amt320 THEN @Amt120 ELSE @Amt320 END;
		SET @DeltaNeg = -@Delta;
        -- Açıklama metni
        SET @Desc = N'Rule6: "' + ISNULL(@Title,N'') + N'" unvanı için 120-320 karşılıklı mahsup. Delta='
                    + CONVERT(NVARCHAR(50), ISNULL(@Delta,0));

        -- History: 120 (-)
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID120, @AccountCode=@AccCode120,
             @Amount= @Delta, @TransactionType='-',
             @Description=@Desc,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        -- History: 320 (-)
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID320, @AccountCode=@AccCode320,
             @Amount=@Delta, @TransactionType='-',
             @Description=@Desc,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        -- Delta > 0 ise düzeltme yap
        IF @Delta > 0
        BEGIN
		    
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												   @AccountNumber = @AccountNumber,
												   @Period = @Period,
												   @FinancialItemDefinitionId = @FID120,
												   @Amount = @DeltaNeg,
												   @UserName = @UserName,
												   @HostName = @HostName,
												   @HostIP = @HostIP;
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												   @AccountNumber = @AccountNumber,
												   @Period = @Period,
												   @FinancialItemDefinitionId = @FID320,
												   @Amount = @DeltaNeg,
												   @UserName = @UserName,
												   @HostName = @HostName,
												   @HostIP = @HostIP;


			EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
											   @AccountNumber = @AccountNumber,
											   @Period = @Period,
											   @FinancialItemDefinitionId = @FID120,
											   @AccountCode = @AccCode120,
											   @Amount = @Delta,
											   @TransactionType = '-',
											   @Description = @Desc,
											   @UserName = @UserName,
											   @HostName = @HostName,
											   @HostIP = @HostIP;

			-- History: 320 (-)
			EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,
											   @AccountNumber = @AccountNumber,
											   @Period = @Period,
											   @FinancialItemDefinitionId = @FID320,
											   @AccountCode = @AccCode320,
											   @Amount = @Delta,
											   @TransactionType = '-',
											   @Description = @Desc,
											   @UserName = @UserName,
											   @HostName = @HostName,
											   @HostIP = @HostIP;
        END

        FETCH NEXT FROM cur INTO @Title, @Amt120, @Amt320, @AccCode120, @AccCode320;
    END

    CLOSE cur;
    DEALLOCATE cur;
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_07]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_07]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) FID'ler */
    DECLARE
        @FID120 INT, @FID121 INT, @FID127 INT,
        @FID128 INT, @FID129 INT,
        @FID136 INT, @FID138 INT, @FID139 INT,
        @FID562 INT;

    SELECT
        @FID120 = NULLIF(MAX(CASE WHEN Code = '120' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = NULLIF(MAX(CASE WHEN Code = '121' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID127 = NULLIF(MAX(CASE WHEN Code = '127' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID128 = NULLIF(MAX(CASE WHEN Code = '128' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID129 = NULLIF(MAX(CASE WHEN Code = '129' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID136 = NULLIF(MAX(CASE WHEN Code = '136' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID138 = NULLIF(MAX(CASE WHEN Code = '138' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID139 = NULLIF(MAX(CASE WHEN Code = '139' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID562 = NULLIF(MAX(CASE WHEN Code = '562' THEN FinancialItemDefinitionId  ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('120','121','127','128','129','136','138','139','562');

    /* 2) Değişkenler */
    DECLARE @TmpDelta DECIMAL(22,2), @Need DECIMAL(22,2);

    /* 3) 128 – 129 kontrolü */
    DECLARE @V128 DECIMAL(22,2) = (
        SELECT COALESCE(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID128
    );

    DECLARE @V129 DECIMAL(22,2) = (
        SELECT COALESCE(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID129
    );

    IF @V128 > @V129
    BEGIN
        SET @TmpDelta = @V128 - @V129;
		 -- 129 arttır
		
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID129,
												@Amount = @TmpDelta,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
       
         

        -- 562 artır
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @TmpDelta,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
         

        -- History (ins_ATC_History ile)
        DECLARE @Desc129 NVARCHAR(4000) = N'Rule7: 128 fazla bakiye 129''ye aktarıldı.';
        DECLARE @Desc562a NVARCHAR(4000) = N'Rule7: 128 fazla bakiye 562''ye aktarıldı.';

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc129,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc562a,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc129,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc562a,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END
    ELSE IF @V129 > @V128
    BEGIN
        SET @Need = @V129 - @V128;
        EXEC ALT.upd_ATC_TransferCascade
             @RuleId, @AccountNumber, @Period, @Need,
             '120,121,127', '128', @UserName,@HostName,@HostIP;
    END

    /* 4) 138 – 139 kontrolü */
    DECLARE @V138 DECIMAL(22,2) = (
        SELECT COALESCE(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID138
    );

    DECLARE @V139 DECIMAL(22,2) = (
        SELECT COALESCE(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID139
    );

    IF @V138 > @V139
    BEGIN
        SET @TmpDelta = @V138 - @V139;
		declare @TmpDeltaNeg DECIMAL(22,2) = -@TmpDelta;
        -- 138 azalt
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID138,
												@Amount = @TmpDeltaNeg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
         
         
        -- 562 artır
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @TmpDelta,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
         
       
        -- History (ins_ATC_History ile)
        DECLARE @Desc139 NVARCHAR(4000) = N'Rule7: 138 fazla bakiye 139''ye aktarıldı.';
        DECLARE @Desc562b NVARCHAR(4000) = N'Rule7: 138 fazla bakiye 562''ye aktarıldı.';

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID139, @AccountCode=N'139',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc139,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc562b,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID139, @AccountCode=N'139',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc139,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@TmpDelta, @TransactionType='+',
             @Description=@Desc562b,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END
    ELSE 
	IF @V139 > @V138
    BEGIN
        SET @Need = @V139 - @V138;
        EXEC ALT.upd_ATC_TransferCascade @RuleId,  @AccountNumber, @Period, @Need,'136,120,121,127', '138', @UserName,@HostName,@HostIP;
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_08]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    
/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 /*
    ALT.upd_ATC_ApplyRule_08
    - Donuk alacak tespiti ve muhasebe aktarımı
*/
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_08]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;



    /* 0) Sabitler */
    DECLARE @Threshold DECIMAL(22,2) = 10000.00;

    DECLARE @Amt120 DECIMAL(22,2),
            @Amt127 DECIMAL(22,2),
            @Amt136 DECIMAL(22,2),
			@Amt159 DECIMAL(22,2),
			@Amt120Neg DECIMAL(22,2),
            @Amt127Neg DECIMAL(22,2),
            @Amt136Neg DECIMAL(22,2),
			@Amt159Neg DECIMAL(22,2);

    /* Finansal kalem FID’leri */
    DECLARE
        @FID120 INT, @FID127 INT, @FID136 INT,
        @FID128 INT, @FID129 INT, @FID138 INT, @FID139 INT, @FID562 INT, @FID159 INT;

    SELECT
        @FID120 = NULLIF(MAX(CASE WHEN Code='120' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID127 = NULLIF(MAX(CASE WHEN Code='127' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID136 = NULLIF(MAX(CASE WHEN Code='136' THEN FinancialItemDefinitionId ELSE 0 END),0),
		@FID159 = NULLIF(MAX(CASE WHEN Code='159' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID128 = NULLIF(MAX(CASE WHEN Code='128' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID129 = NULLIF(MAX(CASE WHEN Code='129' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID138 = NULLIF(MAX(CASE WHEN Code='138' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID139 = NULLIF(MAX(CASE WHEN Code='139' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID562 = NULLIF(MAX(CASE WHEN Code='562' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('120','127','136','159','128','129','138','139','562');

    IF @FID120 IS NULL OR @FID127 IS NULL OR @FID136 IS NULL OR @FID159 IS NULL
       OR @FID128 IS NULL OR @FID129 IS NULL OR @FID138 IS NULL OR @FID139 IS NULL OR @FID562 IS NULL
    BEGIN
        RAISERROR('usp_ApplyRule_08 failed: Gerekli FID (120,127,136,159,128,129,138,139,562) yok.', 16, 1);
        RETURN;
    END

    /* 1) Segment → 4 dönem listesi (#WinPeriods) */
    --IF OBJECT_ID('tempdb..#seg') IS NOT NULL DROP TABLE #seg;
    --CREATE TABLE #seg(
    --    CustomerType             NVARCHAR(50),
    --    CustomerTypeName         NVARCHAR(100),
    --    GroupNumber              INT,
    --    HasExceptionCustomerType BIT
    --);
    --INSERT INTO #seg(CustomerType,CustomerTypeName,GroupNumber,HasExceptionCustomerType)
    --EXEC [ALT].[sel_AllotmentSegment] @AccountNumber;

    --;WITH ctp AS (
    --    SELECT ctp.CustomerType,
    --           ctp.FirstPeriodId,
    --           ctp.SecondPeriodId,
    --           ctp.ThirdPeriodId,
    --           ctp.FourthPeriodId
    --    FROM ALT.CustomerTypePeriod AS ctp WITH (NOLOCK)
    --    JOIN #seg s ON s.CustomerType = ctp.CustomerType
    --),
    --ovr AS (
    --    SELECT PeriodId = MAX(ep.PeriodId)
    --    FROM ALT.ExceptionalPeriod ep WITH (NOLOCK)
    --    CROSS JOIN #seg s
    --    WHERE (ep.GroupNumber = s.GroupNumber OR ep.AccountNumber = @AccountNumber)
    --      AND ep.AllotmentMainId = 0
    --)
    --SELECT v.Period
    --INTO #WinPeriods
    --FROM ctp p
    --LEFT JOIN ovr o ON 1=1
    --CROSS APPLY (VALUES
    --    (p.FirstPeriodId),
    --    (p.SecondPeriodId),
    --    (p.ThirdPeriodId),
    --    (COALESCE(o.PeriodId, p.FourthPeriodId))
    --) AS v(Period)
    --WHERE v.Period IS NOT NULL;

    /* 2) Temel veri (mevcut & önceki dönem & donuklar) */
    
	IF OBJECT_ID('tempdb..#DtlNow')  IS NOT NULL DROP TABLE #DtlNow;
	IF OBJECT_ID('tempdb..#DtlPrev') IS NOT NULL DROP TABLE #DtlPrev;
	IF OBJECT_ID('tempdb..#DtlUnchanged') IS NOT NULL DROP TABLE #DtlUnchanged;

-- 1) Şimdiki dönem: sadece yaprak (alt kırılımı olmayan) hesaplar
	SELECT
		t.AccountCode,
		SUM(COALESCE(t.Debit,0))         AS DebitAmount,
		SUM(COALESCE(t.DebitBalance,0))  AS DebitBalance,
		SUM(COALESCE(t.Credit,0))        AS CreditAmount,
		SUM(COALESCE(t.CreditBalance,0)) AS CreditBalance
	INTO #DtlNow
	FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
	WHERE t.AccountNumber = @AccountNumber
	  AND t.Period        = @Period
	  AND (t.AccountCode LIKE '120%' OR t.AccountCode LIKE '127%' OR t.AccountCode LIKE '136%' OR t.AccountCode LIKE '159%')
	  AND NOT EXISTS (   -- alt kırılımı olmayan (yaprak) seçimi
			SELECT 1
			FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
			WHERE c.AccountNumber = t.AccountNumber
			  AND c.Period        = t.Period
			  AND c.ParentAccountCode = t.AccountCode
	  )
	GROUP BY t.AccountCode;

-- 2) Önceki dönem: #DtlNow’daki her hesap için en yakın önceki dönemi bulup bakiyeleri çek
		SELECT 
			n.AccountCode,
			SUM(COALESCE(p.Debit,0))        AS DebitAmount,
			SUM(COALESCE(p.DebitBalance,0)) AS DebitBalance,
			SUM(COALESCE(p.Credit,0))       AS CreditAmount,
			SUM(COALESCE(p.CreditBalance,0))AS CreditBalance
		INTO #DtlPrev
		FROM #DtlNow n
		OUTER APPLY (
			SELECT TOP (1) t2.Period
			FROM ALT.CustomerDetailedTrialBalance t2 WITH (NOLOCK)
			WHERE t2.AccountNumber = @AccountNumber
			  AND t2.AccountCode   = n.AccountCode
			  AND t2.Period        < @Period
			ORDER BY t2.Period DESC
		) sel
		LEFT JOIN ALT.CustomerDetailedTrialBalance p WITH (NOLOCK)
		  ON p.AccountNumber = @AccountNumber
		 AND p.AccountCode   = n.AccountCode
		 AND p.Period        = sel.Period
		GROUP BY n.AccountCode;

		-- 3) Değişmeyen hesapların (ör. hem DebitBalance hem CreditBalance aynı kalan) kalem bazında toplamı

			SELECT 
				n.AccountCode,
				n.DebitBalance  ,
				n.CreditBalance 
			into #DtlUnchanged
			FROM #DtlNow n
			INNER JOIN #DtlPrev p
				ON p.AccountCode = n.AccountCode
			WHERE 
				-- “değişmeyen” tanımını ihtiyacınıza göre uyarlayın:
				COALESCE(n.DebitBalance,  0) = COALESCE(p.DebitBalance,  0) AND
				COALESCE(n.DebitAmount,  0) = COALESCE(p.DebitAmount,  0)

		 SELECT
			@Amt120 = SUM(CASE WHEN LEFT(AccountCode, 3) = '120' THEN DebitBalance ELSE 0 END),
			@Amt127 = SUM(CASE WHEN LEFT(AccountCode, 3) = '127' THEN DebitBalance ELSE 0 END),
			@Amt136 = SUM(CASE WHEN LEFT(AccountCode, 3) = '136' THEN DebitBalance ELSE 0 END),
			@Amt159 = SUM(CASE WHEN LEFT(AccountCode, 3) = '159' THEN DebitBalance ELSE 0 END)
		FROM #DtlUnchanged;

    SELECT
        @Amt120 = COALESCE(@Amt120,0),
        @Amt127 = COALESCE(@Amt127,0),
        @Amt136 = COALESCE(@Amt136,0),
	    @Amt159 = COALESCE(@Amt159,0);
	SELECT
        @Amt120Neg = -@Amt120,
        @Amt127Neg = -@Amt127,
        @Amt136Neg = -@Amt136,
	    @Amt159Neg = -@Amt159;

    /* 4) Güncelle & History (ALT.ins_ATC_History ile) */

    /* --- 120 bloğu: 120(-), 128(+), 129(+), 562(+) --- */
    IF @Amt120 > 0
    BEGIN
        -- 120'den eksilt
		
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID120,
												@Amount = @Amt120Neg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
        
		 -- 128'e ekle
		 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID128,
												@Amount = @Amt120,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
        
         
		 -- 129 (+)
		 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID129,
												@Amount = @Amt120,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
        
		  -- 562 (+)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @Amt120,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
       

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID120, @AccountCode=N'120',
             @Amount=@Amt120, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 120 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID120, @AccountCode=N'120',
             @Amount=@Amt120, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 120 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktarıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktarıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk 128 karşılığı 129 eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk 128 karşılığı 129 eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP; 

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: 128 için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: 128 için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;


    END

    /* --- 127 bloğu: 127(-), 128(+), 129(+), 562(+) --- */
    IF @Amt127 > 0
    BEGIN
	     EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID127,
												@Amount = @Amt127Neg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

		  EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID128,
												@Amount = @Amt127,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID129,
												@Amount = @Amt127,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
		   
	  EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @Amt127,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
		 

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID127, @AccountCode=N'127',
             @Amount=@Amt127, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 127 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	     EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID127, @AccountCode=N'127',
             @Amount=@Amt127, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 127 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktarıldı (127).',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktarıldı (127).',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP; 
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127 kaynaklı) için 129 karşılığı eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127 kaynaklı) için 129 karşılığı eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP; 
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127) için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127) için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END

    /* --- 136 bloğu: 136(-), 138(+), 139(+), 562(+) --- */
    IF @Amt136 > 0
    BEGIN
	   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID136,
												@Amount = @Amt136Neg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

		 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID138,
												@Amount = @Amt136,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

         EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID139,
												@Amount = @Amt136,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

		 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @Amt136,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
		  

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID136, @AccountCode=N'136',
             @Amount=@Amt136, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 136 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID136, @AccountCode=N'136',
             @Amount=@Amt136, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 136 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID138, @AccountCode=N'138',
             @Amount=@Amt136, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 138 hesaba aktarıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID138, @AccountCode=N'138',
             @Amount=@Amt136, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 138 hesaba aktarıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID139, @AccountCode=N'139',
             @Amount=@Amt136, @TransactionType='+',
             @Description=N'Rule08: 138 için 139 karşılığı eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID139, @AccountCode=N'139',
             @Amount=@Amt136, @TransactionType='+',
             @Description=N'Rule08: 138 için 139 karşılığı eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt136, @TransactionType='+',
             @Description=N'Rule08: 138 için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt136, @TransactionType='+',
             @Description=N'Rule08: 138 için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END

	/* --- 159 bloğu: 159(-), 128(+), 129(+), 562(+) --- */
    IF @Amt159 > 0
    BEGIN
	     EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID159,
												@Amount = @Amt159Neg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID128,
												@Amount = @Amt159,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
        
	  EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID129,
												@Amount = @Amt159,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
        
		 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @Amt159,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
      
		 
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID159, @AccountCode=N'159',
             @Amount=@Amt159, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 159 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID159, @AccountCode=N'159',
             @Amount=@Amt159, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktarımı nedeniyle 159 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktarıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktarıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 için 129 karşılığı eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 için 129 karşılığı eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 için 562 gider karşılığı ayrıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END

END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_09]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 


CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_09]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FID128 INT, @FID129 INT, @FID562 INT;

    -- FID değerlerini al
    SELECT
        @FID128 =NULLIF(MAX(CASE WHEN Code = N'128' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID129 =NULLIF(MAX(CASE WHEN Code = N'129' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID562 =NULLIF(MAX(CASE WHEN Code = N'562' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM  ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('128', '129', '562');

    IF @FID128 IS NULL OR @FID129 IS NULL OR @FID562 IS NULL
	BEGIN
    	RAISERROR('Gerekli FinancialItemDefinition (128, 129, 562) bulunamadı.', 16, 1);
		RETURN
    END
        

    SELECT DISTINCT Name AS Title
      INTO #TmpGreyList
      FROM [INQ].[BankruptcyConcordat] WITH (NOLOCK)
    UNION
    SELECT DISTINCT Title
      FROM INQ.TCMBProtestedBills WITH (NOLOCK)
    UNION
    SELECT DISTINCT Title
      FROM INQ.TCMBBouncedCheckCorp WITH (NOLOCK)
    UNION
    SELECT Title
      FROM INQ.BlackListCorporation BC WITH (NOLOCK)
     WHERE BC.Status = 1 AND BC.BlackListTypeID IN (3,7,9,10,11);

    -- Gri listeden firmaları normalize edip tabloya al
    CREATE TABLE #GreyList  (NormTitle NVARCHAR(255));
    INSERT INTO #GreyList
    SELECT DISTINCT ALT.fGetNormalizeTitle_ATC(Title)
    FROM #TmpGreyList WITH (NOLOCK);

    -- İşlenecek hesap kodları
    CREATE TABLE #Accounts  (AccCode NVARCHAR(50));
    INSERT INTO #Accounts VALUES ('120'), ('127'), ('131'), ('132'), ('133'), ('136');

    -- Mizan verisinden gri liste eşleşmeleri çek
    DECLARE @Matches TABLE (
        NormTitle NVARCHAR(255),
        Amount DECIMAL(22,2),
        AccCode NVARCHAR(50)
    );

    INSERT INTO @Matches
    SELECT
        ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription) AS NormTitle,
        ISNULL(cdtb.DebitBalance, 0) AS Amount,
        cdtb.AccountCode
    FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
    INNER JOIN #Accounts a ON LEFT(cdtb.AccountCode, LEN(a.AccCode)) = a.AccCode
    INNER JOIN #GreyList g ON ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription) = g.NormTitle
    WHERE cdtb.AccountNumber = @AccountNumber
      AND cdtb.Period = @Period;

    -- Döngü ile her eşleşen kaydı işle
    DECLARE @Title NVARCHAR(255),
            @Amt DECIMAL(22,2),
		    @DeltaNeg DECIMAL(22,2) ,
            @AccCode NVARCHAR(50),
            @FIDSource INT,
            @DescSrc NVARCHAR(4000),
            @Desc128 NVARCHAR(4000),
            @Desc129 NVARCHAR(4000),
            @Desc562 NVARCHAR(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT NormTitle, Amount, AccCode
        FROM @Matches;

    OPEN cur;
    FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Kaynağın FID'sini bul (hesap kökü)
        SELECT @FIDSource = FinancialItemDefinitionId
        FROM ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code = LEFT(@AccCode, 3);

        IF @FIDSource IS NOT NULL
        BEGIN
            -- Açıklamalar
            SET @DescSrc  = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. ' + ISNULL(@AccCode,N'') + N' hesabından çıkarıldı.';
            SET @Desc128 = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. 128 hesabına eklendi.';
            SET @Desc129 = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. 129 hesabına eklendi.';
            SET @Desc562 = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. 562 hesabına eklendi.';

            -- History kayıtları (ins_ATC_History ile)
            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FIDSource, @AccountCode=@AccCode,
                 @Amount=@Amt, @TransactionType='-',
                 @Description=@DescSrc,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
                 @Amount=@Amt, @TransactionType='+',
                 @Description=@Desc128,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
                 @Amount=@Amt, @TransactionType='+',
                 @Description=@Desc129,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
                 @Amount=@Amt, @TransactionType='+',
                 @Description=@Desc562,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

            -- CorrectedValue güncellemeleri sadece >0 ise
            IF @Amt > 0
            BEGIN
			   SET @DeltaNeg  = -@Amt
			    
			   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDSource,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
			   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID128,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
               EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID129,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
			  EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID562,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
                

				 EXEC ALT.ins_ATC_HistoryCorrection
					 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
					 @FinancialItemDefinitionId=@FIDSource, @AccountCode=@AccCode,
					 @Amount=@Amt, @TransactionType='-',
					 @Description=@DescSrc,
					 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

				EXEC ALT.ins_ATC_HistoryCorrection
					 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
					 @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
					 @Amount=@Amt, @TransactionType='+',
					 @Description=@Desc128,
					 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

				EXEC ALT.ins_ATC_HistoryCorrection
					 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
					 @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
					 @Amount=@Amt, @TransactionType='+',
					 @Description=@Desc129,
					 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

				EXEC ALT.ins_ATC_HistoryCorrection
					 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
					 @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
					 @Amount=@Amt, @TransactionType='+',
					 @Description=@Desc562,
					 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
            END
        END

        FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode;
    END

    CLOSE cur;
    DEALLOCATE cur;
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_10]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_10]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT, 
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE 
	    @SearchKarsiliksiz NVARCHAR(100) = N'Karşılıksız',
        @SearchProtestolu NVARCHAR(100) = N'Protestolu';
    DECLARE 
        @FID101 INT, @FID121 INT,
        @FID128 INT, @FID129 INT, @FID562 INT;

    SELECT
        @FID101 = NULLIF(MAX(CASE WHEN Code = '101' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = NULLIF(MAX(CASE WHEN Code = '121' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID128 = NULLIF(MAX(CASE WHEN Code = '128' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID129 = NULLIF(MAX(CASE WHEN Code = '129' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID562 = NULLIF(MAX(CASE WHEN Code = '562' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('101','121','128','129','562');

    IF @FID101 IS NULL OR @FID121 IS NULL OR @FID128 IS NULL OR @FID129 IS NULL OR @FID562 IS NULL
	BEGIN
    	 RAISERROR('Gerekli FinancialItemDefinition kayıtları eksik.', 16, 1);
		 RETURN
    END
       

    /* 101 alt kırılım - Karşılıksız */
    DECLARE @Amt101 DECIMAL(22,2);
    SELECT @Amt101 = SUM(NetSum_Leaves)
    FROM (
        SELECT l.NetSum_Leaves
        FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
        CROSS APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, c.AccountCode, 1,null) l
        WHERE c.AccountNumber = @AccountNumber
          AND c.Period        = @Period
          AND c.AccountCode   LIKE '101%'
          AND c.AccountDescription LIKE N'%' + @SearchKarsiliksiz + N'%'
    ) t;

    SET @Amt101 = ISNULL(@Amt101,0);
	DECLARE @Amt101Neg DECIMAL(22,2) = -@Amt101;

    -- History (kaynak 101 - , hedefler +)
    DECLARE @Desc101Src  NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" ifadesi için 101 bakiyesi 128-129-562’ye aktarım.';
    DECLARE @Desc101_128 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" (101) kaynaklı tutar 128 hesabına eklendi.';
    DECLARE @Desc101_129 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" (101) kaynaklı tutar 129 hesabına eklendi.';
    DECLARE @Desc101_562 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" (101) kaynaklı tutar 562 hesabına eklendi.';

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID101, @AccountCode=N'101',
         @Amount=@Amt101, @TransactionType='-',
         @Description=@Desc101Src,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
         @Amount=@Amt101, @TransactionType='+',
         @Description=@Desc101_128,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
         @Amount=@Amt101, @TransactionType='+',
         @Description=@Desc101_129,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
         @Amount=@Amt101, @TransactionType='+',
         @Description=@Desc101_562,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    IF @Amt101 > 0
    BEGIN
	    
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID101,
												@Amount = @Amt101Neg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

      	EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID128,
												@Amount = @Amt101,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID129,
												@Amount = @Amt101,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @Amt101,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;
 
		   EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID101, @AccountCode=N'101',
				 @Amount=@Amt101, @TransactionType='-',
				 @Description=@Desc101Src,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
				 @Amount=@Amt101, @TransactionType='+',
				 @Description=@Desc101_128,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
				 @Amount=@Amt101, @TransactionType='+',
				 @Description=@Desc101_129,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
				 @Amount=@Amt101, @TransactionType='+',
				 @Description=@Desc101_562,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END

    /* 121 alt kırılım - Protestolu */
    DECLARE @Amt121 DECIMAL(22,2);
    SELECT @Amt121 = SUM(NetSum_Leaves)
    FROM (
        SELECT l.NetSum_Leaves
        FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
        CROSS APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, c.AccountCode, 1,null) l
        WHERE c.AccountNumber = @AccountNumber
          AND c.Period        = @Period
          AND c.AccountCode   LIKE '121%'
          AND c.AccountDescription LIKE N'%' + @SearchProtestolu + N'%'
    ) t;

    SET @Amt121 = ISNULL(@Amt121,0);
	DECLARE @Amt121Neg DECIMAL(22,2)= -@Amt121;
    -- History (kaynak 121 - , hedefler +)
    DECLARE @Desc121Src  NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" ifadesi için 121 bakiyesi 128-129-562’ye aktarım.';
    DECLARE @Desc121_128 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" (121) kaynaklı tutar 128 hesabına eklendi.';
    DECLARE @Desc121_129 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" (121) kaynaklı tutar 129 hesabına eklendi.';
    DECLARE @Desc121_562 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" (121) kaynaklı tutar 562 hesabına eklendi.';

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
         @Amount=@Amt121, @TransactionType='-',
         @Description=@Desc121Src,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
         @Amount=@Amt121, @TransactionType='+',
         @Description=@Desc121_128,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
         @Amount=@Amt121, @TransactionType='+',
         @Description=@Desc121_129,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History
         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
         @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
         @Amount=@Amt121, @TransactionType='+',
         @Description=@Desc121_562,
         @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    IF @Amt121 > 0
    BEGIN
	    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID121,
												@Amount = @Amt121Neg,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

      	EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID128,
												@Amount = @Amt121,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID129,
												@Amount = @Amt121,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
												@AccountNumber = @AccountNumber,
												@Period = @Period,
												@FinancialItemDefinitionId = @FID562,
												@Amount = @Amt121,
												@UserName = @UserName,
												@HostName = @HostName,
												@HostIP = @HostIP; 
		    EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
				 @Amount=@Amt121, @TransactionType='-',
				 @Description=@Desc121Src,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
				 @Amount=@Amt121, @TransactionType='+',
				 @Description=@Desc121_128,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
				 @Amount=@Amt121, @TransactionType='+',
				 @Description=@Desc121_129,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
				 @Amount=@Amt121, @TransactionType='+',
				 @Description=@Desc121_562,
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_11]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_11]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- FID'ler
    -------------------------------------------------
    DECLARE @FID131 INT, @FID132 INT, @FID331 INT, @FID332 INT, @FID561 INT;
	DECLARE @Tuzel  TABLE (NormTitle NVARCHAR(255));
    DECLARE @Gercek TABLE (NormTitle NVARCHAR(255));
	DECLARE @TblGroup TABLE (AccountNumber INT, GroupNumber INT, CustomerName VARCHAR(1000));
    DECLARE @TblRiskGroup TABLE (CustomerId INT, GroupNumber INT NULL, CustomerName VARCHAR(1000) NULL);
    DECLARE @TblSharedRelation TABLE (AccountNumber INT, Relation INT);
    DECLARE @CustomerIdList dbo.TpIntTable;
	DECLARE @CustomerId INT;
	DECLARE @Receivable TABLE (Code NVARCHAR(3));
	DECLARE @Payable TABLE (Code NVARCHAR(3));
	DECLARE @Matches TABLE (
        NormTitle   NVARCHAR(255),
        Amount      DECIMAL(22,2),
        AccCode     NVARCHAR(50),
        IsReceivable BIT,
        IsTuzel      BIT
    );
	DECLARE
        @Title NVARCHAR(255),
        @Amt   DECIMAL(22,2),
		@DeltaNeg   DECIMAL(22,2),
        @AccCode NVARCHAR(50),
        @IsReceivable BIT,
        @IsTuzel BIT,
        @FIDSource INT,
        @FIDTarget INT,
        @SourceCode NVARCHAR(10),
        @TargetCode NVARCHAR(10),
        @DescSrc NVARCHAR(4000),
        @DescTgt NVARCHAR(4000);


    SELECT
			@FID131 = NULLIF(MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID132 = NULLIF(MAX(CASE WHEN Code = N'132' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID331 = NULLIF(MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID332 = NULLIF(MAX(CASE WHEN Code = N'332' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID561 = NULLIF(MAX(CASE WHEN Code = N'561' THEN FinancialItemDefinitionId ELSE 0 END),0)
     FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('131','132','331','332','561');

    -------------------------------------------------
    -- Grup / Risk / Ortaklık kümeleri
    -------------------------------------------------
    

    INSERT INTO @TblGroup EXEC ALT.sel_GroupCustomerByAccountNumber @AccountNumber;  -- sabit 16835 yerine parametre
    INSERT INTO @CustomerIdList SELECT AccountNumber FROM @TblGroup;
    INSERT INTO @TblSharedRelation  EXEC ALT.sel_ShareholderCustomerByAccountNumberList @CustomerIdList;

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT AccountNumber FROM @TblGroup;
    OPEN c;
    FETCH NEXT FROM c INTO @CustomerId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Bu satır, SP'nin tek kolon (CustomerId) döndürdüğünü varsayar
        INSERT INTO @TblRiskGroup (CustomerId) EXEC ALT.sel_BDDKRiskGroupCustomersByAccountNumber @CustomerId
        FETCH NEXT FROM c INTO @CustomerId;
    END
    CLOSE c; 
	DEALLOCATE c;

    SELECT s.AccountNumber
      INTO #MergedAccounts
      FROM (
             SELECT CustomerId AS AccountNumber FROM @TblRiskGroup
             UNION
             SELECT AccountNumber FROM @TblSharedRelation
           ) AS s
    EXCEPT
    SELECT AccountNumber FROM @TblGroup;

       SELECT ma.AccountNumber, cus.CustomerName, per.PersonType
         INTO #MergedAccountsWithDetailInfo
         FROM #MergedAccounts ma
   INNER JOIN CUS.Customer cus WITH (NOLOCK) ON cus.Customerid = ma.AccountNumber
   INNER JOIN CUS.CustomerToPerson ctp WITH (NOLOCK) ON ctp.Customerid = cus.Customerid AND ctp.isDefault = 1
   INNER JOIN CUS.Person per WITH (NOLOCK) ON per.Personid = ctp.Personid;

    -------------------------------------------------
    -- BDDK Grup Üyeleri: Tüzel / Gerçek
    -------------------------------------------------
    INSERT INTO @Tuzel
    SELECT DISTINCT ALT.fGetNormalizeTitle_ATC(CustomerName)
    FROM #MergedAccountsWithDetailInfo WITH (NOLOCK)
    WHERE PersonType = 1;

    INSERT INTO @Gercek
    SELECT DISTINCT ALT.fGetNormalizeTitle_ATC(CustomerName)
    FROM #MergedAccountsWithDetailInfo WITH (NOLOCK)
    WHERE PersonType = 0;

    -------------------------------------------------
    -- Hesap grupları
    -------------------------------------------------
    
    INSERT INTO @Receivable VALUES ('120'),('121'),('127'),('136'),('159');
    INSERT INTO @Payable VALUES ('320'),('321'),('329'),('336'),('340');

    -------------------------------------------------
    -- Eşleşen kayıtlar
    -------------------------------------------------
    -- Alacaklar (Tüzel)
    INSERT INTO @Matches
    SELECT ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription),
           ISNULL(cdtb.DebitBalance,0),
           cdtb.AccountCode,
           1,
           0  -- IsTuzel=0 (tüzel) -> mevcut mantığa uyum
    FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
    JOIN @Receivable r ON LEFT(cdtb.AccountCode,3) = r.Code
    JOIN @Tuzel t ON ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription) = t.NormTitle
    WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.Period=@Period
      AND ISNULL(cdtb.CreditBalance,0) > 0;

    -- Alacaklar (Gerçek)
    INSERT INTO @Matches
    SELECT ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription),
           ISNULL(cdtb.DebitBalance,0),
           cdtb.AccountCode,
           1,
           1  -- IsTuzel=1 (gerçek) -> mevcut mantığa uyum (isim seçimi tarihsel)
    FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
    JOIN @Receivable r ON LEFT(cdtb.AccountCode,3) = r.Code
    JOIN @Gercek g ON ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription) = g.NormTitle
    WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.Period=@Period
      AND ISNULL(cdtb.CreditBalance,0) > 0;

    -- Borçlar (Tüzel)
    INSERT INTO @Matches
    SELECT ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription),
           ISNULL(cdtb.CreditBalance,0),
           cdtb.AccountCode,
           0,
           0
    FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
    JOIN @Payable p ON LEFT(cdtb.AccountCode,3) = p.Code
    JOIN @Tuzel t ON ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription) = t.NormTitle
    WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.Period=@Period
      AND ISNULL(cdtb.DebitBalance,0) > 0;

    -- Borçlar (Gerçek)
    INSERT INTO @Matches
    SELECT ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription),
           ISNULL(cdtb.CreditBalance,0),
           cdtb.AccountCode,
           0,
           1
    FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
    JOIN @Payable p ON LEFT(cdtb.AccountCode,3) = p.Code
    JOIN @Gercek g ON ALT.fGetNormalizeTitle_ATC(cdtb.AccountDescription) = g.NormTitle
    WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.Period=@Period
      AND ISNULL(cdtb.DebitBalance,0) > 0;

    -------------------------------------------------
    -- İşleme döngüsü
    -------------------------------------------------
    
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT NormTitle, Amount, AccCode, IsReceivable, IsTuzel FROM @Matches;

    OPEN cur;
    FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @IsReceivable, @IsTuzel;

    WHILE @@FETCH_STATUS = 0
    BEGIN
	    SET @DeltaNeg = -@Amt;
        SET @SourceCode = LEFT(@AccCode,3);

        -- Kaynak FID
        SELECT @FIDSource = FinancialItemDefinitionId
        FROM ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code = @SourceCode;

        -- Hedef FID & hesap kodu (mevcut mantığa göre)
        IF @IsReceivable = 1
        BEGIN
            IF @IsTuzel = 0  -- tüzel
            BEGIN
                SET @FIDTarget = @FID132; SET @TargetCode = N'132';
            END
            ELSE             -- gerçek
            BEGIN
                SET @FIDTarget = @FID131; SET @TargetCode = N'131';
            END
        END
        ELSE
        BEGIN
            IF @IsTuzel = 0  -- tüzel
            BEGIN
                SET @FIDTarget = @FID332; SET @TargetCode = N'332';
            END
            ELSE             -- gerçek
            BEGIN
                SET @FIDTarget = @FID331; SET @TargetCode = N'331';
            END
        END

        IF @FIDSource IS NOT NULL AND @FIDTarget IS NOT NULL AND ISNULL(@Amt,0) <> 0
        BEGIN
            -- History
            SET @DescSrc = N'Rule11: ' + ISNULL(@Title,N'') + N' BDDK/Ortaklık listesinde. ' + ISNULL(@AccCode,N'') + N' hesabından çıkarıldı.';
            SET @DescTgt = N'Rule11: ' + ISNULL(@Title,N'') + N' BDDK/Ortaklık listesinde. ' + @TargetCode + N' hesabına eklendi.';

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FIDSource, @AccountCode=@AccCode,
                 @Amount=@Amt, @TransactionType='-',
                 @Description=@DescSrc,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FIDTarget, @AccountCode=@TargetCode,
                 @Amount=@Amt, @TransactionType='+',
                 @Description=@DescTgt,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;


			EXEC ALT.ins_ATC_HistoryCorrection
					 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
					 @FinancialItemDefinitionId=@FIDSource, @AccountCode=@AccCode,
					 @Amount=@Amt, @TransactionType='-',
					 @Description=@DescSrc,
					 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
					 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
					 @FinancialItemDefinitionId=@FIDTarget, @AccountCode=@TargetCode,
					 @Amount=@Amt, @TransactionType='+',
					 @Description=@DescTgt,
					 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
            
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDSource,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

          	EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDTarget,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

           
        END

        FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @IsReceivable, @IsTuzel;
    END

    CLOSE cur; DEALLOCATE cur;

    -------------------------------------------------
    -- 131 ↔ 331 mahsuplaştır; kalan 561’e
    -------------------------------------------------
    DECLARE @Amt131 DECIMAL(22,2) =
        ISNULL((SELECT SUM(CorrectedValue) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
                WHERE  AccountNumber=@AccountNumber AND Period=@Period
                  AND FinancialItemDefinitionId=@FID131),0);

    DECLARE @Amt331 DECIMAL(22,2) =
        ISNULL((SELECT SUM(CorrectedValue) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
                WHERE AccountNumber=@AccountNumber AND Period=@Period
                  AND FinancialItemDefinitionId=@FID331),0);

    DECLARE @Delta DECIMAL(22,2) = CASE WHEN @Amt131 <= @Amt331 THEN @Amt131 ELSE @Amt331 END;
    DECLARE @Diff DECIMAL(22,2)  = ABS(@Amt131 - @Amt331);
	SET @DeltaNeg  = -@Delta;
    IF @Delta > 0
    BEGIN
        -- History: 131 (-), 331 (-)
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Delta, @TransactionType='-',
             @Description=N'Rule11: 131-331 mahsuplaşma nedeniyle 131 azaltıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
             @Amount=@Delta, @TransactionType='-',
             @Description=N'Rule11: 131-331 mahsuplaşma nedeniyle 331 azaltıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Delta, @TransactionType='-',
             @Description=N'Rule11: 131-331 mahsuplaşma nedeniyle 131 azaltıldı.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
				 @Amount=@Delta, @TransactionType='-',
				 @Description=N'Rule11: 131-331 mahsuplaşma nedeniyle 331 azaltıldı.',
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        -- Güncelle: 131 & 331 ↓
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID131,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID331,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

       
        -- Kalan 561'e (+) (yalnızca fark > 0 ise)
        IF @Diff > 0
        BEGIN
            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Diff, @TransactionType='+',
                 @Description=N'Rule11: 131-331 mahsuplaşma sonrası kalan tutar 561 hesabına aktarıldı.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
			EXEC ALT.ins_ATC_HistoryCorrection
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Diff, @TransactionType='+',
                 @Description=N'Rule11: 131-331 mahsuplaşma sonrası kalan tutar 561 hesabına aktarıldı.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

            EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID561,
														   @Amount = @Diff,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
          
        END
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_12]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */ 


CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_12]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FID131 INT, @FID231 INT, @FID331 INT, @FID431 INT, @FID561 INT;

    SELECT
        @FID131 = NULLIF(MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId END),0),
        @FID231 = NULLIF(MAX(CASE WHEN Code = N'231' THEN FinancialItemDefinitionId END),0),
        @FID331 = NULLIF(MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId END),0),
        @FID431 = NULLIF(MAX(CASE WHEN Code = N'431' THEN FinancialItemDefinitionId END),0),
        @FID561 = NULLIF(MAX(CASE WHEN Code = N'561' THEN FinancialItemDefinitionId END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('131','231','331','431','561');

    /* Bakiye değerleri */
    DECLARE @Amt131 DECIMAL(22,2) = ISNULL((
        SELECT SUM(CorrectedValue) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID131),0);

    DECLARE @Amt231 DECIMAL(22,2) = ISNULL((
        SELECT SUM(CorrectedValue) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID231),0);

    DECLARE @Amt331 DECIMAL(22,2) = ISNULL((
        SELECT SUM(CorrectedValue) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID331),0);

    DECLARE @Amt431 DECIMAL(22,2) = ISNULL((
        SELECT SUM(CorrectedValue) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId=@FID431),0);

    /* ========== 131 / 331 mahsuplaşma ========== */
    IF @Amt131 > 0 AND @Amt331 > 0
    BEGIN
        DECLARE @Delta131331 DECIMAL(22,2) = CASE WHEN @Amt131 <= @Amt331 THEN @Amt131 ELSE @Amt331 END;
		DECLARE @Delta131331Neg DECIMAL(22,2) = -@Delta131331;
        -- History (131 -, 331 -)
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Delta131331, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
             @Amount=@Delta131331, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			  EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Delta131331, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
             @Amount=@Delta131331, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        -- Güncelle (131 ↓, 331 ↓)
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID131,
														   @Amount = @Delta131331Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID331,
														   @Amount = @Delta131331Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
       

        -- Fazla 561’e (+) — yalnızca 131 > 331 ise
        IF @Amt131 > @Amt331
        BEGIN
            DECLARE @Fark131331 DECIMAL(22,2) = @Amt131 - @Amt331;

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Fark131331, @TransactionType='+',
                 @Description=N'Rule12: 131 ve 331 mahsuplaşma farkı 561’e eklendi.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
				 
            EXEC ALT.ins_ATC_HistoryCorrection
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Fark131331, @TransactionType='+',
                 @Description=N'Rule12: 131 ve 331 mahsuplaşma farkı 561’e eklendi.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
			
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID561,
														   @Amount = @Fark131331,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

          
        END
    END

    /* ========== 231 / 431 mahsuplaşma ========== */
    IF @Amt231 > 0 AND @Amt431 > 0
    BEGIN
        DECLARE @Delta231431 DECIMAL(22,2) = CASE WHEN @Amt231 <= @Amt431 THEN @Amt231 ELSE @Amt431 END;
		DECLARE @Delta231431Neg DECIMAL(22,2) = -@Delta231431;
        -- History (231 -, 431 -)
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID231, @AccountCode=N'231',
             @Amount=@Delta231431, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID431, @AccountCode=N'431',
             @Amount=@Delta231431, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID231, @AccountCode=N'231',
             @Amount=@Delta231431, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID431, @AccountCode=N'431',
             @Amount=@Delta231431, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 karşılıklı mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        -- Güncelle (231 ↓, 431 ↓)
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID231,
														   @Amount = @Delta231431Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID431,
														   @Amount = @Delta231431Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        

        -- Fazla 561’e (+) — yalnızca 231 > 431 ise
        IF @Amt231 > @Amt431
        BEGIN
            DECLARE @Fark231431 DECIMAL(22,2) = @Amt231 - @Amt431;

            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Fark231431, @TransactionType='+',
                 @Description=N'Rule12: 231 ve 431 mahsuplaşma farkı 561’e eklendi.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

				  EXEC ALT.ins_ATC_HistoryCorrection
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Fark231431, @TransactionType='+',
                 @Description=N'Rule12: 231 ve 431 mahsuplaşma farkı 561’e eklendi.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID561,
														   @Amount = @Fark231431,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

            
        END
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_13]    Script Date: 13/11/2025 9:23:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
  Düzenlemeler (özet)
   - Türkçe karakter bozulmaları giderildi.
   - Tüm history kayıtları ALT.ins_ATC_History SP’si ile merkezi kayda alındı.
   - Tüm bakiyeler için CorrectedValue baz alındı (BDR/Beyanname verisi).
   - @Period = YYYYQ (örn. 202351) formatı için yıl/çeyrek/ay ayrıştırma eklendi.
   - Kod geneli TRY/CATCH ve NOCOUNT ile sağlamlaştırıldı.
   - Rule20: “Faktoring” leaf tespiti netleştirildi.
   - Rule21: Memzuç kuralı tam akışa göre yeniden yazıldı (Nakdi/Leasing/Faktoring).
 *    
 */ 

/* -----------------------------
   Rule 13
   ----------------------------- */

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_13]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FID180 INT, @FID280 INT, @FID300 INT, @FID400 INT, @FID381 INT, @FID481 INT;

    SELECT
        @FID180 = NULLIF(MAX(CASE WHEN Code = N'180' THEN FinancialItemDefinitionId ELSE 0 END), 0),
        @FID280 = NULLIF(MAX(CASE WHEN Code = N'280' THEN FinancialItemDefinitionId ELSE 0 END), 0),
        @FID300 = NULLIF(MAX(CASE WHEN Code = N'300' THEN FinancialItemDefinitionId ELSE 0 END), 0),
        @FID400 = NULLIF(MAX(CASE WHEN Code = N'400' THEN FinancialItemDefinitionId ELSE 0 END), 0),
        @FID381 = NULLIF(MAX(CASE WHEN Code = N'381' THEN FinancialItemDefinitionId ELSE 0 END), 0),
        @FID481 = NULLIF(MAX(CASE WHEN Code = N'481' THEN FinancialItemDefinitionId ELSE 0 END), 0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN (N'180',N'280',N'300',N'400',N'381',N'481');

    IF @FID180 IS NULL OR @FID280 IS NULL OR @FID300 IS NULL OR @FID400 IS NULL OR @FID381 IS NULL OR @FID481 IS NULL
    BEGIN
        RAISERROR(N'Gerekli FID''ler (180,280,300,400,381,481) bulunamadı.',16,1);
        RETURN;
    END

    DECLARE @Terms TABLE (Term NVARCHAR(100));
    INSERT INTO @Terms(Term) VALUES (N'Finansman'),(N'Faiz'),(N'Borçlanma');

    /* ---------- 180 – 381 – 300 akışı ---------- */
    DECLARE @X DECIMAL(22,2) = 0, @B381 DECIMAL(22,2) = 0;

    -- 180 alt kalemlerinde terim eşleşen yaprak toplamı (X)
	  SELECT @X =SUM(COALESCE(s.NetSum_Leaves, 0) )
	       FROM @Terms AS t
	OUTER APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, N'180', 1, t.Term) AS s


    -- 381 mevcut düzeltme bakiyesi (CorrectedValue baz)
    SELECT @B381 = ISNULL(SUM(a.CorrectedValue),0)
    FROM ALT.AutoTransferCleansing a WITH (NOLOCK)
    WHERE a.AccountNumber=@AccountNumber
      AND a.[Period]=@Period AND a.FinancialItemDefinitionId=@FID381;

   
        DECLARE @Delta180 DECIMAL(22,2) = @X;
        DECLARE @Delta381 DECIMAL(22,2) = @B381;
        DECLARE @Delta300 DECIMAL(22,2) = CASE WHEN @X > @B381 THEN (@X - @B381)
                                               WHEN @X < @B381 THEN -(@B381 - @X)  -- X<B381 ise 300'e EKLEME (+) lazım; aşağıda işaretini yöneteceğiz
                                               ELSE 0 END;
        DECLARE @Delta180Neg DECIMAL(22,2) = -@Delta180;
		DECLARE @Delta381Neg DECIMAL(22,2) = -@Delta381;
		DECLARE @Delta300Neg DECIMAL(22,2) = -@Delta300;
        -- History (çıkarma/ekleme mantığına göre)
        IF @Delta180 <> 0
        BEGIN
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID180, N'180', @Delta180, N'-', N'Rule13: 180 terim eşleşen toplam X kadar eksiltildi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID180, N'180', @Delta180, N'-', N'Rule13: 180 düzeltme.', @UserName, @HostName, @HostIP;
        END

        IF @Delta381 <> 0
        BEGIN
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID381, N'381', @Delta381, N'-', N'Rule13: 381 bakiye kadar eksiltildi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID381, N'381', @Delta381, N'-', N'Rule13: 381 düzeltme.', @UserName, @HostName, @HostIP;
        END

        IF @Delta300 > 0
        BEGIN
            -- X > B381: 300’den eksilt
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID300, N'300', @Delta300, N'-', N'Rule13: X-B381 kadar 300''den eksiltildi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID300, N'300', @Delta300, N'-', N'Rule13: 300 düzeltme (eksiltme).', @UserName, @HostName, @HostIP;
        END
        ELSE IF @Delta300 < 0
        BEGIN
		    DECLARE @AbsDelta300 DECIMAL(22,2) = ABS(@Delta300)
		     -- X < B381: 300’e ekle (mutlak değer kadar +)
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID300, N'300', @AbsDelta300, N'+', N'Rule13: B381-X kadar 300''e eklendi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID300, N'300', @AbsDelta300, N'+', N'Rule13: 300 düzeltme (ekleme).', @UserName, @HostName, @HostIP;
        END

       EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID180,
														   @Amount = @Delta180Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID381,
														   @Amount = @Delta381Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
    
        IF @Delta300 > 0
		    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID300,
														   @Amount = @Delta300Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
           
        ELSE IF @Delta300 < 0
		BEGIN
		   DECLARE  @Delta300ABS DECIMAL(22,2)= ABS(@Delta300)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID300,
														   @Amount = @Delta300ABS,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		END
		     
		    
             
   

    /* ---------- 280 – 481 – 400 akışı ---------- */
    DECLARE @Y DECIMAL(22,2) = 0, @B481 DECIMAL(22,2) = 0;

    -- 280 alt kalemlerinde terim eşleşen yaprak toplamı (Y)

	  SELECT @Y =SUM(COALESCE(s.NetSum_Leaves, 0)) 
	       FROM @Terms AS t
	OUTER APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, N'280', 1, t.Term) AS s

    -- 481 mevcut düzeltme bakiyesi
    SELECT @B481 = ISNULL(SUM(a.CorrectedValue),0)
      FROM ALT.AutoTransferCleansing a WITH (NOLOCK)
     WHERE a.AccountNumber=@AccountNumber
       AND a.[Period]=@Period 
	   AND a.FinancialItemDefinitionId=@FID481;

  
        DECLARE @Delta280 DECIMAL(22,2) = @Y;
        DECLARE @Delta481 DECIMAL(22,2) = @B481;
        DECLARE @Delta400 DECIMAL(22,2) = CASE WHEN @Y > @B481 THEN (@Y - @B481)
                                               WHEN @Y < @B481 THEN -(@B481 - @Y)  -- Y<B481 ise 400’e EKLE
                                               ELSE 0 END;
		 DECLARE @Delta280Neg DECIMAL(22,2) = -@Delta280;
		 DECLARE @Delta481Neg DECIMAL(22,2) = -@Delta481;
		 DECLARE @Delta400Neg DECIMAL(22,2) = -@Delta400;
		 DECLARE @AbsDelta400 DECIMAL(22,2) = ABS(@Delta400)
        IF @Delta280 <> 0
        BEGIN
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID280, N'280', @Delta280, N'-', N'Rule13: 280 terim eşleşen toplam Y kadar eksiltildi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID280, N'280', @Delta280, N'-', N'Rule13: 280 düzeltme.', @UserName, @HostName, @HostIP;
        END

        IF @Delta481 <> 0
        BEGIN
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID481, N'481', @Delta481, N'-', N'Rule13: 481 bakiye kadar eksiltildi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID481, N'481', @Delta481, N'-', N'Rule13: 481 düzeltme.', @UserName, @HostName, @HostIP;
        END

        IF @Delta400 > 0
        BEGIN
            -- Y > B481: 400’den eksilt
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID400, N'400', @Delta400, N'-', N'Rule13: Y-B481 kadar 400''den eksiltildi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID400, N'400', @Delta400, N'-', N'Rule13: 400 düzeltme (eksiltme).', @UserName, @HostName, @HostIP;
        END
        ELSE IF @Delta400 < 0
        BEGIN
		     
            -- Y < B481: 400’e ekle (mutlak değer kadar +)
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID400, N'400', @AbsDelta400, N'+', N'Rule13: B481-Y kadar 400''e eklendi.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID400, N'400', @AbsDelta400, N'+', N'Rule13: 400 düzeltme (ekleme).', @UserName, @HostName, @HostIP;
        END

        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID280,
														   @Amount = @Delta280Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
         EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID481,
														   @Amount = @Delta481Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

      
        IF @Delta400 > 0
		    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID400,
														   @Amount = @Delta400Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
            
        ELSE IF @Delta400 < 0
		    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID400,
														   @Amount = @AbsDelta400,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
           
  
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_14]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

/* -----------------------------
   Rule 14 (191–391 mahsup)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_14]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID191 INT, @FID391 INT, @Amt191 DECIMAL(22,2)=0, @Amt391 DECIMAL(22,2)=0, @Delta DECIMAL(22,2)=0;

    SELECT @FID191 = NULLIF(MAX(CASE WHEN Code='191' THEN FinancialItemDefinitionId ELSE 0 END),0),
           @FID391 = NULLIF(MAX(CASE WHEN Code='391' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('191','391');

    IF @FID191 IS NULL OR @FID391 IS NULL
	BEGIN
    	RAISERROR(N'Gerekli FinancialItemDefinition (191,391) bulunamadı.',16,1);
		RETURN
    END
	

    SELECT @Amt191 = ISNULL(SUM(CorrectedValue),0)
      FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID191;

    SELECT @Amt391 = ISNULL(SUM(CorrectedValue),0)
      FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID391;

	SET @Delta = CASE WHEN @Amt191 <= @Amt391 THEN @Amt191 ELSE @Amt391 END;
    declare  @DeltaNeg DECIMAL(22,2) = -@Delta;

    IF @Delta > 0
    BEGIN
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID191, N'191', @Delta, N'-', N'Rule14: 191–391 mahsuplaşma, 191 düşüldü.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID391, N'391', @Delta, N'-', N'Rule14: 191–391 mahsuplaşma, 391 düşüldü.', @UserName, @HostName, @HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID191, N'191', @Delta, N'-', N'Rule14: 191–391 mahsuplaşma, 191 düşüldü.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID391, N'391', @Delta, N'-', N'Rule14: 191–391 mahsuplaşma, 391 düşüldü.', @UserName, @HostName, @HostIP;
		
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID191,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID391,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        
    END
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_15]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
/* -----------------------------
   Rule 15 (192–392 mahsup)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_15]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID192 INT, @FID392 INT, @Amt192 DECIMAL(22,2)=0, @Amt392 DECIMAL(22,2)=0, @Delta DECIMAL(22,2)=0;

    SELECT @FID192 = NULLIF(MAX(CASE WHEN Code='192' THEN FinancialItemDefinitionId ELSE 0 END),0),
           @FID392 = NULLIF(MAX(CASE WHEN Code='392' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('192','392');

    IF @FID192 IS NULL OR @FID392 IS NULL 
	BEGIN
	   RAISERROR(N'Gerekli FinancialItemDefinition (192,392) bulunamadı.',16,1); 
	   RETURN
    	
    END
	

    SELECT @Amt192 = ISNULL(SUM(CorrectedValue),0)
      FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID192;

    SELECT @Amt392 = ISNULL(SUM(CorrectedValue),0)
      FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID392;

    SET @Delta = CASE WHEN @Amt192 <= @Amt392 THEN @Amt192 ELSE @Amt392 END;
	DECLARE @DeltaNeg DECIMAL(22,2)= -@Delta;
    IF @Delta > 0
    BEGIN
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID192, N'192', @Delta, N'-', N'Rule15: 192–392 mahsuplaşma, 192 düşüldü.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID392, N'392', @Delta, N'-', N'Rule15: 192–392 mahsuplaşma, 392 düşüldü.', @UserName, @HostName, @HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID192, N'192', @Delta, N'-', N'Rule15: 192–392 mahsuplaşma, 192 düşüldü.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID392, N'392', @Delta, N'-', N'Rule15: 192–392 mahsuplaşma, 392 düşüldü.', @UserName, @HostName, @HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID192,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID392,
														   @Amount = @DeltaNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

        
    END
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_16]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
/* -----------------------------
   Rule 16 (193 ↔ 371 dengeleme)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_16]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID193 INT, @FID370 INT, @FID371 INT,
            @Amt193 DECIMAL(22,2)=0, @Amt370 DECIMAL(22,2)=0, @Amt371 DECIMAL(22,2)=0,
            @Diff  DECIMAL(22,2)=0,@DiffNeg  DECIMAL(22,2)=0;

    SELECT @FID193 = NULLIF(MAX(CASE WHEN Code='193' THEN FinancialItemDefinitionId END),0),
           @FID370 = NULLIF(MAX(CASE WHEN Code='370' THEN FinancialItemDefinitionId END),0),
           @FID371 = NULLIF(MAX(CASE WHEN Code='371' THEN FinancialItemDefinitionId END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('193','370','371');

    IF @FID193 IS NULL OR @FID370 IS NULL OR @FID371 IS NULL 
	BEGIN
    	RAISERROR(N'Gerekli FinancialItemDefinition (193,370,371) bulunamadı.',16,1);
		RETURN
    END
	

    /* CorrectedValue baz alınır */
    SELECT @Amt193 = ISNULL(SUM(CorrectedValue),0) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID193;
    SELECT @Amt370 = ISNULL(SUM(CorrectedValue),0) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID370;
    SELECT @Amt371 = ISNULL(SUM(CorrectedValue),0) FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID371;

    IF @Amt370 > @Amt371
    BEGIN
        SET @Diff = @Amt370 - @Amt371;
		SET @DiffNeg = -@Diff;
		IF @Diff < @Amt193 
		BEGIN  
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID193, N'193', @Diff, N'-', N'Rule16: 370 > 371 farkı 193’ten düşüldü.', @UserName, @HostName, @HostIP;
           EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID371, N'371', @Diff, N'+', N'Rule16: 370 > 371 farkı 371’e eklendi.', @UserName, @HostName, @HostIP;
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID193,
														   @Amount = @DiffNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID371,
														   @Amount = @Diff,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

		 
        	
        END
		ELSE
		BEGIN
		   DECLARE @Amt193Neg DECIMAL(22,2) = -@Amt193;
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID193, N'193', @Amt193, N'-', N'Rule16: 193 tutarı 193’ten düşüldü.', @UserName, @HostName, @HostIP;
           EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID371, N'371', @Amt193, N'+', N'Rule16: 193 tutarı 371’e eklendi.', @UserName, @HostName, @HostIP;

		   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID193,
														   @Amount = @Amt193Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID371,
														   @Amount = @Amt193,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;


		   
		 
		END
        
    END
    ELSE IF @Amt371 > @Amt370
    BEGIN
        SET @Diff = @Amt371 - @Amt370;
		SET @DiffNeg = -@Diff;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID193, N'193', @Diff, N'+', N'Rule16: 371 > 370 farkı 193’e eklendi.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID371, N'371', @Diff, N'-', N'Rule16: 371 > 370 farkı 371’den düşüldü.', @UserName, @HostName, @HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID193, N'193', @Diff, N'+', N'Rule16: 371 > 370 farkı 193’e eklendi.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID371, N'371', @Diff, N'-', N'Rule16: 371 > 370 farkı 371’den düşüldü.', @UserName, @HostName, @HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID193,
														   @Amount = @Diff,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID371,
														   @Amount = @DiffNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;


       
    END
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_17]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
/* -----------------------------
   Rule 17 (240/242/245 Enf% leaf → 562)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_17]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID562 INT; SELECT @FID562 = FinancialItemDefinitionId FROM ALT.FinancialItemDefinition WHERE Code='562';
    IF @FID562 IS NULL
	BEGIN
    	RAISERROR(N'FinancialItemDefinition 562 bulunamadı.',16,1);
		RETURN
    END
	

    DECLARE @Roots TABLE(Code NVARCHAR(50)); INSERT INTO @Roots VALUES('240'),('242'),('245');
    DECLARE @AccCode NVARCHAR(50), @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Code FROM @Roots;
    OPEN cur; FETCH NEXT FROM cur INTO @AccCode;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        WITH Tree AS (
            SELECT d.AccountCode, d.ParentAccountCode, d.AccountDescription,
                   CAST(d.DebitBalance AS DECIMAL(22,2)) AS DebitBalance,
                   CAST(d.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
            FROM ALT.CustomerDetailedTrialBalance d
            WHERE d.AccountNumber=@AccountNumber AND d.Period=@Period AND d.AccountCode=@AccCode
            UNION ALL
            SELECT c.AccountCode, c.ParentAccountCode, c.AccountDescription,
                   CAST(c.DebitBalance AS DECIMAL(22,2)), CAST(c.CreditBalance AS DECIMAL(22,2))
            FROM ALT.CustomerDetailedTrialBalance c
            JOIN Tree t ON c.AccountNumber=@AccountNumber AND c.Period=@Period AND c.ParentAccountCode=t.AccountCode
        ), Leaves AS (
            SELECT t.*
            FROM Tree t
            WHERE NOT EXISTS (
                SELECT 1 FROM ALT.CustomerDetailedTrialBalance x
                WHERE x.AccountNumber=@AccountNumber AND x.Period=@Period AND x.ParentAccountCode=t.AccountCode)
        )
        SELECT @Amt = COALESCE(SUM(CASE WHEN ISNULL(DebitBalance,0) - ISNULL(CreditBalance,0) > 0
                                        THEN ISNULL(DebitBalance,0) - ISNULL(CreditBalance,0) ELSE 0 END),0)
        FROM Leaves
        WHERE AccountDescription LIKE N'Enf%' AND AccountCode <> @AccCode;

        IF @Amt > 0
        BEGIN
		    SET @AmtNeg = -@Amt
            DECLARE @FIDSource INT; SELECT @FIDSource = FinancialItemDefinitionId FROM ALT.FinancialItemDefinition WHERE Code=@AccCode;
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule17: Enf% leaf bakiyesi kaynak hesaptan düşüldü.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID562,   N'562',    @Amt, N'+', N'Rule17: Enf% leaf bakiyesi 562’ye aktarıldı.', @UserName, @HostName, @HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule17: Enf% leaf bakiyesi kaynak hesaptan düşüldü.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID562,   N'562',    @Amt, N'+', N'Rule17: Enf% leaf bakiyesi 562’ye aktarıldı.', @UserName, @HostName, @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDSource,
														   @Amount = @AmtNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
            EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID562,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

            
        END
        FETCH NEXT FROM cur INTO @AccCode;
    END
    CLOSE cur; DEALLOCATE cur;
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_18]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

/* -----------------------------
   Rule 18 (262/263/264/271/272/277/279 → 563, 278 negatif)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_18]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID563 INT; SELECT @FID563 = FinancialItemDefinitionId FROM ALT.FinancialItemDefinition WHERE Code='563';
    IF @FID563 IS NULL 
	BEGIN
    	RAISERROR(N'FinancialItemDefinition 563 bulunamadı.',16,1);
		RETURN
    END
	

    DECLARE @AccList TABLE(Code NVARCHAR(50), IsNegative BIT);
    INSERT INTO @AccList VALUES ('262',0),('263',0),('264',0),('271',0),('272',0),('277',0),('279',0),('278',1);

    DECLARE @AccCode NVARCHAR(50), @IsNegative BIT, @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2), @FIDSource INT;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Code, IsNegative FROM @AccList;
    OPEN c; FETCH NEXT FROM c INTO @AccCode, @IsNegative;
    WHILE @@FETCH_STATUS=0
    BEGIN
		SELECT @FIDSource = FinancialItemDefinitionId
		  FROM ALT.FinancialItemDefinition
		 WHERE Code = @AccCode;

		SELECT @Amt = COALESCE(SUM(CorrectedValue), 0)
		  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
		 WHERE AccountNumber = @AccountNumber
		   AND Period = @Period
		   AND FinancialItemDefinitionId = @FIDSource;
        SET @AmtNeg = -@Amt
        IF @Amt <> 0
        BEGIN
			DECLARE @Uamt decimal(22,2)  = CASE WHEN @IsNegative=1 THEN -@Amt ELSE @Amt END
			DECLARE @Sign varchar(1)  =  CASE WHEN @IsNegative=1 THEN N'-' ELSE N'+' END
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule18: Kaynak hesaptan 563’e transfer için düşüldü.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID563,   N'563', @Uamt ,@Sign,N'Rule18: 563 hesabı güncellendi.', @UserName, @HostName, @HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule18: Kaynak hesaptan 563’e transfer için düşüldü.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID563,   N'563', @Uamt ,@Sign,N'Rule18: 563 hesabı güncellendi.', @UserName, @HostName, @HostIP;

			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDSource,
														   @Amount = @AmtNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		  IF @IsNegative=1 
		  BEGIN
		     EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID563,
														   @Amount = @AmtNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		  END
		  ELSE
		  BEGIN
		    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID563,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		  END 
            
            
        END
        FETCH NEXT FROM c INTO @AccCode, @IsNegative;
    END
    CLOSE c; DEALLOCATE c;
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_19]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
/* -----------------------------
   Rule 19 (296 Matrah Art% → 563)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_19]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID296 INT, @FID563 INT, @Amt DECIMAL(22,2)=0,@AmtNeg DECIMAL(22,2);
    SELECT @FID296 = MAX(CASE WHEN Code='296' THEN FinancialItemDefinitionId END),
           @FID563 = MAX(CASE WHEN Code='563' THEN FinancialItemDefinitionId END)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK) WHERE Code IN('296','563');
    IF @FID296 IS NULL OR @FID563 IS NULL
	BEGIN
	  RAISERROR(N'Gerekli FID (296,563) bulunamadı.',16,1);
	  RETURN
	END
	

    SELECT @Amt = SUM(ISNULL(d.DebitBalance,0))
    FROM ALT.CustomerDetailedTrialBalance d WITH (NOLOCK)
    WHERE d.AccountNumber=@AccountNumber AND d.Period=@Period
      AND d.AccountCode LIKE N'296%'
      AND d.AccountCode <> N'296'
      AND (
            d.AccountDescription COLLATE Turkish_CI_AI LIKE N'%Matrah Art%'
         OR d.AccountDescription COLLATE Turkish_CI_AI LIKE N'%Affı%'
         OR d.AccountDescription COLLATE Turkish_CI_AI LIKE N'%Affi%'
		 OR d.AccountDescription COLLATE Turkish_CI_AI LIKE N'%Sayılı Kanun%'
		  OR d.AccountDescription COLLATE Turkish_CI_AI LIKE N'%Sayili Kanun%'
      )
      AND NOT EXISTS (SELECT 1 FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
                      WHERE c.AccountNumber=d.AccountNumber AND c.Period=d.Period AND c.ParentAccountCode=d.AccountCode);

    EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID296, N'296', @Amt, N'-', N'Rule19: %Matrah Art% / %Affı%  leaf toplamı 296’dan düşüldü.', @UserName, @HostName, @HostIP;
    EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID563, N'563', @Amt, N'+', N'Rule19: %Matrah Art% / %Affı%  leaf toplamı 563’e aktarıldı.', @UserName, @HostName, @HostIP;

    IF @Amt > 0
    BEGIN
	    SET @AmtNeg = -@Amt
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID296,
														   @Amount = @AmtNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID563,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

        
		 EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID296, N'296', @Amt, N'-', N'Rule19: %Matrah Art% / %Affı% leaf toplamı 296’dan düşüldü.', @UserName, @HostName, @HostIP;
         EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID563, N'563', @Amt, N'+', N'Rule19: %Matrah Art% / %Affı% leaf toplamı 563’e aktarıldı.', @UserName, @HostName, @HostIP;
    END
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_20]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
/* -----------------------------
   Rule 20 (Faktoring borçları: 320→307, 420→409)
   ----------------------------- */
CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_20]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FID307 INT, @FID320 INT, @FID409 INT, @FID420 INT;
      SELECT   @FID320 = NULLIF(MAX(CASE WHEN Code='320' THEN FinancialItemDefinitionId ELSE 0 END),0),
			   @FID409 = NULLIF(MAX(CASE WHEN Code='409' THEN FinancialItemDefinitionId ELSE 0 END),0),
			   @FID420 = NULLIF(MAX(CASE WHEN Code='420' THEN FinancialItemDefinitionId ELSE 0 END),0),
               @FID307 = NULLIF(MAX(CASE WHEN Code='307' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('307','320','409','420')

    IF @FID307 IS NULL OR @FID320 IS NULL OR @FID409 IS NULL OR @FID420 IS NULL
	BEGIN
	 RAISERROR(N'Gerekli FID (307,320,409,420) bulunamadı.',16,1);
	 RETURN
    END
       

    DECLARE @Map TABLE(AccCode NVARCHAR(3), FIDSource INT, FIDTarget INT);
    INSERT INTO @Map VALUES ('320', @FID320, @FID307), ('420', @FID420, @FID409);

    DECLARE @AccCode NVARCHAR(3), @FIDSource INT, @FIDTarget INT, @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT AccCode, FIDSource, FIDTarget FROM @Map; OPEN cur;
    FETCH NEXT FROM cur INTO @AccCode, @FIDSource, @FIDTarget;
    WHILE @@FETCH_STATUS = 0
    BEGIN
				   ;WITH Tree AS (
				SELECT d.AccountCode, d.ParentAccountCode, d.AccountDescription,
					   CAST(d.DebitBalance AS DECIMAL(22,2)) AS Dr,
					   CAST(d.CreditBalance AS DECIMAL(22,2)) AS Cr
				FROM ALT.CustomerDetailedTrialBalance d WITH (NOLOCK)
				WHERE d.AccountNumber = @AccountNumber
				  AND d.Period        = @Period
				  AND LEFT(d.AccountCode,3) = @AccCode
			),
			Leaves AS (
				SELECT t.*
				FROM Tree t
				WHERE NOT EXISTS (
					SELECT 1
					FROM ALT.CustomerDetailedTrialBalance x WITH (NOLOCK)
					WHERE x.AccountNumber = @AccountNumber
					  AND x.Period        = @Period
					  AND x.ParentAccountCode = t.AccountCode
				)
				AND (
					t.AccountDescription LIKE N'%Faktor%ing%' ESCAPE N'\'
					OR t.AccountDescription LIKE N'%Faktoring%'
				)
			)
			SELECT @Amt = ISNULL(SUM(ABS(ISNULL(Dr,0) - ISNULL(Cr,0))), 0)
			FROM Leaves;

       
		 
        -- History
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule20: Faktoring alt kalemleri kaynak hesaptan düşüldü.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDTarget,@FIDTarget, @Amt, N'+', N'Rule20: Faktoring alt kalemleri hedef hesaba eklendi.', @UserName, @HostName, @HostIP;

        IF ISNULL(@Amt,0) > 0
        BEGIN
		    SET @AmtNeg =-@Amt
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDSource,
														   @Amount = @AmtNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FIDTarget,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;

          

			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule20: Faktoring alt kalemleri kaynak hesaptan düşüldü.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDTarget,@FIDTarget, @Amt, N'+', N'Rule20: Faktoring alt kalemleri hedef hesaba eklendi.', @UserName, @HostName, @HostIP;
        END
        FETCH NEXT FROM cur INTO @AccCode, @FIDSource, @FIDTarget;
    END
    CLOSE cur; DEALLOCATE cur;
END

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_21]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator        : BOA.Tools.CodeGenerator    
 *      Generated By     : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version         : 1.0    
 *  Purpose              : Aktarım arındırma spleri   
 *  Last Modified By     : aelgun    
 *  Last Modification Date: 21.09.2025 13:45:00    
 *    
 */

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_21]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP   VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;
	
        -- TODO: Konsolide BDR kontrolü

        DECLARE 
            @FID198 INT, @FID300 INT, @FID301 INT, @FID307 INT,
            @FID400 INT, @FID401 INT, @FID409 INT, @FID331 INT, @FID431 INT,
            @FID303 INT, @FID304 INT, @FID305 INT, @FID309 INT,
            @FID405 INT, @FID407 INT, @FID408 INT,
            @FID302 INT, @FID402 INT;

        -- yeni kuralın istediği bütün kalemleri al
        SELECT
            @FID198 = NULLIF(MAX(CASE WHEN Code='198' THEN FinancialItemDefinitionId END),0),
            @FID300 = NULLIF(MAX(CASE WHEN Code='300' THEN FinancialItemDefinitionId END),0),
            @FID301 = NULLIF(MAX(CASE WHEN Code='301' THEN FinancialItemDefinitionId END),0),
            @FID307 = NULLIF(MAX(CASE WHEN Code='307' THEN FinancialItemDefinitionId END),0),
            @FID400 = NULLIF(MAX(CASE WHEN Code='400' THEN FinancialItemDefinitionId END),0),
            @FID401 = NULLIF(MAX(CASE WHEN Code='401' THEN FinancialItemDefinitionId END),0),
            @FID409 = NULLIF(MAX(CASE WHEN Code='409' THEN FinancialItemDefinitionId END),0),
            @FID331 = NULLIF(MAX(CASE WHEN Code='331' THEN FinancialItemDefinitionId END),0),
            @FID431 = NULLIF(MAX(CASE WHEN Code='431' THEN FinancialItemDefinitionId END),0),
            @FID303 = NULLIF(MAX(CASE WHEN Code='303' THEN FinancialItemDefinitionId END),0),
            @FID304 = NULLIF(MAX(CASE WHEN Code='304' THEN FinancialItemDefinitionId END),0),
            @FID305 = NULLIF(MAX(CASE WHEN Code='305' THEN FinancialItemDefinitionId END),0),
            @FID309 = NULLIF(MAX(CASE WHEN Code='309' THEN FinancialItemDefinitionId END),0),
            @FID405 = NULLIF(MAX(CASE WHEN Code='405' THEN FinancialItemDefinitionId END),0),
            @FID407 = NULLIF(MAX(CASE WHEN Code='407' THEN FinancialItemDefinitionId END),0),
            @FID408 = NULLIF(MAX(CASE WHEN Code='408' THEN FinancialItemDefinitionId END),0),
            @FID302 = NULLIF(MAX(CASE WHEN Code='302' THEN FinancialItemDefinitionId END),0),
            @FID402 = NULLIF(MAX(CASE WHEN Code='402' THEN FinancialItemDefinitionId END),0)
        FROM ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('198','300','301','307','400','401','409','331','431',
                       '303','304','305','309','405','407','408','302','402');

        IF @FID198 IS NULL OR @FID300 IS NULL OR @FID301 IS NULL OR @FID307 IS NULL
           OR @FID400 IS NULL OR @FID401 IS NULL OR @FID409 IS NULL OR @FID331 IS NULL OR @FID431 IS NULL
           OR @FID303 IS NULL OR @FID304 IS NULL OR @FID305 IS NULL OR @FID309 IS NULL
           OR @FID405 IS NULL OR @FID407 IS NULL OR @FID408 IS NULL
           OR @FID302 IS NULL OR @FID402 IS NULL
        BEGIN
            RAISERROR('upd_ATC_ApplyRule_21 failed: Gerekli FinancialItemDefinition kodlari (198,300,301,302,303,304,305,307,309,400,401,402,405,407,408,409,331,431) bulunamadi.', 16, 1);
            RETURN;
        END

		 DECLARE 
            @KOVNakdiMemzuc       DECIMAL(22,2) = 0,
            @UVNakdiMemzuc        DECIMAL(22,2) = 0,
            @KOVLeasingMemzuc     DECIMAL(22,2) = 0,
            @UVLeasingMemzuc      DECIMAL(22,2) = 0,
            @KOVFaktoringMemzuc   DECIMAL(22,2) = 0,
            @UVFaktoringMemzuc    DECIMAL(22,2) = 0;
        DECLARE @Month INT,@Year INT ,@Quarter INT;
        SET @Year    = CAST(SUBSTRING(CONVERT(varchar(6), @Period), 1, 4) AS int);
        SET @Quarter = CAST(SUBSTRING(CONVERT(varchar(6), @Period), 5, 1) AS int);

        SELECT TOP 1 @Month = Month 
        FROM [BOA].[ALT].[CustomerQuarter] WITH (NOLOCK)
        WHERE AccountNumber IN (@AccountNumber,0) AND Quarter = @Quarter
        ORDER BY AccountNumber DESC;

        ;WITH LatestInquiry AS (
            SELECT TOP 1 crl.InquiryCreditRiskLimitId AS MaxId
            FROM ALT.CreditRiskLimit crl WITH (NOLOCK)
            INNER JOIN ALT.InquiryCreditRiskLimit icrl WITH (NOLOCK)
                    ON icrl.InquiryCreditRiskLimitId = crl.InquiryCreditRiskLimitId
            WHERE icrl.AccountNumber = @AccountNumber
              AND crl.Year  = @Year
              AND crl.Month = @Month
            ORDER BY crl.InquiryCreditRiskLimitId DESC
        ),
        CR AS (
            -- Burada parametre tablosu ile eşleşen ve ParamValue2='Nakdi' olan riskler alınır
            SELECT 
                crl.RiskCode,
                ShortMidProfit =
                    COALESCE(crl.ShortTermRiskAmount,0)
                  + COALESCE(crl.MidTermRiskAmount,0)
                  + COALESCE(crl.ProfitAccrualAmount,0)
                  + COALESCE(crl.ProfitRediscountAmount,0),
                LongAmt = COALESCE(crl.LongTermRiskAmount,0)
            FROM LatestInquiry li
            JOIN ALT.CreditRiskLimit crl WITH (NOLOCK) 
                ON crl.InquiryCreditRiskLimitId = li.MaxId
               AND crl.Year  = @Year
               AND crl.Month = @Month
            JOIN COR.Parameter  p WITH (NOLOCK)
              ON p.ParamCode  = crl.RiskCode
             AND p.ParamType = 'TCMBRISK'
             AND p.ParamValue2 = 'Nakdi'
             AND p.LanguageId = 1
        )
        -- 3 grup toplamı
       

        SELECT
            @KOVNakdiMemzuc =
                COALESCE(SUM(CASE WHEN RiskCode NOT BETWEEN 600 AND 799 THEN ShortMidProfit ELSE 0 END),0),
            @UVNakdiMemzuc  =
                COALESCE(SUM(CASE WHEN RiskCode NOT BETWEEN 600 AND 799 THEN LongAmt       ELSE 0 END),0),
            @KOVLeasingMemzuc =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 600 AND 699 THEN ShortMidProfit ELSE 0 END),0),
            @UVLeasingMemzuc  =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 600 AND 699 THEN LongAmt       ELSE 0 END),0),
            @KOVFaktoringMemzuc =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 700 AND 799 THEN ShortMidProfit ELSE 0 END),0),
            @UVFaktoringMemzuc  =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 700 AND 799 THEN LongAmt       ELSE 0 END),0)
        FROM CR;

        -- Bilanço değerlerini çek
        DECLARE 
            @Bal198 DECIMAL(22,2), @Bal300 DECIMAL(22,2), @Bal301 DECIMAL(22,2), @Bal307 DECIMAL(22,2),
            @Bal400 DECIMAL(22,2), @Bal401 DECIMAL(22,2), @Bal409 DECIMAL(22,2), @Bal331 DECIMAL(22,2), @Bal431 DECIMAL(22,2),
            @Bal303 DECIMAL(22,2), @Bal304 DECIMAL(22,2), @Bal305 DECIMAL(22,2), @Bal309 DECIMAL(22,2),
            @Bal405 DECIMAL(22,2), @Bal407 DECIMAL(22,2), @Bal408 DECIMAL(22,2),
            @Bal302 DECIMAL(22,2), @Bal402 DECIMAL(22,2);

        SELECT 
            @Bal198 = SUM(CASE WHEN FinancialItemDefinitionId=@FID198 THEN CorrectedValue END),
            @Bal300 = SUM(CASE WHEN FinancialItemDefinitionId=@FID300 THEN CorrectedValue END),
            @Bal301 = SUM(CASE WHEN FinancialItemDefinitionId=@FID301 THEN CorrectedValue END),
            @Bal307 = SUM(CASE WHEN FinancialItemDefinitionId=@FID307 THEN CorrectedValue END),
            @Bal400 = SUM(CASE WHEN FinancialItemDefinitionId=@FID400 THEN CorrectedValue END),
            @Bal401 = SUM(CASE WHEN FinancialItemDefinitionId=@FID401 THEN CorrectedValue END),
            @Bal409 = SUM(CASE WHEN FinancialItemDefinitionId=@FID409 THEN CorrectedValue END),
            @Bal331 = SUM(CASE WHEN FinancialItemDefinitionId=@FID331 THEN CorrectedValue END),
            @Bal431 = SUM(CASE WHEN FinancialItemDefinitionId=@FID431 THEN CorrectedValue END),
            @Bal303 = SUM(CASE WHEN FinancialItemDefinitionId=@FID303 THEN CorrectedValue END),
            @Bal304 = SUM(CASE WHEN FinancialItemDefinitionId=@FID304 THEN CorrectedValue END),
            @Bal305 = SUM(CASE WHEN FinancialItemDefinitionId=@FID305 THEN CorrectedValue END),
            @Bal309 = SUM(CASE WHEN FinancialItemDefinitionId=@FID309 THEN CorrectedValue END),
            @Bal405 = SUM(CASE WHEN FinancialItemDefinitionId=@FID405 THEN CorrectedValue END),
            @Bal407 = SUM(CASE WHEN FinancialItemDefinitionId=@FID407 THEN CorrectedValue END),
            @Bal408 = SUM(CASE WHEN FinancialItemDefinitionId=@FID408 THEN CorrectedValue END),
            @Bal302 = SUM(CASE WHEN FinancialItemDefinitionId=@FID302 THEN CorrectedValue END),
            @Bal402 = SUM(CASE WHEN FinancialItemDefinitionId=@FID402 THEN CorrectedValue END)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId IN (
                @FID198,@FID300,@FID301,@FID307,@FID400,@FID401,@FID409,@FID331,@FID431,
                @FID303,@FID304,@FID305,@FID309,@FID405,@FID407,@FID408,@FID302,@FID402
          );

        -- NULL'ları sıfırla
        SELECT 
            @Bal198 = COALESCE(@Bal198,0), @Bal300 = COALESCE(@Bal300,0), @Bal301 = COALESCE(@Bal301,0), @Bal307 = COALESCE(@Bal307,0),
            @Bal400 = COALESCE(@Bal400,0), @Bal401 = COALESCE(@Bal401,0), @Bal409 = COALESCE(@Bal409,0), @Bal331 = COALESCE(@Bal331,0), @Bal431 = COALESCE(@Bal431,0),
            @Bal303 = COALESCE(@Bal303,0), @Bal304 = COALESCE(@Bal304,0), @Bal305 = COALESCE(@Bal305,0), @Bal309 = COALESCE(@Bal309,0),
            @Bal405 = COALESCE(@Bal405,0), @Bal407 = COALESCE(@Bal407,0), @Bal408 = COALESCE(@Bal408,0),
            @Bal302 = COALESCE(@Bal302,0), @Bal402 = COALESCE(@Bal402,0);

        -- Yeni kuralın istediği karşılaştırma tutarları
        DECLARE
            @KOVNakdiBilanco     DECIMAL(22,2) = (@Bal300 + @Bal303 + @Bal304 + @Bal305 + @Bal309),
            @UVNakdiBilanco      DECIMAL(22,2) = (@Bal400 + @Bal405 + @Bal407 - @Bal408),
            @KOVLeasingBilanco   DECIMAL(22,2) = (@Bal301 - @Bal302),
            @UVLeasingBilanco    DECIMAL(22,2) = (@Bal401 - @Bal402);

        -- negatif olursa sıfıra çekmek istersen burayı açabilirsin
        --SET @UVNakdiBilanco   = CASE WHEN @UVNakdiBilanco  < 0 THEN 0 ELSE @UVNakdiBilanco END;
        --SET @KOVLeasingBilanco= CASE WHEN @KOVLeasingBilanco < 0 THEN 0 ELSE @KOVLeasingBilanco END;
        --SET @UVLeasingBilanco = CASE WHEN @UVLeasingBilanco < 0 THEN 0 ELSE @UVLeasingBilanco END;

        DECLARE 
            @tmpAmount     DECIMAL(22,2),
            @tmpAmountNeg  DECIMAL(22,2);

        ----------------------------------------------------------
        -- 1) NAKDİ RİSKLER - KISA/ORTA/FAİZ (KOV)
        ----------------------------------------------------------
        IF @KOVNakdiMemzuc > @KOVNakdiBilanco
        BEGIN
            DECLARE @DeltaKOVNakdi DECIMAL(22,2) = @KOVNakdiMemzuc - @KOVNakdiBilanco;

            -- 300'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID300,
                    @Amount = @DeltaKOVNakdi,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID300,N'300',@DeltaKOVNakdi,'+',
                 N'Rule21 Nakdi KOV: Bilanço (300+303+304+305+309) farkı kadar 300 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID300,N'300',@DeltaKOVNakdi,'+',
                 N'Rule21 Nakdi KOV: Bilanço (300+303+304+305+309) farkı kadar 300 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal300 += @DeltaKOVNakdi;

            DECLARE @RemainKOVNakdi DECIMAL(22,2) = @DeltaKOVNakdi;

            -- 400'den düş
            IF @RemainKOVNakdi > 0 AND @Bal400 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVNakdi > @Bal400 THEN @Bal400 ELSE @RemainKOVNakdi END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID400,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID400,N'400',@tmpAmount,'-',
                     N'Rule21 Nakdi KOV: 400 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID400,N'400',@tmpAmount,'-',
                     N'Rule21 Nakdi KOV: 400 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal400 -= @tmpAmount;
                SET @RemainKOVNakdi -= @tmpAmount;
            END

            -- 331'den düş
            IF @RemainKOVNakdi > 0 AND @Bal331 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVNakdi > @Bal331 THEN @Bal331 ELSE @RemainKOVNakdi END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID331,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Nakdi KOV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Nakdi KOV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal331 -= @tmpAmount;
                SET @RemainKOVNakdi -= @tmpAmount;
            END

            -- 431'den düş
            IF @RemainKOVNakdi > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVNakdi > @Bal431 THEN @Bal431 ELSE @RemainKOVNakdi END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID431,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Nakdi KOV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Nakdi KOV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainKOVNakdi -= @tmpAmount;
            END

            -- kalan 198'ya
            IF @RemainKOVNakdi > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainKOVNakdi,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVNakdi,'+',
                     N'Rule21 Nakdi KOV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVNakdi,'+',
                     N'Rule21 Nakdi KOV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainKOVNakdi;
            END
        END

        ----------------------------------------------------------
        -- 2) NAKDİ RİSKLER - UZUN (UV)
        ----------------------------------------------------------
        IF @UVNakdiMemzuc > @UVNakdiBilanco
        BEGIN
            DECLARE @DeltaUVNakdi DECIMAL(22,2) = @UVNakdiMemzuc - @UVNakdiBilanco;

            -- 400'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID400,
                    @Amount = @DeltaUVNakdi,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID400,N'400',@DeltaUVNakdi,'+',
                 N'Rule21 Nakdi UV: Uzun risk farkı kadar 400 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID400,N'400',@DeltaUVNakdi,'+',
                 N'Rule21 Nakdi UV: Uzun risk farkı kadar 400 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal400 += @DeltaUVNakdi;

            DECLARE @RemainUVNakdi DECIMAL(22,2) = @DeltaUVNakdi;

            -- 331'den düş
            IF @RemainUVNakdi > 0 AND @Bal331 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainUVNakdi > @Bal331 THEN @Bal331 ELSE @RemainUVNakdi END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID331,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Nakdi UV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Nakdi UV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal331 -= @tmpAmount;
                SET @RemainUVNakdi -= @tmpAmount;
            END

            -- 431'den düş
            IF @RemainUVNakdi > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainUVNakdi > @Bal431 THEN @Bal431 ELSE @RemainUVNakdi END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID431,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Nakdi UV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Nakdi UV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainUVNakdi -= @tmpAmount;
            END

            -- kalan 198'ya
            IF @RemainUVNakdi > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainUVNakdi,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainUVNakdi,'+',
                     N'Rule21 Nakdi UV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainUVNakdi,'+',
                     N'Rule21 Nakdi UV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainUVNakdi;
            END
        END

        ----------------------------------------------------------
        -- 3) LEASING RİSKLERİ - KOV (kısa/orta/faiz)
        ----------------------------------------------------------
        IF @KOVLeasingMemzuc > @KOVLeasingBilanco
        BEGIN
            DECLARE @DeltaKOVLease DECIMAL(22,2) = @KOVLeasingMemzuc - @KOVLeasingBilanco;

            -- 301'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID301,
                    @Amount = @DeltaKOVLease,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID301,N'301',@DeltaKOVLease,'+',
                 N'Rule21 Leasing KOV: (301-302) farkı kadar 301 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID301,N'301',@DeltaKOVLease,'+',
                 N'Rule21 Leasing KOV: (301-302) farkı kadar 301 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal301 += @DeltaKOVLease;

            DECLARE @RemainKOVLease DECIMAL(22,2) = @DeltaKOVLease;

            -- önce 401'den (UVLeasingBilanco kadar) düş
            IF @RemainKOVLease > 0 AND @Bal401 > 0 AND @UVLeasingBilanco > 0
            BEGIN
                -- 401'den maksimum düşülecek tutar, kural gereği UVLeasingBilanco ile sınırlı
                SET @tmpAmount = @RemainKOVLease;
                IF @tmpAmount > @UVLeasingBilanco SET @tmpAmount = @UVLeasingBilanco;
                IF @tmpAmount > @Bal401 SET @tmpAmount = @Bal401;

                IF @tmpAmount > 0
                BEGIN
                    SET @tmpAmountNeg = -@tmpAmount;

                    EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                            @RuleId = @RuleId,
                            @AccountNumber = @AccountNumber,
                            @Period = @Period,
                            @FinancialItemDefinitionId = @FID401,
                            @Amount = @tmpAmountNeg,
                            @UserName = @UserName,
                            @HostName = @HostName,
                            @HostIP = @HostIP;

                    EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID401,N'401',@tmpAmount,'-',
                         N'Rule21 Leasing KOV: 401 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                    EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID401,N'401',@tmpAmount,'-',
                         N'Rule21 Leasing KOV: 401 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                    SET @Bal401 -= @tmpAmount;
                    SET @RemainKOVLease -= @tmpAmount;
                END
            END

            -- sonra 331
            IF @RemainKOVLease > 0 AND @Bal331 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVLease > @Bal331 THEN @Bal331 ELSE @RemainKOVLease END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID331,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Leasing KOV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Leasing KOV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal331 -= @tmpAmount;
                SET @RemainKOVLease -= @tmpAmount;
            END

            -- sonra 431
            IF @RemainKOVLease > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVLease > @Bal431 THEN @Bal431 ELSE @RemainKOVLease END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID431,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Leasing KOV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Leasing KOV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainKOVLease -= @tmpAmount;
            END

            -- kalan 198'ya
            IF @RemainKOVLease > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainKOVLease,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVLease,'+',
                     N'Rule21 Leasing KOV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVLease,'+',
                     N'Rule21 Leasing KOV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainKOVLease;
            END
        END

        ----------------------------------------------------------
        -- 4) LEASING RİSKLERİ - UV
        ----------------------------------------------------------
        -- burada UVLeasingBilanco'yu tekrar kullan diyor kural, yukarıda zaten hesaplandı
        IF @UVLeasingMemzuc > @UVLeasingBilanco
        BEGIN
            DECLARE @DeltaUVLease DECIMAL(22,2) = @UVLeasingMemzuc - @UVLeasingBilanco;

            -- 401'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID401,
                    @Amount = @DeltaUVLease,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID401,N'401',@DeltaUVLease,'+',
                 N'Rule21 Leasing UV: Uzun risk farkı kadar 401 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID401,N'401',@DeltaUVLease,'+',
                 N'Rule21 Leasing UV: Uzun risk farkı kadar 401 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal401 += @DeltaUVLease;

            DECLARE @RemainUVLease DECIMAL(22,2) = @DeltaUVLease;

            -- 331
            IF @RemainUVLease > 0 AND @Bal331 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainUVLease > @Bal331 THEN @Bal331 ELSE @RemainUVLease END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID331,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Leasing UV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Leasing UV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal331 -= @tmpAmount;
                SET @RemainUVLease -= @tmpAmount;
            END

            -- 431
            IF @RemainUVLease > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainUVLease > @Bal431 THEN @Bal431 ELSE @RemainUVLease END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID431,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Leasing UV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Leasing UV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainUVLease -= @tmpAmount;
            END

            -- kalan 198
            IF @RemainUVLease > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainUVLease,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainUVLease,'+',
                     N'Rule21 Leasing UV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainUVLease,'+',
                     N'Rule21 Leasing UV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainUVLease;
            END
        END

        ----------------------------------------------------------
        -- 5) FAKTORİNG RİSKLERİ - KOV
        ----------------------------------------------------------
        IF @KOVFaktoringMemzuc > @Bal307
        BEGIN
            DECLARE @DeltaKOVFakt DECIMAL(22,2) = @KOVFaktoringMemzuc - @Bal307;

            -- 307'ye ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID307,
                    @Amount = @DeltaKOVFakt,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID307,N'307',@DeltaKOVFakt,'+',
                 N'Rule21 Faktoring KOV: (307) farkı kadar 307 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID307,N'307',@DeltaKOVFakt,'+',
                 N'Rule21 Faktoring KOV: (307) farkı kadar 307 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal307 += @DeltaKOVFakt;

            DECLARE @RemainKOVFakt DECIMAL(22,2) = @DeltaKOVFakt;

            -- 409'dan düş
            IF @RemainKOVFakt > 0 AND @Bal409 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVFakt > @Bal409 THEN @Bal409 ELSE @RemainKOVFakt END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID409,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID409,N'409',@tmpAmount,'-',
                     N'Rule21 Faktoring KOV: 409 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID409,N'409',@tmpAmount,'-',
                     N'Rule21 Faktoring KOV: 409 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal409 -= @tmpAmount;
                SET @RemainKOVFakt -= @tmpAmount;
            END

            -- 331
            IF @RemainKOVFakt > 0 AND @Bal331 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVFakt > @Bal331 THEN @Bal331 ELSE @RemainKOVFakt END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID331,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Faktoring KOV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Faktoring KOV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal331 -= @tmpAmount;
                SET @RemainKOVFakt -= @tmpAmount;
            END

            -- 431
            IF @RemainKOVFakt > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainKOVFakt > @Bal431 THEN @Bal431 ELSE @RemainKOVFakt END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID431,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Faktoring KOV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Faktoring KOV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainKOVFakt -= @tmpAmount;
            END

            -- kalan 198
            IF @RemainKOVFakt > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainKOVFakt,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVFakt,'+',
                     N'Rule21 Faktoring KOV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVFakt,'+',
                     N'Rule21 Faktoring KOV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainKOVFakt;
            END
        END

        ----------------------------------------------------------
        -- 6) FAKTORİNG RİSKLERİ - UV
        ----------------------------------------------------------
        IF @UVFaktoringMemzuc > @Bal409
        BEGIN
            DECLARE @DeltaUVFakt DECIMAL(22,2) = @UVFaktoringMemzuc - @Bal409;

            -- 409'a ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID409,
                    @Amount = @DeltaUVFakt,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID409,N'409',@DeltaUVFakt,'+',
                 N'Rule21 Faktoring UV: Uzun risk farkı kadar 409 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID409,N'409',@DeltaUVFakt,'+',
                 N'Rule21 Faktoring UV: Uzun risk farkı kadar 409 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal409 += @DeltaUVFakt;

            DECLARE @RemainUVFakt DECIMAL(22,2) = @DeltaUVFakt;

            -- 331
            IF @RemainUVFakt > 0 AND @Bal331 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainUVFakt > @Bal331 THEN @Bal331 ELSE @RemainUVFakt END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID331,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Faktoring UV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID331,N'331',@tmpAmount,'-',
                     N'Rule21 Faktoring UV: 331 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal331 -= @tmpAmount;
                SET @RemainUVFakt -= @tmpAmount;
            END

            -- 431
            IF @RemainUVFakt > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainUVFakt > @Bal431 THEN @Bal431 ELSE @RemainUVFakt END;
                SET @tmpAmountNeg = -@tmpAmount;

                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID431,
                        @Amount = @tmpAmountNeg,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Faktoring UV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',
                     N'Rule21 Faktoring UV: 431 hesaptan düşüldü.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainUVFakt -= @tmpAmount;
            END

            -- kalan 198
            IF @RemainUVFakt > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainUVFakt,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainUVFakt,'+',
                     N'Rule21 Faktoring UV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainUVFakt,'+',
                     N'Rule21 Faktoring UV: artan tutar 198 aktifleştirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainUVFakt;
            END
        END

   
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_22]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_22]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FID320 INT, @FID159 INT;

    -- FID değerlerini al
    SELECT
        @FID320 = NULLIF(MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID159 = NULLIF(MAX(CASE WHEN Code = N'159' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('320', '159');

    IF @FID320 IS NULL OR @FID159 IS NULL
	BEGIN
        RAISERROR('Gerekli FinancialItemDefinition (320, 159) bulunamadı.', 16, 1);
		RETURN
    END
    DECLARE @AnaA_Credit DECIMAL(22,2), @AltA_Credit DECIMAL(22,2), @Fark DECIMAL(22,2);

    -- Ana hesap (320) alacak bakiyesi
    SELECT @AnaA_Credit = ISNULL(CreditBalance,0)
    FROM ALT.CustomerDetailedTrialBalance
    WHERE AccountNumber = @AccountNumber
      AND Period        = @Period
      AND AccountCode   = '320';

    -- Alt hesapların alacak toplamı (leaf)
    SELECT @AltA_Credit = ISNULL(SUM(s.CreditSum_Leaves),0)
    FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, '320', 1,NULL) s;

    -- Fark
    SET @Fark = @AltA_Credit - @AnaA_Credit; 

    IF @Fark <> 0
    BEGIN
        -- HISTORY (yalnızca bu bölüm güncellendi)
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID320, N'320', @Fark, '+',N'Rule22: 320 ters bakiye farkı eklendi.', @UserName, @HostName, @HostIP; 
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID159, N'159', @Fark, '+',N'Rule22: 320 ters bakiye farkı aktifte 159 hesabına eklendi.', @UserName, @HostName, @HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID320, N'320', @Fark, '+',N'Rule22: 320 ters bakiye farkı eklendi.', @UserName, @HostName, @HostIP; 
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID159, N'159', @Fark, '+',N'Rule22: 320 ters bakiye farkı aktifte 159 hesabına eklendi.', @UserName, @HostName, @HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID320,
														   @Amount = @Fark,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID159,
														   @Amount = @Fark,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_23]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_23]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FID331 INT, @FID431 INT, @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2);

    -- FID değerlerini al
    SELECT
        @FID331 = NULLIF(MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId END),0),
        @FID431 = NULLIF(MAX(CASE WHEN Code = N'431' THEN FinancialItemDefinitionId END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('331', '431');

    IF @FID331 IS NULL OR @FID431 IS NULL
	BEGIN
	 RAISERROR('Gerekli FinancialItemDefinition (331, 431) bulunamadı.', 16, 1);
	 RETURN
    END
        

    -- 331 bakiyesi
    SELECT @Amt = ISNULL(SUM(CorrectedValue),0)
    FROM ALT.AutoTransferCleansing
    WHERE AccountNumber=@AccountNumber AND Period=@Period
      AND FinancialItemDefinitionId = @FID331; 

    IF @Amt <> 0
    BEGIN
	   SET @AmtNeg = -@Amt
        -- HISTORY (yalnızca bu bölüm güncellendi)
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID331, N'331', @Amt, N'-',
             N'Rule23: 331 hesabından çıkarıldı.', @UserName, @HostName, @HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID431, N'431', @Amt, N'+',
             N'Rule23: 331 hesabından 431 hesabına aktarıldı.', @UserName, @HostName, @HostIP;

	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID331, N'331', @Amt, N'-',
             N'Rule23: 331 hesabından çıkarıldı.', @UserName, @HostName, @HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID431, N'431', @Amt, N'+',
             N'Rule23: 331 hesabından 431 hesabına aktarıldı.', @UserName, @HostName, @HostIP;

         EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID331,
														   @Amount = @AmtNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID431,
														   @Amount = @Amt,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
	 
    END
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_24]    Script Date: 13/11/2025 9:23:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_24]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period        INT,
    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    /* Yalnızca 2023 yılsonu dönemleri: 202341 ve 202342 */
    IF (@Period NOT IN (202341, 202342))
        RETURN;

    DECLARE
        @FID692 INT, @FID590 INT, @FID580 INT, @FID591 INT, @FID570 INT;

    /* FinancialItemDefinition Id’leri (kod -> FID) */
    SELECT
        @FID692 = NULLIF(MAX(CASE WHEN Code='692' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID590 = NULLIF(MAX(CASE WHEN Code='590' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID580 = NULLIF(MAX(CASE WHEN Code='580' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID591 = NULLIF(MAX(CASE WHEN Code='591' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID570 = NULLIF(MAX(CASE WHEN Code='570' THEN FinancialItemDefinitionId ELSE 0 END), 0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('692','590','580','591','570');

    IF @FID692 IS NULL OR @FID590 IS NULL OR @FID580 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL
    BEGIN
        RAISERROR('usp_ApplyRule_24 failed: Gerekli FinancialItemDefinition (692,590,580,591,570) bulunamadi.', 16, 1);
        RETURN;
    END

    /* BDR/Beyanname verisinden #692 değeri (OriginalValue esas alındı) */
    DECLARE @Val692 DECIMAL(22,2) = 0;

    SELECT @Val692 = COALESCE(SUM(OriginalValue), 0.0)
    FROM ALT.CustomerFinancialItem WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber
      AND PeriodId=@Period
      AND FinancialItemDefinitionId=@FID692;

    IF @Val692 = 0
        RETURN;  -- İşlem yok

    /* Yardımcı: Hedef hesaba ekleme + log */
    DECLARE @Now DATETIME = GETDATE();

    /* Pozitif senaryo: #692 > 0 => 590 ve 580'e ekle */
    IF @Val692 > 0
    BEGIN
        -- 590
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID590,
														   @Amount = @Val692,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        
        -- 580
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID580,
														   @Amount = @Val692,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
     


        -- HISTORY (değiştirilen bölüm)
		 
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID590, N'590', @Val692, N'+',
             N'Rule24: #692>0 => 590 hesaba eklendi.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID580, N'580', @Val692, N'+',
             N'Rule24: #692>0 => 580 hesaba eklendi.', @UserName, @HostName, @HostIP;


	     EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID590, N'590', @Val692, N'+',
             N'Rule24: #692>0 => 590 hesaba eklendi.', @UserName, @HostName, @HostIP;
         EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID580, N'580', @Val692, N'+',
             N'Rule24: #692>0 => 580 hesaba eklendi.', @UserName, @HostName, @HostIP;


    END
    ELSE
    BEGIN
        /* Negatif senaryo: #692 < 0 => 591 ve 570'e |#692| ekle (pozitif tutar) */
        DECLARE @Abs692 DECIMAL(22,2) = ABS(@Val692);

        -- 591
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID591,
														   @Amount = @Abs692,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
       
        -- 570
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID570,
														   @Amount = @Abs692,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
       
        

		-- HISTORY (değiştirilen bölüm)
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID591, N'591', @Abs692, N'+',
             N'Rule24: #692<0 => 591 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;


        -- HISTORY (değiştirilen bölüm)
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID570, N'570', @Abs692, N'+',
             N'Rule24: #692<0 => 570 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;

	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID591, N'591', @Abs692, N'+',
             N'Rule24: #692<0 => 591 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;


        -- HISTORY (değiştirilen bölüm)
        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID570, N'570', @Abs692, N'+',
             N'Rule24: #692<0 => 570 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;

    END 
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_25]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_25]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period      INT,
    @UserName VARCHAR(10) = NULL,  
	@HostName VARCHAR(20) = NULL,  
	@HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;
    

        DECLARE @FID648 INT, @FID658 INT, @FID590 INT, @FID591 INT, @FID570 INT,@FID580 INT;
        DECLARE @Amt648 DECIMAL(22,2), @Amt658 DECIMAL(22,2), @Amt590 DECIMAL(22,2), @Amt591 DECIMAL(22,2),@Amt580 DECIMAL(22,2);

        -- FID değerlerini al
        SELECT
            @FID648 = NULLIF(MAX(CASE WHEN Code = N'648' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID658 = NULLIF(MAX(CASE WHEN Code = N'658' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID590 = NULLIF(MAX(CASE WHEN Code = N'590' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID591 = NULLIF(MAX(CASE WHEN Code = N'591' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID570 = NULLIF(MAX(CASE WHEN Code = N'570' THEN FinancialItemDefinitionId ELSE 0 END), 0),
			@FID580 = NULLIF(MAX(CASE WHEN Code = N'580' THEN FinancialItemDefinitionId ELSE 0 END), 0)
        FROM  ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('648', '658', '590', '591', '570','580');

        IF @FID648 IS NULL OR @FID658 IS NULL OR @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL
		BEGIN
        	RAISERROR('Gerekli FinancialItemDefinition (648, 658, 590, 591, 570) bulunamadı.', 16, 1);
			RETURN
        END
            

        -- Mevcut bakiyeleri çek
        SELECT @Amt648 = ISNULL(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID648;

        SELECT @Amt658 = ISNULL(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID658;

        SELECT @Amt590 = ISNULL(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID590;

        SELECT @Amt591 = ISNULL(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE  AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID591;

		SELECT @Amt580 = ISNULL(SUM(CorrectedValue),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE  AccountNumber=@AccountNumber AND Period=@Period AND FinancialItemDefinitionId=@FID580;


        -- Öncelikle 648 ve 658 karşılıklı mahsup
        IF @Amt648>0 AND @Amt658>0
        BEGIN
            DECLARE @MinAmt DECIMAL(22,2) = IIF(@Amt648<@Amt658,@Amt648,@Amt658);

            EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID648,'648',@MinAmt,'-',N'Rule25: 648 ve 658 mahsup',@UserName,@HostName,@HostIP;
            EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID658,'658',@MinAmt,'-',N'Rule25: 648 ve 658 mahsup',@UserName,@HostName,@HostIP;

            SET @Amt648 = @Amt648 - @MinAmt;
            SET @Amt658 = @Amt658 - @MinAmt;
        END

        -- 648 işlemleri
        IF @Amt648>0
        BEGIN
            IF @Amt648 <= @Amt590
            BEGIN
                -- 648-590'dan düş, 570'e ekle
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID648,'648',@Amt648,'-',N'Rule25: 648 için 648 düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Amt648,'-',N'Rule25: 648 için 590 düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Amt648,'+',N'Rule25: 648 için 570 eklendi',@UserName,@HostName,@HostIP;
            END
            ELSE
            BEGIN
                -- 590'ı sıfırla, farkı 591'e ekle
                IF @Amt590>0
                    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Amt590,'-',N'Rule25: 648 için 590 sıfırlandı',@UserName,@HostName,@HostIP;

                DECLARE @Diff648 DECIMAL(22,2) = @Amt648 - @Amt590;

                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Diff648,'+',N'Rule25: 648 için fark 591 eklendi',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID648,'648',@Amt648,'-',N'Rule25: 648 için 648 eksiltildi',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Amt648,'+',N'Rule25: 648 için 570 eklendi',@UserName,@HostName,@HostIP;
            END
        END

        -- 658 işlemleri
        IF @Amt658>0
        BEGIN
            IF @Amt658 <= @Amt591
            BEGIN
                -- 591 ve 570'ten düş 580 e ekle
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Amt658,'-',N'Rule25: 658 için 591 düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Amt658,'-',N'Rule25: 658 için 570 düşüldü',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID580,'580',@Amt658,'+',N'Rule25: 658 için 580 eklendi',@UserName,@HostName,@HostIP;
            END
            ELSE
            BEGIN
                -- 591'ı sıfırla, farkı 590'a ekle
                IF @Amt591>0
                    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Amt591,'-',N'Rule25: 658 için 591 sıfırlandı',@UserName,@HostName,@HostIP;

                DECLARE @Diff658 DECIMAL(22,2) = @Amt658 - @Amt591;

                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Diff658,'+',N'Rule25: 658 için fark 590 eklendi',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID658,'658',@Amt658,'-',N'Rule25: 658 için 658 düşüldü',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID580,'580',@Amt658,'+',N'Rule25: 658 için 580 eklendi',@UserName,@HostName,@HostIP;
            END
        END 
       
END;

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_26]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_26]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period      INT,
    @UserName VARCHAR(10) = NULL,  
	@HostName VARCHAR(20) = NULL,  
	@HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;
    
        DECLARE 
            @FID590 INT, @FID591 INT,@FID580 INT,@FID570 INT,@FID692 INT;

        -- FID'leri çek
        SELECT
            @FID590 = NULLIF(MAX(CASE WHEN Code = '590' THEN FinancialItemDefinitionId END),0),
            @FID591 = NULLIF(MAX(CASE WHEN Code = '591' THEN FinancialItemDefinitionId END),0),
            @FID570 = NULLIF(MAX(CASE WHEN Code = '570' THEN FinancialItemDefinitionId END),0),
			@FID580 = NULLIF(MAX(CASE WHEN Code = '580' THEN FinancialItemDefinitionId END),0),
			@FID692 = NULLIF(MAX(CASE WHEN Code = '692' THEN FinancialItemDefinitionId END),0)
        FROM  ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('590','591','570','580','692');

        IF @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL OR @FID580 IS NULL OR @FID692 IS NULL 
        BEGIN
            RAISERROR('Rule26: Gerekli FinancialItemDefinition (590,591,570,580,692) bulunamadı.', 16, 1);
			RETURN
        END

        DECLARE @Amt590 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM ALT.AutoTransferCleansing
                                                WHERE  AccountNumber=@AccountNumber AND Period=@Period
                                                  AND FinancialItemDefinitionId=@FID590),0);

        DECLARE @Amt591 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM ALT.AutoTransferCleansing
                                                WHERE AccountNumber=@AccountNumber AND Period=@Period
                                                  AND FinancialItemDefinitionId=@FID591),0);

        DECLARE @Amt580 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM ALT.AutoTransferCleansing
                                                WHERE AccountNumber=@AccountNumber AND Period=@Period
                                                  AND FinancialItemDefinitionId=@FID580),0);

  

        DECLARE @Amt692 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM ALT.AutoTransferCleansing
                                                WHERE AccountNumber=@AccountNumber AND Period=@Period
                                                  AND FinancialItemDefinitionId=@FID692),0);



		IF @Amt692>=0 
		BEGIN  
        	 -- 1) 590 > 692 → fark kadar 590’dan eksilt, 570’e ekle
			IF @Amt590 > @Amt692
			BEGIN
				DECLARE @Diff1 DECIMAL(22,2) = @Amt590 - @Amt692;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Diff1,'-',N'Rule26: 590 > 692 fark',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Diff1,'+',N'Rule26: 590 > 692 fark',@UserName,@HostName,@HostIP;
			END

			-- 2) 590 < 692 → fark kadar 689 ve c2’ye ekle
			IF @Amt590 < @Amt692
			BEGIN
				DECLARE @Diff2 DECIMAL(22,2) = @Amt692 - @Amt590;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Diff2,'+',N'Rule26: 590 < 692 fark',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID580,'580',@Diff2,'+',N'Rule26: 590 < 692 fark',@UserName,@HostName,@HostIP;
			END

        END
		ELSE
		BEGIN
		    -- 3) 591 + 692 > 0 → toplam kadar 689 ve c2’ye ekle
			IF (@Amt591 + @Amt692) > 0
			BEGIN
				DECLARE @Diff3 DECIMAL(22,2) = @Amt591 + @Amt692;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Diff3,'-',N'Rule26: 591 + 692 > 0',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID580,'580',@Diff3,'+',N'Rule26: 591 + 692 > 0',@UserName,@HostName,@HostIP;
			END

			-- 4) 591 + 692 < 0 → abs(toplam) kadar 591 ve 570’e ekle
			IF (@Amt591 + @Amt692) < 0
			BEGIN
				DECLARE @Diff4 DECIMAL(22,2) = ABS(@Amt591 + @Amt692);
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID591,'591',@Diff4,'+',N'Rule26: 591 + 692 < 0',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID570,'570',@Diff4,'+',N'Rule26: 591 + 692 < 0',@UserName,@HostName,@HostIP;
			END
		END
END;

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_27]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE   PROCEDURE [ALT].[upd_ATC_ApplyRule_27]
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @AccountNumber INT,
    @Period      INT,
    @UserName VARCHAR(10) = NULL,  
	@HostName VARCHAR(20) = NULL,  
	@HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;
    

        DECLARE 
            @FID590 INT, @FID591 INT, @FID570 INT, @FID679 INT,@FID549 INT;
        DECLARE @Amt NUMERIC(22,2)

        -- FID'ler
        SELECT
            @FID590 = NULLIF(MAX(CASE WHEN Code = N'590' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID591 = NULLIF(MAX(CASE WHEN Code = N'591' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID570 = NULLIF(MAX(CASE WHEN Code = N'570' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID679 = NULLIF(MAX(CASE WHEN Code = N'679' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID549 = NULLIF(MAX(CASE WHEN Code = N'549' THEN FinancialItemDefinitionId ELSE 0 END),0)
        FROM  ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN (N'549',N'590',N'591',N'570',N'679');

        IF @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL OR @FID679 IS NULL
            RAISERROR('Rule27: Gerekli FID (549,590,591,570,679) bulunamadı.', 16, 1);

        /* 679 ağacındaki LEAF hesapları bul ve isim filtreleriyle topla */
        WITH Tree AS (
            SELECT d.AccountCode, d.ParentAccountCode, d.AccountDescription,
                   CAST(ISNULL(d.Credit,0) AS DECIMAL(22,2)) AS CreditBalance
            FROM ALT.CustomerDetailedTrialBalance d WITH (NOLOCK)
            WHERE d.AccountNumber=@AccountNumber AND d.Period=@Period AND d.AccountCode = N'679'
            UNION ALL
            SELECT c.AccountCode, c.ParentAccountCode, c.AccountDescription,
                   CAST(ISNULL(c.Credit,0) AS DECIMAL(22,2))
            FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
            JOIN Tree t
              ON c.AccountNumber=@AccountNumber AND c.Period=@Period
             AND c.ParentAccountCode = t.AccountCode
        ),
        Leaves AS (
            SELECT t.*
            FROM Tree t
            WHERE NOT EXISTS (
                SELECT 1 FROM ALT.CustomerDetailedTrialBalance x WITH (NOLOCK)
                WHERE x.AccountNumber=@AccountNumber AND x.Period=@Period
                  AND x.ParentAccountCode = t.AccountCode
            )
        )
        SELECT @Amt = ISNULL(SUM(l.CreditBalance),0)
        FROM Leaves l
        WHERE l.AccountDescription LIKE N'%sat geri kirala%'
           OR l.AccountDescription LIKE N'%sale and leaseback%'
           OR l.AccountDescription LIKE N'%leaseback%';

        IF @Amt > 0
        BEGIN
            DECLARE @Bal590 DECIMAL(22,2) =
                ISNULL((
                    SELECT SUM(CorrectedValue) 
                    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
                    WHERE AccountNumber=@AccountNumber AND Period=@Period
                      AND FinancialItemDefinitionId=@FID590
                ),0);

            IF @Amt <= @Bal590
            BEGIN
			    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID679,N'679',@Amt,'-',N'Rule27: Leaseback geliri kadar 679 düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,N'590',@Amt,'-',N'Rule27: Leaseback geliri kadar 590 düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID549,N'549',@Amt,'+',N'Rule27: Leaseback geliri kadar 549 eklendi',@UserName,@HostName,@HostIP;
            END
            ELSE
            BEGIN
                DECLARE @Diff DECIMAL(22,2) = @Amt - @Bal590;
			    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID679,N'679',@Amt,'-',N'Rule27: Leaseback geliri kadar 679 düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,N'590',@Bal590,'-',N'Rule27: Leaseback → 590 eldeki kadar düşüldü',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,N'591',@Diff,'+',N'Rule27: Leaseback farkı 591''e eklendi',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID549,N'549',@Amt,'+',N'Rule27: Leaseback toplamı 549''e eklendi',@UserName,@HostName,@HostIP;
            END
        END 
END;

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_ApplyRule_SendData]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_SendData]
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id (bilgi amaçlı)
    @AccountNumber INT,
    @Period        INT,
    @UserName      VARCHAR(10) = NULL,
    @HostName      VARCHAR(20) = NULL,
    @HostIP        VARCHAR(15) = NULL
AS
BEGIN
    -----------------------------------------
    -- 1) Kaynak: AutoTransferCleansing -> #Src
    -----------------------------------------
    IF OBJECT_ID('tempdb..#Src') IS NOT NULL DROP TABLE #Src;

    SELECT
        a.FirmType,
        a.GroupNumber,
        a.AccountNumber,
        PeriodId = a.[Period],
        a.FinancialItemDefinitionId,
        OriginalValue  = SUM(a.OriginalValue),
        CorrectedValue = SUM(ISNULL(a.CorrectedValue, a.OriginalValue))
    INTO #Src
    FROM ALT.AutoTransferCleansing a WITH (NOLOCK)
    WHERE  a.AccountNumber = @AccountNumber
      AND a.[Period]      = @Period
      AND a.FinancialItemDefinitionId IS NOT NULL
    GROUP BY a.FirmType, a.GroupNumber, a.AccountNumber, a.[Period], a.FinancialItemDefinitionId;

    -- (Opsiyonel) Hız için indeks
    -- CREATE CLUSTERED INDEX IX_Src_Key ON #Src(FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId);

    -----------------------------------------
    -- 2) UPDATE: Her iki tabloda da aynı kayıt varsa güncelle
    --    (gereksiz yazmayı önlemek için farklılık kontrolü ile)
    -----------------------------------------
    IF OBJECT_ID('tempdb..#ToUpdate') IS NOT NULL DROP TABLE #ToUpdate;

    SELECT
        T.CustomerFinancialItemId,
        S.OriginalValue,
        S.CorrectedValue
    INTO #ToUpdate
    FROM ALT.CustomerFinancialItem T WITH (NOLOCK)
    JOIN #Src S
      ON  T.FirmType                  = S.FirmType
      AND T.GroupNumber               = S.GroupNumber
      AND T.AccountNumber             = S.AccountNumber
      AND T.PeriodId                  = S.PeriodId
      AND T.FinancialItemDefinitionId = S.FinancialItemDefinitionId
    WHERE ISNULL(T.OriginalValue ,0) <> ISNULL(S.OriginalValue ,0)
       OR ISNULL(T.CorrectedValue,0) <> ISNULL(S.CorrectedValue,0);

    UPDATE T
       SET T.OriginalValue    = U.OriginalValue,
           T.CorrectedValue   = U.CorrectedValue,
           T.UpdateUserName   = @UserName,
           T.UpdateHostName   = @HostName,
           T.UpdateSystemDate = GETDATE(),
           T.HostIP           = @HostIP
    FROM ALT.CustomerFinancialItem T
    JOIN #ToUpdate U
      ON T.CustomerFinancialItemId = U.CustomerFinancialItemId;

    -----------------------------------------
    -- 3) INSERT: Hedefte olmayan + (OV,CV) ikisi birden 0 değilse
    --    (0,0 olan yeni kayıtlar HARİÇ)
    -----------------------------------------
    IF OBJECT_ID('tempdb..#ToInsert') IS NOT NULL DROP TABLE #ToInsert;

    SELECT
        S.FirmType,
        S.GroupNumber,
        S.AccountNumber,
        S.PeriodId,
        S.FinancialItemDefinitionId,
        S.OriginalValue,
        S.CorrectedValue
    INTO #ToInsert
    FROM #Src S
    LEFT JOIN ALT.CustomerFinancialItem T WITH (NOLOCK)
      ON  T.FirmType                  = S.FirmType
      AND T.GroupNumber               = S.GroupNumber
      AND T.AccountNumber             = S.AccountNumber
      AND T.PeriodId                  = S.PeriodId
      AND T.FinancialItemDefinitionId = S.FinancialItemDefinitionId
    WHERE T.CustomerFinancialItemId IS NULL
      AND (ISNULL(S.OriginalValue,0) <> 0 OR ISNULL(S.CorrectedValue,0) <> 0);  -- (0,0) HARİÇ

    INSERT INTO ALT.CustomerFinancialItem
    (
        FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId,
        OriginalValue, CorrectedValue,
        WorkflowInstanceId, UserName, HostName, SystemDate, HostIP
    )
    SELECT
        FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId,
        OriginalValue, CorrectedValue,
        NULL, @UserName, @HostName, GETDATE(), @HostIP
    FROM #ToInsert;
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_Discount_00]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Tenzilat spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE PROCEDURE [ALT].[upd_ATC_Discount_00] (
    @RuleId        INT,  
	@GroupNumber INT,
	@Period INT,
	@UserName VARCHAR(10) = NULL,
	@HostName VARCHAR(20) = NULL,
	@HostIP VARCHAR(15) = NULL)
AS
BEGIN
			SET NOCOUNT ON;
			-- Mevcut kayıtları sil (aynı müşteri + dönem)
			DELETE FROM ALT.AutoTransferCleansing
			 WHERE AccountNumber = @GroupNumber
			   AND Period = @Period;
			-- Insert işlemi

			INSERT INTO ALT.AutoTransferCleansing (FirmType,
												   GroupNumber,
												   AccountNumber,
												   Period,
												   FinancialItemDefinitionId,
												   OriginalValue,
												   CorrectedValue,
												   UserName,
												   HostName,
												   HostIP,
												   SystemDate)
			SELECT 2,				    
				   @GroupNumber,
				   0,
				   @Period,
				   F.FinancialItemDefinitionId,
				   0 AS OriginalValue,
				   0 AS CorrectedValue,
				   @UserName,
				   @HostName,
				   @HostIP,
				   GETDATE()
			  FROM ALT.FinancialItemDefinition F WITH (NOLOCK)
			 WHERE F.BalanceSheet = 1
			   AND NOT EXISTS (SELECT 1 FROM ALT.CustomerFinancialItem C WITH (NOLOCK) WHERE C.FirmType = 2
					  AND C.GroupNumber = @GroupNumber
					  AND C.AccountNumber = 0
					  AND C.PeriodId = @Period
					  AND C.FinancialItemDefinitionId = F.FinancialItemDefinitionId);

			-- 3. Mevcut olanlar için değerli insert
			INSERT INTO ALT.AutoTransferCleansing (FirmType,
												   GroupNumber,
												   AccountNumber,
												   Period,
												   FinancialItemDefinitionId,
												   OriginalValue,
												   CorrectedValue,
												   UserName,
												   HostName,
												   HostIP,
												   SystemDate)
			SELECT FirmType,
				   GroupNumber,
				   AccountNumber,
				   PeriodId,
				   FinancialItemDefinitionId,
				   OriginalValue,
				   OriginalValue,
				   @UserName,
				   @HostName,
				   @HostIP,
				   GETDATE()
			  FROM ALT.CustomerFinancialItem WITH (NOLOCK)
			 WHERE FirmType = 2
			   AND AccountNumber = 0
			   AND GroupNumber = @GroupNumber
			   AND PeriodId = @Period;




			DECLARE @MasterId INT
			SELECT @MasterId = ficm.FinancialDiscountMasterId
			  FROM boa.ALT.FinancialDiscountMaster ficm WITH (NOLOCK)
			 WHERE ficm.GroupNumber = @GroupNumber
			   AND ficm.PeriodId = @Period
			  
			IF @MasterId IS NOT NULL
			BEGIN
				DELETE FROM ALT.FinancialDiscount
				 WHERE  FinancialDiscountMasterId = @MasterId
				DELETE FROM ALT.FinancialDiscountMaster
				 WHERE FinancialDiscountMasterId = @MasterId
			END
			INSERT INTO ALT.FinancialDiscountMaster (GroupNumber,
													 PeriodId,
													 [Description],
													 UserName,
													 HostName,
													 SystemDate,
													 HostIP)
			VALUES (@GroupNumber, @Period, 'Otomatik tenzilat sistemi',@UserName, @HostName, GETDATE(), @HostIP);
		
END;

GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_Discount_01]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Tenzilat spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE PROCEDURE [ALT].[upd_ATC_Discount_01]
( 
        @RuleId      INT,  
        @GroupNumber INT		 ,
		@Period		 INT		 ,
		@UserName	 VARCHAR(10) = NULL,
		@HostName	 VARCHAR(20) = NULL,
		@HostIP		 VARCHAR(15) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	/* 1) Grup firmalarını hazırla (#GroupInfo) */
	IF OBJECT_ID('tempdb..#GroupInfo') IS NOT NULL
		DROP TABLE #GroupInfo;

	CREATE TABLE #GroupInfo (FirmType TINYINT NOT NULL,
							 AccountNumber INT NOT NULL,
							 GroupNumber INT NOT NULL,
							 AllotmentMainId INT NOT NULL,
							 Consolidation BIT NOT NULL,
							 ConsolidationPercent DECIMAL(9, 2) NOT NULL,
							 EffectiveFirm BIT NOT NULL,
							 PubliclyTradedRatio DECIMAL(9, 2) NOT NULL,
							 BalanceSheet BIT NOT NULL,
							 FirmTitle VARCHAR(4000) NOT NULL);

	INSERT INTO #GroupInfo (FirmType,
							AccountNumber,
							GroupNumber,
							AllotmentMainId,
							Consolidation,
							ConsolidationPercent,
							EffectiveFirm,
							PubliclyTradedRatio,
							BalanceSheet,
							FirmTitle)
	SELECT ci.FirmType,
		   ci.AccountNumber,
		   ci.GroupNumber,
		   ci.AllotmentMainId,
		   ci.Consolidation,
		   ci.ConsolidationPercent,
		   ci.EffectiveFirm,
		   ci.PubliclyTradedRatio,
		   ci.BalanceSheet,
		   c.CustomerName AS FirmTitle
	  FROM ALT.fGetCustomerInfo(@GroupNumber, NULL, NULL) ci
	  INNER JOIN boa.cus.Customer c WITH (NOLOCK)
		ON c.Customerid = ci.AccountNumber
	 WHERE ci.Consolidation = 1;

	/* 2) FID’ler */
	DECLARE @FID240 INT,
			@FID242 INT,
			@FID245 INT,
			@FID500 INT;

	SELECT @FID240 = NULLIF(MAX(CASE
						 WHEN Code = N'240' THEN FinancialItemDefinitionId
						 ELSE 0 END), 0),
		   @FID242 = NULLIF(MAX(CASE
						 WHEN Code = N'242' THEN FinancialItemDefinitionId
						 ELSE 0 END), 0),
		   @FID245 = NULLIF(MAX(CASE
						 WHEN Code = N'245' THEN FinancialItemDefinitionId
						 ELSE 0 END), 0),
		   @FID500 = NULLIF(MAX(CASE
						 WHEN Code = N'500' THEN FinancialItemDefinitionId
						 ELSE 0 END), 0)
	  FROM ALT.FinancialItemDefinition WITH (NOLOCK);

	IF @FID240 IS NULL
	OR @FID242 IS NULL
	OR @FID245 IS NULL
	OR @FID500 IS NULL
	BEGIN
		RAISERROR ('FinancialItemDefinition (240,242,245,500) eksik.', 16, 1);
		IF @@TRANCOUNT > 0
			ROLLBACK;
		RETURN;
	END;

	/* 3) A×B×kök eşleşmeleri (yalnızca yapraklar) */
	;
	WITH ASet
	  AS (SELECT DISTINCT g.FirmType,
						  g.AccountNumber,
						  g.FirmTitle FROM #GroupInfo g),
	  BSet
	  AS (SELECT DISTINCT g.FirmType,
						  g.AccountNumber,
						  g.FirmTitle FROM #GroupInfo g),
	  Roots
	  AS (SELECT CAST('240' AS NVARCHAR(3)) AS RootCode
		  UNION ALL
		  SELECT '242'
		  UNION ALL
		  SELECT '245'),
	  MatchesRaw
	  AS (SELECT a.FirmType AS AFirmType,
				 a.AccountNumber AS AAccountNumber,
				 a.FirmTitle AS ATitle,
				 b.FirmType AS BFirmType,
				 b.AccountNumber AS BAccountNumber,
				 [ALT].[fGetNormalizeTitle_ATC](b.FirmTitle) AS BTitle,
				 r.RootCode,
				 tvf.DebitSum_Leaves,
				 tvf.CreditSum_Leaves,
				 CAST(CASE
							   WHEN tvf.DebitSum_Leaves > 0 THEN tvf.DebitSum_Leaves
							   WHEN tvf.CreditSum_Leaves > 0 THEN tvf.CreditSum_Leaves
							   ELSE 0 END AS DECIMAL(22, 2)) AS MatchedAmount_Pos FROM ASet a
			JOIN BSet b
			  ON b.AccountNumber <> a.AccountNumber
			CROSS JOIN Roots r
			CROSS APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC(a.AccountNumber,@Period,r.RootCode,1,[ALT].[fGetNormalizeTitle_ATC](b.FirmTitle)) tvf WHERE (tvf.DebitSum_Leaves > 0 OR tvf.CreditSum_Leaves > 0)
			),
	  Matches
	  AS (SELECT AFirmType,
				 AAccountNumber,
				 ATitle,
				 BFirmType,
				 BAccountNumber,
				 BTitle,
				 RootCode,
				 SUM(MatchedAmount_Pos) AS MatchedAmount FROM MatchesRaw
		   GROUP BY AFirmType,
					AAccountNumber,
					ATitle,
					BFirmType,
					BAccountNumber,
					BTitle,
					RootCode
		  HAVING SUM(MatchedAmount_Pos) > 0)
	SELECT *
	  INTO #Matches
	  FROM Matches;

	/* #SumPerB'yi #Matches üzerinden üret */
	SELECT BFirmType,
		   BAccountNumber,
		   BTitle,
		   SUM(MatchedAmount) AS TotalAmt
	  INTO #SumPerB
	  FROM #Matches
	GROUP BY BFirmType,
			 BAccountNumber,
			 BTitle;

	/* Eşleşme yoksa çık */
	IF NOT EXISTS (SELECT 1 FROM #Matches)
	AND NOT EXISTS (SELECT 1 FROM #SumPerB)
		RETURN;

	/* 4) A tarafı: A×B×kök bazında A’nın 24x’inden düş + log */
	DECLARE @AFirmType TINYINT,
			@AAcc	   INT,
			@ATitle	   VARCHAR(4000),
			@BFirmType TINYINT,
			@BAcc	   INT,
			@BTitle	   VARCHAR(4000),
			@RootCode  NVARCHAR(3),
			@Amt	   DECIMAL(22, 2),
			@FID	   INT;

	DECLARE curA CURSOR LOCAL FAST_FORWARD FOR SELECT AFirmType,
													  AAccountNumber,
													  ATitle,
													  BFirmType,
													  BAccountNumber,
													  BTitle,
													  RootCode,
													  MatchedAmount FROM #Matches;

	OPEN curA;
	FETCH NEXT FROM curA INTO
	@AFirmType, @AAcc, @ATitle,
	@BFirmType, @BAcc, @BTitle,
	@RootCode, @Amt;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @Amt > 0
		BEGIN
			SET @FID = CASE @RootCode
									WHEN '240' THEN @FID240
									WHEN '242' THEN @FID242
									WHEN '245' THEN @FID245 END;

			DECLARE @DescA NVARCHAR(4000) =
					N'R240_242_245_vs_500: A (' + CONVERT(NVARCHAR(20), @AAcc) + N' - ' + ISNULL(@ATitle, N'') +
					N') detayında B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
					N') ünvanı tespit edildi; kök ' + @RootCode + N' hesabından düşüldü. Tutar=' + CONVERT(NVARCHAR(50), @Amt),
					@DescB NVARCHAR(4000) =
					N'R240_242_245_vs_500: B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
					N') için A firmalarının 240/242/245 yaprak eşleşmeleri toplamı 500 hesabından düşüldü. Toplam=' + CONVERT(NVARCHAR(50), @Amt);

			EXEC ALT.ins_ATC_History @RuleId = @RuleId,
									 @AccountNumber = @GroupNumber,
									 @Period = @Period,
									 @FinancialItemDefinitionId = @FID,
									 @AccountCode = @RootCode,
									 @Amount = @Amt,
									 @TransactionType = '-',
									 @Description = @DescA,
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;

			EXEC ALT.ins_ATC_History @RuleId = @RuleId,
									 @AccountNumber = @GroupNumber,
									 @Period = @Period,
									 @FinancialItemDefinitionId = @FID500,
									 @AccountCode = N'500',
									 @Amount = @Amt,
									 @TransactionType = '-',
									 @Description = @DescB,
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;

			EXEC ALT.ins_ATC_HistoryDiscount @GroupNumber = @GroupNumber,
			                         @AccountNumber = @AAcc,
									 @Period = @Period,
									 @FinancialItemDefinitionId = @FID,
									 @AccountCode = @RootCode,
									 @Amount = @Amt,
									 @TransactionType = '-',
									 @Description = @DescA,
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;
			EXEC ALT.ins_ATC_HistoryDiscount @GroupNumber = @GroupNumber,
			                         @AccountNumber = @BAcc,
									 @Period = @Period,
									 @FinancialItemDefinitionId = @FID500,
									 @AccountCode = N'500',
									 @Amount = @Amt,
									 @TransactionType = '-',
									 @Description = @DescB,
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;

			UPDATE ALT.AutoTransferCleansing
			   SET CorrectedValue = CorrectedValue - @Amt
			WHERE GroupNumber = @GroupNumber
			  AND Period = @Period
			  AND FinancialItemDefinitionId = @FID;

			UPDATE ALT.AutoTransferCleansing
			   SET CorrectedValue = CorrectedValue - @Amt
			WHERE GroupNumber = @GroupNumber
			  AND Period = @Period
			  AND FinancialItemDefinitionId = @FID500;

		END;

		FETCH NEXT FROM curA INTO
		@AFirmType, @AAcc, @ATitle,
		@BFirmType, @BAcc, @BTitle,
		@RootCode, @Amt;
	END;

	CLOSE curA;
	DEALLOCATE curA;
END;
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_Discount_02]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Tenzilat spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */

CREATE PROCEDURE [ALT].[upd_ATC_Discount_02]
(
        @RuleId      INT,
        @GroupNumber INT,
        @Period      INT,
        @UserName    VARCHAR(10) = NULL,
        @HostName    VARCHAR(20) = NULL,
        @HostIP      VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Grup firmalarını hazırla (#GroupInfo) */
    IF OBJECT_ID('tempdb..#GroupInfo') IS NOT NULL
        DROP TABLE #GroupInfo;

    CREATE TABLE #GroupInfo
    (
        FirmType              TINYINT       NOT NULL,
        AccountNumber         INT           NOT NULL,
        GroupNumber           INT           NOT NULL,
        AllotmentMainId       INT           NOT NULL,
        Consolidation         BIT           NOT NULL,
        ConsolidationPercent  DECIMAL(9,2)  NOT NULL,
        EffectiveFirm         BIT           NOT NULL,
        PubliclyTradedRatio   DECIMAL(9,2)  NOT NULL,
        BalanceSheet          BIT           NOT NULL,
        FirmTitle             VARCHAR(4000) NOT NULL
    );

    INSERT INTO #GroupInfo
    (
        FirmType, AccountNumber, GroupNumber, AllotmentMainId,
        Consolidation, ConsolidationPercent, EffectiveFirm,
        PubliclyTradedRatio, BalanceSheet, FirmTitle
    )
    SELECT
        ci.FirmType,
        ci.AccountNumber,
        ci.GroupNumber,
        ci.AllotmentMainId,
        ci.Consolidation,
        ci.ConsolidationPercent,
        ci.EffectiveFirm,
        ci.PubliclyTradedRatio,
        ci.BalanceSheet,
        c.CustomerName AS FirmTitle
    FROM ALT.fGetCustomerInfo(@GroupNumber, NULL, NULL) ci
    INNER JOIN boa.cus.Customer c WITH (NOLOCK)
        ON c.Customerid = ci.AccountNumber
    WHERE ci.Consolidation = 1;

    /* 2) FID’ler */
    DECLARE @FID241 INT,
            @FID243 INT,
            @FID246 INT,
            @FID247 INT,
            @FID501 INT;

    SELECT
        @FID241 = NULLIF(MAX(CASE WHEN Code = N'241' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID243 = NULLIF(MAX(CASE WHEN Code = N'243' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID246 = NULLIF(MAX(CASE WHEN Code = N'246' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID247 = NULLIF(MAX(CASE WHEN Code = N'247' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID501 = NULLIF(MAX(CASE WHEN Code = N'501' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK);

    IF @FID241 IS NULL OR @FID243 IS NULL OR @FID246 IS NULL OR @FID247 IS NULL OR @FID501 IS NULL
    BEGIN
        RAISERROR ('FinancialItemDefinition (241,243,246,247,501) eksik.', 16, 1);
        RETURN;
    END;

    /* 3) A×B×kök eşleşmeleri (yalnızca yapraklar) */
    ;
    WITH ASet AS
    (
        SELECT DISTINCT g.FirmType, g.AccountNumber, g.FirmTitle
        FROM #GroupInfo g
    ),
    BSet AS
    (
        SELECT DISTINCT g.FirmType, g.AccountNumber, g.FirmTitle
        FROM #GroupInfo g
    ),
    Roots AS
    (
        SELECT CAST('241' AS NVARCHAR(3)) AS RootCode
        UNION ALL SELECT '243'
        UNION ALL SELECT '246'
        UNION ALL SELECT '247'
    ),
    MatchesRaw AS
    (
        SELECT
              a.FirmType        AS AFirmType
            , a.AccountNumber   AS AAccountNumber
            , a.FirmTitle       AS ATitle
            , b.FirmType        AS BFirmType
            , b.AccountNumber   AS BAccountNumber
            , [ALT].[fGetNormalizeTitle_ATC](b.FirmTitle)     AS BTitle
            , r.RootCode
            , tvf.DebitSum_Leaves
            , tvf.CreditSum_Leaves
            , CAST(CASE
                    WHEN tvf.DebitSum_Leaves  > 0 THEN tvf.DebitSum_Leaves
                    WHEN tvf.CreditSum_Leaves > 0 THEN tvf.CreditSum_Leaves
                    ELSE 0
                  END AS DECIMAL(22,2)) AS MatchedAmount_Pos
        FROM ASet a
        JOIN BSet b ON b.AccountNumber <> a.AccountNumber
        CROSS JOIN Roots r
        CROSS APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC
        (
              a.AccountNumber,
              @Period,
              r.RootCode,
              1,
              [ALT].[fGetNormalizeTitle_ATC](b.FirmTitle)
        ) tvf
        WHERE (tvf.DebitSum_Leaves > 0 OR tvf.CreditSum_Leaves > 0)
         
    ),
    Matches AS
    (
        SELECT
              AFirmType, AAccountNumber, ATitle,
              BFirmType, BAccountNumber, BTitle,
              RootCode,
              SUM(MatchedAmount_Pos) AS MatchedAmount
        FROM MatchesRaw
        GROUP BY AFirmType, AAccountNumber, ATitle,
                 BFirmType, BAccountNumber, BTitle,
                 RootCode
        HAVING SUM(MatchedAmount_Pos) > 0
    )
    SELECT * INTO #Matches FROM Matches;

    /* (İstenirse B toplamı için) */
    SELECT BFirmType, BAccountNumber, BTitle,
           SUM(MatchedAmount) AS TotalAmt
      INTO #SumPerB
      FROM #Matches
     GROUP BY BFirmType, BAccountNumber, BTitle;

    /* Eşleşme yoksa çık */
    IF NOT EXISTS (SELECT 1 FROM #Matches)
       AND NOT EXISTS (SELECT 1 FROM #SumPerB)
        RETURN;

    /* 4) A×B×kök bazında: A’nın 24x’inden düş + B’nin 501’inden düş + log */
    DECLARE @AFirmType TINYINT,
            @AAcc      INT,
            @ATitle    VARCHAR(4000),
            @BFirmType TINYINT,
            @BAcc      INT,
            @BTitle    VARCHAR(4000),
            @RootCode  NVARCHAR(3),
            @Amt       DECIMAL(22,2),
            @FID       INT;

    DECLARE curA CURSOR LOCAL FAST_FORWARD FOR
        SELECT AFirmType, AAccountNumber, ATitle,
               BFirmType, BAccountNumber, BTitle,
               RootCode, MatchedAmount
        FROM #Matches;

    OPEN curA;
    FETCH NEXT FROM curA INTO
        @AFirmType, @AAcc, @ATitle,
        @BFirmType, @BAcc, @BTitle,
        @RootCode, @Amt;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Amt > 0
        BEGIN
            SET @FID = CASE @RootCode
                         WHEN '241' THEN @FID241
                         WHEN '243' THEN @FID243
                         WHEN '246' THEN @FID246
                         WHEN '247' THEN @FID247
                       END;

            DECLARE @DescA NVARCHAR(4000) =
                N'R241_243_246_247_vs_501: A (' + CONVERT(NVARCHAR(20), @AAcc) + N' - ' + ISNULL(@ATitle, N'') +
                N') detayında B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') ünvanı tespit edildi; kök ' + @RootCode + N' hesabından düşüldü. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

            DECLARE @DescB NVARCHAR(4000) =
                N'R241_243_246_247_vs_501: B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') için A firmalarının 241/243/246/247 yaprak eşleşmeleri toplamı 501 hesabından düşüldü. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

            -- A tarafı (kök 24x) log
            EXEC ALT.ins_ATC_History
                 @RuleId = @RuleId,
                 @AccountNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID,
                 @AccountCode = @RootCode,
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescA,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            -- B tarafı (501) log
            EXEC ALT.ins_ATC_History
                 @RuleId = @RuleId,
                 @AccountNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID501,
                 @AccountCode = N'501',
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescB,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            -- Discount logları
            EXEC ALT.ins_ATC_HistoryDiscount
			     @AccountNumber = @AAcc,
                 @GroupNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID,
                 @AccountCode = @RootCode,
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescA,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            EXEC ALT.ins_ATC_HistoryDiscount
			     @AccountNumber = @BAcc,
                 @GroupNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID501,
                 @AccountCode = N'501',
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescB,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            -- A: 24x düş
            UPDATE ALT.AutoTransferCleansing
               SET CorrectedValue = CorrectedValue - @Amt
             WHERE GroupNumber = @GroupNumber
               AND Period = @Period
               AND FinancialItemDefinitionId = @FID;

            -- B: 501 düş
            UPDATE ALT.AutoTransferCleansing
               SET CorrectedValue = CorrectedValue - @Amt
             WHERE GroupNumber = @GroupNumber
               AND Period = @Period
               AND FinancialItemDefinitionId = @FID501;
        END

        FETCH NEXT FROM curA INTO
            @AFirmType, @AAcc, @ATitle,
            @BFirmType, @BAcc, @BTitle,
            @RootCode, @Amt;
    END

    CLOSE curA;
    DEALLOCATE curA;
END;
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_Discount_03]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Tenzilat spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_Discount_03]
(
    @RuleId      INT,
    @GroupNumber INT,
    @Period      INT,
    @UserName    VARCHAR(10) = NULL,
    @HostName    VARCHAR(20) = NULL,
    @HostIP      VARCHAR(15) = NULL
)
AS

BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* 1) Grup firmalarını hazırla (#GroupInfo) */
    IF OBJECT_ID('tempdb..#GroupInfo') IS NOT NULL DROP TABLE #GroupInfo;

    CREATE TABLE #GroupInfo
    (
        FirmType              TINYINT       NOT NULL,
        AccountNumber         INT           NOT NULL,
        GroupNumber           INT           NOT NULL,
        AllotmentMainId       INT           NOT NULL,
        Consolidation         BIT           NOT NULL,
        ConsolidationPercent  DECIMAL(9,2)  NOT NULL,
        EffectiveFirm         BIT           NOT NULL,
        PubliclyTradedRatio   DECIMAL(9,2)  NOT NULL,
        BalanceSheet          BIT           NOT NULL,
        FirmTitle             VARCHAR(4000) NOT NULL,
        NormTitle             VARCHAR(4000) NULL
    );

    INSERT INTO #GroupInfo
    (
        FirmType, AccountNumber, GroupNumber, AllotmentMainId,
        Consolidation, ConsolidationPercent, EffectiveFirm,
        PubliclyTradedRatio, BalanceSheet, FirmTitle
    )
    SELECT
        ci.FirmType,
        ci.AccountNumber,
        ci.GroupNumber,
        ci.AllotmentMainId,
        ci.Consolidation,
        ci.ConsolidationPercent,
        ci.EffectiveFirm,
        ci.PubliclyTradedRatio,
        ci.BalanceSheet,
        c.CustomerName AS FirmTitle
    FROM ALT.fGetCustomerInfo(@GroupNumber, NULL, NULL) ci
    INNER JOIN boa.cus.Customer c WITH (NOLOCK)
        ON c.Customerid = ci.AccountNumber
    WHERE ci.Consolidation = 1;

    /* Ünvanları tek seferde normalize et */
    UPDATE g
        SET NormTitle = ALT.fGetNormalizeTitle_ATC(g.FirmTitle)
    FROM #GroupInfo g;

    /* 2) Kök sıraları (öncelik) ve FID eşlemesi */
    IF OBJECT_ID('tempdb..#CodeOrder_RCV') IS NOT NULL DROP TABLE #CodeOrder_RCV;
    CREATE TABLE #CodeOrder_RCV(Code NVARCHAR(3) PRIMARY KEY, Seq INT NOT NULL);
    INSERT INTO #CodeOrder_RCV(Code,Seq) VALUES
        (N'120',1),(N'127',2),(N'220',3),
        (N'131',4),(N'132',5),(N'133',6),(N'136',7),(N'159',8),
        (N'231',9),(N'232',10),(N'233',11),(N'236',12);

    IF OBJECT_ID('tempdb..#CodeOrder_PAY') IS NOT NULL DROP TABLE #CodeOrder_PAY;
    CREATE TABLE #CodeOrder_PAY(Code NVARCHAR(3) PRIMARY KEY, Seq INT NOT NULL);
    INSERT INTO #CodeOrder_PAY(Code,Seq) VALUES
        (N'320',1),(N'329',2),(N'420',3),(N'429',4),
        (N'331',5),(N'332',6),(N'333',7),(N'336',8),(N'340',9),
        (N'431',10),(N'432',11),(N'433',12),(N'436',13);

    IF OBJECT_ID('tempdb..#FIDs') IS NOT NULL DROP TABLE #FIDs;
    CREATE TABLE #FIDs(Code NVARCHAR(3) PRIMARY KEY, FinancialItemDefinitionId INT NOT NULL);

    INSERT INTO #FIDs(Code, FinancialItemDefinitionId)
    SELECT f.Code, f.FinancialItemDefinitionId
    FROM ALT.FinancialItemDefinition f WITH (NOLOCK)
    WHERE f.Code IN (
        N'120',N'127',N'220',N'131',N'132',N'133',N'136',N'159',N'231',N'232',N'233',N'236',
        N'320',N'329',N'420',N'429',N'331',N'332',N'333',N'336',N'340',N'431',N'432',N'433',N'436'
    );

    -- Eksik FID kontrolü
    IF EXISTS (
        SELECT 1 FROM (
            SELECT Code FROM #CodeOrder_RCV
            UNION ALL
            SELECT Code FROM #CodeOrder_PAY
        ) x
        WHERE NOT EXISTS (SELECT 1 FROM #FIDs f WHERE f.Code = x.Code)
    )
    BEGIN
        RAISERROR('FinancialItemDefinition eksik (alacak/borç köklerinden biri bulunamadı).',16,1);
        RETURN;
    END

    /* 3) A×B setleri */
    IF OBJECT_ID('tempdb..#ASet') IS NOT NULL DROP TABLE #ASet;
    IF OBJECT_ID('tempdb..#BSet') IS NOT NULL DROP TABLE #BSet;

    CREATE TABLE #ASet (AFirmType TINYINT, AAcc INT, ATitle VARCHAR(4000), ANormTitle VARCHAR(4000));
    CREATE TABLE #BSet (BFirmType TINYINT, BAcc INT, BTitle VARCHAR(4000), BNormTitle VARCHAR(4000));

    INSERT INTO #ASet
    SELECT DISTINCT g.FirmType, g.AccountNumber, g.FirmTitle, g.NormTitle
    FROM #GroupInfo g;

    INSERT INTO #BSet
    SELECT DISTINCT g.FirmType, g.AccountNumber, g.FirmTitle, g.NormTitle
    FROM #GroupInfo g;

    /* 3.5) TVF'yi tek noktada çalıştırmak için gereken tüm kombinasyonları hazırla */
    IF OBJECT_ID('tempdb..#AccCodeCp') IS NOT NULL DROP TABLE #AccCodeCp;

    CREATE TABLE #AccCodeCp
    (
        AccountNumber INT,
        Code          NVARCHAR(3),
        CounterpartyNameNorm VARCHAR(4000)
    );

    -- alacak kökleri için
    INSERT INTO #AccCodeCp (AccountNumber, Code, CounterpartyNameNorm)
    SELECT DISTINCT
        g.AccountNumber,
        r.Code,
        g2.NormTitle
    FROM #GroupInfo g
    CROSS JOIN #CodeOrder_RCV r
    CROSS JOIN #GroupInfo g2
    WHERE g.AccountNumber <> g2.AccountNumber;  -- aynı firma için tvf çağırma

    -- borç kökleri için
    INSERT INTO #AccCodeCp (AccountNumber, Code, CounterpartyNameNorm)
    SELECT DISTINCT
        g.AccountNumber,
        p.Code,
        g2.NormTitle
    FROM #GroupInfo g
    CROSS JOIN #CodeOrder_PAY p
    CROSS JOIN #GroupInfo g2
    WHERE g.AccountNumber <> g2.AccountNumber
      AND NOT EXISTS (
            SELECT 1 FROM #AccCodeCp x
            WHERE x.AccountNumber = g.AccountNumber
              AND x.Code          = p.Code
              AND x.CounterpartyNameNorm = g2.NormTitle
      );

    /* 3.6) Şimdi TVF'yi tek yerde çalıştır ve sonucu #DtlAll'a al */
    IF OBJECT_ID('tempdb..#DtlAll') IS NOT NULL DROP TABLE #DtlAll;

    CREATE TABLE #DtlAll
    (
        AccountNumber INT,
        Period        INT,
        Code          NVARCHAR(3),
        CounterpartyNameNorm VARCHAR(4000),
        DebitSum_Leaves  DECIMAL(22,2),
        CreditSum_Leaves DECIMAL(22,2)
    );

    INSERT INTO #DtlAll (AccountNumber, Period, Code, CounterpartyNameNorm, DebitSum_Leaves, CreditSum_Leaves)
    SELECT
        acc.AccountNumber,
        @Period,
        acc.Code,
        acc.CounterpartyNameNorm,
        tvf.DebitSum_Leaves,
        tvf.CreditSum_Leaves
    FROM #AccCodeCp acc
    CROSS APPLY ALT.fGetDetailedTrialBalanceLeafSums_ATC(
                    acc.AccountNumber,
                    @Period,
                    acc.Code,
                    1,
                    acc.CounterpartyNameNorm
                 ) tvf
    WHERE (tvf.DebitSum_Leaves > 0 OR tvf.CreditSum_Leaves > 0);

    /* 4) A→B (Alacak tarafı) */
    IF OBJECT_ID('tempdb..#RcvPerPairRoot') IS NOT NULL DROP TABLE #RcvPerPairRoot;

    SELECT
        a.AFirmType,
        a.AAcc,
        a.ATitle,
        b.BFirmType,
        b.BAcc,
        b.BTitle,
        o.Code,
        o.Seq,
        CAST(
            CASE
                WHEN d.DebitSum_Leaves  > 0 THEN d.DebitSum_Leaves
                WHEN d.CreditSum_Leaves > 0 THEN d.CreditSum_Leaves
                ELSE 0
            END AS DECIMAL(22,2)
        ) AS AmountPos
    INTO #RcvPerPairRoot
    FROM #ASet a
    JOIN #BSet b
        ON b.BAcc <> a.AAcc
    JOIN #CodeOrder_RCV o
        ON 1=1
    JOIN #DtlAll d
        ON d.AccountNumber        = a.AAcc
       AND d.Code                 = o.Code
       AND d.CounterpartyNameNorm = b.BNormTitle
       AND d.Period               = @Period;

    /* 5) B→A (Borç tarafı) */
    IF OBJECT_ID('tempdb..#PayPerPairRoot') IS NOT NULL DROP TABLE #PayPerPairRoot;

    SELECT
        a.AFirmType,
        a.AAcc,
        a.ATitle,
        b.BFirmType,
        b.BAcc,
        b.BTitle,
        o.Code,
        o.Seq,
        CAST(
            CASE
                WHEN d.DebitSum_Leaves  > 0 THEN d.DebitSum_Leaves
                WHEN d.CreditSum_Leaves > 0 THEN d.CreditSum_Leaves
                ELSE 0
            END AS DECIMAL(22,2)
        ) AS AmountPos
    INTO #PayPerPairRoot
    FROM #ASet a
    JOIN #BSet b
        ON b.BAcc <> a.AAcc
    JOIN #CodeOrder_PAY o
        ON 1=1
    JOIN #DtlAll d
        ON d.AccountNumber        = b.BAcc
       AND d.Code                 = o.Code
       AND d.CounterpartyNameNorm = a.ANormTitle
       AND d.Period               = @Period;

    /* 6) Çift bazında toplamlar ve Delta */
    IF OBJECT_ID('tempdb..#PairDelta') IS NOT NULL DROP TABLE #PairDelta;

    SELECT
        r.AFirmType, r.AAcc, r.ATitle,
        r.BFirmType, r.BAcc, r.BTitle,
        SUM(r.AmountPos) AS SumRcv,
        ISNULL(p.SumPay,0) AS SumPay,
        CAST(
            CASE
                WHEN SUM(r.AmountPos) > 0 AND ISNULL(p.SumPay,0) > 0
                    THEN CASE WHEN SUM(r.AmountPos) <= ISNULL(p.SumPay,0)
                              THEN SUM(r.AmountPos)
                              ELSE ISNULL(p.SumPay,0)
                         END
                ELSE 0
            END AS DECIMAL(22,2)
        ) AS Delta
    INTO #PairDelta
    FROM #RcvPerPairRoot r
    OUTER APPLY (
        SELECT SUM(AmountPos) AS SumPay
        FROM #PayPerPairRoot p
        WHERE p.AFirmType = r.AFirmType
          AND p.AAcc      = r.AAcc
          AND p.BFirmType = r.BFirmType
          AND p.BAcc      = r.BAcc
    ) p
    GROUP BY r.AFirmType, r.AAcc, r.ATitle,
             r.BFirmType, r.BAcc, r.BTitle, p.SumPay;

    DELETE FROM #PairDelta WHERE Delta <= 0;

    IF NOT EXISTS (SELECT 1 FROM #PairDelta)
        RETURN;

    /* 7) Waterfall dağıtımı — A (Alacak) */
    IF OBJECT_ID('tempdb..#AllocA') IS NOT NULL DROP TABLE #AllocA;

    ;WITH RcvWithCum AS (
        SELECT
            r.AFirmType, r.AAcc, r.ATitle,
            r.BFirmType, r.BAcc, r.BTitle,
            r.Code, r.Seq, r.AmountPos,
            d.Delta,
            ISNULL(SUM(r.AmountPos) OVER (
                PARTITION BY r.AFirmType, r.AAcc, r.BFirmType, r.BAcc
                ORDER BY r.Seq
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),0) AS ConsumedBefore
        FROM #RcvPerPairRoot r
        JOIN #PairDelta d
          ON d.AFirmType = r.AFirmType
         AND d.AAcc      = r.AAcc
         AND d.BFirmType = r.BFirmType
         AND d.BAcc      = r.BAcc
    )
    SELECT
        AAcc, ATitle, BAcc, BTitle, Code, Seq,
        CAST(
            CASE
                WHEN Delta <= ConsumedBefore THEN 0
                WHEN Delta >= ConsumedBefore + AmountPos THEN AmountPos
                ELSE Delta - ConsumedBefore
            END AS DECIMAL(22,2)
        ) AS AllocAmt
    INTO #AllocA
    FROM RcvWithCum;

    DELETE FROM #AllocA WHERE AllocAmt <= 0;

    /* 8) Waterfall dağıtımı — B (Borç) */
    IF OBJECT_ID('tempdb..#AllocB') IS NOT NULL DROP TABLE #AllocB;

    ;WITH PayWithCum AS (
        SELECT
            p.AFirmType, p.AAcc, p.ATitle,
            p.BFirmType, p.BAcc, p.BTitle,
            p.Code, p.Seq, p.AmountPos,
            d.Delta,
            ISNULL(SUM(p.AmountPos) OVER (
                PARTITION BY p.AFirmType, p.AAcc, p.BFirmType, p.BAcc
                ORDER BY p.Seq
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),0) AS ConsumedBefore
        FROM #PayPerPairRoot p
        JOIN #PairDelta d
          ON d.AFirmType = p.AFirmType
         AND d.AAcc      = p.AAcc
         AND d.BFirmType = p.BFirmType
         AND d.BAcc      = p.BAcc
    )
    SELECT
        AAcc, ATitle, BAcc, BTitle, Code, Seq,
        CAST(
            CASE
                WHEN Delta <= ConsumedBefore THEN 0
                WHEN Delta >= ConsumedBefore + AmountPos THEN AmountPos
                ELSE Delta - ConsumedBefore
            END AS DECIMAL(22,2)
        ) AS AllocAmt
    INTO #AllocB
    FROM PayWithCum;

    DELETE FROM #AllocB WHERE AllocAmt <= 0;

    /* 9) Log + (şimdilik sadece text) : A tarafı */
    DECLARE
        @AAcc INT,
        @ATitle VARCHAR(4000),
        @BAcc INT,
        @BTitle VARCHAR(4000),
        @Code NVARCHAR(3),
        @Amt DECIMAL(22,2),
        @FID INT,
        @Seq INT;

    DECLARE curA CURSOR LOCAL FAST_FORWARD FOR
        SELECT AAcc, ATitle, BAcc, BTitle, Code, AllocAmt, Seq
        FROM #AllocA
        ORDER BY AAcc, BAcc, Seq;

    OPEN curA;
    FETCH NEXT FROM curA INTO @AAcc, @ATitle, @BAcc, @BTitle, @Code, @Amt, @Seq;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Amt > 0
        BEGIN
            SELECT @FID = FinancialItemDefinitionId FROM #FIDs WHERE Code = @Code;

            DECLARE @DescA NVARCHAR(4000) =
                N'R03 Intercompany Offset: A (' + CONVERT(NVARCHAR(20), @AAcc) + N' - ' + ISNULL(@ATitle, N'') +
                N') detayında B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') nedeniyle alacak kökü ' + @Code + N' tenzil. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

             EXEC ALT.ins_ATC_History
                 @RuleId = 997,
                 @AccountNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID,
                 @AccountCode = @Code,
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescA,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            EXEC ALT.ins_ATC_HistoryDiscount
			     @AccountNumber = @AAcc,
                 @GroupNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID,
                 @AccountCode = @Code,
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescA,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            UPDATE ALT.AutoTransferCleansing
               SET CorrectedValue = CorrectedValue - @Amt
             WHERE GroupNumber = @GroupNumber
               AND Period = @Period
               AND FinancialItemDefinitionId = @FID;
        END

        FETCH NEXT FROM curA INTO @AAcc, @ATitle, @BAcc, @BTitle, @Code, @Amt, @Seq;
    END

    CLOSE curA;
    DEALLOCATE curA;

    /* 10) Log + (şimdilik sadece text) : B tarafı */
    DECLARE curB CURSOR LOCAL FAST_FORWARD FOR
        SELECT AAcc, ATitle, BAcc, BTitle, Code, AllocAmt, Seq
        FROM #AllocB
        ORDER BY BAcc, AAcc, Seq;

    OPEN curB;
    FETCH NEXT FROM curB INTO @AAcc, @ATitle, @BAcc, @BTitle, @Code, @Amt, @Seq;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Amt > 0
        BEGIN
            SELECT @FID = FinancialItemDefinitionId FROM #FIDs WHERE Code = @Code;

            DECLARE @DescB NVARCHAR(4000) =
                N'R03 Intercompany Offset: B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') detayında A (' + CONVERT(NVARCHAR(20), @AAcc) + N' - ' + ISNULL(@ATitle, N'') +
                N') nedeniyle borç kökü ' + @Code + N' tenzil. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

            EXEC ALT.ins_ATC_History
                 @RuleId = @RuleId,
                 @AccountNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID,
                 @AccountCode = @Code,
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescB,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            EXEC ALT.ins_ATC_HistoryDiscount
			     @AccountNumber = @BAcc,
                 @GroupNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = @FID,
                 @AccountCode = @Code,
                 @Amount = @Amt,
                 @TransactionType = '-',
                 @Description = @DescB,
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;

            UPDATE ALT.AutoTransferCleansing
               SET CorrectedValue = CorrectedValue - @Amt
             WHERE GroupNumber = @GroupNumber
               AND Period = @Period
               AND FinancialItemDefinitionId = @FID;
        END

        FETCH NEXT FROM curB INTO @AAcc, @ATitle, @BAcc, @BTitle, @Code, @Amt, @Seq;
    END

    CLOSE curB;
    DEALLOCATE curB;
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_Discount_SendData]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*  KUWAIT TURKISH PARTICIPATION BANK INC.      
 *         
 *  All rights are reserved. Reproduction or transmission in whole or in part, in                
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited      
 *  without the prior written consent of the copyright owner.       
 *       
 *       
 *  Generator Information      
 *      Generator    : BOA.Tools.CodeGenerator      
 *      Generated By   : aelgun      
 *      Generated Date   : 21.09.2025 13:45:00      
 *  File Version            : 1.0      
 *  Purpose                 : Tenzilat spleri     
 *  Last Modified By        : aelgun      
 *  Last Modification Date  : 21.09.2025 13:45:00      
 *      
 */  
CREATE PROCEDURE [ALT].[upd_ATC_Discount_SendData]  (
        @RuleId      INT   ,
        @GroupNumber INT		 ,
		@Period		 INT		 ,
		@UserName	 VARCHAR(10) = NULL,
		@HostName	 VARCHAR(20) = NULL,
		@HostIP		 VARCHAR(15) = NULL )
AS  
BEGIN  
    -----------------------------------------  
    -- 1) Kaynak: AutoTransferCleansing -> #Src  
    -----------------------------------------  
    IF OBJECT_ID('tempdb..#Src') IS NOT NULL DROP TABLE #Src;  
  
    SELECT  
        a.FirmType,  
        a.GroupNumber,  
        a.AccountNumber,  
        PeriodId = a.[Period],  
        a.FinancialItemDefinitionId,  
        OriginalValue  = SUM(a.OriginalValue),  
        CorrectedValue = SUM(ISNULL(a.CorrectedValue, a.OriginalValue))  
    INTO #Src  
    FROM ALT.AutoTransferCleansing a WITH (NOLOCK)  
    WHERE  a.GroupNumber = @GroupNumber  
      AND a.[Period]      = @Period  
      AND a.FinancialItemDefinitionId IS NOT NULL  
    GROUP BY a.FirmType, a.GroupNumber, a.AccountNumber, a.[Period], a.FinancialItemDefinitionId;  
  
    -- (Opsiyonel) Hız için indeks  
    -- CREATE CLUSTERED INDEX IX_Src_Key ON #Src(FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId);  
  
    -----------------------------------------  
    -- 2) UPDATE: Her iki tabloda da aynı kayıt varsa güncelle  
    --    (gereksiz yazmayı önlemek için farklılık kontrolü ile)  
    -----------------------------------------  
    IF OBJECT_ID('tempdb..#ToUpdate') IS NOT NULL DROP TABLE #ToUpdate;  
  
    SELECT  
        T.CustomerFinancialItemId,  
        S.OriginalValue,  
        S.CorrectedValue  
    INTO #ToUpdate  
    FROM ALT.CustomerFinancialItem T WITH (NOLOCK)  
    JOIN #Src S  
      ON  T.FirmType                  = S.FirmType  
      AND T.GroupNumber               = S.GroupNumber  
      AND T.AccountNumber             = S.AccountNumber  
      AND T.PeriodId                  = S.PeriodId  
      AND T.FinancialItemDefinitionId = S.FinancialItemDefinitionId  
    WHERE ISNULL(T.OriginalValue ,0) <> ISNULL(S.OriginalValue ,0)  
       OR ISNULL(T.CorrectedValue,0) <> ISNULL(S.CorrectedValue,0);  
  
    UPDATE T  
       SET T.OriginalValue    = U.OriginalValue,  
           T.CorrectedValue   = U.CorrectedValue,  
           T.UpdateUserName   = @UserName,  
           T.UpdateHostName   = @HostName,  
           T.UpdateSystemDate = GETDATE(),  
           T.HostIP           = @HostIP  
    FROM ALT.CustomerFinancialItem T  
    JOIN #ToUpdate U  
      ON T.CustomerFinancialItemId = U.CustomerFinancialItemId;  
  
    -----------------------------------------  
    -- 3) INSERT: Hedefte olmayan + (OV,CV) ikisi birden 0 değilse  
    --    (0,0 olan yeni kayıtlar HARİÇ)  
    -----------------------------------------  
    IF OBJECT_ID('tempdb..#ToInsert') IS NOT NULL DROP TABLE #ToInsert;  
  
    SELECT  
        S.FirmType,  
        S.GroupNumber,  
        S.AccountNumber,  
        S.PeriodId,  
        S.FinancialItemDefinitionId,  
        S.OriginalValue,  
        S.CorrectedValue  
    INTO #ToInsert  
    FROM #Src S  
    LEFT JOIN ALT.CustomerFinancialItem T WITH (NOLOCK)  
      ON  T.FirmType                  = S.FirmType  
      AND T.GroupNumber               = S.GroupNumber  
      AND T.AccountNumber             = S.AccountNumber  
      AND T.PeriodId                  = S.PeriodId  
      AND T.FinancialItemDefinitionId = S.FinancialItemDefinitionId  
    WHERE T.CustomerFinancialItemId IS NULL  
      AND (ISNULL(S.OriginalValue,0) <> 0 OR ISNULL(S.CorrectedValue,0) <> 0);  -- (0,0) HARİÇ  
  
    INSERT INTO ALT.CustomerFinancialItem  
    (  
        FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId,  
        OriginalValue, CorrectedValue,  
        WorkflowInstanceId, UserName, HostName, SystemDate, HostIP  
    )  
    SELECT  
        FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId,  
        OriginalValue, CorrectedValue,  
        NULL, @UserName, @HostName, GETDATE(), @HostIP  
    FROM #ToInsert;  
END  
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_TransferAmount]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.    
 *       
 *  All rights are reserved. Reproduction or transmission in whole or in part, in              
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited    
 *  without the prior written consent of the copyright owner.     
 *     
 *     
 *  Generator Information    
 *      Generator    : BOA.Tools.CodeGenerator    
 *      Generated By   : aelgun    
 *      Generated Date   : 21.09.2025 13:45:00    
 *  File Version            : 1.0    
 *  Purpose                 : Aktarım arındırma spleri   
 *  Last Modified By        : aelgun    
 *  Last Modification Date  : 21.09.2025 13:45:00    
 *    
 */
CREATE PROCEDURE [ALT].[upd_ATC_TransferAmount]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @FID           INT,
    @AccountCode   NVARCHAR(50),
    @Amount        DECIMAL(22,2),
    @Process       CHAR(1), -- '+' veya '-'
    @Description   NVARCHAR(500),
    @UserName VARCHAR(10) = NULL,  
    @HostName VARCHAR(20) = NULL,  
    @HostIP VARCHAR(15) = NULL  
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Amount IS NULL OR @Amount = 0
        RETURN;
    DECLARE @AmountNeg DECIMAL(22,2) = -@Amount
    -- HISTORY (güncellenen bölüm)
    EXEC ALT.ins_ATC_History
         @RuleId,
         @AccountNumber,
         @Period,
         @FID,
         @AccountCode,
         @Amount,
         @Process,
         @Description,
         @UserName,
         @HostName,
         @HostIP;
	 EXEC ALT.ins_ATC_HistoryCorrection
         @RuleId,
         @AccountNumber,
         @Period,
         @FID,
         @AccountCode,
         @Amount,
         @Process,
         @Description,
         @UserName,
         @HostName,
         @HostIP;

    -- CorrectedValue güncelle
	IF @Process = '+'
	BEGIN
	   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID,
														   @Amount = @Amount,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
	END
	ELSE
	BEGIN
	  
	   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID,
														   @Amount = @AmountNeg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
	END
	
    
END
GO

/****** Object:  StoredProcedure [ALT].[upd_ATC_TransferCascade]    Script Date: 13/11/2025 9:23:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*  KUWAIT TURKISH PARTICIPATION BANK INC.      
 *         
 *  All rights are reserved. Reproduction or transmission in whole or in part, in                
 *  any form or by any means, electronic, mechanical or otherwise, is prohibited      
 *  without the prior written consent of the copyright owner.       
 *       
 *       
 *  Generator Information      
 *      Generator    : BOA.Tools.CodeGenerator      
 *      Generated By   : aelgun      
 *      Generated Date   : 21.09.2025 13:45:00      
 *  File Version            : 1.0      
 *  Purpose                 : Aktarım arındırma spleri     
 *  Last Modified By        : aelgun      
 *  Last Modification Date  : 21.09.2025 13:45:00      
 *      
 */  
  
CREATE PROCEDURE [ALT].[upd_ATC_TransferCascade]  
(  
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id  
    @AccountNumber INT,  
    @Period        INT,   
    @Need          DECIMAL(22,2),     -- Hedefte ihtiyaç duyulan tutar  
    @SourceCodes   NVARCHAR(200),     -- Virgüllü liste: '120,121,127' ya da '136,120,121,127'  
    @TargetCode    NVARCHAR(10),      -- Örn: '128' veya '138'  
    @UserName VARCHAR(10) = NULL,    
    @HostName VARCHAR(20) = NULL,    
    @HostIP VARCHAR(15) = NULL   
)  
AS  
BEGIN
				SET NOCOUNT ON;
  
  
					/* 0) Kaynak kodları sırayla tabloya aç */  
					DECLARE @Src TABLE (  
						Ord  INT IDENTITY(1,1),  
						Code NVARCHAR(10)  
					);

				INSERT INTO @Src (Code)
				SELECT LTRIM(RTRIM(s.value))
				  FROM STRING_SPLIT(@SourceCodes, ',') AS s
				 WHERE NULLIF(LTRIM(RTRIM(s.value)), N'') IS NOT NULL;

				IF NOT EXISTS (SELECT 1 FROM @Src)
				RETURN;

				/* 1) Hedef FID */
				DECLARE @FIDTarget INT;

				;
				WITH AllCodes
				  AS (SELECT Code FROM @Src
					  UNION
					  SELECT @TargetCode)
				SELECT @FIDTarget = MAX(CASE
								  WHEN f.Code = @TargetCode THEN f.FinancialItemDefinitionId END)
				  FROM AllCodes ac
				  JOIN ALT.FinancialItemDefinition f WITH (NOLOCK)
					ON f.Code = ac.Code;

				IF @FIDTarget IS NULL
				RAISERROR ('upd_ATC_TransferCascade: Target FID bulunamadı (%s).', 16, 1, @TargetCode);

				/* 2) Hedef satırı yoksa oluştur */
				IF NOT EXISTS (SELECT 1 FROM ALT.AutoTransferCleansing WHERE AccountNumber = @AccountNumber
					   AND Period = @Period
					   AND FinancialItemDefinitionId = @FIDTarget)
				BEGIN
				INSERT INTO ALT.AutoTransferCleansing (FirmType,
													   GroupNumber,
													   AccountNumber,
													   Period,
													   FinancialItemDefinitionId,
													   OriginalValue,
													   CorrectedValue)
				VALUES (1, 0, @AccountNumber, @Period, @FIDTarget, 0, 0);
				END

				/* 3) Sırayla kaynaklardan aktar */
				DECLARE @Remain DECIMAL(22, 2) = ISNULL(@Need, 0);
				DECLARE @SrcCode NVARCHAR(10),
						@FIDSrc	 INT,
						@Avail	 DECIMAL(22, 2),
						@Take	 DECIMAL(22, 2),
						@TakeNeg	 DECIMAL(22, 2);

				DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Code FROM @Src ORDER BY Ord;

				OPEN cur;
				FETCH NEXT FROM cur INTO @SrcCode;

				WHILE @@FETCH_STATUS = 0
				  AND @Remain > 0
				BEGIN
				-- Kaynağın FID'si  
					SELECT @FIDSrc = f.FinancialItemDefinitionId
					  FROM ALT.FinancialItemDefinition f WITH (NOLOCK)
					 WHERE f.Code = @SrcCode;

					IF @FIDSrc IS NULL
					BEGIN
					FETCH NEXT FROM cur INTO @SrcCode;
					CONTINUE;
					END

								-- Kaynak bakiye  
								SELECT @Avail = COALESCE(SUM(CorrectedValue), 0)
								  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
								 WHERE AccountNumber = @AccountNumber
								   AND Period = @Period
								   AND FinancialItemDefinitionId = @FIDSrc;

								SET @Take = CASE
														 WHEN @Avail >= @Remain THEN @Remain
														 ELSE @Avail END;
  
  
										-- Açıklamalar (string concat’ı önce değişkene al)  
										DECLARE @DescTake NVARCHAR(500),  
												@DescAdd  NVARCHAR(500);

								SET @DescTake = N'Rule7 Cascade: ' + @SrcCode + N' -> ' + @TargetCode
								+ N' aktarım denemesi. Kalan ihtiyaç=' + CONVERT(NVARCHAR(50), @Remain);

								SET @DescAdd = N'Rule7 Cascade: ' + @SrcCode + N' -> ' + @TargetCode + N' aktarıldı.';

								-- HISTORY  
								EXEC ALT.ins_ATC_History @RuleId,
														 @AccountNumber,
														 @Period,
														 @FIDSrc,
														 @SrcCode,
														 @Take,
														 N'-',
														 @DescTake,
														 @UserName,
														 @HostName,
														 @HostIP;

								EXEC ALT.ins_ATC_History @RuleId,
														 @AccountNumber,
														 @Period,
														 @FIDTarget,
														 @TargetCode,
														 @Take,
														 N'+',
														 @DescAdd,
														 @UserName,
														 @HostName,
														 @HostIP;

								-- Güncellemeler  
								IF @Take > 0
								BEGIN
								    
										EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
																			   @AccountNumber = @AccountNumber,
																			   @Period = @Period,
																			   @FinancialItemDefinitionId = @FIDSrc,
																			   @Amount = @TakeNeg,
																			   @UserName = @UserName,
																			   @HostName = @HostName,
																			   @HostIP = @HostIP;

										EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
																			   @AccountNumber = @AccountNumber,
																			   @Period = @Period,
																			   @FinancialItemDefinitionId = @FIDTarget,
																			   @Amount = @Take,
																			   @UserName = @UserName,
																			   @HostName = @HostName,
																			   @HostIP = @HostIP;
							 
									    SET @Remain = @Remain - @Take;
  
						        END
  
  
						FETCH NEXT FROM cur INTO @SrcCode;
  
					END
  
  
					CLOSE cur; 
					DEALLOCATE cur;
  
  
					-- Karşılanamayan bakiye bilgisi  
					IF @Remain > 0  
					BEGIN
  
						DECLARE @DescRemain NVARCHAR(500) = N'Rule7 Cascade: Kaynaklar yetersiz. Karşılanamayan bakiye=' + CONVERT(NVARCHAR(50), @Remain);

						EXEC ALT.ins_ATC_History @RuleId,
												 @AccountNumber,
												 @Period,
												 @FIDTarget,
												 @TargetCode,
												 0,
												 N'+',
												 @DescRemain,
												 @UserName,
												 @HostName,
												 @HostIP;
						EXEC ALT.ins_ATC_HistoryCorrection @RuleId,
														   @AccountNumber,
														   @Period,
														   @FIDTarget,
														   @TargetCode,
														   0,
														   N'+',
														   @DescRemain,
														   @UserName,
														   @HostName,
														   @HostIP;
				      END
END
GO


