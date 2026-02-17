USE [MizanDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
    
 
CREATE PROCEDURE [ALT].[ins_CustomerFinancialItemFromDetailedTrialBalance]        
 @AccountNumber INT,        
 @Period INT        
AS        
BEGIN    
  SET NOCOUNT ON;    
        
   -- Staging: yaln?zca ilgili hesap/d?nem ve 3 haneli (100?599) kodlar          
   IF OBJECT_ID('tempdb..#tmpXXX') IS NOT NULL    
  DROP TABLE #tmpXXX;    
    
  DECLARE @UserName   VARCHAR(10) = NULL,    
    @HostName   VARCHAR(20) = NULL,    
    @HostIP    VARCHAR(15) = NULL,    
    @UpdateUserName  VARCHAR(10) = NULL,    
    @UpdateHostName  VARCHAR(20) = NULL,    
    @UpdateSystemDate   DATETIME,    
    @WorkflowInstanceId INT,    
    @SystemDate   DATETIME  ,
	@ACredit DECIMAL(22, 2) = 0,    
    @ADebit  DECIMAL(22, 2) = 0,    
    @ANet  DECIMAL(22, 2) = 0,    
    @PCredit DECIMAL(22, 2) = 0,    
    @PDebit  DECIMAL(22, 2) = 0,    
    @PNet  DECIMAL(22, 2) = 0,    
    @FIDA  INT,    
    @FIDP  INT  
  
  
   SELECT TOP 1 @UserName = UserName,    
                @HostName = HostName,    
                @HostIP = HostIP,    
                @UpdateUserName = UpdateUserName,    
                @UpdateHostName = UpdateHostName,    
                @UpdateSystemDate = UpdateSystemDate,    
                @WorkflowInstanceId = WorkflowInstanceId,    
                @SystemDate = SystemDate    
     FROM ALT.CustomerDetailedTrialBalance AS c WITH (NOLOCK)    
    WHERE c.AccountNumber = @AccountNumber    
      AND c.[Period] = @Period      
    
	  ;    
	  WITH Base    
		AS (SELECT c.AccountNumber,    
		  c.[Period],    
		  LTRIM(RTRIM(c.AccountCode)) AS AccountCode,    
		  CAST(c.DebitBalance AS DECIMAL(38, 2)) AS DebitBalance,    
		  CAST(c.CreditBalance AS DECIMAL(38, 2)) AS CreditBalance,    
		  CAST(c.DebitBalance - c.CreditBalance AS DECIMAL(38, 2)) AS Balance FROM ALT.CustomerDetailedTrialBalance AS c WITH (NOLOCK) WHERE c.AccountNumber = @AccountNumber    
		 AND c.[Period] = @Period    
		 AND LTRIM(RTRIM(c.AccountCode)) LIKE '[1-5][0-9][0-9]'   -- 3 haneli 100?599        
		)    
	  SELECT b.AccountNumber,    
			  b.[Period],    
			  b.AccountCode,    
			  b.DebitBalance,    
			  b.CreditBalance,    
			  b.Balance,    
			  fid.FinancialItemDefinitionId,    
			  CAST(0 AS TINYINT) AS RollupLevel     -- 0: Detay        
		INTO #tmpXXX    
		FROM Base b    
		LEFT JOIN ALT.FinancialItemDefinition AS fid WITH (NOLOCK)  ON fid.Code = b.AccountCode   
    
		DELETE FROM #tmpXXX WHERE FinancialItemDefinitionId IS NULL    
    
  -- 2) 2 hane rollup (?rn. 100/101/102 → 10)        
     ;WITH G AS  
     (  
      SELECT   
       b.AccountNumber,  
       b.[Period],  
       Code2 = LEFT(b.AccountCode, 2),  
       DebitBalance   = SUM(b.DebitBalance),  
       CreditBalance  = SUM(b.CreditBalance),  
       Balance        = SUM(b.Balance)  
      FROM #tmpXXX b  
      WHERE b.RollupLevel = 0                    -- sadece detaylardan topla  
      GROUP BY b.AccountNumber, b.[Period], LEFT(b.AccountCode, 2)  
     ),  
     GS AS  
     (  
      SELECT   
       g.AccountNumber,  
       g.[Period],  
       AccountCode = g.Code2,  
       g.DebitBalance,  
       g.CreditBalance,  
       g.Balance,  
       fid.FinancialItemDefinitionId,  
       RollupLevel = 2  
      FROM G g  
      LEFT JOIN ALT.FinancialItemDefinition AS fid WITH (NOLOCK)  ON fid.Code = g.Code2  
     )  
     MERGE #tmpXXX AS T  
     USING GS AS S  
        ON  T.AccountNumber = S.AccountNumber  
        AND T.[Period]      = S.[Period]  
        AND T.AccountCode   = S.AccountCode  
        AND T.RollupLevel   = S.RollupLevel  
     WHEN MATCHED THEN  
      UPDATE SET   
       T.DebitBalance  = S.DebitBalance,  
       T.CreditBalance = S.CreditBalance,  
       T.Balance       = S.Balance,  
       T.FinancialItemDefinitionId = S.FinancialItemDefinitionId  
     WHEN NOT MATCHED BY TARGET THEN  
      INSERT (AccountNumber, [Period], AccountCode, DebitBalance, CreditBalance, Balance, FinancialItemDefinitionId, RollupLevel)  
      VALUES (S.AccountNumber, S.[Period], S.AccountCode, S.DebitBalance, S.CreditBalance, S.Balance, S.FinancialItemDefinitionId, S.RollupLevel);  
    
    
  -- 3) 1 hane rollup (?rn. 10/11/12 → 1)        
     ;WITH G AS  
   (  
    SELECT   
     b.AccountNumber,  
     b.[Period],  
     Code1 = LEFT(b.AccountCode, 1),  
     DebitBalance   = SUM(b.DebitBalance),  
     CreditBalance  = SUM(b.CreditBalance),  
     Balance        = SUM(b.Balance)  
    FROM #tmpXXX b  
    WHERE b.RollupLevel IN (0)              -- detay + 2 hane toplamlardan topla  
    GROUP BY b.AccountNumber, b.[Period], LEFT(b.AccountCode, 1)  
   ),  
   GS AS  
   (  
    SELECT   
     g.AccountNumber,  
     g.[Period],  
     AccountCode = g.Code1,  
     g.DebitBalance,  
     g.CreditBalance,  
     g.Balance,  
     fid.FinancialItemDefinitionId,  
     RollupLevel = 1  
    FROM G g  
    LEFT JOIN ALT.FinancialItemDefinition AS fid WITH (NOLOCK)  ON fid.Code = g.Code1  
   )  
   MERGE #tmpXXX AS T  
   USING GS AS S  
      ON  T.AccountNumber = S.AccountNumber  
      AND T.[Period]      = S.[Period]  
      AND T.AccountCode   = S.AccountCode  
      AND T.RollupLevel   = S.RollupLevel  
   WHEN MATCHED THEN  
    UPDATE SET   
     T.DebitBalance  = S.DebitBalance,  
     T.CreditBalance = S.CreditBalance,  
     T.Balance       = S.Balance,  
     T.FinancialItemDefinitionId = S.FinancialItemDefinitionId  
   WHEN NOT MATCHED BY TARGET THEN  
    INSERT (AccountNumber, [Period], AccountCode, DebitBalance, CreditBalance, Balance, FinancialItemDefinitionId, RollupLevel)  
    VALUES (S.AccountNumber, S.[Period], S.AccountCode, S.DebitBalance, S.CreditBalance, S.Balance, S.FinancialItemDefinitionId, S.RollupLevel);   
 
    
  SELECT @FIDA = MAX(CASE    
        WHEN Code = 'A' THEN FinancialItemDefinitionId END),    
      @FIDP = MAX(CASE    
        WHEN Code = 'P' THEN FinancialItemDefinitionId END)    
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)    
   WHERE Code IN ('A', 'P');    
    
  ;    
  WITH X    
    AS (SELECT AccountCode,    
      CreditBalance,    
      DebitBalance,    
      Balance  -- yoksa: DebitBalance - CreditBalance kullanabilirsiniz    
    FROM #tmpXXX WHERE AccountCode IN ('1', '2', '3', '4', '5'))    
  SELECT @ACredit = SUM(CASE    
        WHEN AccountCode IN ('1', '2') THEN CreditBalance    
        ELSE 0 END),    
      @ADebit = SUM(CASE    
        WHEN AccountCode IN ('1', '2') THEN DebitBalance    
        ELSE 0 END),    
      @ANet = SUM(CASE    
        WHEN AccountCode IN ('1', '2') THEN Balance    
        ELSE 0 END),    
    
      @PCredit = SUM(CASE    
        WHEN AccountCode IN ('3', '4', '5') THEN CreditBalance    
        ELSE 0 END),    
      @PDebit = SUM(CASE    
        WHEN AccountCode IN ('3', '4', '5') THEN DebitBalance    
        ELSE 0 END),    
      @PNet = SUM(CASE    
        WHEN AccountCode IN ('3', '4', '5') THEN Balance    
        ELSE 0 END)    
    FROM X    
    
    
    
  INSERT INTO #tmpXXX (AccountNumber,    
        [Period],    
        AccountCode,    
        DebitBalance,    
        CreditBalance,    
        Balance,    
        FinancialItemDefinitionId,    
        RollupLevel)    
  VALUES (@AccountNumber, @Period, 'A', @ADebit, @ACredit, @ANet, @FIDA, 1),    
      (@AccountNumber, @Period, 'P', @PDebit, @PCredit, @PNet, @FIDP, 1)    
    
    
  ;    
  WITH S    
    AS (SELECT 1 AS FirmType,    
      0 AS GroupNumber,    
      t.AccountNumber,    
      t.[Period] AS PeriodId,  -- hedef tablodaki PeriodId s?tunu i?in alias          
      t.FinancialItemDefinitionId,    
      CAST(    
      ROUND(    
      ABS(    
      SUM(CAST(ISNULL(t.DebitBalance, 0) - ISNULL(t.CreditBalance, 0) AS DECIMAL(22, 2)))    
      ),    
      2    
      ) AS NUMERIC(22, 2)    
      ) AS NetAmount FROM #tmpXXX AS t    
      GROUP BY t.AccountNumber,    
      t.[Period],    
      t.FinancialItemDefinitionId)    
  MERGE ALT.CustomerFinancialItem AS T    
  USING S    
     ON T.FirmType = S.FirmType    
     AND T.GroupNumber = S.GroupNumber    
     AND T.AccountNumber = S.AccountNumber    
     AND T.PeriodId = S.PeriodId    
     AND T.FinancialItemDefinitionId = S.FinancialItemDefinitionId    
  WHEN MATCHED THEN UPDATE SET T.OriginalValue = S.NetAmount,    
          T.CorrectedValue = S.NetAmount,    
          T.UpdateUserName = @UpdateUserName,    
          T.UpdateHostName = @UpdateHostName,    
          T.UpdateSystemDate = @UpdateSystemDate,    
          T.HostIP = @HostIP    
  WHEN NOT MATCHED THEN INSERT (FirmType,    
           GroupNumber,    
           AccountNumber,    
           PeriodId,    
           FinancialItemDefinitionId,    
           OriginalValue,    
           CorrectedValue,    
           WorkflowInstanceId,    
           UserName,    
           HostName,    
           SystemDate,    
           HostIP)    
   VALUES (S.FirmType, S.GroupNumber, S.AccountNumber, S.PeriodId, S.FinancialItemDefinitionId, S.NetAmount, S.NetAmount, @WorkflowInstanceId, @UserName, @HostName, @SystemDate, @HostIP);    
    
END;
GO


CREATE   PROCEDURE [ALT].[ins_ATC_History]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,
    @AccountCode   NVARCHAR(50),
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

CREATE   PROCEDURE [ALT].[ins_ATC_HistoryCorrection]
(
    @RuleId        INT,
    @AccountNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,
    @AccountCode   NVARCHAR(50),
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

       -- Sabitler (d??ar?dan al?nm?yor)
        DECLARE @CorrectionType     TINYINT = 0;   -- talebiniz: 0
        DECLARE @IsAutoCorrection   TINYINT = 1;   -- talebiniz: 1
        DECLARE @SequenceNumber     INT     = 0;   -- talebiniz: 0

		DECLARE @Sign TINYINT = CASE WHEN @TransactionType='+' THEN 1 WHEN @TransactionType='-' THEN 2 ELSE 0 END;
        -- 1) MASTER: her ?a?r?da yeni master olu?tur
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
				'Otomatik aktar?m ar?nd?rma sistemi',  -- tablo VARCHAR(200); uzun metinler k?rp?labilir
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

CREATE   PROCEDURE [ALT].[ins_ATC_HistoryDiscount]
(
    @AccountNumber INT,
    @GroupNumber INT,
    @Period        INT,
    @FinancialItemDefinitionId INT,
    @AccountCode   NVARCHAR(50),
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
        -- 1) MASTER: her ?a?r?da yeni master olu?tur
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
			VALUES (@GroupNumber, @Period, 'Otomatik tenzilat sistemi',  -- tablo VARCHAR(200); uzun metinler k?rp?labilir
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

CREATE PROCEDURE [ALT].[ins_FillGreyListCacheAtc]
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
   DECLARE @Today SMALLDATETIME = CAST(GETDATE() AS DATE)
   IF NOT EXISTS(SELECT TOP 1  1 
		                FROM [ALT].[GreyListCacheAtc] atc WITH(NOLOCK) 
					   WHERE atc.TranDate = @Today)
   BEGIN
	 TRUNCATE TABLE [ALT].[GreyListCacheAtc]
	 INSERT INTO [ALT].[GreyListCacheAtc](Title,TranDate)
		SELECT DISTINCT ALT.fn_NormalizeCompany_First2_Scalar(A.Title) ,@Today
		  FROM (
				SELECT Name AS Title FROM INQ.BankruptcyConcordat WITH (NOLOCK)
				WHERE EndDate IS NULL OR EndDate > CAST(GETDATE() AS date)
				UNION ALL
				SELECT Title FROM INQ.TCMBProtestedBills WITH (NOLOCK)
				UNION ALL
				SELECT a.Title
				FROM [INQ].TCMBBouncedCheckCorp a WITH (NOLOCK)
				WHERE a.StateCode = 'B'
					AND (a.SubmissionDate IS NULL OR a.SubmissionDate >= DATEADD(YEAR, -4, CAST(GETDATE() AS date)))
					AND NOT EXISTS (
						SELECT 1
						FROM [INQ].TCMBBouncedCheckCorp b WITH (NOLOCK)
						WHERE b.CheckAccountNumber = a.CheckAccountNumber
						AND b.CheckOrderNumber = a.CheckOrderNumber
						AND b.StateCode IN ('K', 'S')
					)
				UNION ALL
				SELECT Title
				FROM INQ.BlackListCorporation BC WITH (NOLOCK)
				WHERE BC.Status = 1
					AND BC.BlackListTypeID IN (3,7,9,10,11)
						) A
					

		END
	
END

GO

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
   DECLARE @BaseCode NVARCHAR(200),@BaseSign INT, @BaseFID INT ,@BaseParentId INT,@pCode NVARCHAR(2000),@pParentid INT, @pOrd INT = 1 , 
   @pFID INT,@pSign INT,@cCode NVARCHAR(2000),@cParentid INT , @cFID INT,@cSign INT;  
    
 
   SELECT @BaseCode = f.Code,  
          @BaseSign = f.Sign,  
          @BaseFID = f.FinancialItemDefinitionId,  
          @BaseParentId = f.ParentId  
     FROM ALT.FinancialItemDefinition f WITH (NOLOCK)  
    WHERE f.FinancialItemDefinitionId = @FinancialItemDefinitionId  
      AND f.Status = 1;  
  
	 IF @BaseCode IS NULL  
	 BEGIN  
		  RAISERROR ('Ge?ersiz FinancialItemDefinitionId.', 16, 1);  
		  RETURN;  
	 END  
 /* 1) Hedef + Atalar listesi (?nce taban, sonra atalar: 100?10?1) */  
	 IF OBJECT_ID('tempdb..#Targets') IS NOT NULL  
	  DROP TABLE #Targets;  
    
	CREATE TABLE #Targets (Ord INT NOT NULL, Code NVARCHAR(20) NOT NULL,FID INT NOT NULL,[Sign] INT NOT NULL);   
	INSERT INTO #Targets (Ord,Code,FID,[Sign]) VALUES( 0,@BaseCode,@BaseFID,@BaseSign)  
	SET @pParentid  = @BaseParentId;  
     
	 WHILE @pParentid IS NOT NULL   
	 BEGIN  
		  /* Ebeveyn kayd?: hem de?erleri hem de bir sonraki ParentId?yi tek seferde al */ 
		  SELECT @pCode=f.Code,@pFID=f.FinancialItemDefinitionId,@pParentid=f.ParentId,@pSign=f.Sign  
			FROM ALT.FinancialItemDefinition AS f WITH (NOLOCK)  
		   WHERE f.FinancialItemDefinitionId = @pParentid  
			 AND f.Status = 1;  
		 IF @@ROWCOUNT = 0  
			BREAK; 
		 INSERT INTO #Targets (Ord,Code,FID,[Sign]) VALUES (@pOrd,@pCode,@pFID,@pSign)  
      
		 SET @pOrd += 1;  
	 END   
   /* 2) Mevcut sat?rlar i?in delta uygula (taban + t?m atalar) */  

     
    UPDATE a WITH (ROWLOCK, UPDLOCK)  
       SET a.CorrectedValue = a.CorrectedValue + CASE WHEN t.[Sign] = @BaseSign THEN ISNULL(@Amount,0) ELSE -1 * ISNULL(@Amount,0) END  
      FROM ALT.AutoTransferCleansing a    JOIN #Targets t ON t.FID = a.FinancialItemDefinitionId  
     WHERE a.AccountNumber = @AccountNumber  
       AND a.[Period]      = @Period;  
  
END
GO


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
			-- Mevcut kay?tlar? sil (ayn? m??teri + d?nem)
			DELETE FROM ALT.AutoTransferCleansing WHERE AccountNumber = @AccountNumber AND Period = @Period;
			-- Insert i?lemi

			INSERT INTO ALT.AutoTransferCleansing (
			FirmType,
			GroupNumber,
			AccountNumber,
			Period,
			FinancialItemDefinitionId,
			OriginalValue,
			CorrectedValue,
			UserName,
			HostName,
			HostIP,
			SystemDate
			)
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
				AND NOT EXISTS (SELECT 1 
				                  FROM ALT.CustomerFinancialItem C WITH (NOLOCK) 
				                 WHERE C.FirmType = 1
								  AND C.GroupNumber = 0
								  AND C.AccountNumber = @AccountNumber
								  AND C.PeriodId = @Period
								  AND C.FinancialItemDefinitionId = F.FinancialItemDefinitionId)
				UNION ALL
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
				DELETE FROM ALT.FinancialItemCorrection WHERE FinancialItemCorrectionMasterId = @MasterId
				DELETE FROM ALT.FinancialItemCorrectionMaster WHERE FinancialItemCorrectionMasterId = @MasterId
			END

			IF NOT EXISTS (SELECT TOP 1 1 FROM boa.ALT.PCAutoCorrection pc WITH (NOLOCK) WHERE pc.AccountNumber = @AccountNumber AND pc.PeriodId = @Period)
			BEGIN
				INSERT INTO ALT.PCAutoCorrection (PowerCurveCallId,AccountNumber,PeriodId,UserName,SystemDate)
				VALUES (0, @AccountNumber, @Period, @UserName, GETDATE());

			END


END;
GO

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
   

        DECLARE @FID100 INT, @FID600 INT, @FID563 INT,@V100 DECIMAL(22, 2) = 0,@V600 DECIMAL(22, 2) = 0

		SELECT @FID100 = ISNULL(MAX(CASE WHEN Code = '100' THEN FinancialItemDefinitionId ELSE 0 END),0),
			   @FID600 = ISNULL(MAX(CASE WHEN Code = '600' THEN FinancialItemDefinitionId ELSE 0 END),0),
			   @FID563 = ISNULL(MAX(CASE WHEN Code = '563' THEN FinancialItemDefinitionId ELSE 0 END),0)
		  FROM ALT.FinancialItemDefinition WITH (NOLOCK)
		 WHERE Code IN ('100', '600', '563')

		IF @FID100 IS NULL OR @FID600 IS NULL OR @FID563 IS NULL
		BEGIN
			RAISERROR ('Gerekli FinancialItemDefinition (100, 600, 563) bulunamad?.', 16, 1)
			RETURN
		END
			SELECT
				@V100 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID100 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@V600 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID600 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
			  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
			 WHERE AccountNumber = @AccountNumber
			   AND Period        = @Period
			   AND FinancialItemDefinitionId IN (@FID100, @FID600)
			   

			DECLARE @Cap	  DECIMAL(22, 2),
					@Delta	  DECIMAL(22, 2),
					@DeltaNeg DECIMAL(22, 2)

			SET @Cap = CASE WHEN (@V600 * 0.02) < 5000000 THEN CAST(@V600 * 0.02 AS DECIMAL(22, 2)) ELSE CAST(5000000 AS DECIMAL(22, 2)) END
			SET @Delta = CASE WHEN @V100 > @Cap THEN CAST(@V100 - @Cap AS DECIMAL(22, 2)) ELSE CAST(0 AS DECIMAL(22, 2)) END
			SET @DeltaNeg = -@Delta

			DECLARE @Mesaj100 varchar(4000) =CONCAT(N'Rule1: Fiktif kasa ?st s?n?r(', CONVERT(NVARCHAR(500), @Cap), N') fazlas?(',CONVERT(NVARCHAR(500), @Delta), N') ??kar?ld?.')
			DECLARE @Mesaj563 varchar(4000) =CONCAT(N'Rule1: Fiktif kasa fazlas?(', CONVERT(NVARCHAR(500), @Delta), N') 563 hesab?na aktar?ld?.')

			EXEC ALT.ins_ATC_History @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID100,
									 @AccountCode = N'100',@Amount = @Delta,@TransactionType = '-',@Description = @Mesaj100,@UserName = @UserName,
									 @HostName = @HostName,@HostIP = @HostIP

			EXEC ALT.ins_ATC_History @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID563,
									 @AccountCode = N'563',@Amount = @Delta,@TransactionType = '+',@Description = @Mesaj563,@UserName = @UserName,
									 @HostName = @HostName,@HostIP = @HostIP

			IF @Delta > 0
			BEGIN
					EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId, @AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID100,
														   @Amount = @DeltaNeg, @UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP

					EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId, @AccountNumber = @AccountNumber, @Period = @Period,@FinancialItemDefinitionId = @FID563,
														   @Amount = @Delta,@UserName = @UserName, @HostName = @HostName,@HostIP = @HostIP


					EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID100,
													   @AccountCode = N'100',@Amount = @Delta,@TransactionType = '-',@Description = @Mesaj100,@UserName = @UserName,
													   @HostName = @HostName,@HostIP = @HostIP;

					EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId, @AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID563,
													   @AccountCode = N'563',@Amount = @Delta,@TransactionType = '+',@Description = @Mesaj563,@UserName = @UserName,
													   @HostName = @HostName,@HostIP = @HostIP


			END

END
GO

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
    DECLARE @FID101 INT, @FID121 INT, @V101 DECIMAL(22,2) = 0,@Desc101 NVARCHAR(4000),@Desc121 NVARCHAR(4000),@V101Neg DECIMAL(22,2)=0

    SELECT
        @FID101 = ISNULL(MAX(CASE WHEN Code = N'101' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = ISNULL(MAX(CASE WHEN Code = N'121' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
	WHERE Code IN ('101','121')

    IF @FID101 IS NULL OR @FID121 IS NULL
	BEGIN
	 RAISERROR('Gerekli FinancialItemDefinition (101, 121) bulunamad?.', 16, 1)
    	RETURN
    END
    SELECT
			@V101 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID101 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
	  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
	 WHERE AccountNumber = @AccountNumber
	   AND Period        = @Period
	   AND FinancialItemDefinitionId IN (@FID101)
    IF @V101 > 0
    BEGIN
        SET @Desc101 = N'Rule 2: 101 hesab?ndaki tutar 121 hesab?na aktar?lmak ?zere ??kar?ld?.'
        SET @Desc121 = N'Rule 2: 101 hesab?ndaki tutar 121 hesab?na eklendi.'
    END
    ELSE
    BEGIN
        SET @Desc101 = N'Rule 2: 101 hesab?nda bakiye yok, transfer yap?lmad?.'
        SET @Desc121 = N'Rule 2: 101 hesab?nda bakiye yok, 121 hesab?na ekleme yap?lmad?.'
    END

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID101, @AccountCode=N'101',
         @Amount=@V101, @TransactionType='-',@Description=@Desc101,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
         @Amount=@V101, @TransactionType='+',@Description=@Desc121,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

    IF @V101 > 0
    BEGIN
         SET @V101Neg = -@V101
         EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId, @AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID101,
														  @Amount = @V101Neg,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId, @AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID121,
														 @Amount = @V101,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP

	
		EXEC ALT.ins_ATC_HistoryCorrection @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID101, @AccountCode=N'101',
				 @Amount=@V101, @TransactionType='-',@Description=@Desc101,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
				 @Amount=@V101, @TransactionType='+',@Description=@Desc121,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

    END
END
GO

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
	DECLARE  @SearchTerms   NVARCHAR(4000) ,@FID102 INT, @FID121 INT,@Delta DECIMAL(22,2) = 0,@DeltaNeg DECIMAL(22,2)=0
   
	   SELECT @SearchTerms= ParamDescription
	     FROM boa.cor.Parameter WITH(NOLOCK)
	    WHERE ParamType = 'ATCSEARCH'
	      AND ParamCode = '3'
	      AND LanguageId = 1

    SELECT @FID102 = ISNULL(MAX(CASE WHEN Code = N'102' THEN FinancialItemDefinitionId ELSE 0 END),0),
		   @FID121 = ISNULL(MAX(CASE WHEN Code = N'121' THEN FinancialItemDefinitionId ELSE 0 END),0)
     FROM ALT.FinancialItemDefinition WITH (NOLOCK)
	WHERE Code IN ('102','121')

    IF @FID102 IS NULL OR @FID121 IS NULL
	BEGIN
	    RAISERROR('Gerekli FinancialItemDefinition (102, 121) bulunamad?.', 16, 1)
        RETURN
	END
  

    SELECT @Delta= ISNULL(NetSum_Leaves,0) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber,@Period, N'102',1, @SearchTerms)

    DECLARE @Desc102 NVARCHAR(4000) = N'Rule3: 102 alt kalemlerinden [' + ISNULL(@SearchTerms,N'') + N'] filtrelendi, Toplam=' + CONVERT(NVARCHAR(50), @Delta)
    DECLARE @Desc121 NVARCHAR(4000) = N'Rule3: 102 alt kalemlerinden [' + ISNULL(@SearchTerms,N'') + N'] aktar?lan tutar eklendi, Toplam=' + CONVERT(NVARCHAR(50), @Delta)

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID102, @AccountCode=N'102',
							 @Amount=@Delta, @TransactionType='-', @Description=@Desc102,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
							 @Amount=@Delta, @TransactionType='+',@Description=@Desc121,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

     IF @Delta > 0
    BEGIN
        SET @DeltaNeg  = -@Delta
        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID102,
														   @Amount = @DeltaNeg,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID121,
														 @Amount = @Delta,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP

        EXEC ALT.ins_ATC_HistoryCorrection @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID102, @AccountCode=N'102',
										   @Amount=@Delta, @TransactionType='-',@Description=@Desc102,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID121, @AccountCode=N'121',
										   @Amount=@Delta, @TransactionType='+',@Description=@Desc121,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP
    END
END
GO

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
    SET NOCOUNT ON

    /* 0) FID'leri yakala (103, 321) */
    DECLARE @FID103 INT, @FID321 INT,@V103 DECIMAL(22,2) = 0,@V103Neg DECIMAL(22,2)=0

    SELECT
        @FID103 = ISNULL(MAX(CASE WHEN Code = N'103' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID321 = ISNULL(MAX(CASE WHEN Code = N'321' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
	WHERE Code in ('103','321')

    IF @FID103 IS NULL OR @FID321 IS NULL
	BEGIN
	   RAISERROR('Gerekli FinancialItemDefinition (103, 321) bulunamad?.', 16, 1)
	   RETURN
	END
    
    SELECT
		@V103 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID103 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
	  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
     WHERE AccountNumber = @AccountNumber
       AND Period        = @Period
       AND FinancialItemDefinitionId IN (@FID103)

    DECLARE @Desc103 NVARCHAR(4000) =CASE WHEN @V103 > 0 THEN N'Rule 4: 103 hesab?ndaki t?m tutar 321 hesab?na aktar?ld?.' ELSE N'Rule 4: 103 hesab?nda bakiye yok, transfer yap?lmad?.' END
    DECLARE @Desc321 NVARCHAR(4000) =CASE WHEN @V103 > 0 THEN N'Rule 4: 103 hesab?ndan gelen tutar 321 hesab?na eklendi.' ELSE N'Rule 4: 103 hesab?nda bakiye yok, 321 hesab?na ekleme yap?lmad?.' END

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID103, @AccountCode=N'103',@Amount=@V103, @TransactionType='-',
							 @Description=@Desc103,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FID321, @AccountCode=N'321',
         @Amount=@V103, @TransactionType='+',@Description=@Desc321,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP

    IF @V103 > 0
    BEGIN
        SET @V103Neg = -@V103;
        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID103,
														 @Amount = @V103Neg,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP
        EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID321,
														 @Amount = @V103,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID103,@AccountCode = N'103',
													 @Amount = @V103,@TransactionType = '-',@Description = @Desc103,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID321,@AccountCode = N'321',
													 @Amount = @V103,@TransactionType = '+',@Description = @Desc321,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP
    END
END
GO

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
        @FIDRoot   = ISNULL(MAX(CASE WHEN Code = @RootCode   THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FIDTarget = ISNULL(MAX(CASE WHEN Code = @TargetCode THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
	 WHERE code IN (@RootCode,@TargetCode)

    IF @FIDRoot IS NULL OR @FIDTarget IS NULL
	BEGIN
	    RAISERROR('Gerekli FinancialItemDefinition (120, 340) bulunamad?.', 16, 1);
		RETURN
    END
       

    /* 120 alt k?r?l?mlardaki alacak bakiyesi toplam? (k?k hari?) */
    SELECT @LeafCredit = ISNULL(CreditSum_Leaves,0) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, @RootCode, 1,null);

    /* 120 ana kalemin alacak bakiyesi (mizan) */
    SELECT @RootCredit = COALESCE(SUM(CreditBalance), 0)
    FROM ALT.CustomerDetailedTrialBalance WITH (NOLOCK)
    WHERE AccountNumber = @AccountNumber
      AND Period        = @Period
      AND AccountCode   = @RootCode COLLATE SQL_Latin1_General_CP1_CI_AS;

    /* Delta = (alt kalem alacak toplam?) - (ana kalem alacak) */
    SET @Delta = ISNULL(@LeafCredit,0) - ISNULL(@RootCredit,0);

    /* History a??klamalar? + i?lem tipi */
    DECLARE @TxnType CHAR(1) = CASE WHEN @Delta >= 0 THEN '+' ELSE '-' END;

    DECLARE @DescRoot NVARCHAR(4000) = N'Rule5: 120 yaprak alacak toplam? (' + CONVERT(NVARCHAR(50), ISNULL(@LeafCredit,0)) +
        N') - ana alacak (' + CONVERT(NVARCHAR(50), ISNULL(@RootCredit,0)) +N') = ' + CONVERT(NVARCHAR(50), ISNULL(@Delta,0)) + N'.';

    DECLARE @DescTarget NVARCHAR(4000) = N'Rule5: 120 ters bakiyesi kadar 340 hesab? g?ncellendi.';

    /* History (ins_ATC_History ile) */
    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FIDRoot, @AccountCode=@RootCode,
         @Amount= @Delta, @TransactionType=@TxnType,@Description=@DescRoot,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    EXEC ALT.ins_ATC_History @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,@FinancialItemDefinitionId=@FIDTarget, @AccountCode=@TargetCode,
         @Amount= @Delta, @TransactionType=@TxnType, @Description=@DescTarget,@UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

    /* Delta pozitif ise CorrectedValue g?ncelle */
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

    -- FID de?erlerini filtreli al
    SELECT
        @FID120 = ISNULL(MAX(CASE WHEN Code = N'120' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID320 = ISNULL(MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('120', '320');

    IF @FID120 IS NULL OR @FID320 IS NULL
	BEGIN
    	RAISERROR('Gerekli FinancialItemDefinition (120, 320) bulunamad?.', 16, 1);
		RETURN
    END

	DECLARE @T TABLE
	(
		RootCode    CHAR(3)        NOT NULL,   -- '120' veya '320'
		AccountDescription   NVARCHAR(4000),
		Amount      DECIMAL(22,2),
		AccountCode NVARCHAR(500)
	);

	INSERT INTO @T (RootCode, AccountDescription, Amount, AccountCode)
	SELECT
		CASE 
			WHEN t.AccountCode LIKE '120%' THEN '120'
			WHEN t.AccountCode LIKE '320%' THEN '320'
		END AS RootCode,
		t.AccountDescription,
		CASE 
			WHEN t.AccountCode LIKE '120%' THEN ISNULL(t.DebitBalance, 0)
			WHEN t.AccountCode LIKE '320%' THEN ISNULL(t.CreditBalance, 0)
		END AS Amount,
		t.AccountCode
	FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
	WHERE t.AccountNumber = @AccountNumber
	  AND t.Period        = @Period
	  AND (t.AccountCode LIKE '120%' OR t.AccountCode LIKE '320%')
	  AND NOT EXISTS            -- yaprak (leaf) hesap
	  (
			SELECT 1
			FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
			WHERE c.AccountNumber      = t.AccountNumber
			  AND c.Period             = t.Period
			  AND c.ParentAccountCode  = t.AccountCode
	  );
        

    -- E?le?en unvanlar ?zerinden d?n
    DECLARE @Title NVARCHAR(255),
            @Amt120 DECIMAL(22,2),
            @Amt320 DECIMAL(22,2),
            @Delta  DECIMAL(22,2),
			@DeltaNeg  DECIMAL(22,2),
            @AccCode120 NVARCHAR(50),
            @AccCode320 NVARCHAR(50),
            @Desc NVARCHAR(4000);

		SELECT 
			t120.AccountDescription AS AccountDescription120,
			t320.AccountDescription AS AccountDescription320,
			t120.Amount            AS Amount120,
			t320.Amount            AS Amount320,
			t120.AccountCode       AS AccountCode120,
			t320.AccountCode       AS AccountCode320
		INTO #Matches
		FROM @T t120
		JOIN @T t320
			ON t120.RootCode = '120'
		   AND t320.RootCode = '320'
		CROSS APPLY ALT.fCompareFirstTwoWords_ATC(t120.AccountDescription, t320.AccountDescription) cmp
		WHERE cmp.Result = 1;


		IF NOT EXISTS( select top 1 1 from #Matches)
		BEGIN  
     	 EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=0, @AccountCode=null,
             @Amount= null, @TransactionType=null,
             @Description='Rule6: 120 ve 320 e?le?en kay?t bulunamad?',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
			RETURN
        END

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        select AccountDescription120,
		       Amount120,
			   Amount320,
			   AccountCode120,
			   AccountCode320 
		from #Matches

    OPEN cur;
    FETCH NEXT FROM cur INTO @Title, @Amt120, @Amt320, @AccCode120, @AccCode320;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- K???k olan? Delta olarak belirle
        SET @Delta = CASE WHEN @Amt120 <= @Amt320 THEN @Amt120 ELSE @Amt320 END;
		SET @DeltaNeg = -@Delta;
        -- A??klama metni
        SET @Desc = N'Rule6: "' + ISNULL(@Title,N'') + N'" unvan? i?in 120-320 kar??l?kl? mahsup. Delta='
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

        -- Delta > 0 ise d?zeltme yap
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
        @FID120 INT, @FID121 INT, @FID127 INT,@FID128 INT, @FID129 INT,
        @FID136 INT, @FID138 INT, @FID139 INT,@FID562 INT;

    SELECT
        @FID120 = ISNULL(MAX(CASE WHEN Code = '120' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = ISNULL(MAX(CASE WHEN Code = '121' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID127 = ISNULL(MAX(CASE WHEN Code = '127' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID128 = ISNULL(MAX(CASE WHEN Code = '128' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID129 = ISNULL(MAX(CASE WHEN Code = '129' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID136 = ISNULL(MAX(CASE WHEN Code = '136' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID138 = ISNULL(MAX(CASE WHEN Code = '138' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID139 = ISNULL(MAX(CASE WHEN Code = '139' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID562 = ISNULL(MAX(CASE WHEN Code = '562' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('120','121','127','128','129','136','138','139','562');

    /* 2) De?i?kenler */
    DECLARE 
        @NegNeed      DECIMAL(22,2) = 0, 
        @Need         DECIMAL(22,2) = 0,
        @V120         DECIMAL(22,2) = 0,
        @NegV120      DECIMAL(22,2) = 0,
        @V121         DECIMAL(22,2) = 0,
        @NegV121      DECIMAL(22,2) = 0,
        @V127         DECIMAL(22,2) = 0,
        @V128         DECIMAL(22,2) = 0,
        @V129         DECIMAL(22,2) = 0,
        @V136         DECIMAL(22,2) = 0,
        @NegV136      DECIMAL(22,2) = 0,
        @V138         DECIMAL(22,2) = 0,
        @V139         DECIMAL(22,2) = 0,
        @Need138      DECIMAL(22,2) = 0,
        @NegNeed138   DECIMAL(22,2) = 0;

    SELECT
        @V120 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID120 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
        @V121 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID121 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
        @V127 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID127 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
        @V128 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID128 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
        @V129 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID129 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
        @V136 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID136 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
        @V138 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID138 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0), 
        @V139 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID139 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
    FROM ALT.AutoTransferCleansing WITH (NOLOCK)
    WHERE AccountNumber = @AccountNumber
      AND Period        = @Period
      AND FinancialItemDefinitionId IN 
          (@FID120,@FID121,@FID127,@FID128,@FID129,@FID136,@FID138,@FID139);

    /* Ortak Negatifler */
    SET @NegV120 = -@V120;
    SET @NegV121 = -@V121;
    SET @NegV136 = -@V136;

    ------------------------------------------------------------------------
    -- #128 / #129 BLO?U
    ------------------------------------------------------------------------
    SET @Need    = CASE WHEN @V128 > @V129 THEN (@V128 - @V129) ELSE (@V129 - @V128) END;
    SET @NegNeed = -@Need;

    IF @V128 > @V129
    BEGIN
        /* 
           #128 > #129 ise, #128 - #129 fark? #129?a eklenecek, #562?ye eklenecek.
           128?den azal?? yok, sadece 129 ve 562 art?yor. 
        */
	    DECLARE @Desc129 NVARCHAR(4000) = N'Rule7: (#128 > #129) 128 fazla bakiye 129''a aktar?ld?.';
        DECLARE @Desc562 NVARCHAR(4000) = N'Rule7: (#128 > #129) 128 fazla bakiye 562''ye aktar?ld?.';

        -- 129 art?r
		EXEC ALT.upd_ATC_AddDeltaWithAncestors 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID129,@Amount=@Need,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;  

        -- 562 art?r
		EXEC ALT.upd_ATC_AddDeltaWithAncestors 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID562,@Amount=@Need,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

        -- History
        EXEC ALT.ins_ATC_History 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID129,@AccountCode=N'129',
             @Amount=@Need,@TransactionType='+',@Description=@Desc129,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID129,@AccountCode=N'129',
             @Amount=@Need,@TransactionType='+',@Description=@Desc129,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

        EXEC ALT.ins_ATC_History 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID562,@AccountCode=N'562',
             @Amount=@Need,@TransactionType='+',@Description=@Desc562,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID562,@AccountCode=N'562',
             @Amount=@Need,@TransactionType='+',@Description=@Desc562,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
    END
    ELSE IF @V129 > @V128
    BEGIN 
        /* #128 < #129 taraf? */

        IF @Need <= @V120
        BEGIN
           /* 
              #129 - #128 <= #120 ise, #129 - #128 fark? #120?den eksiltilecek, #128?e eklenecek 
           */
		   -- 120 azalt
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@Amount=@NegNeed,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 128 art?r
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@Amount=@Need,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

           -- History
		   EXEC ALT.ins_ATC_History 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                @Amount=@Need,@TransactionType='-',
                @Description=N'Rule7: (#129 - #128 <= #120) 129-128 fark? 120''den eksiltildi.',
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   EXEC ALT.ins_ATC_HistoryCorrection 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                @Amount=@Need,@TransactionType='-',
                @Description=N'Rule7: (#129 - #128 <= #120) 129-128 fark? 120''den eksiltildi.',
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   EXEC ALT.ins_ATC_History 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                @Amount=@Need,@TransactionType='+',
                @Description=N'Rule7: (#129 - #128 <= #120) 129-128 fark? 128''e aktar?ld?.',
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   EXEC ALT.ins_ATC_HistoryCorrection 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                @Amount=@Need,@TransactionType='+',
                @Description=N'Rule7: (#129 - #128 <= #120) 129-128 fark? 128''e aktar?ld?.',
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
		ELSE IF @Need <= @V120 + @V121
		BEGIN
           /*
              #129 - #128 <= #120 + #121 ise,
              - #120?deki tutar?n tamam? #120?den eksiltilecek, #128?e eklenecek
              - #129 - #128 - #120 fark? #121?den eksiltilecek, #128?e eklenecek 
           */
		   DECLARE @Need121 DECIMAL(22,2) = @Need - @V120;
		   DECLARE @NegNeed121 DECIMAL(22,2) = -@Need121;

		   -- 120 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@Amount=@NegV120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 128 art?r (120 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@Amount=@V120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            -- 121 azalt (kalan fark)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID121,@Amount=@NegNeed121,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 128 art?r (121'den gelen)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@Amount=@Need121,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
         
            -- History

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 120 kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 120 kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@Need121,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 129-128-120 fark? 121''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@Need121,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 129-128-120 fark? 121''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@Need121,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 129-128-120 fark? 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@Need121,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121) 129-128-120 fark? 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
		ELSE IF @Need <= @V120 + @V121 + @V127
		BEGIN
            /*
              #129 - #128 <= #120 + #121 + #127 ise,
              - #120?deki tutar?n tamam? #120?den eksiltilecek, #128?e eklenecek 
              - #121?deki tutar?n tamam? #121?den eksiltilecek, #128?e eklenecek 
              - #129 - #128 - #120 - #121 fark? #127?den eksiltilecek, #128?e eklenecek 
            */
		   DECLARE @Need127 DECIMAL(22,2) = @Need - @V120 - @V121;
		   DECLARE @NegNeed127 DECIMAL(22,2) = -@Need127;

		   -- 120 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@Amount=@NegV120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 128 art?r (120 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@Amount=@V120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 121 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID121,@Amount=@NegV121,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 128 art?r (121 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@Amount=@V121,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 127 azalt (kalan fark)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID127,@Amount=@NegNeed127,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 128 art?r (127'den gelen)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID128,@Amount=@Need127,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
         
            -- History

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 120 kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 120 kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@V121,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 121 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@V121,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 121 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@V121,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 121 kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@V121,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 121 kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID127,@AccountCode=N'127',
                 @Amount=@Need127,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 129-128-120-121 fark? 127''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		    EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID127,@AccountCode=N'127',
                 @Amount=@Need127,@TransactionType='-',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 129-128-120-121 fark? 127''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		    EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@Need127,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 129-128-120-121 fark? kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		    EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID128,@AccountCode=N'128',
                 @Amount=@Need127,@TransactionType='+',
                 @Description=N'Rule7: (#129 - #128 <= #120 + #121 + #127) 129-128-120-121 fark? kadar 128''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
    END
	ELSE
	BEGIN
	    EXEC ALT.ins_ATC_History
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=0,@AccountCode=NULL,
             @Amount=NULL,@TransactionType=NULL,
             @Description=N'Rule7: 128-129 e?it oldu?u i?in bir bakiye aktar?m? olmad?',
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
	END

    ------------------------------------------------------------------------
    -- #138 / #139 BLO?U
    ------------------------------------------------------------------------
	SET @Need138    = CASE WHEN @V138 > @V139 THEN (@V138 - @V139) ELSE (@V139 - @V138) END;
	SET @NegNeed138 = -@Need138;
	  
    IF @V138 > @V139
    BEGIN
        /*
           #138 > #139 ise, #138 - #139 fark? #139?a eklenecek, #562?ye eklenecek.
           138?den azal?? yok; 139 ve 562 art?yor.
        */
	    DECLARE @Desc139 NVARCHAR(4000)  = N'Rule7: (#138 > #139) 138 fazla bakiye 139''a aktar?ld?.';
        DECLARE @Desc562b NVARCHAR(4000) = N'Rule7: (#138 > #139) 138 fazla bakiye 562''ye aktar?ld?.';

        -- 139 art?r
		EXEC ALT.upd_ATC_AddDeltaWithAncestors 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID139,@Amount=@Need138,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

        -- 562 art?r
		EXEC ALT.upd_ATC_AddDeltaWithAncestors 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID562,@Amount=@Need138,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
             
        -- History
        EXEC ALT.ins_ATC_History 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID139,@AccountCode=N'139',
             @Amount=@Need138,@TransactionType='+',@Description=@Desc139,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID139,@AccountCode=N'139',
             @Amount=@Need138,@TransactionType='+',@Description=@Desc139,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
 	   
    	EXEC ALT.ins_ATC_History 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID562,@AccountCode=N'562',
             @Amount=@Need138,@TransactionType='+',@Description=@Desc562b,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;	   

        EXEC ALT.ins_ATC_HistoryCorrection 
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=@FID562,@AccountCode=N'562',
             @Amount=@Need138,@TransactionType='+',@Description=@Desc562b,
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
    END
    ELSE IF @V139 > @V138
    BEGIN
        /* #138 < #139 taraf? */

        IF @Need138 <= @V136
		BEGIN
           /*
              #139 - #138 <= #136 ise, #139 - #138 fark? #136?dan eksiltilecek, #138?e eklenecek 
           */
		   -- 136 azalt
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID136,@Amount=@NegNeed138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			-- 138 art?r
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@Need138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            -- History
			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@Need138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136) 139-138 fark? 136''dan eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@Need138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136) 139-138 fark? 136''dan eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136) 139-138 fark? 138''e aktar?ld?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136) 139-138 fark? 138''e aktar?ld?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
		ELSE IF @Need138 <= @V136 + @V120  
		BEGIN
           /*
              #139 - #138 <= #136 + #120 ise,  
              - #136?daki tutar?n tamam? #136?dan eksiltilecek, #138?e eklenecek 
              - #139 - #138 - #136 fark? #120?den eksiltilecek, #138?e eklenecek 
           */
		   DECLARE @Need120_138 DECIMAL(22,2) = @Need138 - @V136;
		   DECLARE @NegNeed120_138 DECIMAL(22,2) = -@Need120_138;

		   -- 136 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID136,@Amount=@NegV136,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			-- 138 art?r (136 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@V136,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		    -- 120 azalt (kalan fark)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@Amount=@NegNeed120_138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 138 art?r (120'den gelen)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@Need120_138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
         
            -- History

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@V136,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 136 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@V136,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 136 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V136,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 136 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V136,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 136 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@Need120_138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 139-138-136 fark? 120''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@Need120_138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 139-138-136 fark? 120''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need120_138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 139-138-136 fark? 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need120_138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120) 139-138-136 fark? 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
		ELSE IF @Need138 <= @V136 + @V120 + @V121
		BEGIN
           /*
              #139 - #138 <= #136 + #120 + #121 ise,  
              - #136?daki tutar?n tamam? #136?dan eksiltilecek, #138?e eklenecek 
              - #120?deki tutar?n tamam? #120?den eksiltilecek, #138?e eklenecek 
              - #139 - #138 - #136 - #120 fark? #121?den eksiltilecek, #138?e eklenecek 
           */
		   DECLARE @Need121_138 DECIMAL(22,2) = @Need138 - @V136 - @V120;
		   DECLARE @NegNeed121_138 DECIMAL(22,2) = -@Need121_138;

		   -- 136 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID136,@Amount=@NegV136,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			-- 138 art?r (136 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@V136,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		    -- 120 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@Amount=@NegV120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 138 art?r (120 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@V120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            -- 121 azalt (kalan fark)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID121,@Amount=@NegNeed121_138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 138 art?r (121'den gelen)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@Need121_138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

           -- History

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@V136,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 136 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@V136,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 136 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V136,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 136 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V136,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 136 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 120 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 120 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@Need121_138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 139-138-136-120 fark? 121''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@Need121_138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 139-138-136-120 fark? 121''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need121_138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 139-138-136-120 fark? 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need121_138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121) 139-138-136-120 fark? 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
		ELSE IF @Need138 <= @V136 + @V120 + @V121 + @V127
		BEGIN
           /*
              #139 - #138 <= #136 + #120 + #121 + #127 ise,  
              - #136?daki tutar?n tamam? #136?dan eksiltilecek, #138?e eklenecek 
              - #120?deki tutar?n tamam? #120?den eksiltilecek, #138?e eklenecek 
              - #121?deki tutar?n tamam? #121?den eksiltilecek, #138?e eklenecek 
              - #139 - #138 - #136 - #120 - #121 fark? #127?den eksiltilecek, #138?e eklenecek 
           */
		   DECLARE @Need127_138 DECIMAL(22,2) = @Need138 - @V136 - @V120 - @V121;
		   DECLARE @NegNeed127_138 DECIMAL(22,2) = -@Need127_138;

		   -- 136 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID136,@Amount=@NegV136,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			-- 138 art?r (136 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@V136,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		    -- 120 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID120,@Amount=@NegV120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 138 art?r (120 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@V120,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            -- 121 azalt (tamam?)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID121,@Amount=@NegV121,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 138 art?r (121 kadar)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@V121,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            -- 127 azalt (kalan fark)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID127,@Amount=@NegNeed127_138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

		   -- 138 art?r (127'den gelen)
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                @FinancialItemDefinitionId=@FID138,@Amount=@Need127_138,
                @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

           -- History

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@V136,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 136 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID136,@AccountCode=N'136',
                 @Amount=@V136,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 136 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V136,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 136 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V136,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 136 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID120,@AccountCode=N'120',
                 @Amount=@V120,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 120 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 120 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V120,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 120 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@V121,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 121 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID121,@AccountCode=N'121',
                 @Amount=@V121,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 121 s?f?rland?.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V121,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 121 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@V121,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 121 kadar 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID127,@AccountCode=N'127',
                 @Amount=@Need127_138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 139-138-136-120-121 fark? 127''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID127,@AccountCode=N'127',
                 @Amount=@Need127_138,@TransactionType='-',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 139-138-136-120-121 fark? 127''den eksiltildi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_History 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need127_138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 139-138-136-120-121 fark? 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;

            EXEC ALT.ins_ATC_HistoryCorrection 
                 @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
                 @FinancialItemDefinitionId=@FID138,@AccountCode=N'138',
                 @Amount=@Need127_138,@TransactionType='+',
                 @Description=N'Rule7: (#139 - #138 <= #136 + #120 + #121 + #127) 139-138-136-120-121 fark? 138''e eklendi.',
                 @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
		END
    END
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History
             @RuleId=@RuleId,@AccountNumber=@AccountNumber,@Period=@Period,
             @FinancialItemDefinitionId=0,@AccountCode=NULL,
             @Amount=NULL,@TransactionType=NULL,
             @Description=N'Rule7: 138-139 e?it oldu?u i?in bir bakiye aktar?m? olmad?',
             @UserName=@UserName,@HostName=@HostName,@HostIP=@HostIP;
	END
END
GO

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
    ------------------------------------------------------------
    -- 0) D?NEM T?R?
    ------------------------------------------------------------
	DECLARE @IsFullPeriod BIT= CASE WHEN SUBSTRING(CAST(@Period AS VARCHAR(10)),5,1) = '4' THEN 1 ELSE 0 END;

    ------------------------------------------------------------
    -- Sabitler
    ------------------------------------------------------------
    DECLARE @Amt120 DECIMAL(22,2),
            @Amt127 DECIMAL(22,2),
            @Amt159 DECIMAL(22,2),
            @Amt120Neg DECIMAL(22,2),
            @Amt127Neg DECIMAL(22,2),
            @Amt159Neg DECIMAL(22,2),
			@FID120 INT, 
			@FID127 INT, 
			@FID128 INT,
			@FID129 INT, 
			@FID562 INT, 
			@FID159 INT,
            @AccountCode	 VARCHAR(200),
			@DebitAmount	 DECIMAL(22, 2),
			@DebitBalance	 DECIMAL(22, 2),
			@CreditAmount	 DECIMAL(22, 2),
			@TmpCreditAmount DECIMAL(22, 2),
			@TmpPeriod		 INT,
			@TmpPeriod1 INT,
			@TmpPeriod2 INT,
			@TmpCredit1 DECIMAL(22, 2),
			@TmpCredit2 DECIMAL(22, 2);
	DECLARE @TblNow TABLE (AccountCode VARCHAR(200),DebitAmount DECIMAL(22, 2),DebitBalance DECIMAL(22, 2),CreditAmount DECIMAL(22, 2))
	DECLARE @TblUnchanged TABLE (AccountCode VARCHAR(200),DebitBalance DECIMAL(22, 2))

    SELECT
        @FID120 = NULLIF(MAX(CASE WHEN Code='120' THEN FinancialItemDefinitionId END),0),
        @FID127 = NULLIF(MAX(CASE WHEN Code='127' THEN FinancialItemDefinitionId END),0),
        @FID159 = NULLIF(MAX(CASE WHEN Code='159' THEN FinancialItemDefinitionId END),0),
        @FID128 = NULLIF(MAX(CASE WHEN Code='128' THEN FinancialItemDefinitionId END),0),
        @FID129 = NULLIF(MAX(CASE WHEN Code='129' THEN FinancialItemDefinitionId END),0),
        @FID562 = NULLIF(MAX(CASE WHEN Code='562' THEN FinancialItemDefinitionId END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('120','127','159','128','129','562');

 

    ------------------------------------------------------------
    -- 1) ??MD?K? D?NEM ? YAPRAK HESAPLAR
    ------------------------------------------------------------
	INSERT INTO @TblNow (AccountCode,DebitAmount,DebitBalance,CreditAmount)
    SELECT
        t.AccountCode,
        SUM(ISNULL(t.Debit,0)) ,
        SUM(ISNULL(t.DebitBalance,0)) ,
        SUM(ISNULL(t.Credit,0))
     FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
    WHERE t.AccountNumber = @AccountNumber
      AND t.Period = @Period
      AND (t.AccountCode LIKE '120%' OR t.AccountCode LIKE '127%' OR t.AccountCode LIKE '159%')
      AND NOT EXISTS (
            SELECT 1
            FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
            WHERE c.AccountNumber = t.AccountNumber
              AND c.Period = t.Period
              AND c.ParentAccountCode = t.AccountCode
      )
    GROUP BY t.AccountCode;

	

    ------------------------------------------------------------
    -- 2) REFERANS D?NEMLER (TAM / ARA KURALI)
    ------------------------------------------------------------
    DECLARE cur CURSOR FAST_FORWARD READ_ONLY LOCAL FOR SELECT AccountCode,
														   DebitAmount,
														   DebitBalance,
														   CreditAmount FROM @TblNow;

	OPEN cur;
	FETCH NEXT FROM cur
	INTO @AccountCode, @DebitAmount, @DebitBalance, @CreditAmount;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @TmpCreditAmount = NULL;
		SET @TmpPeriod = NULL;

		--------------------------------------------------------
		-- TAM / ARA kontrol
		--------------------------------------------------------
		IF @IsFullPeriod = 0
		BEGIN
		

			SET @TmpPeriod1 = NULL;
			SET @TmpPeriod2 = NULL;
			SET @TmpCredit1 = NULL;
			SET @TmpCredit2 = NULL;

			;
			WITH PrevFullPeriods
			  AS (SELECT t.Period,
						 t.Credit,
						 ROW_NUMBER() OVER (ORDER BY t.Period DESC) AS rn 
					FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK) 
				   WHERE t.AccountNumber = @AccountNumber
					 AND t.AccountCode = @AccountCode
					 AND t.Period < @Period
					 AND SUBSTRING(CAST(t.Period AS VARCHAR(10)), 5, 1) = '4')
			SELECT @TmpPeriod1 = MAX(CASE WHEN rn = 1 THEN Period END),
				   @TmpCredit1 = MAX(CASE WHEN rn = 1 THEN Credit END),
				   @TmpPeriod2 = MAX(CASE WHEN rn = 2 THEN Period END),
				   @TmpCredit2 = MAX(CASE WHEN rn = 2 THEN Credit END)
			  FROM PrevFullPeriods;


			IF @CreditAmount = @TmpCredit1 AND @CreditAmount = @TmpCredit2
			BEGIN
				INSERT INTO @TblUnchanged (AccountCode, DebitBalance) VALUES (@AccountCode, @DebitBalance);
			END

		END
		ELSE
		BEGIN
			----------------------------------------------------
			-- ?nceki TAM d?nem
			----------------------------------------------------
			SELECT TOP 1 @TmpPeriod = t.Period, @TmpCreditAmount = t.Credit
			  FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
			 WHERE t.AccountNumber = @AccountNumber
			   AND t.AccountCode = @AccountCode
			   AND t.Period < @Period
			   AND SUBSTRING(CAST(t.Period AS VARCHAR(10)), 5, 1) = '4'
			 ORDER BY t.Period DESC;

			----------------------------------------------------
			-- ?nceki yoksa ? Sonraki TAM d?nem
			----------------------------------------------------
			IF @TmpCreditAmount IS NULL
			BEGIN
				SELECT TOP 1 @TmpPeriod = t.Period,
							 @TmpCreditAmount = t.Credit
				  FROM ALT.CustomerDetailedTrialBalance t WITH (NOLOCK)
				 WHERE t.AccountNumber = @AccountNumber
				   AND t.AccountCode = @AccountCode
				   AND t.Period > @Period
				   AND SUBSTRING(CAST(t.Period AS VARCHAR(10)), 5, 1) = '4'
				 ORDER BY t.Period ASC;
			END

			----------------------------------------------------
			-- Karar
			----------------------------------------------------

			IF @TmpCreditAmount = @CreditAmount
			BEGIN
				INSERT INTO @TblUnchanged (AccountCode,DebitBalance) VALUES (@AccountCode, @DebitBalance);
			END
		END

		FETCH NEXT FROM cur
		INTO @AccountCode, @DebitAmount, @DebitBalance, @CreditAmount;
	END

	CLOSE cur;
	DEALLOCATE cur;

    ------------------------------------------------------------
    -- 4) TUTARLAR
    ------------------------------------------------------------
   SELECT
        @Amt120 = SUM(CASE WHEN LEFT(AccountCode,3)='120' THEN DebitBalance ELSE 0 END),
        @Amt127 = SUM(CASE WHEN LEFT(AccountCode,3)='127' THEN DebitBalance ELSE 0 END),
        @Amt159 = SUM(CASE WHEN LEFT(AccountCode,3)='159' THEN DebitBalance ELSE 0 END)
    FROM @TblUnchanged;

    SELECT
        @Amt120 = ISNULL(@Amt120,0),
        @Amt127 = ISNULL(@Amt127,0),
        @Amt159 = ISNULL(@Amt159,0),
        @Amt120Neg = -ISNULL(@Amt120,0),
        @Amt127Neg = -ISNULL(@Amt127,0),
        @Amt159Neg = -ISNULL(@Amt159,0);

    ------------------------------------------------------------
    -- 5) MUHASEBE AKTARIM BLOKLARI
    -- (120 / 127 / 159 ? 128 + 129 + 562)
    ------------------------------------------------------------
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
             @Description=N'Rule08: Donuk alacak aktar?m? nedeniyle 120 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID120, @AccountCode=N'120',
             @Amount=@Amt120, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktar?m? nedeniyle 120 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktar?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktar?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk 128 kar??l??? 129 eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: Donuk 128 kar??l??? 129 eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP; 

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: 128 i?in 562 gider kar??l??? ayr?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt120, @TransactionType='+',
             @Description=N'Rule08: 128 i?in 562 gider kar??l??? ayr?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;


    END
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID120, @AccountCode=N'120',
             @Amount=null, @TransactionType=null,
             @Description=N'Rule8: Donuk alacak aktar?m?  olmad??? i?in bir aktar?m yap?lmad?',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	END

    /* --- 127 blo?u: 127(-), 128(+), 129(+), 562(+) --- */
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
             @Description=N'Rule08: Donuk alacak aktar?m? nedeniyle 127 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	     EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID127, @AccountCode=N'127',
             @Amount=@Amt127, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktar?m? nedeniyle 127 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktar?ld? (127).',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktar?ld? (127).',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP; 
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127 kaynakl?) i?in 129 kar??l??? eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127 kaynakl?) i?in 129 kar??l??? eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP; 
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127) i?in 562 gider kar??l??? ayr?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt127, @TransactionType='+',
             @Description=N'Rule08: 128 (127) i?in 562 gider kar??l??? ayr?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID127, @AccountCode=N'127',
             @Amount=null, @TransactionType=null,
             @Description=N'Rule8: Donuk alacak aktar?m?  olmad??? i?in bir aktar?m yap?lmad?',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	END

	/* --- 159 blo?u: 159(-), 128(+), 129(+), 562(+) --- */
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
             @Description=N'Rule08: Donuk alacak aktar?m? nedeniyle 159 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID159, @AccountCode=N'159',
             @Amount=@Amt159, @TransactionType='-',
             @Description=N'Rule08: Donuk alacak aktar?m? nedeniyle 159 eksiltildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktar?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: Donuk alacak 128 hesaba aktar?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 i?in 129 kar??l??? eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID129, @AccountCode=N'129',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 i?in 129 kar??l??? eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 i?in 562 gider kar??l??? ayr?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID562, @AccountCode=N'562',
             @Amount=@Amt159, @TransactionType='+',
             @Description=N'Rule08: 128 i?in 562 gider kar??l??? ayr?ld?.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
    END
	ELSE
	BEGIN
	    EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID128, @AccountCode=N'128',
             @Amount=null, @TransactionType=null,
             @Description=N'Rule8: Donuk alacak aktar?m?  olmad??? i?in bir aktar?m yap?lmad?',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	END

END
GO


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
    SET NOCOUNT ON
    SET XACT_ABORT ON

	IF OBJECT_ID('tempdb..#Matches') IS NOT NULL DROP TABLE #Matches
	IF OBJECT_ID('tempdb..#CustomerDetailedTrialBalance') IS NOT NULL DROP TABLE #CustomerDetailedTrialBalance
	
	DECLARE @Accounts TABLE  (AccCode NVARCHAR(50),FID INT)
	
	CREATE TABLE #Matches(NormTitle NVARCHAR(4000),Amount    DECIMAL(22,2),AccCode   NVARCHAR(50),FIDSource INT)
    CREATE CLUSTERED INDEX IX_Matches_FID_Acc ON #Matches(FIDSource, AccCode)
    
	DECLARE @FID128 INT, @FID129 INT, @FID562 INT,@FID120 INT, @FID127 INT, @FID131 INT,@FID132 INT, @FID133 INT, @FID136 INT,
	        @Title NVARCHAR(4000),@Amt DECIMAL(22,2),@DeltaNeg DECIMAL(22,2),@AccCode NVARCHAR(50),@FIDSourceCur INT,@DescSrc NVARCHAR(4000),
            @Desc128 NVARCHAR(4000), @Desc129 NVARCHAR(4000),@Desc562 NVARCHAR(4000)

        -- FID de?erlerini al
        SELECT
            @FID128 = ISNULL(MAX(CASE WHEN Code = N'128' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID129 = ISNULL(MAX(CASE WHEN Code = N'129' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID562 = ISNULL(MAX(CASE WHEN Code = N'562' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID120 = ISNULL(MAX(CASE WHEN Code = N'120' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID127 = ISNULL(MAX(CASE WHEN Code = N'127' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID131 = ISNULL(MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID132 = ISNULL(MAX(CASE WHEN Code = N'132' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID133 = ISNULL(MAX(CASE WHEN Code = N'133' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID136 = ISNULL(MAX(CASE WHEN Code = N'136' THEN FinancialItemDefinitionId ELSE 0 END),0)
        FROM ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('128', '129', '562','120', '127', '131', '132', '133', '136')

        IF @FID128 IS NULL OR @FID129 IS NULL OR @FID562 IS NULL
        BEGIN
            RAISERROR('Gerekli FinancialItemDefinition (128, 129, 562) bulunamad?.', 16, 1)
            RETURN;
        END

		INSERT INTO @Accounts VALUES ('120',@FID120), ('127',@FID127), ('131',@FID131), ('132',@FID132), ('133',@FID133), ('136',@FID136)
		DECLARE @Today SMALLDATETIME = CAST(GETDATE() AS DATE)
        SELECT DISTINCT
				   cdtb.AccountDescription AS NormTitle,
				   ISNULL(cdtb.DebitBalance, 0) AS Amount,
				   cdtb.AccountCode,
			       a.FID,
				   ALT.fn_NormalizeCompany_First2_Scalar(cdtb.AccountDescription) AS Title
				INTO #CustomerDetailedTrialBalance
               FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
         INNER JOIN @Accounts a ON cdtb.AccountCode LIKE a.AccCode + '%'
              WHERE cdtb.AccountNumber = @AccountNumber
                AND cdtb.Period        = @Period
		
       

         INSERT INTO #Matches (NormTitle, Amount, AccCode, FIDSource)
             SELECT DISTINCT
				   cdtb.NormTitle,
				   cdtb.Amount,
				   cdtb.AccountCode,
			       cdtb.FID
               FROM #CustomerDetailedTrialBalance cdtb
          INNER JOIN ALT.GreyListCacheAtc g WITH (NOLOCK) ON g.TranDate =@Today AND g.Title = cdtb.Title

        

        IF NOT EXISTS (SELECT TOP 1 1 FROM #Matches)
        BEGIN
            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=0, @AccountCode=NULL,
                 @Amount=NULL, @TransactionType=NULL,
                 @Description='Rule9: Gri liste ile e?le?en bir kay?t olmad??? i?in herhangi bir i?lem yap?lmad?.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
            RETURN;
        END

        

        -------------------------------------------------------------------
        -- DE????KL?K 2: Cursor ORDER BY FIDSource, AccCode
        -- B?ylece t?m session'lar ayn? lock s?ras?n? izler ? deadlock azal?r
        -------------------------------------------------------------------
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT NormTitle, Amount, AccCode, FIDSource
            FROM #Matches
            ORDER BY FIDSource, AccCode;

        OPEN cur;
        FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @FIDSourceCur;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @FIDSourceCur IS NOT NULL
            BEGIN
                -- A??klamalar
                SET @DescSrc = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. '+ ISNULL(@AccCode,N'') + N' hesab?ndan ??kar?ld?.';
                SET @Desc128 = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. 128 hesab?na eklendi.';
                SET @Desc129 = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. 129 hesab?na eklendi.';
                SET @Desc562 = N'Rule9: ' + ISNULL(@Title,N'') + N' gri listede. 562 hesab?na eklendi.';

                -- History
                EXEC ALT.ins_ATC_History
                     @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                     @FinancialItemDefinitionId=@FIDSourceCur, @AccountCode=@AccCode,
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

                -- CorrectedValue / delta
                IF @Amt > 0
                BEGIN
                    SET @DeltaNeg = -@Amt;

                    EXEC ALT.upd_ATC_AddDeltaWithAncestors
                         @RuleId = @RuleId,
                         @AccountNumber = @AccountNumber,
                         @Period = @Period,
                         @FinancialItemDefinitionId = @FIDSourceCur,
                         @Amount = @DeltaNeg,
                         @UserName = @UserName,
                         @HostName = @HostName,
                         @HostIP = @HostIP;

                    EXEC ALT.upd_ATC_AddDeltaWithAncestors
                         @RuleId = @RuleId,
                         @AccountNumber = @AccountNumber,
                         @Period = @Period,
                         @FinancialItemDefinitionId = @FID128,
                         @Amount = @Amt,
                         @UserName = @UserName,
                         @HostName = @HostName,
                         @HostIP = @HostIP;

                    EXEC ALT.upd_ATC_AddDeltaWithAncestors
                         @RuleId = @RuleId,
                         @AccountNumber = @AccountNumber,
                         @Period = @Period,
                         @FinancialItemDefinitionId = @FID129,
                         @Amount = @Amt,
                         @UserName = @UserName,
                         @HostName = @HostName,
                         @HostIP = @HostIP;

                    EXEC ALT.upd_ATC_AddDeltaWithAncestors
                         @RuleId = @RuleId,
                         @AccountNumber = @AccountNumber,
                         @Period = @Period,
                         @FinancialItemDefinitionId = @FID562,
                         @Amount = @Amt,
                         @UserName = @UserName,
                         @HostName = @HostName,
                         @HostIP = @HostIP;

                    EXEC ALT.ins_ATC_HistoryCorrection
                         @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                         @FinancialItemDefinitionId=@FIDSourceCur, @AccountCode=@AccCode,
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

            FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @FIDSourceCur;
        END

        CLOSE cur;
        DEALLOCATE cur;

    
END
GO

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
	    @SearchKarsiliksiz NVARCHAR(100) ,
        @SearchProtestolu NVARCHAR(100) 
    DECLARE 
        @FID101 INT, @FID121 INT,
        @FID128 INT, @FID129 INT, @FID562 INT;

	SELECT @SearchKarsiliksiz=CASE WHEN ParamCode = '10_1' then ParamDescription else N'Kar??l?ks?z' END,
	       @SearchProtestolu=CASE WHEN ParamCode = '10_2' then ParamDescription else N'Protestolu' END
      FROM boa.cor.Parameter WITH(NOLOCK)
     WHERE ParamType = 'ATCSEARCH'
       AND ParamCode in ( '10_1','10_2')
       AND LanguageId = 1
    SELECT
        @FID101 = ISNULL(MAX(CASE WHEN Code = '101' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID121 = ISNULL(MAX(CASE WHEN Code = '121' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID128 = ISNULL(MAX(CASE WHEN Code = '128' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID129 = ISNULL(MAX(CASE WHEN Code = '129' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID562 = ISNULL(MAX(CASE WHEN Code = '562' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('101','121','128','129','562');

    IF @FID101 IS NULL OR @FID121 IS NULL OR @FID128 IS NULL OR @FID129 IS NULL OR @FID562 IS NULL
	BEGIN
    	 RAISERROR('Gerekli FinancialItemDefinition kay?tlar? eksik.', 16, 1);
		 RETURN
    END
       

    /* 101 alt k?r?l?m - Kar??l?ks?z */
    DECLARE @Amt101 DECIMAL(22,2) =0;
    SELECT @Amt101 = SUM(ISNULL(NetSum_Leaves,0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period,N'101', 1,@SearchKarsiliksiz) l
       
   

    SET @Amt101 = ISNULL(@Amt101,0);
	DECLARE @Amt101Neg DECIMAL(22,2) = -@Amt101;

    -- History (kaynak 101 - , hedefler +)
    DECLARE @Desc101Src  NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" ifadesi i?in 101 bakiyesi 128-129-562?ye aktar?m.';
    DECLARE @Desc101_128 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" (101) kaynakl? tutar 128 hesab?na eklendi.';
    DECLARE @Desc101_129 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" (101) kaynakl? tutar 129 hesab?na eklendi.';
    DECLARE @Desc101_562 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchKarsiliksiz,N'') + N'" (101) kaynakl? tutar 562 hesab?na eklendi.';

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

    /* 121 alt k?r?l?m - Protestolu */
    DECLARE @Amt121 DECIMAL(22,2)=0;
	SELECT @Amt121 = SUM(ISNULL(NetSum_Leaves,0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period,N'121', 1,@SearchProtestolu)
    
   
    SET @Amt121 = ISNULL(@Amt121,0);
	DECLARE @Amt121Neg DECIMAL(22,2)= -@Amt121;
    -- History (kaynak 121 - , hedefler +)
    DECLARE @Desc121Src  NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" ifadesi i?in 121 bakiyesi 128-129-562?ye aktar?m.';
    DECLARE @Desc121_128 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" (121) kaynakl? tutar 128 hesab?na eklendi.';
    DECLARE @Desc121_129 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" (121) kaynakl? tutar 129 hesab?na eklendi.';
    DECLARE @Desc121_562 NVARCHAR(4000) = N'Rule10: "' + ISNULL(@SearchProtestolu,N'') + N'" (121) kaynakl? tutar 562 hesab?na eklendi.';

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
			@FID131 = ISNULL(MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID132 = ISNULL(MAX(CASE WHEN Code = N'132' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID331 = ISNULL(MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID332 = ISNULL(MAX(CASE WHEN Code = N'332' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID561 = ISNULL(MAX(CASE WHEN Code = N'561' THEN FinancialItemDefinitionId ELSE 0 END),0)
     FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('131','132','331','332','561');

    -------------------------------------------------
    -- Grup / Risk / Ortakl?k k?meleri
    -------------------------------------------------
    

    INSERT INTO @TblGroup EXEC ALT.sel_GroupCustomerByAccountNumber @AccountNumber;  -- sabit 16835 yerine parametre
    INSERT INTO @CustomerIdList SELECT AccountNumber FROM @TblGroup;
    INSERT INTO @TblSharedRelation  EXEC ALT.sel_ShareholderCustomerByAccountNumberList @CustomerIdList;

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT AccountNumber FROM @TblGroup;
    OPEN c;
    FETCH NEXT FROM c INTO @CustomerId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Bu sat?r, SP'nin tek kolon (CustomerId) d?nd?rd???n? varsayar
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
    -- BDDK Grup ?yeleri: T?zel / Ger?ek
    -------------------------------------------------
    INSERT INTO @Tuzel
    SELECT Distinct CustomerName
    FROM #MergedAccountsWithDetailInfo WITH (NOLOCK)
    WHERE PersonType = 1;

    INSERT INTO @Gercek
    SELECT DISTINCT CustomerName
    FROM #MergedAccountsWithDetailInfo WITH (NOLOCK)
    WHERE PersonType = 0;

    -------------------------------------------------
    -- Hesap gruplar?
    -------------------------------------------------
    
    INSERT INTO @Receivable VALUES ('120'),('121'),('127'),('136'),('159');
    INSERT INTO @Payable VALUES ('320'),('321'),('329'),('336'),('340');

    -------------------------------------------------
	-- E?le?en kay?tlar (ilk 2 kelime bazl?)
	-------------------------------------------------



	-- Alacaklar (T?zel)
	INSERT INTO @Matches
	SELECT 
		cdtb.AccountDescription,
		ISNULL(cdtb.DebitBalance,0),
		cdtb.AccountCode,
		1,     -- IsReceivable = 1
		0      -- IsTuzel = 0 (t?zel)
	FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
	JOIN @Receivable r ON LEFT(cdtb.AccountCode,3) = r.Code
	JOIN @Tuzel t ON 1 = 1   -- e?le?tirme fonksiyonda
	CROSS APPLY ALT.fCompareFirstTwoWords_ATC(cdtb.AccountDescription, t.NormTitle) cmp
	WHERE cdtb.AccountNumber = @AccountNumber
	  AND cdtb.Period        = @Period
	  AND ISNULL(cdtb.DebitBalance,0) > 0
	  AND cmp.Result = 1;


	-- Alacaklar (Ger?ek)
	INSERT INTO @Matches
	SELECT 
		cdtb.AccountDescription,
		ISNULL(cdtb.DebitBalance,0),
		cdtb.AccountCode,
		1,     -- IsReceivable = 1
		1      -- IsTuzel = 1 (ger?ek)
	FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
	JOIN @Receivable r ON LEFT(cdtb.AccountCode,3) = r.Code
	JOIN @Gercek g ON 1 = 1
	CROSS APPLY ALT.fCompareFirstTwoWords_ATC(cdtb.AccountDescription, g.NormTitle) cmp
	WHERE cdtb.AccountNumber = @AccountNumber
	  AND cdtb.Period        = @Period
	  AND ISNULL(cdtb.DebitBalance,0) > 0
	  AND cmp.Result = 1;


	-- Bor?lar (T?zel)
	INSERT INTO @Matches
	SELECT 
		cdtb.AccountDescription,
		ISNULL(cdtb.CreditBalance,0),
		cdtb.AccountCode,
		0,     -- IsReceivable = 0
		0      -- IsTuzel = 0 (t?zel)
	FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
	JOIN @Payable p ON LEFT(cdtb.AccountCode,3) = p.Code
	JOIN @Tuzel t  ON 1 = 1
	CROSS APPLY ALT.fCompareFirstTwoWords_ATC(cdtb.AccountDescription, t.NormTitle) cmp
	WHERE cdtb.AccountNumber = @AccountNumber
	  AND cdtb.Period        = @Period
	  AND ISNULL(cdtb.CreditBalance,0) > 0
	  AND cmp.Result = 1;


	-- Bor?lar (Ger?ek)
	INSERT INTO @Matches
	SELECT 
		cdtb.AccountDescription,
		ISNULL(cdtb.CreditBalance,0),
		cdtb.AccountCode,
		0,     -- IsReceivable = 0
		1      -- IsTuzel = 1 (ger?ek)
	FROM ALT.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
	JOIN @Payable p ON LEFT(cdtb.AccountCode,3) = p.Code
	JOIN @Gercek g  ON 1 = 1
	CROSS APPLY ALT.fCompareFirstTwoWords_ATC(cdtb.AccountDescription, g.NormTitle) cmp
	WHERE cdtb.AccountNumber = @AccountNumber
	  AND cdtb.Period        = @Period
	  AND ISNULL(cdtb.CreditBalance,0) > 0
	  AND cmp.Result = 1;

    -------------------------------------------------
    -- ??leme d?ng?s?
    -------------------------------------------------
	IF NOT EXISTS ( SELECT TOP 1 1 FROM @Matches)
	BEGIN
	    EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=0, @AccountCode=NULL,
                 @Amount=null, @TransactionType=NULL,
                 @Description=N'Rule11:  BDDK/Ortakl?k listesinde. e?le?me olmad??? i?in aktar?m yap?lmad?',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		RETURN
	END
    
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT m.NormTitle, m.Amount, m.AccCode, m.IsReceivable, m.IsTuzel,fi.FinancialItemDefinitionId
		  FROM @Matches m
	INNER JOIN ALT.FinancialItemDefinition fi WITH (NOLOCK) on fi.Code = LEFT(m.AccCode,3);

    OPEN cur;
    FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @IsReceivable, @IsTuzel,@FIDSource;

    WHILE @@FETCH_STATUS = 0
    BEGIN
	    SET @DeltaNeg = -@Amt;
        -- Hedef FID & hesap kodu (mevcut mant??a g?re)
        IF @IsReceivable = 1
        BEGIN
            IF @IsTuzel = 0  -- t?zel
            BEGIN
                SET @FIDTarget = @FID132; SET @TargetCode = N'132';
            END
            ELSE             -- ger?ek
            BEGIN
                SET @FIDTarget = @FID131; SET @TargetCode = N'131';
            END
        END
        ELSE
        BEGIN
            IF @IsTuzel = 0  -- t?zel
            BEGIN
                SET @FIDTarget = @FID332; SET @TargetCode = N'332';
            END
            ELSE             -- ger?ek
            BEGIN
                SET @FIDTarget = @FID331; SET @TargetCode = N'331';
            END
        END

        IF @FIDSource IS NOT NULL AND @FIDTarget IS NOT NULL AND ISNULL(@Amt,0) <> 0
        BEGIN
            -- History
            SET @DescSrc = N'Rule11: ' + ISNULL(@Title,N'') + N' BDDK/Ortakl?k listesinde. ' + ISNULL(@AccCode,N'') + N' hesab?ndan ??kar?ld?.';
            SET @DescTgt = N'Rule11: ' + ISNULL(@Title,N'') + N' BDDK/Ortakl?k listesinde. ' + @TargetCode + N' hesab?na eklendi.';

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

        FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @IsReceivable, @IsTuzel,@FIDSource;
    END

    CLOSE cur; DEALLOCATE cur;

  
END
GO

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
        @FID131 = ISNULL(MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId else 0 END),0),
        @FID231 = ISNULL(MAX(CASE WHEN Code = N'231' THEN FinancialItemDefinitionId else 0 END),0),
        @FID331 = ISNULL(MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId else 0 END),0),
        @FID431 = ISNULL(MAX(CASE WHEN Code = N'431' THEN FinancialItemDefinitionId else 0 END),0),
        @FID561 = ISNULL(MAX(CASE WHEN Code = N'561' THEN FinancialItemDefinitionId else 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('131','231','331','431','561');

    /* Bakiye de?erleri */
    
	DECLARE @Amt131 DECIMAL(22,2),
        @Amt231 DECIMAL(22,2),
        @Amt331 DECIMAL(22,2),
        @Amt431 DECIMAL(22,2);

	SELECT
		@Amt131 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID131 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
		@Amt231 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID231 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
		@Amt331 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID331 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
		@Amt431 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID431 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
	FROM ALT.AutoTransferCleansing WITH (NOLOCK)
	WHERE AccountNumber = @AccountNumber
	  AND Period        = @Period
	  AND FinancialItemDefinitionId IN (@FID131, @FID231, @FID331, @FID431);


    DECLARE @Delta DECIMAL(22,2) = @Amt131 - @Amt331;
	DECLARE @Amt131Neg DECIMAL(22,2) = -@Amt131 ;
	DECLARE @Amt331Neg DECIMAL(22,2) = -@Amt331 ;

    DECLARE @Delta231 DECIMAL(22,2) = @Amt231 - @Amt431;
	DECLARE @Amt231Neg DECIMAL(22,2) = -@Amt231 ;
	DECLARE @Amt431Neg DECIMAL(22,2) = -@Amt431 ;
	

	/*
		o	#131 <= #331 ise, #131?deki bakiyenin tamam? hem #131?den hem de #331?den eksiltilecek
		o	#131 > #331 ise, #131?deki bakiyenin tamam? #131?den eksiltilecek, #331?deki bakiyenin tamam? #331?den eksiltilecek, 
			 #131 - #331 fark? #561?e eklenecek
	*/
    IF @Amt131 <= @Amt331
	BEGIN
	   EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Amt131, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
             @Amount=@Amt131, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	    IF @Amt131 >0
		BEGIN
		   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Amt131, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection
				 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
				 @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
				 @Amount=@Amt131, @TransactionType='-',
				 @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
				 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
															   @AccountNumber = @AccountNumber,
															   @Period = @Period,
															   @FinancialItemDefinitionId = @FID131,
															   @Amount = @Amt131Neg,
															   @UserName = @UserName,
															   @HostName = @HostName,
															   @HostIP = @HostIP;
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
															   @AccountNumber = @AccountNumber,
															   @Period = @Period,
															   @FinancialItemDefinitionId = @FID331,
															   @Amount = @Amt131Neg,
															   @UserName = @UserName,
															   @HostName = @HostName,
															   @HostIP = @HostIP;
		END
		
	END
	ELSE
	BEGIN
	   
	  
	  EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Amt131, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
             @Amount=@Amt331, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		 EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
             @Amount=@Delta, @TransactionType='+',
             @Description=N'Rule12: 131 ve 331 mahsupla?ma fark? 561?e eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
        IF @Amt131 >0
		BEGIN
		   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID131, @AccountCode=N'131',
             @Amount=@Amt131, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
		    EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID131,
														   @Amount = @Amt131Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		 END
		 IF @Amt331 >0
		 BEGIN
		   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID331, @AccountCode=N'331',
             @Amount=@Amt331, @TransactionType='-',
             @Description=N'Rule12: 131 ve 331 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;	 
		   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID331,
														   @Amount = @Amt331Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
          END
		  IF @Delta >0
		  BEGIN
		     EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
             @Amount=@Delta, @TransactionType='+',
             @Description=N'Rule12: 131 ve 331 mahsupla?ma fark? 561?e eklendi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	    
		
		
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID561,
														   @Amount = @Delta,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		  END

			
		END
		

    /*
	   o	#231 <= #431 ise, #231?deki bakiyenin tamam? hem #231?den hem de #431?den eksiltilecek
	   o	#231 > #431 ise, #231?deki bakiyenin tamam? #231?den eksiltilecek, #431?deki bakiyenin tamam? #431?den eksiltilecek,
		#231 - #431 fark? #561?e eklenecek
	*/
    
	IF @Amt231 <= @Amt431
	BEGIN
	    EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID231, @AccountCode=N'231',
             @Amount=@Amt231, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID431, @AccountCode=N'431',
             @Amount=@Amt231, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	   
	    IF @Amt231 >0
		BEGIN
		   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID231, @AccountCode=N'231',
             @Amount=@Amt231, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID431, @AccountCode=N'431',
             @Amount=@Amt231, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID231,
														   @Amount = @Amt231Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID431,
														   @Amount = @Amt231Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		END

		
	END
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID231, @AccountCode=N'231',
             @Amount=@Amt231, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID431, @AccountCode=N'431',
             @Amount=@Amt431, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
	    EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Delta231, @TransactionType='+',
                 @Description=N'Rule12: 231 ve 431 mahsupla?ma fark? 561?e eklendi.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		IF @Amt231>0
		BEGIN
		   EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID231, @AccountCode=N'231',
             @Amount=@Amt231, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
			 EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID231,
														   @Amount = @Amt231Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		END
		IF @Amt431>0
		BEGIN
		     EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FID431, @AccountCode=N'431',
             @Amount=@Amt431, @TransactionType='-',
             @Description=N'Rule12: 231 ve 431 kar??l?kl? mahsup edildi.',
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID431,
														   @Amount = @Amt431Neg,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		END

		IF @Delta231>0
		BEGIN
		   EXEC ALT.ins_ATC_HistoryCorrection
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FID561, @AccountCode=N'561',
                 @Amount=@Delta231, @TransactionType='+',
                 @Description=N'Rule12: 231 ve 431 mahsupla?ma fark? 561?e eklendi.',
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

		   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID561,
														   @Amount = @Delta231,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		END

	END
END
GO

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
	DECLARE @Y DECIMAL(22,2) = 0, @B481 DECIMAL(22,2) = 0,@X DECIMAL(22,2) = 0, @B381 DECIMAL(22,2) = 0,
			@Delta300 DECIMAL(22,2),@Delta300Neg DECIMAL(22,2),@AbsDelta300 DECIMAL(22,2),@DeltaX DECIMAL(22,2),@Delta381 DECIMAL(22,2),
		    @Delta400 DECIMAL(22,2),@Delta400Neg DECIMAL(22,2),@AbsDelta400 DECIMAL(22,2),@DeltaY DECIMAL(22,2),@Delta481 DECIMAL(22,2)


    SELECT
        @FID180 = ISNULL(MAX(CASE WHEN Code = N'180' THEN FinancialItemDefinitionId ELSE 0 END),0), 
        @FID280 = ISNULL(MAX(CASE WHEN Code = N'280' THEN FinancialItemDefinitionId ELSE 0 END),0), 
        @FID300 = ISNULL(MAX(CASE WHEN Code = N'300' THEN FinancialItemDefinitionId ELSE 0 END),0), 
        @FID400 = ISNULL(MAX(CASE WHEN Code = N'400' THEN FinancialItemDefinitionId ELSE 0 END),0), 
        @FID381 = ISNULL(MAX(CASE WHEN Code = N'381' THEN FinancialItemDefinitionId ELSE 0 END),0), 
        @FID481 = ISNULL(MAX(CASE WHEN Code = N'481' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN (N'180',N'280',N'300',N'400',N'381',N'481');

    IF @FID180 IS NULL OR @FID280 IS NULL OR @FID300 IS NULL OR @FID400 IS NULL OR @FID381 IS NULL OR @FID481 IS NULL
    BEGIN
        RAISERROR(N'Gerekli FID''ler (180,280,300,400,381,481) bulunamad?.',16,1);
        RETURN;
    END
	  Declare @SearchWords VARCHAR(120)
	  
	SELECT @SearchWords=ParamDescription
      FROM boa.cor.Parameter WITH(NOLOCK)
     WHERE ParamType = 'ATCSEARCH'
       AND ParamCode in ( '13')
       AND LanguageId = 1

	-- 180 alt kalemlerinde terim e?le?en yaprak toplam? (X)
	  SELECT @X =SUM(COALESCE(NetSum_Leaves, 0) ) from ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, N'180', 1, @SearchWords)   
    -- 280 alt kalemlerinde terim e?le?en yaprak toplam? (Y)
	  SELECT @Y =SUM(COALESCE(NetSum_Leaves, 0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, N'280', 1, @SearchWords)

      SELECT
			@B381 = ISNULL(SUM(CASE WHEN a.FinancialItemDefinitionId = @FID381 THEN ISNULL(a.CorrectedValue,0) ELSE 0 END),0),
			@B481 = ISNULL(SUM(CASE WHEN a.FinancialItemDefinitionId = @FID481 THEN ISNULL(a.CorrectedValue,0) ELSE 0 END),0)
		FROM ALT.AutoTransferCleansing a WITH (NOLOCK)
		WHERE a.AccountNumber = @AccountNumber
		  AND a.[Period]      = @Period
		  AND a.FinancialItemDefinitionId IN (@FID381, @FID481);

        
	
	    SET @Delta300 = (@X - @B381)
		SET @AbsDelta300 = ABS(@Delta300)
		SET @DeltaX = -@X
		SET @Delta381 = -@B381
		SET @Delta300Neg = -@Delta300
	    SET @Delta400 = (@Y - @B481)
		SET @AbsDelta400 = ABS(@Delta400)
		SET @DeltaY = -@Y
		SET @Delta481 = -@B481
		SET @Delta400Neg = -@Delta400  

		IF @X<>0
		BEGIN
		
			EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID180, N'180', @X, N'-', N'Rule13: 180 terim e?le?en toplam X kadar eksiltildi.', @UserName, @HostName, @HostIP;
			EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID381, N'381', @B381, N'-', N'Rule13: 381 bakiye kadar eksiltildi.', @UserName, @HostName, @HostIP;
			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID180, N'180', @X, N'-', N'Rule13: 180 d?zeltme.', @UserName, @HostName, @HostIP;
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period, @FinancialItemDefinitionId = @FID180,@Amount = @DeltaX,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
			
			IF @B381<> 0
			BEGIN
			   EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID381, N'381', @B381, N'-', N'Rule13: 381 d?zeltme.', @UserName, @HostName, @HostIP;
			   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID381,@Amount = @Delta381,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
			END
		   
			IF @Delta300 > 0
			BEGIN
			   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID300, N'300', @Delta300, N'-', N'Rule13: X-B381 kadar 300''den eksiltildi.', @UserName, @HostName, @HostIP;
			   EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID300, N'300', @Delta300, N'-', N'Rule13: 300 d?zeltme (eksiltme).', @UserName, @HostName, @HostIP;
			   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID300,@Amount = @Delta300Neg,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
     		END
			ELSE IF @Delta300 < 0
			BEGIN
				 -- X < B381: 300?e ekle (mutlak de?er kadar +)
				EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID300, N'300', @AbsDelta300, N'+', N'Rule13: B381-X kadar 300''e eklendi.', @UserName, @HostName, @HostIP;
				EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID300, N'300', @AbsDelta300, N'+', N'Rule13: 300 d?zeltme (ekleme).', @UserName, @HostName, @HostIP;
				EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID300,@Amount = @AbsDelta300,@HostName = @HostName,@HostIP = @HostIP;
     		END
		END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, NULL, null, null, N'Rule13: 180 alt kalemlerinde terim e?le?en yaprak toplam? (X) de?eri 0 oldu?u i?in i?lem yap?lmad?.', @UserName, @HostName, @HostIP;
			
		END
            
		IF @Y<>0
		BEGIN	
			EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID280, N'280', @Y, N'-', N'Rule13: 280 terim e?le?en toplam Y kadar eksiltildi.', @UserName, @HostName, @HostIP;
			EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID481, N'481', @B481, N'-', N'Rule13: 481 bakiye kadar eksiltildi.', @UserName, @HostName, @HostIP;
			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID280, N'280', @Y, N'-', N'Rule13: 280 d?zeltme.', @UserName, @HostName, @HostIP;
			EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID280,@Amount = @DeltaY,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
			
			IF @B481<> 0
			BEGIN
			   EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID481, N'481', @Delta481, N'-', N'Rule13: 481 d?zeltme.', @UserName, @HostName, @HostIP;
			   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID481,@Amount = @Delta481,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
			END
		   
			IF @Delta400 > 0
			BEGIN
			   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID400, N'400', @Delta400, N'-', N'Rule13: Y-B481 kadar 400''den eksiltildi.', @UserName, @HostName, @HostIP;
			   EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID400, N'400', @Delta400, N'-', N'Rule13: 400 d?zeltme (eksiltme).', @UserName, @HostName, @HostIP;
			   EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period, @FinancialItemDefinitionId = @FID400,@Amount = @Delta400Neg,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
     		END
			ELSE IF @Delta400 < 0
			BEGIN
				EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID400, N'400', @AbsDelta400, N'+', N'Rule13: B481-Y kadar 400''e eklendi.', @UserName, @HostName, @HostIP;
				EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID400, N'400', @AbsDelta400, N'+', N'Rule13: 400 d?zeltme (ekleme).', @UserName, @HostName, @HostIP;
				EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,@AccountNumber = @AccountNumber,@Period = @Period,@FinancialItemDefinitionId = @FID400,@Amount = @AbsDelta400,@UserName = @UserName,@HostName = @HostName,@HostIP = @HostIP;
     		END
		END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, NULL, null, null, N'Rule13: 280 alt kalemlerinde terim e?le?en yaprak toplam? (Y) de?eri 0 oldu?u i?in i?lem yap?lmad?.', @UserName, @HostName, @HostIP;
			
		END
      
  
END
GO

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

    SELECT @FID191 = ISNULL(MAX(CASE WHEN Code='191' THEN FinancialItemDefinitionId ELSE 0 END),0),
           @FID391 = ISNULL(MAX(CASE WHEN Code='391' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('191','391');

    IF @FID191 IS NULL OR @FID391 IS NULL
	BEGIN
    	RAISERROR(N'Gerekli FinancialItemDefinition (191,391) bulunamad?.',16,1);
		RETURN
    END
	
	SELECT
			@Amt191 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID191 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
			@Amt391 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID391 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
	  FROM ALT.AutoTransferCleansing WITH (NOLOCK)																		
	 WHERE AccountNumber = @AccountNumber
	   AND Period        = @Period
	   AND FinancialItemDefinitionId IN (@FID191, @FID391);
   

	SET @Delta = CASE WHEN @Amt191 <= @Amt391 THEN @Amt191 ELSE @Amt391 END;
	DECLARE @Desc NVARCHAR(4000) = CASE WHEN @Amt191 <= @Amt391 THEN N'Rule14: 191?391 mahsupla?ma 191 kadar d???ld?' ELSE N'Rule14: 191?391 mahsupla?ma 391 kadar d???ld?' END;
    declare  @DeltaNeg DECIMAL(22,2) = -@Delta;

    IF @Delta > 0
    BEGIN
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID191, N'191', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID391, N'391', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;
		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID191, N'191', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID391, N'391', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;
		
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
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null, N'Rule14: 191?391  0 oldu?u i?in aktar?m yap?lmad?.', @UserName, @HostName, @HostIP;
	END
END

GO

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

    SELECT @FID192 = ISNULL(MAX(CASE WHEN Code='192' THEN FinancialItemDefinitionId ELSE 0 END),0),
           @FID392 = ISNULL(MAX(CASE WHEN Code='392' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('192','392');

    IF @FID192 IS NULL OR @FID392 IS NULL 
	BEGIN
	   RAISERROR(N'Gerekli FinancialItemDefinition (192,392) bulunamad?.',16,1); 
	   RETURN
    	
    END
	

    SELECT
			@Amt192 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID192 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
			@Amt392 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID392 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
		FROM ALT.AutoTransferCleansing WITH (NOLOCK)
		WHERE AccountNumber = @AccountNumber
		  AND Period        = @Period
		  AND FinancialItemDefinitionId IN (@FID192, @FID392);

    SET @Delta = CASE WHEN @Amt192 <= @Amt392 THEN @Amt192 ELSE @Amt392 END;
	DECLARE @DeltaNeg DECIMAL(22,2)= -@Delta;

	DECLARE @Desc NVARCHAR(4000) = CASE WHEN @Amt192 <= @Amt392  THEN N'Rule15: 192?392 mahsupla?ma 192 kadar d???ld?' ELSE N'Rule14: 191?391 mahsupla?ma 392 kadar d???ld?' END;
    IF @Delta > 0
    BEGIN
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID192, N'192', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID392, N'392', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID192, N'192', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID392, N'392', @Delta, N'-', @Desc, @UserName, @HostName, @HostIP;

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
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null, N'Rule15: 192?392 0 oldu?u i?in aktar?m yap?lmad?', @UserName, @HostName, @HostIP;
	END
END

GO

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

    SELECT @FID193 = ISNULL(MAX(CASE WHEN Code='193' THEN FinancialItemDefinitionId ELSE 0 END),0),
           @FID370 = ISNULL(MAX(CASE WHEN Code='370' THEN FinancialItemDefinitionId ELSE 0 END),0),
           @FID371 = ISNULL(MAX(CASE WHEN Code='371' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('193','370','371');

    IF @FID193 IS NULL OR @FID370 IS NULL OR @FID371 IS NULL 
	BEGIN
    	RAISERROR(N'Gerekli FinancialItemDefinition (193,370,371) bulunamad?.',16,1);
		RETURN
    END
	

    /* CorrectedValue baz al?n?r */
   SELECT
		@Amt193 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID193 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
		@Amt370 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID370 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
		@Amt371 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID371 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
		FROM ALT.AutoTransferCleansing WITH (NOLOCK)
	WHERE AccountNumber = @AccountNumber
	  AND Period        = @Period
	  AND FinancialItemDefinitionId IN (@FID193, @FID370, @FID371);
    IF @Amt370 > @Amt371
    BEGIN
        SET @Diff = @Amt370 - @Amt371;
		SET @DiffNeg = -@Diff;
		IF @Diff < @Amt193 
		BEGIN  
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID193, N'193', @Diff, N'-', N'Rule16: 370 > 371 fark? 193?ten d???ld?.', @UserName, @HostName, @HostIP;
           EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID371, N'371', @Diff, N'+', N'Rule16: 370 > 371 fark? 371?e eklendi.', @UserName, @HostName, @HostIP;
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
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID193, N'193', @Amt193, N'-', N'Rule16: 193 tutar? 193?ten d???ld?.', @UserName, @HostName, @HostIP;
           EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID371, N'371', @Amt193, N'+', N'Rule16: 193 tutar? 371?e eklendi.', @UserName, @HostName, @HostIP;

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
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID193, N'193', @Diff, N'+', N'Rule16: 371 > 370 fark? 193?e eklendi.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID371, N'371', @Diff, N'-', N'Rule16: 371 > 370 fark? 371?den d???ld?.', @UserName, @HostName, @HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID193, N'193', @Diff, N'+', N'Rule16: 371 > 370 fark? 193?e eklendi.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID371, N'371', @Diff, N'-', N'Rule16: 371 > 370 fark? 371?den d???ld?.', @UserName, @HostName, @HostIP;

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
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null,null, N'Rule16: 370 ve 371 e?it oldu?u i?in i?lem yap?lmad?', @UserName, @HostName, @HostIP;
	END
END

GO

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
    DECLARE @FID562 INT,@FID240 INT,@FID242 INT,@FID245 INT; 
	
	 SELECT @FID562 = ISNULL(MAX(CASE WHEN Code='562' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID240 = ISNULL(MAX(CASE WHEN Code='240' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID242 = ISNULL(MAX(CASE WHEN Code='242' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID245 = ISNULL(MAX(CASE WHEN Code='245' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('562','240','242','245');

	DECLARE @SearchWords VARCHAR(120)
	 SELECT @SearchWords=ParamDescription
      FROM boa.cor.Parameter WITH(NOLOCK)
     WHERE ParamType = 'ATCSEARCH'
       AND ParamCode in ( '17')
       AND LanguageId = 1

    DECLARE @Roots TABLE(Code NVARCHAR(50),FID INT); 
	
	INSERT INTO @Roots VALUES('240',@FID240),('242',@FID242),('245',@FID245);
    DECLARE @AccCode NVARCHAR(50), @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2),@FIDSource INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT Code ,FID FROM @Roots;
    OPEN cur; FETCH NEXT FROM cur INTO @AccCode,@FIDSource;
    WHILE @@FETCH_STATUS = 0
    BEGIN
		SELECT  @Amt = SUM(ISNULL(NetSum_Leaves,0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber,@Period,@AccCode,1,@SearchWords);
        IF @Amt > 0
        BEGIN
		    SET @AmtNeg = -@Amt
            
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule17: Enf% leaf bakiyesi kaynak hesaptan d???ld?.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID562,   N'562',    @Amt, N'+', N'Rule17: Enf% leaf bakiyesi 562?ye aktar?ld?.', @UserName, @HostName, @HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule17: Enf% leaf bakiyesi kaynak hesaptan d???ld?.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID562,   N'562',    @Amt, N'+', N'Rule17: Enf% leaf bakiyesi 562?ye aktar?ld?.', @UserName, @HostName, @HostIP;

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
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, null, null, N'Rule17: Enf% bulunamad??? i?in i?lem yap?lamad?', @UserName, @HostName, @HostIP;
            
		END
        FETCH NEXT FROM cur INTO @AccCode,@FIDSource;
    END
    CLOSE cur; DEALLOCATE cur;
END

GO

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
    DECLARE @FID563 INT,@FID262 INT,@FID263 INT,@FID264 INT,@FID271 INT,@FID272 INT,@FID277 INT,@FID278 INT,@FID279 INT
	DECLARE @Amt262 decimal(22,2)=0 ,@Amt263 decimal(22,2)=0,@Amt264 decimal(22,2)=0,@Amt271 decimal(22,2)=0,
			@Amt272 decimal(22,2)=0,@Amt277 decimal(22,2)=0,@Amt278 decimal(22,2)=0,@Amt279 decimal(22,2)=0
	
	 SELECT @FID563 = ISNULL(MAX(CASE WHEN Code='563' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID262 = ISNULL(MAX(CASE WHEN Code='262' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID263 = ISNULL(MAX(CASE WHEN Code='263' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID264 = ISNULL(MAX(CASE WHEN Code='264' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID271 = ISNULL(MAX(CASE WHEN Code='271' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID272 = ISNULL(MAX(CASE WHEN Code='272' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID277 = ISNULL(MAX(CASE WHEN Code='277' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID278 = ISNULL(MAX(CASE WHEN Code='278' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID279 = ISNULL(MAX(CASE WHEN Code='279' THEN FinancialItemDefinitionId ELSE 0 END),0)
		FROM ALT.FinancialItemDefinition WITH (NOLOCK)
		WHERE Code IN ('563','262','263','264','271','272','277','279','278');

	    SELECT
				@Amt262 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID262 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt263 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID263 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt264 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID264 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt271 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID271 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt272 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID272 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt277 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID277 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt278 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID278 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
				@Amt279 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID279 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
			  FROM ALT.AutoTransferCleansing WITH (NOLOCK)
			 WHERE AccountNumber = @AccountNumber
			   AND Period        = @Period
			   AND FinancialItemDefinitionId IN (@FID262, @FID263,@FID264,@FID271,@FID272,@FID277,@FID278,@FID279)


    
	

    DECLARE @AccList TABLE(Code NVARCHAR(50), IsNegative BIT,FID INT,Amt DECIMAL(22,2));
    INSERT INTO @AccList VALUES 
	('262',0,@FID262,@Amt262),
	('263',0,@FID263,@Amt263),
	('264',0,@FID264,@Amt264),
	('271',0,@FID271,@Amt271),
	('272',0,@FID272,@Amt272),
	('277',0,@FID277,@Amt272),
	('278',1,@FID278,@Amt278),
	('279',0,@FID279,@Amt272);

    DECLARE @AccCode NVARCHAR(50), @IsNegative BIT, @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2),@AmtTmp DECIMAL(22,2), @FIDSource INT;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Code, IsNegative,FID,Amt FROM @AccList;
    OPEN c; FETCH NEXT FROM c INTO @AccCode, @IsNegative,@FIDSource,@Amt;
    WHILE @@FETCH_STATUS=0
    BEGIN
	    SET @AmtNeg = -@Amt
	    
	    IF @IsNegative=1 
		BEGIN
			SET @AmtTmp = -@Amt
		END
		ELSE
		BEGIN
		   SET @AmtTmp = @Amt
		END
        IF @Amt <> 0
        BEGIN
			DECLARE @Uamt decimal(22,2)  = CASE WHEN @IsNegative=1 THEN -@Amt ELSE @Amt END
			DECLARE @Sign varchar(1)  =  CASE WHEN @IsNegative=1 THEN N'-' ELSE N'+' END
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule18: Kaynak hesaptan 563?e transfer i?in d???ld?.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID563,   N'563', @Uamt ,@Sign,N'Rule18: 563 hesab? g?ncellendi.', @UserName, @HostName, @HostIP;

			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule18: Kaynak hesaptan 563?e transfer i?in d???ld?.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID563,   N'563', @Uamt ,@Sign,N'Rule18: 563 hesab? g?ncellendi.', @UserName, @HostName, @HostIP;

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
														   @FinancialItemDefinitionId = @FID563,
														   @Amount = @AmtTmp,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		  
            
            
        END
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, null, null, N'Rule18: kaynak hesap 0 oldu?u i?in i?lem yap?lamad?', @UserName, @HostName, @HostIP;
            
		END
        FETCH NEXT FROM c INTO  @AccCode, @IsNegative,@FIDSource,@Amt;
    END
    CLOSE c; DEALLOCATE c;
END

GO

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
    SELECT @FID296 = ISNULL(MAX(CASE WHEN Code='296' THEN FinancialItemDefinitionId else 0 END),0),
           @FID563 = ISNULL(MAX(CASE WHEN Code='563' THEN FinancialItemDefinitionId else 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK) 											   
	WHERE Code IN('296','563');
    
	IF @FID296 IS NULL OR @FID563 IS NULL
	BEGIN
	  RAISERROR(N'Gerekli FID (296,563) bulunamad?.',16,1);
	  RETURN
	END
	DECLARE @SearchWords VARCHAR(120)
	   SELECT @SearchWords=ParamDescription
      FROM boa.cor.Parameter WITH(NOLOCK)
     WHERE ParamType = 'ATCSEARCH'
       AND ParamCode in ( '19')
       AND LanguageId = 1

	SELECT @Amt = SUM(ISNULL(DebitSum_Leaves,0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber,@Period,N'296',1,@SearchWords);
    
	EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID296, N'296', @Amt, N'-', N'Rule19: %Matrah Art% / %Aff?%  leaf toplam? 296?dan d???ld?.', @UserName, @HostName, @HostIP;
    EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID563, N'563', @Amt, N'+', N'Rule19: %Matrah Art% / %Aff?%  leaf toplam? 563?e aktar?ld?.', @UserName, @HostName, @HostIP;

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

        
		 EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID296, N'296', @Amt, N'-', N'Rule19: %Matrah Art% / %Aff?% leaf toplam? 296?dan d???ld?.', @UserName, @HostName, @HostIP;
         EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID563, N'563', @Amt, N'+', N'Rule19: %Matrah Art% / %Aff?% leaf toplam? 563?e aktar?ld?.', @UserName, @HostName, @HostIP;
    END
END

GO

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
    
	SELECT     @FID320 = MAX(CASE WHEN Code='320' THEN FinancialItemDefinitionId ELSE 0 END),
			   @FID409 = MAX(CASE WHEN Code='409' THEN FinancialItemDefinitionId ELSE 0 END),
			   @FID420 = MAX(CASE WHEN Code='420' THEN FinancialItemDefinitionId ELSE 0 END),
               @FID307 = MAX(CASE WHEN Code='307' THEN FinancialItemDefinitionId ELSE 0 END)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN('307','320','409','420')

    IF @FID307 IS NULL OR @FID320 IS NULL OR @FID409 IS NULL OR @FID420 IS NULL
	BEGIN
	 RAISERROR(N'Gerekli FID (307,320,409,420) bulunamad?.',16,1);
	 RETURN
    END
         DECLARE @SearchWords varchar(120)
	   SELECT @SearchWords=ParamDescription
      FROM boa.cor.Parameter WITH(NOLOCK)
     WHERE ParamType = 'ATCSEARCH'
       AND ParamCode in ( '20')
       AND LanguageId = 1


    DECLARE @Map TABLE(AccCode NVARCHAR(3), FIDSource INT, FIDTarget INT,TargetAccCode NVARCHAR(3));
    INSERT INTO @Map VALUES ('320', @FID320, @FID307,'307'), ('420', @FID420, @FID409,'409');

    DECLARE @AccCode NVARCHAR(3), @FIDSource INT, @FIDTarget INT, @Amt DECIMAL(22,2),@AmtNeg DECIMAL(22,2),@TargetAccCode NVARCHAR(3);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR 
	
	SELECT AccCode, FIDSource, FIDTarget,TargetAccCode FROM @Map; OPEN cur;
    FETCH NEXT FROM cur INTO @AccCode, @FIDSource, @FIDTarget,@TargetAccCode;
    WHILE @@FETCH_STATUS = 0
    BEGIN
	   SELECT @Amt = SUM(ISNULL(NetSum_Leaves,0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber,@Period,@AccCode,1,@SearchWords);
        -- History
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule20: Faktoring alt kalemleri kaynak hesaptan d???ld?.', @UserName, @HostName, @HostIP;
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FIDTarget,@TargetAccCode, @Amt, N'+', N'Rule20: Faktoring alt kalemleri hedef hesaba eklendi.', @UserName, @HostName, @HostIP;

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

          

			EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDSource, @AccCode, @Amt, N'-', N'Rule20: Faktoring alt kalemleri kaynak hesaptan d???ld?.', @UserName, @HostName, @HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FIDTarget,@TargetAccCode, @Amt, N'+', N'Rule20: Faktoring alt kalemleri hedef hesaba eklendi.', @UserName, @HostName, @HostIP;
        END
        FETCH NEXT FROM cur INTO @AccCode, @FIDSource, @FIDTarget,@TargetAccCode;
    END
    CLOSE cur; DEALLOCATE cur;
END

GO

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
	
        -- TODO: Konsolide BDR kontrol?

        DECLARE 
		    @FID125 INT,@FID265 INT,
            @FID198 INT, @FID300 INT, @FID301 INT, @FID307 INT,
            @FID400 INT, @FID401 INT, @FID409 INT, @FID431 INT,
            @FID303 INT, @FID304 INT, @FID305 INT, @FID309 INT,
            @FID405 INT, @FID407 INT, @FID408 INT,
            @FID302 INT, @FID402 INT;

        -- yeni kural?n istedi?i b?t?n kalemleri al
        SELECT
            @FID125 = ISNULL(MAX(CASE WHEN Code='125' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID198 = ISNULL(MAX(CASE WHEN Code='198' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID265 = ISNULL(MAX(CASE WHEN Code='265' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID300 = ISNULL(MAX(CASE WHEN Code='300' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID301 = ISNULL(MAX(CASE WHEN Code='301' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID307 = ISNULL(MAX(CASE WHEN Code='307' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID400 = ISNULL(MAX(CASE WHEN Code='400' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID401 = ISNULL(MAX(CASE WHEN Code='401' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID409 = ISNULL(MAX(CASE WHEN Code='409' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID431 = ISNULL(MAX(CASE WHEN Code='431' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID303 = ISNULL(MAX(CASE WHEN Code='303' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID304 = ISNULL(MAX(CASE WHEN Code='304' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID305 = ISNULL(MAX(CASE WHEN Code='305' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID309 = ISNULL(MAX(CASE WHEN Code='309' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID405 = ISNULL(MAX(CASE WHEN Code='405' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID407 = ISNULL(MAX(CASE WHEN Code='407' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID408 = ISNULL(MAX(CASE WHEN Code='408' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID302 = ISNULL(MAX(CASE WHEN Code='302' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID402 = ISNULL(MAX(CASE WHEN Code='402' THEN FinancialItemDefinitionId ELSE 0 END),0)
        FROM ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('125','198','265','300','301','307','400','401','409','431',
                       '303','304','305','309','405','407','408','302','402');

        

		 DECLARE 
            @KOVNakdiMemzuc       DECIMAL(22,2) = 0,
            @TotalNakdiMemzuc        DECIMAL(22,2) = 0,
            @KOVLeasingMemzuc     DECIMAL(22,2) = 0,
            @TotalLeasingMemzuc      DECIMAL(22,2) = 0,
            @KOVFaktoringMemzuc   DECIMAL(22,2) = 0,
            @TotalFaktoringMemzuc    DECIMAL(22,2) = 0;

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
            INNER JOIN ALT.InquiryCreditRiskLimit icrl WITH (NOLOCK) ON icrl.InquiryCreditRiskLimitId = crl.InquiryCreditRiskLimitId
            WHERE icrl.AccountNumber = @AccountNumber
              AND crl.Year  = @Year
              AND crl.Month = @Month
            ORDER BY crl.InquiryCreditRiskLimitId DESC
        ),
        CR AS (
            -- Burada parametre tablosu ile e?le?en ve ParamValue2='Nakdi' olan riskler al?n?r
            SELECT 
                crl.RiskCode,
                ShortMidProfit =COALESCE(crl.ShortTermRiskAmount,0)+ COALESCE(crl.MidTermRiskAmount,0)+ COALESCE(crl.ProfitAccrualAmount,0)+ COALESCE(crl.ProfitRediscountAmount,0),
                TotalAmt = COALESCE(crl.ShortTermRiskAmount,0)+ COALESCE(crl.MidTermRiskAmount,0)+ COALESCE(crl.ProfitAccrualAmount,0)+ COALESCE(crl.ProfitRediscountAmount,0) + COALESCE(crl.LongTermRiskAmount,0)
            FROM LatestInquiry li
            JOIN ALT.CreditRiskLimit crl WITH (NOLOCK) ON crl.InquiryCreditRiskLimitId = li.MaxId
             AND crl.Year  = @Year
             AND crl.Month = @Month
            JOIN COR.Parameter  p WITH (NOLOCK) ON p.ParamCode  = crl.RiskCode
             AND p.ParamType = 'TCMBRISK'
             AND p.ParamValue2 = 'Nakdi'
             AND p.LanguageId = 1
        )
        -- 3 grup toplam?
       

        SELECT
            @KOVNakdiMemzuc =
                COALESCE(SUM(CASE WHEN RiskCode NOT BETWEEN 600 AND 799 THEN ShortMidProfit ELSE 0 END),0),
            @TotalNakdiMemzuc  =
                COALESCE(SUM(CASE WHEN RiskCode NOT BETWEEN 600 AND 799 THEN TotalAmt       ELSE 0 END),0),
            @KOVLeasingMemzuc =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 600 AND 699 THEN ShortMidProfit ELSE 0 END),0),
            @TotalLeasingMemzuc  =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 600 AND 699 THEN TotalAmt       ELSE 0 END),0),
            @KOVFaktoringMemzuc =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 700 AND 799 THEN ShortMidProfit ELSE 0 END),0),
            @TotalFaktoringMemzuc  =
                COALESCE(SUM(CASE WHEN RiskCode BETWEEN 700 AND 799 THEN TotalAmt       ELSE 0 END),0)
        FROM CR;

        -- Bilan?o de?erlerini ?ek
        DECLARE 
            @Bal198 DECIMAL(22,2), @Bal300 DECIMAL(22,2), @Bal301 DECIMAL(22,2), @Bal307 DECIMAL(22,2),
            @Bal400 DECIMAL(22,2), @Bal401 DECIMAL(22,2), @Bal409 DECIMAL(22,2), @Bal431 DECIMAL(22,2),
            @Bal303 DECIMAL(22,2), @Bal304 DECIMAL(22,2), @Bal305 DECIMAL(22,2), @Bal309 DECIMAL(22,2),
            @Bal405 DECIMAL(22,2), @Bal407 DECIMAL(22,2), @Bal408 DECIMAL(22,2),
            @Bal302 DECIMAL(22,2), @Bal402 DECIMAL(22,2), @Bal125 DECIMAL(22,2), @Bal265 DECIMAL(22,2);

        SELECT 
            @Bal198 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID198 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal300 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID300 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal301 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID301 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal307 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID307 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal400 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID400 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal401 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID401 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal409 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID409 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal125 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID125 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
			@Bal265 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID265 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal431 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID431 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal303 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID303 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal304 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID304 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal305 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID305 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal309 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID309 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal405 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID405 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal407 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID407 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal408 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID408 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal302 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID302 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
            @Bal402 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId=@FID402 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
        FROM ALT.AutoTransferCleansing WITH (NOLOCK)
        WHERE AccountNumber=@AccountNumber AND Period=@Period
          AND FinancialItemDefinitionId IN (
                @FID198,@FID300,@FID301,@FID307,@FID400,@FID401,@FID409,@FID125,@FID265,@FID431,
                @FID303,@FID304,@FID305,@FID309,@FID405,@FID407,@FID408,@FID302,@FID402
          );
		 
        -- NULL'lar? s?f?rla
        SELECT 
            @Bal198 = COALESCE(@Bal198,0), @Bal300 = COALESCE(@Bal300,0), @Bal301 = COALESCE(@Bal301,0), @Bal307 = COALESCE(@Bal307,0),
            @Bal400 = COALESCE(@Bal400,0), @Bal401 = COALESCE(@Bal401,0), @Bal409 = COALESCE(@Bal409,0), @Bal125 = COALESCE(@Bal125,0), @Bal431 = COALESCE(@Bal431,0),
            @Bal303 = COALESCE(@Bal303,0), @Bal304 = COALESCE(@Bal304,0), @Bal305 = COALESCE(@Bal305,0), @Bal309 = COALESCE(@Bal309,0),
            @Bal405 = COALESCE(@Bal405,0), @Bal407 = COALESCE(@Bal407,0), @Bal408 = COALESCE(@Bal408,0), @Bal265 = COALESCE(@Bal265,0),
            @Bal302 = COALESCE(@Bal302,0), @Bal402 = COALESCE(@Bal402,0);

        -- Yeni kural?n istedi?i kar??la?t?rma tutarlar?
		DECLARE @TotalNakdiBilanco   DECIMAL(22,2) = (@Bal300 + @Bal303 + @Bal304 + @Bal305 + @Bal309 + @Bal400 + @Bal405 + @Bal407 - @Bal408)
       
       

        DECLARE 
            @tmpAmount     DECIMAL(22,2),
            @tmpAmountNeg  DECIMAL(22,2);

		----------------------------------------------------------
        -- 1) NAKD? R?SKLER TOTAL
        ----------------------------------------------------------
		IF @TotalNakdiMemzuc > @TotalNakdiBilanco
		BEGIN
		   DECLARE @DeltaTotalNakdi DECIMAL(22,2) = @TotalNakdiMemzuc - @TotalNakdiBilanco;

            -- 300'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID300,
                    @Amount = @DeltaTotalNakdi,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID300,N'300',@DeltaTotalNakdi,'+', N'Rule21 Nakdi Total: Total risk fark? kadar 300 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID300,N'300',@DeltaTotalNakdi,'+',N'Rule21 Nakdi Total: Total risk fark? kadar 300 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal300 += @DeltaTotalNakdi;

            DECLARE @RemainTotalNakdi DECIMAL(22,2) = @DeltaTotalNakdi;
            -- 431'den d??
            IF @RemainTotalNakdi > 0 AND @Bal431 > 0
            BEGIN
                SET @tmpAmount = CASE WHEN @RemainTotalNakdi > @Bal431 THEN @Bal431 ELSE @RemainTotalNakdi END;
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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Nakdi Total: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Nakdi Total: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

                SET @Bal431 -= @tmpAmount;
                SET @RemainTotalNakdi -= @tmpAmount;
            END

            -- kalan 198'ya
            IF @RemainTotalNakdi > 0
            BEGIN
                EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                        @RuleId = @RuleId,
                        @AccountNumber = @AccountNumber,
                        @Period = @Period,
                        @FinancialItemDefinitionId = @FID198,
                        @Amount = @RemainTotalNakdi,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainTotalNakdi,'+', N'Rule21 Nakdi Total: artan tutar 198 aktifle?tirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainTotalNakdi,'+',N'Rule21 Nakdi Total: artan tutar 198 aktifle?tirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainTotalNakdi;
            END
		END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,0,null,null,null, N'Rule21 Nakdi Total: TotalNakdiMemzuc > TotalNakdiBilanco de?il i?lem yap?lmad?',@UserName,@HostName,@HostIP;
            
		END

		 DECLARE @KOVNakdiBilanco     DECIMAL(22,2) = (@Bal300 + @Bal303 + @Bal304 + @Bal305 + @Bal309)
           

        ----------------------------------------------------------
        -- 2) NAKD? R?SKLER - KISA/ORTA/FA?Z (KOV)
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

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID300,N'300',@DeltaKOVNakdi,'+', N'Rule21 Nakdi KOV: Bilan?o (300+303+304+305+309) fark? kadar 300 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID300,N'300',@DeltaKOVNakdi,'+',N'Rule21 Nakdi KOV: Bilan?o (300+303+304+305+309) fark? kadar 300 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal300 += @DeltaKOVNakdi;

            DECLARE @RemainKOVNakdi DECIMAL(22,2) = @DeltaKOVNakdi;

            -- 400'den d??
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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID400,N'400',@tmpAmount,'-', N'Rule21 Nakdi KOV: 400 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID400,N'400',@tmpAmount,'-',N'Rule21 Nakdi KOV: 400 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

                SET @Bal400 -= @tmpAmount;
                SET @RemainKOVNakdi -= @tmpAmount;
            END
            -- 431'den d??
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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-', N'Rule21 Nakdi KOV: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Nakdi KOV: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVNakdi,'+',N'Rule21 Nakdi KOV: artan tutar 198 aktifle?tirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID198,N'198',@RemainKOVNakdi,'+',N'Rule21 Nakdi KOV: artan tutar 198 aktifle?tirildi.',@UserName,@HostName,@HostIP;

                SET @Bal198 += @RemainKOVNakdi;
            END
        END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,0,null,null,null, N'Rule21 Nakdi KOV: KOVNakdiMemzuc > KOVNakdiBilanco de?il i?lem yap?lmad?',@UserName,@HostName,@HostIP;
            
		END
		----------------------------------------------------------
        -- 3) LEASING R?SKLER TOTAL
        ----------------------------------------------------------
        DECLARE @TotalLeasingBilanco DECIMAL(22,2) = (@Bal301 +@Bal401 - @Bal302- @Bal402)

        IF @TotalLeasingMemzuc > @TotalLeasingBilanco
        BEGIN
            DECLARE @DeltaTotalLease DECIMAL(22,2) = @TotalLeasingMemzuc - @TotalLeasingBilanco;

            -- 301'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID301,
                    @Amount = @DeltaTotalLease,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID301,N'301',@DeltaTotalLease,'+',N'Rule21 Leasing Total: Total risk fark? kadar 301 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID301,N'301',@DeltaTotalLease,'+',N'Rule21 Leasing Total: Total risk fark? kadar 301 eklendi.',@UserName,@HostName,@HostIP;

		   -- 265'e ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID265,
                    @Amount = @DeltaTotalLease,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID265,N'265',@DeltaTotalLease,'+',N'Rule21 Leasing Total: Total risk fark? kadar 265 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID265,N'265',@DeltaTotalLease,'+',N'Rule21 Leasing Total: Total risk fark? kadar 265 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal301 += @DeltaTotalLease;
			SET @Bal265 += @DeltaTotalLease;
        END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,0,null,null,null, N'Rule21 Leasing Total: TotalLeasingMemzuc > TotalLeasingBilanco de?il i?lem yap?lmad?',@UserName,@HostName,@HostIP;
            
		END
        ----------------------------------------------------------
        -- 4) LEASING R?SKLER? - KOV (k?sa/orta/faiz)
        ----------------------------------------------------------
          DECLARE
            @KOVLeasingBilanco   DECIMAL(22,2) = (@Bal301 - @Bal302),
            @UVLeasingBilanco    DECIMAL(22,2) = (@Bal401 - @Bal402)

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

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID301,N'301',@DeltaKOVLease,'+',N'Rule21 Leasing KOV: (301-302) fark? kadar 301 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID301,N'301',@DeltaKOVLease,'+',N'Rule21 Leasing KOV: (301-302) fark? kadar 301 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal301 += @DeltaKOVLease;

            DECLARE @RemainKOVLease DECIMAL(22,2) = @DeltaKOVLease;

            -- ?nce 401'den (UVLeasingBilanco kadar) d??
            IF @RemainKOVLease > 0 AND @Bal401 > 0 AND @UVLeasingBilanco > 0
            BEGIN
                -- 401'den maksimum d???lecek tutar, kural gere?i UVLeasingBilanco ile s?n?rl?
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

                    EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID401,N'401',@tmpAmount,'-',N'Rule21 Leasing KOV: 401 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                    EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID401,N'401',@tmpAmount,'-',N'Rule21 Leasing KOV: 401 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

                    SET @Bal401 -= @tmpAmount;
                    SET @RemainKOVLease -= @tmpAmount;
                END
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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Leasing KOV: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Leasing KOV: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

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
                        @FinancialItemDefinitionId = @FID265,
                        @Amount = @RemainKOVLease,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID265,N'265',@RemainKOVLease,'+',N'Rule21 Leasing KOV: artan tutar 265 aktifle?tirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID265,N'265',@RemainKOVLease,'+',N'Rule21 Leasing KOV: artan tutar 265 aktifle?tirildi.',@UserName,@HostName,@HostIP;

                SET @Bal265 += @RemainKOVLease;
            END
        END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,0,null,null,null, N'Rule21 Leasing KOV: KOVLeasingMemzuc > KOVLeasingBilanco de?il i?lem yap?lmad?',@UserName,@HostName,@HostIP;
            
		END
		----------------------------------------------------------
        -- 5) FAKTOR?NG R?SKLER? TOTAL
        ----------------------------------------------------------
		 DECLARE @TotalFaktoringBilanco DECIMAL(22,2) = (@Bal307 +@Bal409)

        IF @TotalFaktoringMemzuc > @TotalFaktoringBilanco
        BEGIN
            DECLARE @DeltaTotalFakt DECIMAL(22,2) = @TotalFaktoringMemzuc - @TotalFaktoringBilanco;

            -- 307'ye ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID307,
                    @Amount = @DeltaTotalFakt,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID307,N'307',@DeltaTotalFakt,'+',N'Rule21 Faktoring Total: Total risk fark? kadar 307 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID307,N'307',@DeltaTotalFakt,'+',N'Rule21 Faktoring Total: Total risk fark? kadar 307 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal307 += @DeltaTotalFakt;
			 -- 125'ye ekle
            EXEC ALT.upd_ATC_AddDeltaWithAncestors 
                    @RuleId = @RuleId,
                    @AccountNumber = @AccountNumber,
                    @Period = @Period,
                    @FinancialItemDefinitionId = @FID125,
                    @Amount = @DeltaTotalFakt,
                    @UserName = @UserName,
                    @HostName = @HostName,
                    @HostIP = @HostIP;

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID125,N'125',@DeltaTotalFakt,'+',N'Rule21 Faktoring Total: Total risk fark? kadar 125 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID125,N'125',@DeltaTotalFakt,'+',N'Rule21 Faktoring Total: Totail risk fark? kadar 125 eklendi.',@UserName,@HostName,@HostIP;

           
            
        END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,0,null,null,null, N'Rule21 Faktoring Total: TotalFaktoringMemzuc > TotalFaktoringBilanco de?il i?lem yap?lmad?',@UserName,@HostName,@HostIP;
            
		END
        ----------------------------------------------------------
        -- 6) FAKTOR?NG R?SKLER? - KOV
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

            EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID307,N'307',@DeltaKOVFakt,'+',N'Rule21 Faktoring KOV: (307) fark? kadar 307 eklendi.',@UserName,@HostName,@HostIP;
            EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID307,N'307',@DeltaKOVFakt,'+',N'Rule21 Faktoring KOV: (307) fark? kadar 307 eklendi.',@UserName,@HostName,@HostIP;

            SET @Bal307 += @DeltaKOVFakt;

            DECLARE @RemainKOVFakt DECIMAL(22,2) = @DeltaKOVFakt;

            -- 409'dan d??
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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID409,N'409',@tmpAmount,'-',N'Rule21 Faktoring KOV: 409 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID409,N'409',@tmpAmount,'-',N'Rule21 Faktoring KOV: 409 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

                SET @Bal409 -= @tmpAmount;
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

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Faktoring KOV: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID431,N'431',@tmpAmount,'-',N'Rule21 Faktoring KOV: 431 hesaptan d???ld?.',@UserName,@HostName,@HostIP;

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
                        @FinancialItemDefinitionId = @FID125,
                        @Amount = @RemainKOVFakt,
                        @UserName = @UserName,
                        @HostName = @HostName,
                        @HostIP = @HostIP;

                EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,@FID125,N'125',@RemainKOVFakt,'+',N'Rule21 Faktoring KOV: artan tutar 125 aktifle?tirildi.',@UserName,@HostName,@HostIP;
                EXEC ALT.ins_ATC_HistoryCorrection @RuleId,@AccountNumber,@Period,@FID125,N'125',@RemainKOVFakt,'+',N'Rule21 Faktoring KOV: artan tutar 125 aktifle?tirildi.',@UserName,@HostName,@HostIP;

                SET @Bal125+= @RemainKOVFakt;
            END
        END
		ELSE
		BEGIN
		   EXEC ALT.ins_ATC_History @RuleId,@AccountNumber,@Period,0,null,null,null, N'Rule21 Faktoring KOV: KOVFaktoringMemzuc > 307 de?il i?lem yap?lmad?',@UserName,@HostName,@HostIP;
            
		END
     
   
END
GO
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

    -- FID de?erlerini al
    SELECT
        @FID320 = ISNULL(MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId ELSE 0 END),0),
        @FID159 = ISNULL(MAX(CASE WHEN Code = N'159' THEN FinancialItemDefinitionId ELSE 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('320', '159');

    IF @FID320 IS NULL OR @FID159 IS NULL
	BEGIN
        RAISERROR('Gerekli FinancialItemDefinition (320, 159) bulunamad?.', 16, 1);
		RETURN
    END
    DECLARE @AltA_Debit DECIMAL(22,2);

    
    -- Alt hesaplar?n alacak toplam? (leaf)
    SELECT @AltA_Debit = SUM(ISNULL(s.DebitSum_Leaves,0))FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber, @Period, '320', 1,NULL) s;

    IF @AltA_Debit <> 0
    BEGIN
        -- HISTORY (yaln?zca bu b?l?m g?ncellendi)
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID320, N'320', @AltA_Debit, '+',N'Rule22: 320 ters bakiye fark? eklendi.', @UserName, @HostName, @HostIP; 
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, @FID159, N'159', @AltA_Debit, '+',N'Rule22: 320 ters bakiye fark? aktifte 159 hesab?na eklendi.', @UserName, @HostName, @HostIP;

		EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID320, N'320', @AltA_Debit, '+',N'Rule22: 320 ters bakiye fark? eklendi.', @UserName, @HostName, @HostIP; 
        EXEC ALT.ins_ATC_HistoryCorrection @RuleId, @AccountNumber, @Period, @FID159, N'159', @AltA_Debit, '+',N'Rule22: 320 ters bakiye fark? aktifte 159 hesab?na eklendi.', @UserName, @HostName, @HostIP;

		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID320,
														   @Amount = @AltA_Debit,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
		EXEC ALT.upd_ATC_AddDeltaWithAncestors @RuleId = @RuleId,
														   @AccountNumber = @AccountNumber,
														   @Period = @Period,
														   @FinancialItemDefinitionId = @FID159,
														   @Amount = @AltA_Debit,
														   @UserName = @UserName,
														   @HostName = @HostName,
														   @HostIP = @HostIP;
        
    END
	ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null,N'Rule22: Alt hesaplar?n alacak toplam? (leaf) 0 oldu?u i?in i?lem yap?lmad?.', @UserName, @HostName, @HostIP; 
        
	END
END
GO

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

    -- FID de?erlerini al
    SELECT
        @FID331 = ISNULL(MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId else 0 END),0),
        @FID431 = ISNULL(MAX(CASE WHEN Code = N'431' THEN FinancialItemDefinitionId else 0 END),0)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('331', '431');

    IF @FID331 IS NULL OR @FID431 IS NULL
	BEGIN
	 RAISERROR('Gerekli FinancialItemDefinition (331, 431) bulunamad?.', 16, 1);
	 RETURN
    END
        

    -- 331 bakiyesi
    SELECT @Amt = SUM(ISNULL(CorrectedValue,0))
    FROM ALT.AutoTransferCleansing WITH(NOLOCK)
    WHERE AccountNumber=@AccountNumber AND Period=@Period
      AND FinancialItemDefinitionId = @FID331; 

    IF @Amt <> 0
    BEGIN
	   SET @AmtNeg = -@Amt
        -- HISTORY (yaln?zca bu b?l?m g?ncellendi)
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID331, N'331', @Amt, N'-',
             N'Rule23: 331 hesab?ndan ??kar?ld?.', @UserName, @HostName, @HostIP;

        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID431, N'431', @Amt, N'+',
             N'Rule23: 331 hesab?ndan 431 hesab?na aktar?ld?.', @UserName, @HostName, @HostIP;

	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID331, N'331', @Amt, N'-',
             N'Rule23: 331 hesab?ndan ??kar?ld?.', @UserName, @HostName, @HostIP;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID431, N'431', @Amt, N'+',
             N'Rule23: 331 hesab?ndan 431 hesab?na aktar?ld?.', @UserName, @HostName, @HostIP;

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
    ELSE
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null,N'Rule23: 331 bakiyesi 0 i?lem yap?lmad?', @UserName, @HostName, @HostIP;
	END
END
GO

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

    /* Yaln?zca 2023 y?lsonu d?nemleri: 202341 ve 202342 */
    IF (@Period NOT IN (202341, 202342))
        RETURN;

    DECLARE
        @FID692 INT, @FID590 INT, @FID580 INT, @FID591 INT, @FID570 INT;

    /* FinancialItemDefinition Id?leri (kod -> FID) */
    SELECT
        @FID692 = MAX(CASE WHEN Code='692' THEN FinancialItemDefinitionId ELSE 0 END),
        @FID590 = MAX(CASE WHEN Code='590' THEN FinancialItemDefinitionId ELSE 0 END),
        @FID580 = MAX(CASE WHEN Code='580' THEN FinancialItemDefinitionId ELSE 0 END),
        @FID591 = MAX(CASE WHEN Code='591' THEN FinancialItemDefinitionId ELSE 0 END),
        @FID570 = MAX(CASE WHEN Code='570' THEN FinancialItemDefinitionId ELSE 0 END)
    FROM ALT.FinancialItemDefinition WITH (NOLOCK)
    WHERE Code IN ('692','590','580','591','570');

   

    /* BDR/Beyanname verisinden #692 de?eri (OriginalValue esas al?nd?) */
    DECLARE @Val692 DECIMAL(22,2) = 0;

    SELECT @Val692 = COALESCE(SUM(OriginalValue), 0.0)
    FROM ALT.CustomerFinancialItem WITH (NOLOCK)
    WHERE AccountNumber=@AccountNumber
      AND PeriodId=@Period
      AND FinancialItemDefinitionId=@FID692;
	 
    IF @Val692 = 0
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null,N'Rule24: #692=0 => i?lem yap?lmad?', @UserName, @HostName, @HostIP;
	    RETURN;  -- ??lem yok
	END
       

    /* Yard?mc?: Hedef hesaba ekleme + log */
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
     


        -- HISTORY (de?i?tirilen b?l?m)
		 
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
       
        

		-- HISTORY (de?i?tirilen b?l?m)
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID591, N'591', @Abs692, N'+',
             N'Rule24: #692<0 => 591 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;


        -- HISTORY (de?i?tirilen b?l?m)
        EXEC ALT.ins_ATC_History
             @RuleId, @AccountNumber, @Period, @FID570, N'570', @Abs692, N'+',
             N'Rule24: #692<0 => 570 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;

	    EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID591, N'591', @Abs692, N'+',
             N'Rule24: #692<0 => 591 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;


        -- HISTORY (de?i?tirilen b?l?m)
        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId, @AccountNumber, @Period, @FID570, N'570', @Abs692, N'+',
             N'Rule24: #692<0 => 570 hesaba eklendi (|692|).', @UserName, @HostName, @HostIP;

    END 
END
GO

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
        DECLARE @Amt648 DECIMAL(22,2)=0, @Amt658 DECIMAL(22,2)=0, @Amt590 DECIMAL(22,2)=0, @Amt591 DECIMAL(22,2)=0;

        -- FID de?erlerini al
        SELECT
            @FID648 = ISNULL(MAX(CASE WHEN Code = N'648' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID658 = ISNULL(MAX(CASE WHEN Code = N'658' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID590 = ISNULL(MAX(CASE WHEN Code = N'590' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID591 = ISNULL(MAX(CASE WHEN Code = N'591' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID570 = ISNULL(MAX(CASE WHEN Code = N'570' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID580 = ISNULL(MAX(CASE WHEN Code = N'580' THEN FinancialItemDefinitionId ELSE 0 END),0)
        FROM  ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('648', '658', '590', '591', '570','580');


        -- Mevcut bakiyeleri ?ek
       SELECT
			@Amt648 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID648 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
			@Amt658 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID658 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
			@Amt590 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID590 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0),
			@Amt591 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID591 THEN ISNULL(CorrectedValue,0) ELSE 0 END),0)
			
		FROM ALT.AutoTransferCleansing WITH (NOLOCK)
		WHERE AccountNumber = @AccountNumber
		  AND Period        = @Period
		  AND FinancialItemDefinitionId IN (@FID648, @FID658, @FID590, @FID591);

		
		DECLARE @Mesaj NVARCHAR(4000) = CONCAT(N'Rule25: #590,#591,#648,#658 => ',CAST(@Amt590 as VARCHAR(100)),' ',CAST(@Amt591 as VARCHAR(100)),' ',
		CAST(@Amt648 as VARCHAR(100)),' ',CAST(@Amt658 as VARCHAR(100)),N' Bu de?erlere g?re kural ?al??acak.')
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null,@Mesaj, @UserName, @HostName, @HostIP;

        -- ?ncelikle 648 ve 658 kar??l?kl? mahsup
        IF @Amt648>0 AND @Amt658>0
        BEGIN
            DECLARE @MinAmt DECIMAL(22,2) = IIF(@Amt648<@Amt658,@Amt648,@Amt658);

            EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID648,'648',@MinAmt,'-',N'Rule25: 648 ve 658 mahsup',@UserName,@HostName,@HostIP;
            EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID658,'658',@MinAmt,'-',N'Rule25: 648 ve 658 mahsup',@UserName,@HostName,@HostIP;

            SET @Amt648 = @Amt648 - @MinAmt;
            SET @Amt658 = @Amt658 - @MinAmt;
        END

        -- 648 i?lemleri
        IF @Amt648>0
        BEGIN
            IF @Amt648 <= @Amt590
            BEGIN
                -- 648-590'dan d??, 570'e ekle
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID648,'648',@Amt648,'-',N'Rule25: 648 i?in 648 d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Amt648,'-',N'Rule25: 648 i?in 590 d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Amt648,'+',N'Rule25: 648 i?in 570 eklendi',@UserName,@HostName,@HostIP;
            END
            ELSE
            BEGIN
                -- 590'? s?f?rla, fark? 591'e ekle
                IF @Amt590>0
                    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Amt590,'-',N'Rule25: 648 i?in 590 s?f?rland?',@UserName,@HostName,@HostIP;

                DECLARE @Diff648 DECIMAL(22,2) = @Amt648 - @Amt590;

                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Diff648,'+',N'Rule25: 648 i?in fark 591 eklendi',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID648,'648',@Amt648,'-',N'Rule25: 648 i?in 648 eksiltildi',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Amt648,'+',N'Rule25: 648 i?in 570 eklendi',@UserName,@HostName,@HostIP;
            END
        END

        -- 658 i?lemleri
        IF @Amt658>0
        BEGIN
            IF @Amt658 <= @Amt591
            BEGIN
                -- 591 ve 570'ten d?? 580 e ekle
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Amt658,'-',N'Rule25: 658 i?in 591 d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Amt658,'-',N'Rule25: 658 i?in 570 d???ld?',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID580,'580',@Amt658,'+',N'Rule25: 658 i?in 580 eklendi',@UserName,@HostName,@HostIP;
            END
            ELSE
            BEGIN
                -- 591'? s?f?rla, fark? 590'a ekle
                IF @Amt591>0
                    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Amt591,'-',N'Rule25: 658 i?in 591 s?f?rland?',@UserName,@HostName,@HostIP;

                DECLARE @Diff658 DECIMAL(22,2) = @Amt658 - @Amt591;

                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Diff658,'+',N'Rule25: 658 i?in fark 590 eklendi',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID658,'658',@Amt658,'-',N'Rule25: 658 i?in 658 d???ld?',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID580,'580',@Amt658,'+',N'Rule25: 658 i?in 580 eklendi',@UserName,@HostName,@HostIP;
            END
        END 
       
END;

GO

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
             @FID370 INT,@FID590 INT, @FID591 INT,@FID580 INT,@FID570 INT,@FID691 INT,@FID692 INT,@Donem INT,
		     @Amt590 DECIMAL(22,2)=0, @Amt591 DECIMAL(22,2)=0,@Amt692 DECIMAL(22,2)=0,@Amt691 DECIMAL(22,2)=0

		SET @Donem =SUBSTRING(cast(@Period as varchar(10)), 5, 1);
		
		
        -- FID'leri ?ek
        SELECT
			@FID590 = ISNULL(MAX(CASE WHEN Code = '590' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID591 = ISNULL(MAX(CASE WHEN Code = '591' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID570 = ISNULL(MAX(CASE WHEN Code = '570' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID580 = ISNULL(MAX(CASE WHEN Code = '580' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID692 = ISNULL(MAX(CASE WHEN Code = '692' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID691 = ISNULL(MAX(CASE WHEN Code = '691' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID370 = ISNULL(MAX(CASE WHEN Code = '370' THEN FinancialItemDefinitionId ELSE 0 END),0)
		FROM ALT.FinancialItemDefinition WITH (NOLOCK)
		WHERE Code IN ('370','590','591','570','580','691','692');

		
        IF @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL OR @FID580 IS NULL OR @FID691 IS NULL OR @FID692 IS NULL OR @FID370 IS NULL 
        BEGIN
            RAISERROR('Rule26: Gerekli FinancialItemDefinition (370,590,591,570,580,691,692) bulunamad?.', 16, 1);
			RETURN
        END

         SELECT
			@Amt590 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID590 THEN ISNULL(CorrectedValue,0) else 0 END),0),
			@Amt591 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID591 THEN ISNULL(CorrectedValue,0) else 0 END),0),
			@Amt692 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID692 THEN ISNULL(CorrectedValue,0) else 0 END),0),
			@Amt691 = ISNULL(SUM(CASE WHEN FinancialItemDefinitionId = @FID691 THEN ISNULL(CorrectedValue,0) else 0 END),0)
		FROM ALT.AutoTransferCleansing WITH (NOLOCK)
		WHERE AccountNumber = @AccountNumber
		  AND Period        = @Period
		  AND FinancialItemDefinitionId IN (@FID590, @FID591, @FID691, @FID692);
         
		 DECLARE @Mesaj NVARCHAR(4000) = CONCAT(N'Rule26: #590,#591,#691,#692 => ',CAST(@Amt590 as VARCHAR(100)),' ',CAST(@Amt591 as VARCHAR(100)),' ',
		CAST(@Amt691 as VARCHAR(100)),' ',CAST(@Amt692 as VARCHAR(100)),N' Bu de?erlere g?re kural ?al??acak.')
        EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null,@Mesaj, @UserName, @HostName, @HostIP;

		IF @Amt692>=0 
		BEGIN  
        	 -- 1) #590 > #692 ise, #590 - #692 kadar #590?dan eksiltilecek #570?e eklenecek
			IF @Amt590 > @Amt692
			BEGIN
				DECLARE @Diff1 DECIMAL(22,2) = @Amt590 - @Amt692;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Diff1,'-',N'Rule26:590 > 692 fark',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID570,'570',@Diff1,'+',N'Rule26: 590 > 692 fark',@UserName,@HostName,@HostIP;
			END
			ELSE
			-- 2) #590 < #692 ise, #692 - #590 kadar #590?a eklenecek, tam d?nem ise #692 - #590 kadar #580?e de eklenecek, 
			IF @Amt590 < @Amt692
			BEGIN
			    
				DECLARE @Diff2 DECIMAL(22,2) = @Amt692 - @Amt590;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,'590',@Diff2,'+',N'Rule26: 590 < 692 fark 692-590 590 a eklendi ',@UserName,@HostName,@HostIP
				IF @Donem =4
				BEGIN
				   EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID580,'580',@Diff2,'+',N'Rule26: 590 < 692 fark 692-590 580 a eklendi tam d?nem ',@UserName,@HostName,@HostIP;
				END
			END
			--ara d?nem ise, #691 kadar #370?e eklenecek
			IF @Donem <>4
			BEGIN
		       EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID370,'370',@Amt691,'+',N'Rule26: 691 kadar 370 e eklendi ara d?nem ',@UserName,@HostName,@HostIP
			END

        END
		ELSE
		BEGIN
		    -- 3) 591 + 692 > 0 ? toplam kadar 689 ve c2?ye ekle
			IF (@Amt591 + @Amt692) > 0
			BEGIN
			  
				DECLARE @Diff3 DECIMAL(22,2) = @Amt591 + @Amt692;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,'591',@Diff3,'-',N'Rule26: 591 + 692 > 0',@UserName,@HostName,@HostIP;
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID580,'580',@Diff3,'+',N'Rule26: 591 + 692 > 0',@UserName,@HostName,@HostIP;
			END
			ELSE
			IF (@Amt591 + @Amt692) < 0
			BEGIN
			    
				DECLARE @Diff4 DECIMAL(22,2) = ABS(@Amt591 + @Amt692);
				EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID591,'591',@Diff4,'+',N'Rule26: 591 + 692 < 0',@UserName,@HostName,@HostIP;
				IF @Donem =4
				BEGIN
				   EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period, @FID570,'570',@Diff4,'+',N'Rule26: 591 + 692 < 0 d?nem tam',@UserName,@HostName,@HostIP;
				END
			END
		END
END;

GO

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
            @FID590 = ISNULL(MAX(CASE WHEN Code = N'590' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID591 = ISNULL(MAX(CASE WHEN Code = N'591' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID570 = ISNULL(MAX(CASE WHEN Code = N'570' THEN FinancialItemDefinitionId ELSE 0 END),0),
            @FID679 = ISNULL(MAX(CASE WHEN Code = N'679' THEN FinancialItemDefinitionId ELSE 0 END),0),
			@FID549 = ISNULL(MAX(CASE WHEN Code = N'549' THEN FinancialItemDefinitionId ELSE 0 END),0)
        FROM  ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN (N'549',N'590',N'591',N'570',N'679');

        IF @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL OR @FID679 IS NULL
            RAISERROR('Rule27: Gerekli FID (549,590,591,570,679) bulunamad?.', 16, 1);

	    DECLARE @SearchWords varchar(120)
	   SELECT @SearchWords=ParamDescription
      FROM boa.cor.Parameter WITH(NOLOCK)
     WHERE ParamType = 'ATCSEARCH'
       AND ParamCode in ( '27')
       AND LanguageId = 1

		 /* 679 a?ac?ndaki LEAF hesaplar? bul ve isim filtreleriyle topla */
		SELECT @Amt = SUM(ISNULL(CreditSum_Leaves,0)) FROM ALT.fGetDetailedTrialBalanceLeafSums_ATC(@AccountNumber,@Period,N'679',1,@SearchWords);

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
			    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID679,N'679',@Amt,'-',N'Rule27: Leaseback geliri kadar 679 d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,N'590',@Amt,'-',N'Rule27: Leaseback geliri kadar 590 d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID549,N'549',@Amt,'+',N'Rule27: Leaseback geliri kadar 549 eklendi',@UserName,@HostName,@HostIP;
            END
            ELSE
            BEGIN
                DECLARE @Diff DECIMAL(22,2) = @Amt - @Bal590;
			    EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID679,N'679',@Amt,'-',N'Rule27: Leaseback geliri kadar 679 d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID590,N'590',@Bal590,'-',N'Rule27: Leaseback ? 590 eldeki kadar d???ld?',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID591,N'591',@Diff,'+',N'Rule27: Leaseback fark? 591''e eklendi',@UserName,@HostName,@HostIP;
                EXEC ALT.upd_ATC_TransferAmount @RuleId,@AccountNumber,@Period,@FID549,N'549',@Amt,'+',N'Rule27: Leaseback toplam? 549''e eklendi',@UserName,@HostName,@HostIP;
            END
        END 
		ELSE
		BEGIN
		    EXEC ALT.ins_ATC_History @RuleId, @AccountNumber, @Period, 0, null, null, null,N'Rule27: #679 hesab?n?n alt kalemlerinde sat geri kirala,sale and leaseback,leaseback tespit edilemedi?i i?in i?lem yap?lmad?', @UserName, @HostName, @HostIP;
		END
END;

GO

CREATE PROCEDURE [ALT].[upd_ATC_ApplyRule_SendData]
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id (bilgi ama?l?)
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

    -- (Opsiyonel) H?z i?in indeks
    -- CREATE CLUSTERED INDEX IX_Src_Key ON #Src(FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId);

    -----------------------------------------
    -- 2) UPDATE: Her iki tabloda da ayn? kay?t varsa g?ncelle
    --    (gereksiz yazmay? ?nlemek i?in farkl?l?k kontrol? ile)
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
    -- 3) INSERT: Hedefte olmayan + (OV,CV) ikisi birden 0 de?ilse
    --    (0,0 olan yeni kay?tlar HAR??)
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
      AND (ISNULL(S.OriginalValue,0) <> 0 OR ISNULL(S.CorrectedValue,0) <> 0);  -- (0,0) HAR??

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

CREATE PROCEDURE [ALT].[upd_ATC_CascadeCorrectedValue]
(
    @RuleId        INT = NULL,        -- opsiyonel: log i?in
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @Period        INT,

    @FinancialItemDefinitionId INT,   -- g?ncellenecek taban kalem
    @NewCorrectedValue         DECIMAL(22,2),

    @UserName VARCHAR(10) = NULL,
    @HostName VARCHAR(20) = NULL,
    @HostIP   VARCHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

   
        /* ---- 1) Taban kalemin kodunu ve mevcut de?erini al ---- */
        DECLARE @BaseCode NVARCHAR(20);

        SELECT @BaseCode = f.Code
        FROM ALT.FinancialItemDefinition f WITH (NOLOCK)
        WHERE f.FinancialItemDefinitionId = @FinancialItemDefinitionId;

        IF @BaseCode IS NULL
        BEGIN
            RAISERROR('Ge?ersiz FinancialItemDefinitionId.', 16, 1);
            RETURN;
        END

        DECLARE @OldCorrected DECIMAL(22,2) = 0.00;

        SELECT @OldCorrected = COALESCE(SUM(a.CorrectedValue), 0.00)
        FROM ALT.AutoTransferCleansing a WITH (NOLOCK)
        WHERE a.FirmType=@FirmType AND a.GroupNumber=@GroupNumber
          AND a.AccountNumber=@AccountNumber AND a.[Period]=@Period
          AND a.FinancialItemDefinitionId=@FinancialItemDefinitionId;

        DECLARE @Delta DECIMAL(22,2) = @NewCorrectedValue - @OldCorrected;
		DECLARE @ABSDelta DECIMAL(22,2) = ABS(@Delta);

        /* ? = 0 ise i? yok */
        IF @Delta = 0
        BEGIN
            DECLARE @NoopMsg NVARCHAR(4000) = N'Cascade: Yeni de?er mevcut de?er ile ayn?; g?ncelleme yap?lmad?.';
            EXEC ALT.ins_ATC_History
                 @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                 @FinancialItemDefinitionId=@FinancialItemDefinitionId, @AccountCode=@BaseCode,
                 @Amount=0, @TransactionType='0', @Description=@NoopMsg,
                 @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
            RETURN;
        END

        /* ---- 2) Ata zinciri: base hari?  (?rn. '100' ? '10' ? '1') ---- */
        IF OBJECT_ID('tempdb..#Ancestors') IS NOT NULL DROP TABLE #Ancestors;
        CREATE TABLE #Ancestors
        (
            Code NVARCHAR(20) NOT NULL,
            FinancialItemDefinitionId INT NULL
        );

        DECLARE @c NVARCHAR(20) = @BaseCode;

        /* Base'i hari? tutarak atalar? ?ret */
        WHILE LEN(@c) > 1
        BEGIN
            SET @c = LEFT(@c, LEN(@c) - 1);
            INSERT INTO #Ancestors(Code) VALUES (@c);
        END

        /* FID e?lemelerini getir */
        UPDATE an
           SET an.FinancialItemDefinitionId = f.FinancialItemDefinitionId
        FROM #Ancestors an
        LEFT JOIN ALT.FinancialItemDefinition f WITH (NOLOCK)
               ON f.Code = an.Code;

        /* Ge?ersiz (e?le?meyen) kodlar elensin */
        DELETE FROM #Ancestors WHERE FinancialItemDefinitionId IS NULL;

        /* ---- 3) LOG: planlanan de?i?ikli?i yaz ---- */
        DECLARE @SignChar CHAR(1) = CASE WHEN @Delta > 0 THEN '+' ELSE '-' END;
        DECLARE @MsgBase NVARCHAR(4000) =
            CONCAT(N'Cascade: ', @BaseCode, N' CorrectedValue ', CONVERT(NVARCHAR(50), @OldCorrected),
                   N' ? ', CONVERT(NVARCHAR(50), @NewCorrectedValue),
                   N' (?=', CONVERT(NVARCHAR(50), @Delta), N').');

        EXEC ALT.ins_ATC_History
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FinancialItemDefinitionId, @AccountCode=@BaseCode,
             @Amount=@ABSDelta, @TransactionType=@SignChar, @Description=@MsgBase,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        /* ---- 4) BASE UPDATE: yeni de?eri set et ---- */
        UPDATE a
           SET a.CorrectedValue = @NewCorrectedValue
          FROM ALT.AutoTransferCleansing a
         WHERE a.AccountNumber=@AccountNumber 
		   AND a.[Period]=@Period
		   AND a.FirmType=@FirmType AND a.GroupNumber=@GroupNumber
          AND a.FinancialItemDefinitionId=@FinancialItemDefinitionId;

        EXEC ALT.ins_ATC_HistoryCorrection
             @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
             @FinancialItemDefinitionId=@FinancialItemDefinitionId, @AccountCode=@BaseCode,
             @Amount=@ABSDelta, @TransactionType=@SignChar, @Description=@MsgBase,
             @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

        /* ---- 5) ANCESTOR UPDATES: her ata i?in +? uygula ---- */
        DECLARE @AncestorCode NVARCHAR(20), @AncestorFID INT;

        DECLARE cur CURSOR FAST_FORWARD FOR
            SELECT Code, FinancialItemDefinitionId
            FROM #Ancestors
            ORDER BY LEN(Code) DESC;  -- ?nce en yak?n ata (?rn. 10), sonra 1

        OPEN cur;
        FETCH NEXT FROM cur INTO @AncestorCode, @AncestorFID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            /* Sadece mevcut sat?rlar g?ncellensin (insert yok) */
            IF EXISTS (
                SELECT 1
                FROM ALT.AutoTransferCleansing a WITH (NOLOCK)
                WHERE a.AccountNumber=@AccountNumber AND a.[Period]=@Period
				  AND a.FirmType=@FirmType AND a.GroupNumber=@GroupNumber
				  AND a.FinancialItemDefinitionId=@AncestorFID
            )
            BEGIN
                /* Log (info) */
                DECLARE @MsgAnc NVARCHAR(4000) = CONCAT(N'Cascade: ', @BaseCode,
                       N' g?ncellemesi ', @AncestorCode, N' atas?na yans?t?ld? (?=',
                       CONVERT(NVARCHAR(50), @Delta), N').');

                EXEC ALT.ins_ATC_History
                     @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                     @FinancialItemDefinitionId=@AncestorFID, @AccountCode=@AncestorCode,
                     @Amount=@ABSDelta, @TransactionType=@SignChar, @Description=@MsgAnc,
                     @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;

                /* +? uygula */
                UPDATE a
                   SET a.CorrectedValue = a.CorrectedValue + @Delta
                FROM ALT.AutoTransferCleansing a
                WHERE a.FirmType=@FirmType AND a.GroupNumber=@GroupNumber
                  AND a.AccountNumber=@AccountNumber AND a.[Period]=@Period
                  AND a.FinancialItemDefinitionId=@AncestorFID;

                /* Correction log */
                EXEC ALT.ins_ATC_HistoryCorrection
                     @RuleId=@RuleId, @AccountNumber=@AccountNumber, @Period=@Period,
                     @FinancialItemDefinitionId=@AncestorFID, @AccountCode=@AncestorCode,
                     @Amount=@ABSDelta, @TransactionType=@SignChar, @Description=@MsgAnc,
                     @UserName=@UserName, @HostName=@HostName, @HostIP=@HostIP;
            END

            FETCH NEXT FROM cur INTO @AncestorCode, @AncestorFID;
        END

        CLOSE cur; DEALLOCATE cur;
   
END
GO

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
			-- Mevcut kay?tlar? sil (ayn? m??teri + d?nem)
			DELETE FROM ALT.AutoTransferCleansing WHERE GroupNumber = @GroupNumber AND Period = @Period;
			-- Insert i?lemi

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
			   AND NOT EXISTS (SELECT 1 
			                     FROM ALT.CustomerFinancialItem C WITH (NOLOCK)
								WHERE C.GroupNumber = @GroupNumber
								  AND C.PeriodId = @Period
								  AND C.FinancialItemDefinitionId = F.FinancialItemDefinitionId
								  AND C.FirmType = 2
								  AND AccountNumber = 0)
            UNION ALL
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
			 WHERE GroupNumber = @GroupNumber 
			   AND PeriodId = @Period
			   AND FirmType = 2
			   AND AccountNumber = 0
			  


			DECLARE @MasterId INT
			SELECT @MasterId = ficm.FinancialDiscountMasterId
			  FROM boa.ALT.FinancialDiscountMaster ficm WITH (NOLOCK)
			 WHERE ficm.GroupNumber = @GroupNumber
			   AND ficm.PeriodId = @Period
			  
			IF @MasterId IS NOT NULL
			BEGIN
				DELETE FROM ALT.FinancialDiscount WHERE  FinancialDiscountMasterId = @MasterId
				DELETE FROM ALT.FinancialDiscountMaster WHERE FinancialDiscountMasterId = @MasterId
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
	  INNER JOIN boa.cus.Customer c WITH (NOLOCK) ON c.Customerid = ci.AccountNumber
	 WHERE ci.Consolidation = 1;


	/* 2) FID?ler */
	DECLARE @FID240 INT,
			@FID242 INT,
			@FID245 INT,
			@FID500 INT;

	SELECT @FID240 = NULLIF(MAX(CASE WHEN Code = N'240' THEN FinancialItemDefinitionId ELSE 0 END), 0),
		   @FID242 = NULLIF(MAX(CASE WHEN Code = N'242' THEN FinancialItemDefinitionId ELSE 0 END), 0),
		   @FID245 = NULLIF(MAX(CASE WHEN Code = N'245' THEN FinancialItemDefinitionId ELSE 0 END), 0),
		   @FID500 = NULLIF(MAX(CASE WHEN Code = N'500' THEN FinancialItemDefinitionId ELSE 0 END), 0)
	  FROM ALT.FinancialItemDefinition WITH (NOLOCK);

	IF @FID240 IS NULL OR @FID242 IS NULL OR @FID245 IS NULL OR @FID500 IS NULL
	BEGIN
		RAISERROR ('FinancialItemDefinition (240,242,245,500) eksik.', 16, 1);
		RETURN;
	END;

	/* 3) A×B×k?k e?le?meleri (yaln?zca yapraklar) */
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
				 b.FirmTitle AS BTitle,
				 r.RootCode,
				 tvf.DebitSum_Leaves,
				 tvf.CreditSum_Leaves,
				 CAST(CASE
							   WHEN tvf.DebitSum_Leaves > 0 THEN tvf.DebitSum_Leaves
							   WHEN tvf.CreditSum_Leaves > 0 THEN tvf.CreditSum_Leaves
							   ELSE 0 END AS DECIMAL(22, 2)) AS MatchedAmount_Pos 
			FROM ASet a
			JOIN BSet b ON b.AccountNumber <> a.AccountNumber
			CROSS JOIN Roots r
			CROSS APPLY ALT.fGetDetailedTrialBalanceContainesGroupsLeafSums_ATC(a.AccountNumber,@Period,r.RootCode,1,b.FirmTitle) tvf WHERE (tvf.DebitSum_Leaves > 0 OR tvf.CreditSum_Leaves > 0)
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

	/* #SumPerB'yi #Matches ?zerinden ?ret */
	SELECT BFirmType,
		   BAccountNumber,
		   BTitle,
		   SUM(MatchedAmount) AS TotalAmt
	  INTO #SumPerB
	  FROM #Matches
	GROUP BY BFirmType,
			 BAccountNumber,
			 BTitle;

	/* E?le?me yoksa ??k */
	IF NOT EXISTS (SELECT 1 FROM #Matches)
	AND NOT EXISTS (SELECT 1 FROM #SumPerB)
	BEGIN
	   EXEC ALT.ins_ATC_History @RuleId = @RuleId,
									 @AccountNumber = @GroupNumber,
									 @Period = @Period,
									 @FinancialItemDefinitionId = 0,
									 @AccountCode = null,
									 @Amount = null,
									 @TransactionType = null,
									 @Description = N'Discount 1 : e?le?me yok',
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;
	   RETURN;
	END
		

	/* 4) A taraf?: A×B×k?k baz?nda A?n?n 24x?inden d?? + log */
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
	FETCH NEXT FROM curA INTO @AFirmType, @AAcc, @ATitle,@BFirmType, @BAcc, @BTitle,@RootCode, @Amt;

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
					N') detay?nda B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
					N') ?nvan? tespit edildi; k?k ' + @RootCode + N' hesab?ndan d???ld?. Tutar=' + CONVERT(NVARCHAR(50), @Amt),
					@DescB NVARCHAR(4000) =
					N'R240_242_245_vs_500: B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
					N') i?in A firmalar?n?n 240/242/245 yaprak e?le?meleri toplam? 500 hesab?ndan d???ld?. Toplam=' + CONVERT(NVARCHAR(50), @Amt);

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
			  AND FinancialItemDefinitionId IN (@FID,@FID500);
		END;

		FETCH NEXT FROM curA INTO @AFirmType, @AAcc, @ATitle,@BFirmType, @BAcc, @BTitle,@RootCode, @Amt;
	END;

	CLOSE curA;
	DEALLOCATE curA;
END;
GO

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

    /* 1) Grup firmalar?n? haz?rla (#GroupInfo) */
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

    /* 2) FID?ler */
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

    /* 3) A×B×k?k e?le?meleri (yaln?zca yapraklar) */
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
            , b.FirmTitle     AS BTitle
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
		CROSS APPLY ALT.fGetDetailedTrialBalanceContainesGroupsLeafSums_ATC(a.AccountNumber,@Period,r.RootCode,1,b.FirmTitle) tvf WHERE (tvf.DebitSum_Leaves > 0 OR tvf.CreditSum_Leaves > 0)
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

    /* (?stenirse B toplam? i?in) */
    SELECT BFirmType, BAccountNumber, BTitle,
           SUM(MatchedAmount) AS TotalAmt
      INTO #SumPerB
      FROM #Matches
     GROUP BY BFirmType, BAccountNumber, BTitle;

    /* E?le?me yoksa ??k */
    IF NOT EXISTS (SELECT 1 FROM #Matches)
       AND NOT EXISTS (SELECT 1 FROM #SumPerB)
       BEGIN
	   EXEC ALT.ins_ATC_History @RuleId = @RuleId,
									 @AccountNumber = @GroupNumber,
									 @Period = @Period,
									 @FinancialItemDefinitionId = 0,
									 @AccountCode = null,
									 @Amount = null,
									 @TransactionType = null,
									 @Description = N'Discount 2 : e?le?me yok',
									 @UserName = @UserName,
									 @HostName = @HostName,
									 @HostIP = @HostIP;
	   RETURN;
	END

    /* 4) A×B×k?k baz?nda: A?n?n 24x?inden d?? + B?nin 501?inden d?? + log */
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
                N') detay?nda B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') ?nvan? tespit edildi; k?k ' + @RootCode + N' hesab?ndan d???ld?. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

            DECLARE @DescB NVARCHAR(4000) =
                N'R241_243_246_247_vs_501: B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') i?in A firmalar?n?n 241/243/246/247 yaprak e?le?meleri toplam? 501 hesab?ndan d???ld?. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

            -- A taraf? (k?k 24x) log
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

            -- B taraf? (501) log
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

            -- Discount loglar?
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

            -- A: 24x d??
            UPDATE ALT.AutoTransferCleansing
               SET CorrectedValue = CorrectedValue - @Amt
             WHERE GroupNumber = @GroupNumber
               AND Period = @Period
               AND FinancialItemDefinitionId IN (@FID,@FID501);
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

    /* 1) Grup firmalar?n? haz?rla (#GroupInfo) */
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

    /* ?nvanlar? tek seferde normalize et */
    UPDATE g
        SET NormTitle = g.FirmTitle
    FROM #GroupInfo g;

    /* 2) K?k s?ralar? (?ncelik) ve FID e?lemesi */
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

    -- Eksik FID kontrol?
    IF EXISTS (
        SELECT 1 FROM (
            SELECT Code FROM #CodeOrder_RCV
            UNION ALL
            SELECT Code FROM #CodeOrder_PAY
        ) x
        WHERE NOT EXISTS (SELECT 1 FROM #FIDs f WHERE f.Code = x.Code)
    )
    BEGIN
        RAISERROR('FinancialItemDefinition eksik (alacak/bor? k?klerinden biri bulunamad?).',16,1);
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

    /* 3.5) TVF'yi tek noktada ?al??t?rmak i?in gereken t?m kombinasyonlar? haz?rla */
    IF OBJECT_ID('tempdb..#AccCodeCp') IS NOT NULL DROP TABLE #AccCodeCp;

    CREATE TABLE #AccCodeCp
    (
        AccountNumber INT,
        Code          NVARCHAR(3),
        CounterpartyNameNorm VARCHAR(4000)
    );

    -- alacak k?kleri i?in
    INSERT INTO #AccCodeCp (AccountNumber, Code, CounterpartyNameNorm)
    SELECT DISTINCT
        g.AccountNumber,
        r.Code,
        g2.NormTitle
    FROM #GroupInfo g
    CROSS JOIN #CodeOrder_RCV r
    CROSS JOIN #GroupInfo g2
    WHERE g.AccountNumber <> g2.AccountNumber;  -- ayn? firma i?in tvf ?a??rma

    -- bor? k?kleri i?in
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

    /* 3.6) ?imdi TVF'yi tek yerde ?al??t?r ve sonucu #DtlAll'a al */
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
	CROSS APPLY ALT.fGetDetailedTrialBalanceContainesGroupsLeafSums_ATC(acc.AccountNumber,@Period, acc.Code,1, acc.CounterpartyNameNorm) tvf WHERE (tvf.DebitSum_Leaves > 0 OR tvf.CreditSum_Leaves > 0);
    
    /* 4) A?B (Alacak taraf?) */
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

    /* 5) B?A (Bor? taraf?) */
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

    /* 6) ?ift baz?nda toplamlar ve Delta */
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
	BEGIN
	    EXEC ALT.ins_ATC_History
                 @RuleId = @RuleId,
                 @AccountNumber = @GroupNumber,
                 @Period = @Period,
                 @FinancialItemDefinitionId = 0,
                 @AccountCode = NULL,
                 @Amount = NULL,
                 @TransactionType = null,
                 @Description = N'Discount 3: e?le?me yok',
                 @UserName = @UserName,
                 @HostName = @HostName,
                 @HostIP = @HostIP;
        RETURN;
	END

    /* 7) Waterfall da??t?m? ? A (Alacak) */
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

    /* 8) Waterfall da??t?m? ? B (Bor?) */
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

    /* 9) Log + (?imdilik sadece text) : A taraf? */
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
                N') detay?nda B (' + CONVERT(NVARCHAR(20), @BAcc) + N' - ' + ISNULL(@BTitle, N'') +
                N') nedeniyle alacak k?k? ' + @Code + N' tenzil. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

             EXEC ALT.ins_ATC_History
                 @RuleId = @RuleId,
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

    /* 10) Log + (?imdilik sadece text) : B taraf? */
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
                N') detay?nda A (' + CONVERT(NVARCHAR(20), @AAcc) + N' - ' + ISNULL(@ATitle, N'') +
                N') nedeniyle bor? k?k? ' + @Code + N' tenzil. Tutar=' + CONVERT(NVARCHAR(50), @Amt);

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
  
    -- (Opsiyonel) H?z i?in indeks  
    -- CREATE CLUSTERED INDEX IX_Src_Key ON #Src(FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId);  
  
    -----------------------------------------  
    -- 2) UPDATE: Her iki tabloda da ayn? kay?t varsa g?ncelle  
    --    (gereksiz yazmay? ?nlemek i?in farkl?l?k kontrol? ile)  
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
    -- 3) INSERT: Hedefte olmayan + (OV,CV) ikisi birden 0 de?ilse  
    --    (0,0 olan yeni kay?tlar HAR??)  
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
      AND (ISNULL(S.OriginalValue,0) <> 0 OR ISNULL(S.CorrectedValue,0) <> 0);  -- (0,0) HAR??  
  
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
CREATE PROCEDURE [ALT].[upd_ATC_FillGreyListCache]
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
   DECLARE @Today SMALLDATETIME = CAST(GETDATE() AS DATE)
        IF NOT EXISTS(SELECT TOP 1  1 
		                FROM [ALT].[GreyListCacheAtc] atc WITH(NOLOCK) 
					   WHERE atc.TranDate = @Today)
		BEGIN
		   TRUNCATE TABLE [ALT].[GreyListCacheAtc]
		   INSERT INTO [ALT].[GreyListCacheAtc](Title,TranDate)
		   SELECT DISTINCT
						FW + '|' + SW AS NormTitle,
						@Today
					FROM (
						SELECT
							Title,
							CleanTitle =
							LTRIM(RTRIM(
								REPLACE(
								REPLACE(
								REPLACE(
								REPLACE(
									LOWER(replACE(replace(REPlACE(REPLACE(REPLACE(Title, '.', ' '),'(',''),')',''),',',''),':','')),
									'(iflas nedeniyle)', ''
								),
									'iflas nedeniyle', ''
								),
									'tasfiye halinde', ''
								),
									'tasfiye', ''
								)
							))
						FROM (
							SELECT Name AS Title FROM INQ.BankruptcyConcordat WITH (NOLOCK)
							WHERE EndDate IS NULL OR EndDate > CAST(GETDATE() AS date)

							UNION ALL
							SELECT Title FROM INQ.TCMBProtestedBills WITH (NOLOCK)

							UNION ALL
							SELECT a.Title
							FROM [INQ].TCMBBouncedCheckCorp a WITH (NOLOCK)
							WHERE a.StateCode = 'B'
							  AND (a.SubmissionDate IS NULL OR a.SubmissionDate >= DATEADD(YEAR, -4, CAST(GETDATE() AS date)))
							  AND NOT EXISTS (
								  SELECT 1
								  FROM [INQ].TCMBBouncedCheckCorp b WITH (NOLOCK)
								  WHERE b.CheckAccountNumber = a.CheckAccountNumber
									AND b.CheckOrderNumber = a.CheckOrderNumber
									AND b.StateCode IN ('K', 'S')
							  )

							UNION ALL
							SELECT Title
							FROM INQ.BlackListCorporation BC WITH (NOLOCK)
							WHERE BC.Status = 1
							  AND BC.BlackListTypeID IN (3,7,9,10,11)
						) A
					) X
					CROSS APPLY (
						SELECT
							T1 = LTRIM(X.CleanTitle)
					) N
					CROSS APPLY (
						SELECT
							FW = LEFT(N.T1, CHARINDEX(' ', N.T1 + ' ') - 1),
							R1 = LTRIM(SUBSTRING(N.T1, CHARINDEX(' ', N.T1 + ' ') + 1, 4000))
					) W1
					CROSS APPLY (
						SELECT
							SW = LEFT(W1.R1, CHARINDEX(' ', W1.R1 + ' ') - 1)
					) W2;

		END
	
END

GO

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
    -- HISTORY (g?ncellenen b?l?m)
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

    -- CorrectedValue g?ncelle
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
CREATE PROCEDURE [ALT].[upd_ATC_TransferCascade]  
(  
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id  
    @AccountNumber INT,  
    @Period        INT,   
    @Need          DECIMAL(22,2),     -- Hedefte ihtiya? duyulan tutar  
    @SourceCodes   NVARCHAR(200),     -- Virg?ll? liste: '120,121,127' ya da '136,120,121,127'  
    @TargetCode    NVARCHAR(10),      -- ?rn: '128' veya '138'  
    @UserName VARCHAR(10) = NULL,    
    @HostName VARCHAR(20) = NULL,    
    @HostIP VARCHAR(15) = NULL   
)  
AS  
BEGIN
				SET NOCOUNT ON;
  
  
					/* 0) Kaynak kodlar? s?rayla tabloya a? */  
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
				RAISERROR ('upd_ATC_TransferCascade: Target FID bulunamad? (%s).', 16, 1, @TargetCode);

				/* 2) Hedef sat?r? yoksa olu?tur */
				IF NOT EXISTS (SELECT 1 FROM ALT.AutoTransferCleansing WITH (NOLOCK)
				     WHERE AccountNumber = @AccountNumber
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

				/* 3) S?rayla kaynaklardan aktar */
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
				-- Kayna??n FID'si  
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
  
  
										-- A??klamalar (string concat?? ?nce de?i?kene al)  
										DECLARE @DescTake NVARCHAR(500),  
												@DescAdd  NVARCHAR(500);

								SET @DescTake = N'Rule7 Cascade: ' + @SrcCode + N' -> ' + @TargetCode
								+ N' aktar?m denemesi. Kalan ihtiya?=' + CONVERT(NVARCHAR(50), @Remain);

								SET @DescAdd = N'Rule7 Cascade: ' + @SrcCode + N' -> ' + @TargetCode + N' aktar?ld?.';

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

								-- G?ncellemeler  
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
  
  
					-- Kar??lanamayan bakiye bilgisi  
					IF @Remain > 0  
					BEGIN
  
						DECLARE @DescRemain NVARCHAR(500) = N'Rule7 Cascade: Kaynaklar yetersiz. Kar??lanamayan bakiye=' + CONVERT(NVARCHAR(50), @Remain);

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


