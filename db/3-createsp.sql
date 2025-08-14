CREATE   FUNCTION dbo.fn_GetLeafSums
(
      @AccountNumber INT
    , @PeriodId      INT
    , @RootCode      NVARCHAR(50)
    , @ExcludeRoot   BIT = 1  -- 1: kök hariç (alt kırılımlar), 0: kök dahil (kök de yapraksa)
)
RETURNS TABLE
AS
RETURN
WITH Tree AS
(
    -- Kök
    SELECT
        p.AccountCode,
        p.ParentAccountCode,
        p.AccountName,
        CAST(p.DebitBalance  AS DECIMAL(22,2)) AS DebitBalance,
        CAST(p.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
    FROM MizanDB.dbo.CustomerDetailedTrialBalance p
    WHERE p.AccountNumber = @AccountNumber
      AND p.PeriodId      = @PeriodId
      AND p.AccountCode   = @RootCode

    UNION ALL

    -- Alt ağaç (tüm torunlar)
    SELECT
        c.AccountCode,
        c.ParentAccountCode,
        c.AccountName,
        CAST(c.DebitBalance  AS DECIMAL(22,2)) AS DebitBalance,
        CAST(c.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
    FROM MizanDB.dbo.CustomerDetailedTrialBalance c
    JOIN Tree t
      ON  c.AccountNumber      = @AccountNumber
      AND c.PeriodId           = @PeriodId
      AND c.ParentAccountCode  = t.AccountCode
),
Leaves AS
(
    -- Yaprak = hiç çocuğu olmayan düğüm
    SELECT t.*
    FROM Tree t
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM MizanDB.dbo.CustomerDetailedTrialBalance x
        WHERE x.AccountNumber     = @AccountNumber
          AND x.PeriodId          = @PeriodId
          AND x.ParentAccountCode = t.AccountCode
    )
)
SELECT
    -- Kök dahil/haricini kontrol et (kök yapraksa ve @ExcludeRoot=1 ise sayma)
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE DebitBalance END)  AS DECIMAL(22,2)) AS DebitSum_Leaves,
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE CreditBalance END) AS DECIMAL(22,2)) AS CreditSum_Leaves,
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE (DebitBalance - CreditBalance) END) AS DECIMAL(22,2)) AS NetSum_Leaves
FROM Leaves;

CREATE   FUNCTION dbo.fn_NormalizeTitle
(
    @name NVARCHAR(255)
)
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @s NVARCHAR(255);

    -- NULL güvenliği
    IF @name IS NULL RETURN N'';

    -- İşaretler ve şirket ekleri temizliği
    SET @s = REPLACE(@name, N'.', N' ');
    SET @s = REPLACE(@s   , N',', N' ');
    SET @s = REPLACE(@s   , N'-', N' ');
    SET @s = REPLACE(@s   , N'_', N' ');
    SET @s = REPLACE(@s   , N'''', N' ');

    -- Yaygın şirket ekleri (varyantlarıyla)
    SET @s = REPLACE(@s, N' AŞ '     , N' ');
    SET @s = REPLACE(@s, N' A.Ş '    , N' ');
    SET @s = REPLACE(@s, N' AS '     , N' ');
    SET @s = REPLACE(@s, N' A.S '    , N' ');
    SET @s = REPLACE(@s, N' LTD '    , N' ');
    SET @s = REPLACE(@s, N' LİMİTED ', N' ');
    SET @s = REPLACE(@s, N' LIMITED ', N' ');
    SET @s = REPLACE(@s, N' ŞTİ '    , N' ');
    SET @s = REPLACE(@s, N' STI '    , N' ');

    -- Baştaki/sondaki boşlukları kırp
    SET @s = TRIM(@s);

    -- Çoklu boşluğu tek boşluğa indir (3 kez genelde yeterli; istersen WHILE ile de olur)
    SET @s = REPLACE(@s, N'  ', N' ');
    SET @s = REPLACE(@s, N'  ', N' ');
    SET @s = REPLACE(@s, N'  ', N' ');

    -- Büyük harfe çevir
    SET @s = UPPER(@s);

    RETURN @s;
END;

CREATE     PROCEDURE dbo.sp_ATC_ApplyRule_01
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID100 INT, @FID600 INT, @FID563 INT;

        SELECT
            @FID100 = MAX(CASE WHEN Code = N'100' THEN FinancialItemDefinitionId END),
            @FID600 = MAX(CASE WHEN Code = N'600' THEN FinancialItemDefinitionId END),
            @FID563 = MAX(CASE WHEN Code = N'563' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK);

        IF @FID100 IS NULL OR @FID600 IS NULL OR @FID563 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (100, 600, 563) bulunamadı.', 16, 1);

        DECLARE
            @V100 DECIMAL(22,2) = 0,
            @V600 DECIMAL(22,2) = 0,
            @V563 DECIMAL(22,2) = 0;

        -- Artık CorrectedValue üzerinden çalışıyoruz
        SELECT @V100 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID100;

        SELECT @V600 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID600;

        SELECT @V563 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID563;

        DECLARE @Cap DECIMAL(22,2),
                @Delta DECIMAL(22,2);

        SET @Cap = CASE WHEN (@V600 * 0.02) < 5000000
                        THEN CAST(@V600 * 0.02 AS DECIMAL(22,2))
                        ELSE CAST(5000000 AS DECIMAL(22,2)) END;

        SET @Delta = CASE WHEN @V100 > @Cap
                          THEN CAST(@V100 - @Cap AS DECIMAL(22,2))
                          ELSE CAST(0 AS DECIMAL(22,2)) END;

        IF @Debug = 1
            PRINT CONCAT('V100=', @V100, ' V600=', @V600, ' V563=', @V563, ' Cap=', @Cap, ' Delta=', @Delta);

        /* History Kayıtları */
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID100, N'100', @Delta, '-',
         N'Rule1: Fiktif kasa üst sınır (' + CONVERT(NVARCHAR(50), @Cap) + N') fazlası çıkarıldı.');

        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID563, N'563', @Delta, '+',
         N'Rule1: Fiktif kasa fazlası 563 hesabına aktarıldı.');

        /* Delta yoksa güncelleme yapmadan çık */
        IF @Delta <= 0
        BEGIN
            COMMIT;
            RETURN;
        END

        /* Delta > 0 ise CorrectedValue güncelle */
        -- 100
        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @V100 - @Delta
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID100;

        -- 563
        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @V563 + @Delta
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID563;

        IF @Debug = 1
        BEGIN
            SELECT [Item]='100', [Before]=@V100, [After]=@V100 - @Delta
            UNION ALL
            SELECT '563', @V563, @V563 + @Delta;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_01 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_02
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* 0) FID'leri yakala (101, 121) */
        DECLARE @FID101 INT, @FID121 INT;

        SELECT
            @FID101 = MAX(CASE WHEN Code = N'101' THEN FinancialItemDefinitionId END),
            @FID121 = MAX(CASE WHEN Code = N'121' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK);

        IF @FID101 IS NULL OR @FID121 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (101, 121) bulunamadı.', 16, 1);

        /* 1) Mevcut düzeltilmiş değerleri oku */
        DECLARE
            @V101 DECIMAL(22,2) = 0,
            @V121 DECIMAL(22,2) = 0;

        SELECT @V101 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID101;

        SELECT @V121 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID121;

        /* 2) Delta hesapla */
        DECLARE @Delta DECIMAL(22,2) = @V101;

        IF @Debug = 1
            PRINT CONCAT('V101=', @V101, ' V121=', @V121, ' Delta=', @Delta);

        /* 3) History kayıtları (Delta olsa da olmasa da) */
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID101, N'101', @Delta, '-',
         CASE WHEN @Delta > 0
              THEN N'101 hesabındaki tutar 121 hesabına aktarılmak üzere çıkarıldı.'
              ELSE N'101 hesabında bakiye yok, transfer yapılmadı.'
         END);

        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID121, N'121', @Delta, '+',
         CASE WHEN @Delta > 0
              THEN N'101 hesabındaki tutar 121 hesabına eklendi.'
              ELSE N'101 hesabında bakiye yok, 121 hesabına ekleme yapılmadı.'
         END);

        /* 4) Delta <= 0 ise erken çık */
        IF @Delta <= 0
        BEGIN
            COMMIT;
            RETURN;
        END

        /* 5) Yeni değerler */
        DECLARE
            @New101 DECIMAL(22,2) = @V101 - @Delta, -- yani 0
            @New121 DECIMAL(22,2) = @V121 + @Delta;

        /* 6) CorrectedValue güncelle */
        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @New101
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID101;

        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @New121
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID121;

        IF @Debug = 1
        BEGIN
            SELECT [Item]='101', [Before]=@V101, [After]=@New101
            UNION ALL
            SELECT '121', @V121, @New121;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_02 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_03
(
    @RuleId        INT,                 -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @SearchTerms   NVARCHAR(4000) = N'Çek,Senet',  -- virgülle ayrılmış kelimeler
    @BalanceMode   NVARCHAR(10)  = N'POS_SIDE',    -- 'POS_SIDE' | 'NET'
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* 1) FID (102, 121) */
        DECLARE @FID102 INT, @FID121 INT;

        SELECT
            @FID102 = MAX(CASE WHEN Code = N'102' THEN FinancialItemDefinitionId END),
            @FID121 = MAX(CASE WHEN Code = N'121' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK);

        IF @FID102 IS NULL OR @FID121 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (102, 121) bulunamadı.', 16, 1);

        /* 2) Mevcut düzeltilmiş değerler */
        DECLARE @V102 DECIMAL(22,2) = 0,
                @V121 DECIMAL(22,2) = 0;

        SELECT @V102 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID102;

        SELECT @V121 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
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

        IF UPPER(@BalanceMode) = N'NET'
        BEGIN
            SELECT @DeltaBase =
                   COALESCE(SUM(
                       CASE
                           WHEN DebitBalance IS NOT NULL AND CreditBalance IS NOT NULL
                                THEN (DebitBalance - CreditBalance)
                           WHEN DebitBalance IS NOT NULL THEN DebitBalance
                           WHEN CreditBalance IS NOT NULL THEN -CreditBalance
                           ELSE 0
                       END
                   ), 0)
            FROM MizanDB.dbo.CustomerDetailedTrialBalance d WITH (NOLOCK)
            WHERE d.AccountNumber = @AccountNumber
              AND d.PeriodId      = @PeriodId
              AND d.AccountCode   LIKE N'102%' COLLATE SQL_Latin1_General_CP1_CI_AS
              AND EXISTS (SELECT 1 FROM @Terms t
                          WHERE d.AccountName LIKE t.Pattern COLLATE SQL_Latin1_General_CP1_CI_AS);
        END
        ELSE
        BEGIN
            SELECT @DeltaBase =
                   COALESCE(SUM(
                       CASE
                           WHEN ISNULL(DebitBalance,0)  > 0 THEN DebitBalance
                           WHEN ISNULL(CreditBalance,0) > 0 THEN CreditBalance
                           ELSE 0
                       END
                   ), 0)
            FROM MizanDB.dbo.CustomerDetailedTrialBalance d WITH (NOLOCK)
            WHERE d.AccountNumber = @AccountNumber
              AND d.PeriodId      = @PeriodId
              AND d.AccountCode   LIKE N'102%' COLLATE SQL_Latin1_General_CP1_CI_AS
              AND EXISTS (SELECT 1 FROM @Terms t
                  WHERE d.AccountName LIKE t.Pattern COLLATE SQL_Latin1_General_CP1_CI_AS);
        END

        DECLARE @Delta DECIMAL(22,2) =
            CASE WHEN @DeltaBase > 0 THEN CAST(@DeltaBase AS DECIMAL(22,2)) ELSE 0 END;

        IF @Debug = 1
            PRINT CONCAT('Mode=', @BalanceMode, ' | V102=', @V102, ' V121=', @V121,
                         ' DeltaBase=', @DeltaBase, ' Delta=', @Delta,
                         ' Terms=', @SearchTerms);

        /* 5) History kayıtları */
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID102, N'102', @Delta, '-',
         N'Rule3: 102 alt kalemlerinden [' + ISNULL(@SearchTerms,N'') +
         N'] filtrelendi. Mode=' + UPPER(@BalanceMode) +
         N', Toplam=' + CONVERT(NVARCHAR(50), @DeltaBase));

        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID121, N'121', @Delta, '+',
         N'Rule3: 102 alt kalemlerinden [' + ISNULL(@SearchTerms,N'') +
         N'] aktarılan tutar eklendi. Mode=' + UPPER(@BalanceMode) +
         N', Toplam=' + CONVERT(NVARCHAR(50), @DeltaBase));

        /* 6) Delta <= 0 ise çık */
        IF @Delta <= 0
        BEGIN
            COMMIT;
            RETURN;
        END

        /* 7) Yeni değerler */
        DECLARE @New102 DECIMAL(22,2) = @V102 - @Delta,
                @New121 DECIMAL(22,2) = @V121 + @Delta;

        /* 8) CorrectedValue güncelle */
        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @New102
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID102;

        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @New121
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID121;

        IF @Debug = 1
        BEGIN
            SELECT [Item]='102', [Before]=@V102, [After]=@New102
            UNION ALL
            SELECT '121', @V121, @New121;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_03 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_04
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* 0) FID'leri yakala (103, 321) */
        DECLARE @FID103 INT, @FID321 INT;

        SELECT
            @FID103 = MAX(CASE WHEN Code = N'103' THEN FinancialItemDefinitionId END),
            @FID321 = MAX(CASE WHEN Code = N'321' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK);

        IF @FID103 IS NULL OR @FID321 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (103, 321) bulunamadı.', 16, 1);

        /* 1) Mevcut düzeltilmiş değerler */
        DECLARE @V103 DECIMAL(22,2) = 0,
                @V321 DECIMAL(22,2) = 0;

        SELECT @V103 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID103;

        SELECT @V321 = COALESCE(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID321;

        /* 2) Delta: 103’ün tamamı */
        DECLARE @Delta DECIMAL(22,2) = @V103;

        IF @Debug = 1
            PRINT CONCAT('V103=', @V103, ' V321=', @V321, ' Delta=', @Delta);

        /* 3) History kayıtları */
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID103, N'103', @Delta, '-',
         CASE WHEN @Delta > 0
              THEN N'103 hesabındaki tüm tutar 321 hesabına aktarıldı.'
              ELSE N'103 hesabında bakiye yok, transfer yapılmadı.'
         END);

        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID321, N'321', @Delta, '+',
         CASE WHEN @Delta > 0
              THEN N'103 hesabından gelen tutar 321 hesabına eklendi.'
              ELSE N'103 hesabında bakiye yok, 321 hesabına ekleme yapılmadı.'
         END);

        /* 4) Delta <= 0 ise erken çık */
        IF @Delta <= 0
        BEGIN
            COMMIT;
            RETURN;
        END

        /* 5) Yeni değerler */
        DECLARE @New103 DECIMAL(22,2) = @V103 - @Delta,  -- 0
                @New321 DECIMAL(22,2) = @V321 + @Delta;

        /* 6) CorrectedValue güncelle */
        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @New103
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID103;

        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue = @New321
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId=@FID321;

        IF @Debug = 1
        BEGIN
            SELECT [Item]='103', [Before]=@V103, [After]=@New103
            UNION ALL
            SELECT '321', @V321, @New321;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_04 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_05
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

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
            @FIDRoot   = MAX(CASE WHEN Code = @RootCode   THEN FinancialItemDefinitionId END),
            @FIDTarget = MAX(CASE WHEN Code = @TargetCode THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK);

        IF @FIDRoot IS NULL OR @FIDTarget IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (120, 340) bulunamadı.', 16, 1);

        /* 120 alt kırılımlardaki alacak bakiyesi toplamı (kök hariç) */
        SELECT @LeafCredit = CreditSum_Leaves
        FROM MizanDB.dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, @RootCode, 1);

        /* 120 ana kalemin alacak bakiyesi (mizan) */
        SELECT @RootCredit = COALESCE(SUM(CreditBalance), 0)
        FROM MizanDB.dbo.CustomerDetailedTrialBalance WITH (NOLOCK)
        WHERE AccountNumber = @AccountNumber
          AND PeriodId      = @PeriodId
          AND AccountCode   = @RootCode COLLATE SQL_Latin1_General_CP1_CI_AS;

        /* Delta = (alt kalem alacak toplamı) - (ana kalem alacak) */
        SET @Delta = ISNULL(@LeafCredit,0) - ISNULL(@RootCredit,0);

        /* Debug */
        IF @Debug = 1
        BEGIN
            PRINT '--- Rule 5 Debug Info ---';
            PRINT 'LeafCredit   = ' + CONVERT(NVARCHAR(50), ISNULL(@LeafCredit,0));
            PRINT 'RootCredit   = ' + CONVERT(NVARCHAR(50), ISNULL(@RootCredit,0));
            PRINT 'Delta        = ' + CONVERT(NVARCHAR(50), ISNULL(@Delta,0));
        END

        /* History (her durumda) */
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FIDRoot, @RootCode, ISNULL(@Delta,0),
         CASE WHEN @Delta >= 0 THEN '+' ELSE '-' END,
         N'Rule5: 120 yaprak alacak toplamı (' + CONVERT(NVARCHAR(50), ISNULL(@LeafCredit,0)) +
         N') - ana alacak (' + CONVERT(NVARCHAR(50), ISNULL(@RootCredit,0)) +
         N') = ' + CONVERT(NVARCHAR(50), ISNULL(@Delta,0)) + N'.');

        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FIDTarget, @TargetCode, ISNULL(@Delta,0),
         CASE WHEN @Delta >= 0 THEN '+' ELSE '-' END,
         N'Rule5: 120 ters bakiyesi kadar 340 hesabı güncellendi.');

        /* Delta pozitif ise CorrectedValue güncelle */
        IF @Delta > 0
        BEGIN
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDRoot;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDTarget;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_05 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_06
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID120 INT, @FID320 INT;

        -- FID değerlerini filtreli al
        SELECT
            @FID120 = MAX(CASE WHEN Code = N'120' THEN FinancialItemDefinitionId END),
            @FID320 = MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('120', '320');

        IF @FID120 IS NULL OR @FID320 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (120, 320) bulunamadı.', 16, 1);

        -- 120 ve 320 alt kalemlerini çek
        DECLARE @T120 TABLE (
            NormTitle NVARCHAR(255),
            Amount DECIMAL(22,2),
            AccountCode NVARCHAR(50)
        );

        DECLARE @T320 TABLE (
            NormTitle NVARCHAR(255),
            Amount DECIMAL(22,2),
            AccountCode NVARCHAR(50)
        );

        INSERT INTO @T120
        SELECT
            dbo.fn_NormalizeTitle(AccountName),
            ISNULL(CreditBalance, 0) AS Amount,
            AccountCode
        FROM MizanDB.dbo.CustomerDetailedTrialBalance WITH (NOLOCK)
        WHERE AccountNumber = @AccountNumber
          AND PeriodId      = @PeriodId
          AND AccountCode LIKE '120%';

        INSERT INTO @T320
        SELECT
            dbo.fn_NormalizeTitle(AccountName),
            ISNULL(DebitBalance, 0) AS Amount,
            AccountCode
        FROM MizanDB.dbo.CustomerDetailedTrialBalance WITH (NOLOCK)
        WHERE AccountNumber = @AccountNumber
          AND PeriodId      = @PeriodId
          AND AccountCode LIKE '320%';

        -- Eşleşen unvanlar üzerinden dön
        DECLARE @Title NVARCHAR(255),
                @Amt120 DECIMAL(22,2),
                @Amt320 DECIMAL(22,2),
                @Delta DECIMAL(22,2),
                @AccCode120 NVARCHAR(50),
                @AccCode320 NVARCHAR(50);

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

            -- History: 120
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID120, @AccCode120, ISNULL(@Delta,0), '-',
             N'Rule6: "' + @Title + N'" unvanı için 120-320 karşılıklı mahsup kontrolü yapıldı. Delta=' + CONVERT(NVARCHAR(50),ISNULL(@Delta,0)));

            -- History: 320
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID320, @AccCode320, ISNULL(@Delta,0), '-',
             N'Rule6: "' + @Title + N'" unvanı için 120-320 karşılıklı mahsup kontrolü yapıldı. Delta=' + CONVERT(NVARCHAR(50),ISNULL(@Delta,0)));

            -- Delta > 0 ise düzeltme yap
            IF @Delta > 0
            BEGIN
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue - @Delta
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FID120;

                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue - @Delta
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FID320;

                IF @Debug = 1
                    PRINT CONCAT('Eşleşen Firma: ', @Title, ' | Delta: ', @Delta);
            END

            FETCH NEXT FROM cur INTO @Title, @Amt120, @Amt320, @AccCode120, @AccCode320;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_06 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE  PROCEDURE dbo.sp_ATC_ApplyRule_07
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* --------------------------------------------------
           1) Gerekli FinancialItemDefinitionId'leri al
        -------------------------------------------------- */
        DECLARE 
            @FID120 INT, @FID121 INT, @FID127 INT,
            @FID128 INT, @FID129 INT,
            @FID136 INT, @FID138 INT, @FID139 INT,
            @FID562 INT;

        SELECT
            @FID120 = MAX(CASE WHEN Code = '120' THEN FinancialItemDefinitionId END),
            @FID121 = MAX(CASE WHEN Code = '121' THEN FinancialItemDefinitionId END),
            @FID127 = MAX(CASE WHEN Code = '127' THEN FinancialItemDefinitionId END),
            @FID128 = MAX(CASE WHEN Code = '128' THEN FinancialItemDefinitionId END),
            @FID129 = MAX(CASE WHEN Code = '129' THEN FinancialItemDefinitionId END),
            @FID136 = MAX(CASE WHEN Code = '136' THEN FinancialItemDefinitionId END),
            @FID138 = MAX(CASE WHEN Code = '138' THEN FinancialItemDefinitionId END),
            @FID139 = MAX(CASE WHEN Code = '139' THEN FinancialItemDefinitionId END),
            @FID562 = MAX(CASE WHEN Code = '562' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('120','121','127','128','129','136','138','139','562');

        /* --------------------------------------------------
           2) Ortak yardımcı işlem prosedürü:
              Belirli kaynaklardan hedef hesaba aktarım
        -------------------------------------------------- */
        DECLARE @Desc NVARCHAR(500);

        DECLARE @TmpDelta DECIMAL(22,2), @Need DECIMAL(22,2);

        /* Yardımcı: Kaynaktan düş, hedefe ekle */
        DECLARE @srcFID INT, @srcCode NVARCHAR(10), @take DECIMAL(22,2);
        DECLARE @targetFID INT, @targetCode NVARCHAR(10);

        /* --------------------------------------------------
           3) 128 – 129 kontrolü
        -------------------------------------------------- */
        DECLARE @V128 DECIMAL(22,2) = (
            SELECT COALESCE(SUM(CorrectedValue),0) 
            FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID128
        );

        DECLARE @V129 DECIMAL(22,2) = (
            SELECT COALESCE(SUM(CorrectedValue),0) 
            FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID129
        );

        IF @V128 > @V129
        BEGIN
            SET @TmpDelta = @V128 - @V129;

            -- 128 azalt
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @TmpDelta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID128;

            -- 562 artır
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @TmpDelta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID562;

            -- History
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID128, '128', @TmpDelta, '-', N'Rule7: 128 fazla bakiye karşılık ayrıldı (562’ye).'),
            (@RuleId, @AccountNumber, @PeriodId, @FID562, '562', @TmpDelta, '+', N'Rule7: 128 fazla bakiye 562’ye aktarıldı.');
        END
        ELSE IF @V129 > @V128
        BEGIN
            SET @Need = @V129 - @V128;
            EXEC dbo.sp_ATC_TransferCascade @RuleId, @FirmType, @GroupNumber, @AccountNumber, @PeriodId, @Need,
                                            '120,121,127', '128', @Debug;
        END

        /* --------------------------------------------------
           4) 138 – 139 kontrolü
        -------------------------------------------------- */
        DECLARE @V138 DECIMAL(22,2) = (
            SELECT COALESCE(SUM(CorrectedValue),0) 
            FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID138
        );

        DECLARE @V139 DECIMAL(22,2) = (
            SELECT COALESCE(SUM(CorrectedValue),0) 
            FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID139
        );

        IF @V138 > @V139
        BEGIN
            SET @TmpDelta = @V138 - @V139;

            -- 138 azalt
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @TmpDelta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID138;

            -- 562 artır
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @TmpDelta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID562;

            -- History
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID138, '138', @TmpDelta, '-', N'Rule7: 138 fazla bakiye karşılık ayrıldı (562’ye).'),
            (@RuleId, @AccountNumber, @PeriodId, @FID562, '562', @TmpDelta, '+', N'Rule7: 138 fazla bakiye 562’ye aktarıldı.');
        END
        ELSE IF @V139 > @V138
        BEGIN
            SET @Need = @V139 - @V138;
            EXEC dbo.sp_ATC_TransferCascade @RuleId, @FirmType, @GroupNumber, @AccountNumber, @PeriodId, @Need,
                                            '136,120,121,127', '138', @Debug;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('sp_ATC_ApplyRule_07 failed: %s', 16, 1, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_09
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID128 INT, @FID129 INT, @FID562 INT;

        -- FID değerlerini al
        SELECT
            @FID128 = MAX(CASE WHEN Code = N'128' THEN FinancialItemDefinitionId END),
            @FID129 = MAX(CASE WHEN Code = N'129' THEN FinancialItemDefinitionId END),
            @FID562 = MAX(CASE WHEN Code = N'562' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('128', '129', '562');

        IF @FID128 IS NULL OR @FID129 IS NULL OR @FID562 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (128, 129, 562) bulunamadı.', 16, 1);

        -- Gri listeden firmaları normalize edip tabloya al
        DECLARE @GreyList TABLE (NormTitle NVARCHAR(255));
        INSERT INTO @GreyList
        SELECT DISTINCT dbo.fn_NormalizeTitle(FirmName)
        FROM ALT.GreyListFirms WITH (NOLOCK);

        -- İşlenecek hesap kodları
        DECLARE @Accounts TABLE (AccCode NVARCHAR(50));
        INSERT INTO @Accounts VALUES
        ('120'), ('127'), ('131'), ('132'), ('133'), ('136');

        -- Mizan verisinden gri liste eşleşmelerini çek
        DECLARE @Matches TABLE (
            NormTitle NVARCHAR(255),
            Amount DECIMAL(22,2),
            AccCode NVARCHAR(50)
        );

        INSERT INTO @Matches
        SELECT
            dbo.fn_NormalizeTitle(cdtb.AccountName) AS NormTitle,
            ISNULL(cdtb.CreditBalance, 0) AS Amount,
            cdtb.AccountCode
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb WITH (NOLOCK)
        INNER JOIN @Accounts a ON LEFT(cdtb.AccountCode, LEN(a.AccCode)) = a.AccCode
        INNER JOIN @GreyList g ON dbo.fn_NormalizeTitle(cdtb.AccountName) = g.NormTitle
        WHERE cdtb.AccountNumber = @AccountNumber
          AND cdtb.PeriodId = @PeriodId;

        -- Döngü ile her eşleşen kaydı işle
        DECLARE @Title NVARCHAR(255),
                @Amt DECIMAL(22,2),
                @AccCode NVARCHAR(50),
                @FIDSource INT;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT NormTitle, Amount, AccCode
        FROM @Matches;

        OPEN cur;
        FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kaynağın FID'sini bul
            SELECT @FIDSource = FinancialItemDefinitionId
            FROM MizanDB.ALT.FinancialItemDefinition
            WHERE Code = LEFT(@AccCode, 3);

            IF @FIDSource IS NOT NULL
            BEGIN
                -- History kayıtları (koşulsuz)
                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FIDSource, @AccCode, ISNULL(@Amt,0), '-',
                 N'Rule9: ' + @Title + N' gri listede. ' + @AccCode + N' hesabından çıkarıldı.');

                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FID128, '128', ISNULL(@Amt,0), '+',
                 N'Rule9: ' + @Title + N' gri listede. 128 hesabına eklendi.');

                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FID129, '129', ISNULL(@Amt,0), '+',
                 N'Rule9: ' + @Title + N' gri listede. 129 hesabına eklendi.');

                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FID562, '562', ISNULL(@Amt,0), '+',
                 N'Rule9: ' + @Title + N' gri listede. 562 hesabına eklendi.');

                -- CorrectedValue güncellemeleri sadece >0 ise
                IF @Amt > 0
                BEGIN
                    UPDATE MizanDB.dbo.AutoTransferCleansing
                    SET CorrectedValue = CorrectedValue - @Amt
                    WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                      AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                      AND FinancialItemDefinitionId=@FIDSource;

                    UPDATE MizanDB.dbo.AutoTransferCleansing
                    SET CorrectedValue = CorrectedValue + @Amt
                    WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                      AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                      AND FinancialItemDefinitionId IN (@FID128, @FID129, @FID562);
                END

                IF @Debug = 1
                    PRINT CONCAT('Eşleşen Firma: ', @Title, ' | Hesap: ', @AccCode, ' | Tutar: ', @Amt);
            END

            FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_09 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_10
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @SearchKarsiliksiz NVARCHAR(100) = N'Karşılıksız',
    @SearchProtestolu NVARCHAR(100) = N'Protestolu',
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE 
            @FID101 INT, @FID121 INT,
            @FID128 INT, @FID129 INT, @FID562 INT;

        SELECT
            @FID101 = MAX(CASE WHEN Code = '101' THEN FinancialItemDefinitionId END),
            @FID121 = MAX(CASE WHEN Code = '121' THEN FinancialItemDefinitionId END),
            @FID128 = MAX(CASE WHEN Code = '128' THEN FinancialItemDefinitionId END),
            @FID129 = MAX(CASE WHEN Code = '129' THEN FinancialItemDefinitionId END),
            @FID562 = MAX(CASE WHEN Code = '562' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('101','121','128','129','562');

        IF @FID101 IS NULL OR @FID121 IS NULL OR @FID128 IS NULL OR @FID129 IS NULL OR @FID562 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition kayıtları eksik.', 16, 1);

        /* 101 alt kırılım - Karşılıksız */
        DECLARE @Amt101 DECIMAL(22,2);
        SELECT @Amt101 = SUM(NetSum_Leaves)
        FROM
        (
            SELECT l.NetSum_Leaves
            FROM MizanDB.dbo.CustomerDetailedTrialBalance c
            CROSS APPLY MizanDB.dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, c.AccountCode, 1) l
            WHERE c.AccountNumber = @AccountNumber
              AND c.PeriodId      = @PeriodId
              AND c.AccountCode LIKE '101%'
              AND c.AccountName LIKE '%' + @SearchKarsiliksiz + '%'
        ) t;

        SET @Amt101 = ISNULL(@Amt101,0);

        -- History koşulsuz
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID101, '101', @Amt101, '-', 
         N'Rule10: "' + @SearchKarsiliksiz + N'" ifadesi için 101 hesabı bakiyesi 128-129-562 aktarıldı.');

        IF @Amt101 > 0
        BEGIN
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Amt101
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID101;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Amt101
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId IN (@FID128, @FID129, @FID562);
        END

        /* 121 alt kırılım - Protestolu */
        DECLARE @Amt121 DECIMAL(22,2);
        SELECT @Amt121 = SUM(NetSum_Leaves)
        FROM
        (
            SELECT l.NetSum_Leaves
            FROM MizanDB.dbo.CustomerDetailedTrialBalance c
            CROSS APPLY MizanDB.dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, c.AccountCode, 1) l
            WHERE c.AccountNumber = @AccountNumber
              AND c.PeriodId      = @PeriodId
              AND c.AccountCode LIKE '121%'
              AND c.AccountName LIKE '%' + @SearchProtestolu + '%'
        ) t;

        SET @Amt121 = ISNULL(@Amt121,0);

        -- History koşulsuz
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID121, '121', @Amt121, '-', 
         N'Rule10: "' + @SearchProtestolu + N'" ifadesi için 121 hesabı bakiyesi 128-129-562 aktarıldı.');

        IF @Amt121 > 0
        BEGIN
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Amt121
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID121;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Amt121
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId IN (@FID128, @FID129, @FID562);
        END

        IF @Debug = 1
        BEGIN
            PRINT CONCAT('101 bakiyesi: ', @Amt101);
            PRINT CONCAT('121 bakiyesi: ', @Amt121);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_10 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_11
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        -------------------------------------------------
        -- FinancialItemDefinitionId’leri al
        -------------------------------------------------
        DECLARE @FID131 INT, @FID132 INT, @FID331 INT, @FID332 INT, @FID561 INT;

        SELECT
            @FID131 = MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId END),
            @FID132 = MAX(CASE WHEN Code = N'132' THEN FinancialItemDefinitionId END),
            @FID331 = MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId END),
            @FID332 = MAX(CASE WHEN Code = N'332' THEN FinancialItemDefinitionId END),
            @FID561 = MAX(CASE WHEN Code = N'561' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('131', '132', '331', '332', '561');

        -------------------------------------------------
        -- BDDK Grup Üyelerini Listele
        -------------------------------------------------
        DECLARE @Tuzel TABLE (NormTitle NVARCHAR(255));
        DECLARE @Gercek TABLE (NormTitle NVARCHAR(255));

        INSERT INTO @Tuzel
        SELECT DISTINCT dbo.fn_NormalizeTitle(MemberName)
        FROM MizanDB.ALT.BDDKGroupMembers WITH (NOLOCK)
        WHERE FirmType = @FirmType AND GroupNumber = @GroupNumber AND IsPerson = 0;

        INSERT INTO @Gercek
        SELECT DISTINCT dbo.fn_NormalizeTitle(MemberName)
        FROM MizanDB.ALT.BDDKGroupMembers WITH (NOLOCK)
        WHERE FirmType = @FirmType AND GroupNumber = @GroupNumber AND IsPerson = 1;

        -------------------------------------------------
        -- Hesap grupları
        -------------------------------------------------
        DECLARE @Receivable TABLE (Code NVARCHAR(3));  -- Alacak hesapları
        INSERT INTO @Receivable VALUES ('120'), ('121'), ('127'), ('136'), ('159');

        DECLARE @Payable TABLE (Code NVARCHAR(3));    -- Borç hesapları
        INSERT INTO @Payable VALUES ('320'), ('321'), ('329'), ('336'), ('340');

        -------------------------------------------------
        -- İşlenecek kayıtları topla
        -------------------------------------------------
        DECLARE @Matches TABLE (
            NormTitle NVARCHAR(255),
            Amount DECIMAL(22,2),
            AccCode NVARCHAR(50),
            IsReceivable BIT,
            IsTuzel BIT
        );

        -- Alacaklar
        INSERT INTO @Matches
        SELECT
            dbo.fn_NormalizeTitle(cdtb.AccountName),
            ISNULL(cdtb.CreditBalance,0) AS Amount,
            cdtb.AccountCode,
            1 AS IsReceivable,
            0 AS IsTuzel
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb
        JOIN @Receivable r ON LEFT(cdtb.AccountCode,3) = r.Code
        JOIN @Tuzel t ON dbo.fn_NormalizeTitle(cdtb.AccountName) = t.NormTitle
        WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.PeriodId=@PeriodId
          AND ISNULL(cdtb.CreditBalance,0) > 0;

        INSERT INTO @Matches
        SELECT
            dbo.fn_NormalizeTitle(cdtb.AccountName),
            ISNULL(cdtb.CreditBalance,0) AS Amount,
            cdtb.AccountCode,
            1,
            1
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb
        JOIN @Receivable r ON LEFT(cdtb.AccountCode,3) = r.Code
        JOIN @Gercek g ON dbo.fn_NormalizeTitle(cdtb.AccountName) = g.NormTitle
        WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.PeriodId=@PeriodId
          AND ISNULL(cdtb.CreditBalance,0) > 0;

        -- Borçlar
        INSERT INTO @Matches
        SELECT
            dbo.fn_NormalizeTitle(cdtb.AccountName),
            ISNULL(cdtb.DebitBalance,0) AS Amount,
            cdtb.AccountCode,
            0,
            0
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb
        JOIN @Payable p ON LEFT(cdtb.AccountCode,3) = p.Code
        JOIN @Tuzel t ON dbo.fn_NormalizeTitle(cdtb.AccountName) = t.NormTitle
        WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.PeriodId=@PeriodId
          AND ISNULL(cdtb.DebitBalance,0) > 0;

        INSERT INTO @Matches
        SELECT
            dbo.fn_NormalizeTitle(cdtb.AccountName),
            ISNULL(cdtb.DebitBalance,0) AS Amount,
            cdtb.AccountCode,
            0,
            1
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb
        JOIN @Payable p ON LEFT(cdtb.AccountCode,3) = p.Code
        JOIN @Gercek g ON dbo.fn_NormalizeTitle(cdtb.AccountName) = g.NormTitle
        WHERE cdtb.AccountNumber=@AccountNumber AND cdtb.PeriodId=@PeriodId
          AND ISNULL(cdtb.DebitBalance,0) > 0;

        -------------------------------------------------
        -- Döngü ile işleme
        -------------------------------------------------
        DECLARE @Title NVARCHAR(255), @Amt DECIMAL(22,2), @AccCode NVARCHAR(50), @IsReceivable BIT, @IsTuzel BIT;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT NormTitle, Amount, AccCode, IsReceivable, IsTuzel FROM @Matches;

        OPEN cur;
        FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @IsReceivable, @IsTuzel;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @FIDSource INT, @FIDTarget INT;

            SELECT @FIDSource = FinancialItemDefinitionId
            FROM MizanDB.ALT.FinancialItemDefinition
            WHERE Code = LEFT(@AccCode,3);

            IF @IsReceivable = 1
                SET @FIDTarget = CASE WHEN @IsTuzel=0 THEN @FID132 ELSE @FID131 END;
            ELSE
                SET @FIDTarget = CASE WHEN @IsTuzel=0 THEN @FID332 ELSE @FID331 END;

            -- History kayıtları (koşulsuz)
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FIDSource, @AccCode, @Amt, '-',
             N'Rule11: ' + @Title + N' BDDK/Ortaklık listesinde. ' + @AccCode + N' hesabından çıkarıldı.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FIDTarget, CAST(@FIDTarget AS NVARCHAR), @Amt, '+',
             N'Rule11: ' + @Title + N' BDDK/Ortaklık listesinde. ' + CAST(@FIDTarget AS NVARCHAR) + N' hesabına eklendi.');

            -- CorrectedValue güncellemeleri
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Amt
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDSource;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Amt
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDTarget;

            IF @Debug = 1
                PRINT CONCAT('Firma: ', @Title, ' | Kaynak: ', @AccCode, ' | Tutar: ', @Amt, ' | HedefFID: ', @FIDTarget);

            FETCH NEXT FROM cur INTO @Title, @Amt, @AccCode, @IsReceivable, @IsTuzel;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -------------------------------------------------
        -- 131 - 331 mahsuplaşma ve kalan bakiyeyi 561’e atma
        -------------------------------------------------
        DECLARE @Amt131 DECIMAL(22,2) = ISNULL((SELECT SUM(CorrectedValue) FROM MizanDB.dbo.AutoTransferCleansing WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID131),0);
        DECLARE @Amt331 DECIMAL(22,2) = ISNULL((SELECT SUM(CorrectedValue) FROM MizanDB.dbo.AutoTransferCleansing WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID331),0);
        DECLARE @Delta DECIMAL(22,2) = CASE WHEN @Amt131 <= @Amt331 THEN @Amt131 ELSE @Amt331 END;

        IF @Delta > 0
        BEGIN
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId IN (@FID131, @FID331);

            IF @Amt131 > @Amt331
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + (@Amt131 - @Amt331)
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FID561;
            ELSE IF @Amt331 > @Amt131
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + (@Amt331 - @Amt131)
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FID561;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_11 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_12
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID131 INT, @FID231 INT, @FID331 INT, @FID431 INT, @FID561 INT;

        SELECT
            @FID131 = MAX(CASE WHEN Code = N'131' THEN FinancialItemDefinitionId END),
            @FID231 = MAX(CASE WHEN Code = N'231' THEN FinancialItemDefinitionId END),
            @FID331 = MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId END),
            @FID431 = MAX(CASE WHEN Code = N'431' THEN FinancialItemDefinitionId END),
            @FID561 = MAX(CASE WHEN Code = N'561' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('131', '231', '331', '431', '561');

        -- Bakiye değerlerini al (BDR/Beyanname verisi)
        DECLARE @Amt131 DECIMAL(22,2) = ISNULL((
            SELECT SUM(CorrectedValue) FROM MizanDB.dbo.AutoTransferCleansing
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID131
        ),0);

        DECLARE @Amt231 DECIMAL(22,2) = ISNULL((
            SELECT SUM(CorrectedValue) FROM MizanDB.dbo.AutoTransferCleansing
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID231
        ),0);

        DECLARE @Amt331 DECIMAL(22,2) = ISNULL((
            SELECT SUM(CorrectedValue) FROM MizanDB.dbo.AutoTransferCleansing
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID331
        ),0);

        DECLARE @Amt431 DECIMAL(22,2) = ISNULL((
            SELECT SUM(CorrectedValue) FROM MizanDB.dbo.AutoTransferCleansing
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID431
        ),0);

        -------------------------------------------------
        -- 131 / 331 mahsuplaşma
        -------------------------------------------------
        IF @Amt131 > 0 AND @Amt331 > 0
        BEGIN
            DECLARE @Delta131331 DECIMAL(22,2) = CASE WHEN @Amt131 <= @Amt331 THEN @Amt131 ELSE @Amt331 END;

            -- Her durumda düş
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta131331
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber
              AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID131;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta131331
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber
              AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID331;

            -- History
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID131, '131', @Delta131331, '-', N'Rule12: 131 ve 331 karşılıklı mahsup edildi.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID331, '331', @Delta131331, '-', N'Rule12: 131 ve 331 karşılıklı mahsup edildi.');

            -- Fazla varsa 561’e ekle
            IF @Amt131 > @Amt331
            BEGIN
                DECLARE @Fark131331 DECIMAL(22,2) = @Amt131 - @Amt331;
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + @Fark131331
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber
                  AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID561;

                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FID561, '561', @Fark131331, '+', N'Rule12: 131 ve 331 mahsuplaşma farkı 561’e eklendi.');
            END
        END

        -------------------------------------------------
        -- 231 / 431 mahsuplaşma
        -------------------------------------------------
        IF @Amt231 > 0 AND @Amt431 > 0
        BEGIN
            DECLARE @Delta231431 DECIMAL(22,2) = CASE WHEN @Amt231 <= @Amt431 THEN @Amt231 ELSE @Amt431 END;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta231431
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber
              AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID231;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta231431
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber
              AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID431;

            -- History
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID231, '231', @Delta231431, '-', N'Rule12: 231 ve 431 karşılıklı mahsup edildi.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID431, '431', @Delta231431, '-', N'Rule12: 231 ve 431 karşılıklı mahsup edildi.');

            -- Fazla varsa 561’e ekle
            IF @Amt231 > @Amt431
            BEGIN
                DECLARE @Fark231431 DECIMAL(22,2) = @Amt231 - @Amt431;
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + @Fark231431
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber AND AccountNumber=@AccountNumber
                  AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID561;

                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FID561, '561', @Fark231431, '+', N'Rule12: 231 ve 431 mahsuplaşma farkı 561’e eklendi.');
            END
        END

        IF @Debug = 1
        BEGIN
            PRINT CONCAT('131: ', @Amt131, ' | 331: ', @Amt331);
            PRINT CONCAT('231: ', @Amt231, ' | 431: ', @Amt431);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_12 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_13
(
    @RuleId        INT,         -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @SearchTerms   NVARCHAR(MAX), -- Örn: 'Faiz,Borçlanma'
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID180 INT, @FID280 INT, @FID300 INT, @FID400 INT;

        -- FID değerlerini al
        SELECT
            @FID180 = MAX(CASE WHEN Code = N'180' THEN FinancialItemDefinitionId END),
            @FID280 = MAX(CASE WHEN Code = N'280' THEN FinancialItemDefinitionId END),
            @FID300 = MAX(CASE WHEN Code = N'300' THEN FinancialItemDefinitionId END),
            @FID400 = MAX(CASE WHEN Code = N'400' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('180', '280', '300', '400');

        IF @FID180 IS NULL OR @FID280 IS NULL OR @FID300 IS NULL OR @FID400 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (180, 280, 300, 400) bulunamadı.', 16, 1);

        -- Arama terimlerini parçala
        DECLARE @Terms TABLE (Term NVARCHAR(100));
        INSERT INTO @Terms
        SELECT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@SearchTerms, ',');

        ------------------------------------------------------------
        -- 180 hesabı eşleşmeleri
        ------------------------------------------------------------
        DECLARE @Sum180 DECIMAL(22,2) = 0;

        SELECT @Sum180 = ISNULL(SUM(NetSum_Leaves), 0)
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb
        CROSS APPLY dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, cdtb.AccountCode, 1) s
        WHERE LEFT(cdtb.AccountCode, 3) = '180'
          AND EXISTS (
              SELECT 1 FROM @Terms t WHERE cdtb.AccountName LIKE '%' + t.Term + '%'
          )
          AND cdtb.AccountNumber = @AccountNumber
          AND cdtb.PeriodId = @PeriodId;

        IF @Sum180 > 0
        BEGIN
            -- History kayıtları
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID180, '180', @Sum180, '-', N'Rule13: 180 hesabı faiz/borçlanma mahsup.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID300, '300', @Sum180, '-', N'Rule13: 300 hesabı faiz/borçlanma mahsup.');

            -- CorrectedValue güncelle
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Sum180
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId IN (@FID180, @FID300);
        END

        ------------------------------------------------------------
        -- 280 hesabı eşleşmeleri
        ------------------------------------------------------------
        DECLARE @Sum280 DECIMAL(22,2) = 0;

        SELECT @Sum280 = ISNULL(SUM(NetSum_Leaves), 0)
        FROM MizanDB.dbo.CustomerDetailedTrialBalance cdtb
        CROSS APPLY dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, cdtb.AccountCode, 1) s
        WHERE LEFT(cdtb.AccountCode, 3) = '280'
          AND EXISTS (
              SELECT 1 FROM @Terms t WHERE cdtb.AccountName LIKE '%' + t.Term + '%'
          )
          AND cdtb.AccountNumber = @AccountNumber
          AND cdtb.PeriodId = @PeriodId;

        IF @Sum280 > 0
        BEGIN
            -- History kayıtları
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID280, '280', @Sum280, '-', N'Rule13: 280 hesabı faiz/borçlanma mahsup.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID400, '400', @Sum280, '-', N'Rule13: 400 hesabı faiz/borçlanma mahsup.');

            -- CorrectedValue güncelle
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Sum280
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId IN (@FID280, @FID400);
        END

        IF @Debug = 1
        BEGIN
            PRINT CONCAT('Rule13 - 180 Toplam: ', @Sum180);
            PRINT CONCAT('Rule13 - 280 Toplam: ', @Sum280);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_13 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_14
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID191 INT, @FID391 INT;
        DECLARE @Amt191 DECIMAL(22,2) = 0;
        DECLARE @Amt391 DECIMAL(22,2) = 0;
        DECLARE @Delta DECIMAL(22,2) = 0;

        -- FinancialItemDefinitionId değerlerini al
        SELECT
            @FID191 = MAX(CASE WHEN Code = N'191' THEN FinancialItemDefinitionId END),
            @FID391 = MAX(CASE WHEN Code = N'391' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('191', '391');

        IF @FID191 IS NULL OR @FID391 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (191, 391) bulunamadı.', 16, 1);

        -- Mevcut CorrectedValue tutarlarını al
        SELECT @Amt191 = ISNULL(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType = @FirmType AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber AND PeriodId = @PeriodId
          AND FinancialItemDefinitionId = @FID191;

        SELECT @Amt391 = ISNULL(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType = @FirmType AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber AND PeriodId = @PeriodId
          AND FinancialItemDefinitionId = @FID391;

        -- Mahsuplaşma miktarını belirle
        SET @Delta = CASE 
                        WHEN @Amt191 <= @Amt391 THEN @Amt191
                        ELSE @Amt391
                     END;

        IF @Delta > 0
        BEGIN
            -- History: 191 düşüş
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID191, '191', @Delta, '-',
             N'Rule14: 191-391 mahsuplaştırma. 191 hesabından düşüldü.');

            -- History: 391 düşüş
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID391, '391', @Delta, '-',
             N'Rule14: 191-391 mahsuplaştırma. 391 hesabından düşüldü.');

            -- CorrectedValue güncelleme
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID191;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID391;

            IF @Debug = 1
                PRINT CONCAT('Rule14: Mahsuplaşma yapıldı. Delta=', @Delta, ' | 191=', @Amt191, ' | 391=', @Amt391);
        END
        ELSE IF @Debug = 1
            PRINT 'Rule14: Mahsuplaşacak bakiye bulunamadı.';

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_14 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_15
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID192 INT, @FID392 INT;
        DECLARE @Amt192 DECIMAL(22,2) = 0;
        DECLARE @Amt392 DECIMAL(22,2) = 0;
        DECLARE @Delta DECIMAL(22,2) = 0;

        -- FinancialItemDefinitionId değerlerini al
        SELECT
            @FID192 = MAX(CASE WHEN Code = N'192' THEN FinancialItemDefinitionId END),
            @FID392 = MAX(CASE WHEN Code = N'392' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('192', '392');

        IF @FID192 IS NULL OR @FID392 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (192, 392) bulunamadı.', 16, 1);

        -- Mevcut CorrectedValue tutarlarını al
        SELECT @Amt192 = ISNULL(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType = @FirmType AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber AND PeriodId = @PeriodId
          AND FinancialItemDefinitionId = @FID192;

        SELECT @Amt392 = ISNULL(SUM(CorrectedValue), 0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType = @FirmType AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber AND PeriodId = @PeriodId
          AND FinancialItemDefinitionId = @FID392;

        -- Mahsuplaşma miktarını belirle
        SET @Delta = CASE 
                        WHEN @Amt192 <= @Amt392 THEN @Amt192
                        ELSE @Amt392
                     END;

        IF @Delta > 0
        BEGIN
            -- History: 192 düşüş
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID192, '192', @Delta, '-',
             N'Rule15: 192-392 mahsuplaştırma. 192 hesabından düşüldü.');

            -- History: 392 düşüş
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID392, '392', @Delta, '-',
             N'Rule15: 192-392 mahsuplaştırma. 392 hesabından düşüldü.');

            -- CorrectedValue güncelleme
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID192;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Delta
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID392;

            IF @Debug = 1
                PRINT CONCAT('Rule15: Mahsuplaşma yapıldı. Delta=', @Delta, ' | 192=', @Amt192, ' | 392=', @Amt392);
        END
        ELSE IF @Debug = 1
            PRINT 'Rule15: Mahsuplaşacak bakiye bulunamadı.';

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_15 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_16
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID193 INT, @FID370 INT, @FID371 INT;
        DECLARE @Amt193 DECIMAL(22,2) = 0, @Amt370 DECIMAL(22,2) = 0, @Amt371 DECIMAL(22,2) = 0;
        DECLARE @Diff DECIMAL(22,2) = 0;

        -- FID değerlerini al
        SELECT
            @FID193 = MAX(CASE WHEN Code = N'193' THEN FinancialItemDefinitionId END),
            @FID370 = MAX(CASE WHEN Code = N'370' THEN FinancialItemDefinitionId END),
            @FID371 = MAX(CASE WHEN Code = N'371' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('193', '370', '371');

        IF @FID193 IS NULL OR @FID370 IS NULL OR @FID371 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (193, 370, 371) bulunamadı.', 16, 1);

        -- Bakiye bilgilerini çek (BDR verisinden)
        SELECT
            @Amt193 = ISNULL(SUM(OriginalValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId = @FID193;

        SELECT
            @Amt370 = ISNULL(SUM(OriginalValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId = @FID370;

        SELECT
            @Amt371 = ISNULL(SUM(OriginalValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId = @FID371;

        -- Kural uygulanması
        IF @Amt370 > @Amt371
        BEGIN
            SET @Diff = @Amt370 - @Amt371;

            -- History
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID193, '193', @Diff, '-', N'Rule16: 370 > 371 farkı 193’ten düşüldü.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID371, '371', @Diff, '+', N'Rule16: 370 > 371 farkı 371’e eklendi.');

            -- CorrectedValue güncellemeleri
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Diff
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID193;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Diff
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID371;
        END
        ELSE IF @Amt370 < @Amt371
        BEGIN
            SET @Diff = @Amt371 - @Amt370;

            -- History
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID193, '193', @Diff, '+', N'Rule16: 371 > 370 farkı 193’e eklendi.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID371, '371', @Diff, '-', N'Rule16: 371 > 370 farkı 371’den düşüldü.');

            -- CorrectedValue güncellemeleri
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Diff
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID193;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Diff
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID371;
        END

        IF @Debug = 1
            PRINT CONCAT('370=', @Amt370, ' | 371=', @Amt371, ' | 193=', @Amt193, ' | Diff=', @Diff);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_16 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_17
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID562 INT;
        SELECT @FID562 = FinancialItemDefinitionId
        FROM MizanDB.ALT.FinancialItemDefinition
        WHERE Code = '562';

        IF @FID562 IS NULL
            RAISERROR('FinancialItemDefinition 562 bulunamadı.', 16, 1);

        DECLARE @AccCodes TABLE (Code NVARCHAR(50));
        INSERT INTO @AccCodes VALUES ('240'), ('242'), ('245');

        DECLARE @AccCode NVARCHAR(50), @Amt DECIMAL(22,2);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Code FROM @AccCodes;

        OPEN cur;
        FETCH NEXT FROM cur INTO @AccCode;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Enf ile başlayan yaprak alt hesap bakiyesini bul
            WITH Tree AS
            (
                SELECT
                    d.AccountCode,
                    d.ParentAccountCode,
                    d.AccountName,
                    CAST(d.DebitBalance  AS DECIMAL(22,2)) AS DebitBalance,
                    CAST(d.CreditBalance AS DECIMAL(22,2)) AS CreditBalance
                FROM MizanDB.dbo.CustomerDetailedTrialBalance d
                WHERE d.AccountNumber = @AccountNumber
                  AND d.PeriodId      = @PeriodId
                  AND d.AccountCode   = @AccCode

                UNION ALL

                SELECT
                    c.AccountCode,
                    c.ParentAccountCode,
                    c.AccountName,
                    CAST(c.DebitBalance  AS DECIMAL(22,2)),
                    CAST(c.CreditBalance AS DECIMAL(22,2))
                FROM MizanDB.dbo.CustomerDetailedTrialBalance c
                JOIN Tree t
                  ON  c.AccountNumber     = @AccountNumber
                  AND c.PeriodId          = @PeriodId
                  AND c.ParentAccountCode = t.AccountCode
            ),
            Leaves AS
            (
                SELECT t.*
                FROM Tree t
                WHERE NOT EXISTS
                (
                    SELECT 1
                    FROM MizanDB.dbo.CustomerDetailedTrialBalance x
                    WHERE x.AccountNumber     = @AccountNumber
                      AND x.PeriodId          = @PeriodId
                      AND x.ParentAccountCode = t.AccountCode
                )
            )
            SELECT @Amt =
                COALESCE(SUM(ISNULL(DebitBalance,0) - ISNULL(CreditBalance,0)),0)
            FROM Leaves
            WHERE AccountName LIKE N'Enf%'  
              AND AccountCode <> @AccCode; -- kökü hariç

            IF @Amt > 0
            BEGIN
                DECLARE @FIDSource INT;
                SELECT @FIDSource = FinancialItemDefinitionId
                FROM MizanDB.ALT.FinancialItemDefinition
                WHERE Code = @AccCode;

                -- History kayıtları (koşulsuz)
                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FIDSource, @AccCode, @Amt, '-',
                 CONCAT('Rule17: ', @AccCode, ' hesabından Enf% alt hesap bakiyesi düşüldü.')),
                (@RuleId, @AccountNumber, @PeriodId, @FID562, '562', @Amt, '+',
                 CONCAT('Rule17: ', @AccCode, ' hesabından Enf% alt hesap bakiyesi 562 hesabına eklendi.'));

                -- CorrectedValue güncelle
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue - @Amt
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FIDSource;

                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + @Amt
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FID562;

                IF @Debug = 1
                    PRINT CONCAT(@AccCode, ' hesabından ', @Amt, ' TL 562 hesabına aktarıldı.');
            END

            FETCH NEXT FROM cur INTO @AccCode;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_17 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_18
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID563 INT;
        SELECT @FID563 = FinancialItemDefinitionId
        FROM MizanDB.ALT.FinancialItemDefinition
        WHERE Code = '563';

        IF @FID563 IS NULL
            RAISERROR('FinancialItemDefinition 563 bulunamadı.', 16, 1);

        DECLARE @AccList TABLE (Code NVARCHAR(50), IsNegative BIT);
        INSERT INTO @AccList VALUES
        ('262', 0), ('263', 0), ('264', 0), ('271', 0), 
        ('272', 0), ('277', 0), ('279', 0),
        ('278', 1); -- 278 negatif etki

        DECLARE @AccCode NVARCHAR(50), @IsNegative BIT, @Amt DECIMAL(22,2);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Code, IsNegative FROM @AccList;

        OPEN cur;
        FETCH NEXT FROM cur INTO @AccCode, @IsNegative;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kaynak FID
            DECLARE @FIDSource INT;
            SELECT @FIDSource = FinancialItemDefinitionId
            FROM MizanDB.ALT.FinancialItemDefinition
            WHERE Code = @AccCode;

            -- Bakiye al (BDR / Beyanname verisinden)
            SELECT @Amt = COALESCE(SUM(CorrectedValue),0)
            FROM MizanDB.dbo.AutoTransferCleansing
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDSource;

            IF @Amt <> 0
            BEGIN
                -- History kayıtları
                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FIDSource, @AccCode, @Amt, '-',
                 CONCAT('Rule18: ', @AccCode, ' hesabı 563 hesabına aktarım için düşüldü.'));

                INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
                (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
                VALUES
                (@RuleId, @AccountNumber, @PeriodId, @FID563, '563', @Amt, 
                 CASE WHEN @IsNegative=1 THEN '-' ELSE '+' END,
                 CONCAT('Rule18: ', @AccCode, ' bakiyesi 563 hesabına ',
                        CASE WHEN @IsNegative=1 THEN 'düşüldü.' ELSE 'eklendi.' END));

                -- CorrectedValue güncelle
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue - @Amt
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FIDSource;

                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + 
                    CASE WHEN @IsNegative=1 THEN -@Amt ELSE @Amt END
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FID563;

                IF @Debug = 1
                    PRINT CONCAT(@AccCode, ' hesabından ', 
                                 FORMAT(@Amt,'N2'), ' TL ', 
                                 CASE WHEN @IsNegative=1 THEN 'düşüldü' ELSE 'eklendi' END,
                                 ' (563).');
            END

            FETCH NEXT FROM cur INTO @AccCode, @IsNegative;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
       DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_18 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_19
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID296 INT, @FID563 INT;

        -- FID'leri al
        SELECT
            @FID296 = MAX(CASE WHEN Code = N'296' THEN FinancialItemDefinitionId END),
            @FID563 = MAX(CASE WHEN Code = N'563' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN (N'296', N'563');

        IF @FID296 IS NULL OR @FID563 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (296, 563) bulunamadı.', 16, 1);

        DECLARE @Amt DECIMAL(22,2) = 0;

        /* 
           Leaf tespiti: 
           - 296 ağacındaki tüm düğümler: AccountCode LIKE '296%'
           - kökü hariç tut: AccountCode <> '296'
           - yaprak: kendisini parent alan bir alt kayıt yok
           - "Matrah Art%" ile başlayan adlar
           - pozitif net bakiye: (Debit - Credit) > 0
        */
        SELECT @Amt =
            ISNULL(SUM(
                CASE WHEN (ISNULL(d.DebitBalance,0) - ISNULL(d.CreditBalance,0)) > 0
                     THEN (ISNULL(d.DebitBalance,0) - ISNULL(d.CreditBalance,0))
                     ELSE 0
                END
            ), 0)
        FROM MizanDB.dbo.CustomerDetailedTrialBalance d WITH (NOLOCK)
        WHERE d.AccountNumber = @AccountNumber
          AND d.PeriodId      = @PeriodId
          AND d.AccountCode   LIKE N'296%' COLLATE SQL_Latin1_General_CP1_CI_AS
          AND d.AccountCode  <> N'296'
          AND d.AccountName   LIKE N'Matrah Art%' COLLATE SQL_Latin1_General_CP1_CI_AS
          AND NOT EXISTS (
                SELECT 1
                FROM MizanDB.dbo.CustomerDetailedTrialBalance c WITH (NOLOCK)
                WHERE c.AccountNumber     = d.AccountNumber
                  AND c.PeriodId          = d.PeriodId
                  AND c.ParentAccountCode = d.AccountCode
            );

        -- History: koşulsuz
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
        VALUES
        (@RuleId, @AccountNumber, @PeriodId, @FID296, N'296', @Amt, N'-',
         N'Rule19: "Matrah Art%" ibareli leaf alt hesap toplamı 296’dan düşüldü.'),
        (@RuleId, @AccountNumber, @PeriodId, @FID563, N'563', @Amt, N'+',
         N'Rule19: "Matrah Art%" ibareli leaf alt hesap toplamı 563’e eklendi.');

        -- Tutar pozitifse düzeltme uygula
        IF @Amt > 0
        BEGIN
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Amt
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID296;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Amt
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID563;
        END

        IF @Debug = 1
            PRINT CONCAT('Rule19 | Matrah Art leaf toplamı = ', FORMAT(@Amt,'N2'));

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_19 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_21
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID307 INT, @FID320 INT, @FID420 INT;

        SELECT
            @FID307 = MAX(CASE WHEN Code = N'307' THEN FinancialItemDefinitionId END),
            @FID320 = MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId END),
            @FID420 = MAX(CASE WHEN Code = N'420' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('307','320','420');

        IF @FID307 IS NULL OR @FID320 IS NULL OR @FID420 IS NULL
            RAISERROR('Gerekli FID (307, 320, 420) bulunamadı.', 16, 1);

        DECLARE @AccCodes TABLE (AccCode NVARCHAR(50), FID INT);
        INSERT INTO @AccCodes VALUES
        ('320', @FID320),
        ('420', @FID420);

        DECLARE @AccCode NVARCHAR(50), @FIDSource INT, @Amt DECIMAL(22,2);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT AccCode, FID FROM @AccCodes;

        OPEN cur;
        FETCH NEXT FROM cur INTO @AccCode, @FIDSource;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Sadece leaf hesaplardan, "Faktoring" içeren alt hesapların bakiyesi
            SELECT @Amt = ISNULL(SUM(s.NetSum_Leaves),0)
            FROM dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, @AccCode, 1) s
            WHERE EXISTS (
                SELECT 1
                FROM MizanDB.dbo.CustomerDetailedTrialBalance d
                WHERE d.AccountNumber = @AccountNumber
                  AND d.PeriodId = @PeriodId
                  AND d.AccountName LIKE N'%Faktoring%'
                  AND LEFT(d.AccountCode, LEN(@AccCode)) = @AccCode
                  AND NOT EXISTS (
                        SELECT 1
                        FROM MizanDB.dbo.CustomerDetailedTrialBalance c
                        WHERE c.AccountNumber = d.AccountNumber
                          AND c.PeriodId = d.PeriodId
                          AND c.ParentAccountCode = d.AccountCode
                  ) -- leaf kontrolü
            );

            -- Her durumda History’ye yaz
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FIDSource, @AccCode, ISNULL(@Amt,0), '-', 
             N'Rule21: ' + @AccCode + N' hesabından Faktoring borçları çıkarıldı.');

            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID307, '307', ISNULL(@Amt,0), '+',
             N'Rule21: ' + @AccCode + N' hesabındaki Faktoring borçları 307 hesabına aktarıldı.');

            -- CorrectedValue güncelle
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - ISNULL(@Amt,0)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDSource;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + ISNULL(@Amt,0)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FID307;

            IF @Debug = 1
                PRINT CONCAT('Rule21 | Hesap: ', @AccCode, ' | Tutar: ', @Amt);

            FETCH NEXT FROM cur INTO @AccCode, @FIDSource;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_21 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_22
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID320 INT, @FID159 INT;

        -- FID değerlerini al
        SELECT
            @FID320 = MAX(CASE WHEN Code = N'320' THEN FinancialItemDefinitionId END),
            @FID159 = MAX(CASE WHEN Code = N'159' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('320', '159');

        IF @FID320 IS NULL OR @FID159 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (320, 159) bulunamadı.', 16, 1);

        DECLARE @AnaA_Credit DECIMAL(22,2), @AltA_Credit DECIMAL(22,2), @Fark DECIMAL(22,2);

        -- Ana hesap (320) alacak bakiyesi
        SELECT @AnaA_Credit = ISNULL(CreditBalance,0)
        FROM MizanDB.dbo.CustomerDetailedTrialBalance
        WHERE AccountNumber = @AccountNumber
          AND PeriodId      = @PeriodId
          AND AccountCode   = '320';

        -- Alt hesapların alacak toplamı (leaf)
        SELECT @AltA_Credit = ISNULL(SUM(s.CreditSum_Leaves),0)
        FROM dbo.fn_GetLeafSums(@AccountNumber, @PeriodId, '320', 1) s;

        -- Fark
        SET @Fark = @AltA_Credit - @AnaA_Credit;

        IF @Debug = 1
        BEGIN
            PRINT CONCAT('Ana Alacak: ', @AnaA_Credit, ' | Alt Alacak: ', @AltA_Credit, ' | Fark: ', @Fark);
        END

        IF @Fark <> 0
        BEGIN
            -- History kayıtları (koşulsuz ekle)
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID320, '320', @Fark, '+',
             N'Rule22: 320 ters bakiye farkı eklendi.'),
            (@RuleId, @AccountNumber, @PeriodId, @FID159, '159', @Fark, '+',
             N'Rule22: 320 ters bakiye farkı aktifte 159 hesabına eklendi.');

            -- CorrectedValue güncelle
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Fark
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId IN (@FID320, @FID159);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_22 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_23
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID331 INT, @FID431 INT, @Amt DECIMAL(22,2);

        -- FID değerlerini al
        SELECT
            @FID331 = MAX(CASE WHEN Code = N'331' THEN FinancialItemDefinitionId END),
            @FID431 = MAX(CASE WHEN Code = N'431' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('331', '431');

        IF @FID331 IS NULL OR @FID431 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (331, 431) bulunamadı.', 16, 1);

        -- 331 bakiyesi
        SELECT @Amt = ISNULL(SUM(CorrectedValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
          AND FinancialItemDefinitionId = @FID331;

        IF @Debug = 1
            PRINT CONCAT('331 Toplam Bakiye: ', @Amt);

        IF @Amt <> 0
        BEGIN
            -- History kayıtları (koşulsuz ekle)
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FID331, '331', @Amt, '-',
             N'Rule23: 331 hesabından çıkarıldı.'),
            (@RuleId, @AccountNumber, @PeriodId, @FID431, '431', @Amt, '+',
             N'Rule23: 331 hesabından 431 hesabına aktarıldı.');

            -- CorrectedValue güncelle
            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue - @Amt
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID331;

            UPDATE MizanDB.dbo.AutoTransferCleansing
            SET CorrectedValue = CorrectedValue + @Amt
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId = @FID431;
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_23 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_25
(
    @RuleId        INT,        -- AutoTransferCleansingRuleDefinition.Id
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @FID648 INT, @FID658 INT, @FID590 INT, @FID591 INT, @FID570 INT;
        DECLARE @Amt648 DECIMAL(22,2), @Amt658 DECIMAL(22,2), @Amt590 DECIMAL(22,2), @Amt591 DECIMAL(22,2);

        -- FID değerlerini al
        SELECT
            @FID648 = MAX(CASE WHEN Code = N'648' THEN FinancialItemDefinitionId END),
            @FID658 = MAX(CASE WHEN Code = N'658' THEN FinancialItemDefinitionId END),
            @FID590 = MAX(CASE WHEN Code = N'590' THEN FinancialItemDefinitionId END),
            @FID591 = MAX(CASE WHEN Code = N'591' THEN FinancialItemDefinitionId END),
            @FID570 = MAX(CASE WHEN Code = N'570' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('648', '658', '590', '591', '570');

        IF @FID648 IS NULL OR @FID658 IS NULL OR @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL
            RAISERROR('Gerekli FinancialItemDefinition (648, 658, 590, 591, 570) bulunamadı.', 16, 1);

        -- Mevcut bakiyeleri çek
        SELECT @Amt648 = ISNULL(SUM(CorrectedValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID648;

        SELECT @Amt658 = ISNULL(SUM(CorrectedValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID658;

        SELECT @Amt590 = ISNULL(SUM(CorrectedValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID590;

        SELECT @Amt591 = ISNULL(SUM(CorrectedValue),0)
        FROM MizanDB.dbo.AutoTransferCleansing
        WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
          AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId AND FinancialItemDefinitionId=@FID591;

        IF @Debug=1
            PRINT CONCAT('#648=',@Amt648,' #658=',@Amt658,' #590=',@Amt590,' #591=',@Amt591);

        -- Öncelikle 648 ve 658 karşılıklı mahsup
        IF @Amt648>0 AND @Amt658>0
        BEGIN
            DECLARE @MinAmt DECIMAL(22,2) = IIF(@Amt648<@Amt658,@Amt648,@Amt658);

            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID648,'648',@MinAmt,'-',N'Rule25: 648 ve 658 mahsup';
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID658,'658',@MinAmt,'-',N'Rule25: 648 ve 658 mahsup';

            SET @Amt648 = @Amt648 - @MinAmt;
            SET @Amt658 = @Amt658 - @MinAmt;
        END

        -- 648 işlemleri
        IF @Amt648>0
        BEGIN
            IF @Amt648 <= @Amt590
            BEGIN
                -- 590'dan düş, 570'e ekle
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID590,'590',@Amt648,'-',N'Rule25: 648 için 590 düşüldü';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID570,'570',@Amt648,'+',N'Rule25: 648 için 570 eklendi';
            END
            ELSE
            BEGIN
                -- 590'ı sıfırla, farkı 591'e ekle
                IF @Amt590>0
                    EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID590,'590',@Amt590,'-',N'Rule25: 648 için 590 sıfırlandı';

                DECLARE @Diff648 DECIMAL(22,2) = @Amt648 - @Amt590;

                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID591,'591',@Diff648,'+',N'Rule25: 648 için fark 591 eklendi';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID570,'570',@Amt648,'+',N'Rule25: 648 için 570 eklendi';
            END
        END

        -- 658 işlemleri
        IF @Amt658>0
        BEGIN
            IF @Amt658 <= @Amt591
            BEGIN
                -- 591 ve 570'ten düş
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID591,'591',@Amt658,'-',N'Rule25: 658 için 591 düşüldü';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID570,'570',@Amt658,'-',N'Rule25: 658 için 570 düşüldü';
            END
            ELSE
            BEGIN
                -- 591'ı sıfırla, farkı 590'a ekle
                IF @Amt591>0
                    EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID591,'591',@Amt591,'-',N'Rule25: 658 için 591 sıfırlandı';

                DECLARE @Diff658 DECIMAL(22,2) = @Amt658 - @Amt591;

                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID590,'590',@Diff658,'+',N'Rule25: 658 için fark 590 eklendi';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,@FID570,'570',@Amt658,'-',N'Rule25: 658 için 570 düşüldü';
            END
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_ApplyRule_25 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_ApplyRule_26
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE 
            @FID590 INT, @FID591 INT, @FID689 INT, @FID692 INT,
            @FID570 INT, @FIDc2 INT;

        -- FID'leri çek
        SELECT
            @FID590 = MAX(CASE WHEN Code = '590' THEN FinancialItemDefinitionId END),
            @FID591 = MAX(CASE WHEN Code = '591' THEN FinancialItemDefinitionId END),
            @FID689 = MAX(CASE WHEN Code = '689' THEN FinancialItemDefinitionId END),
            @FID692 = MAX(CASE WHEN Code = '692' THEN FinancialItemDefinitionId END),
            @FID570 = MAX(CASE WHEN Code = '570' THEN FinancialItemDefinitionId END),
            @FIDc2  = MAX(CASE WHEN Code = 'c2'  THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN ('590','591','689','692','570','c2');

        IF @FID590 IS NULL OR @FID591 IS NULL OR @FID689 IS NULL 
           OR @FID692 IS NULL OR @FID570 IS NULL OR @FIDc2 IS NULL
        BEGIN
            RAISERROR('Rule26: Gerekli FinancialItemDefinition (590,591,689,692,570,c2) bulunamadı.', 16, 1);
        END

        DECLARE @Amt590 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM MizanDB.dbo.AutoTransferCleansing
                                                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                                                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                                                  AND FinancialItemDefinitionId=@FID590),0);

        DECLARE @Amt591 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM MizanDB.dbo.AutoTransferCleansing
                                                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                                                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                                                  AND FinancialItemDefinitionId=@FID591),0);

        DECLARE @Amt689 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM MizanDB.dbo.AutoTransferCleansing
                                                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                                                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                                                  AND FinancialItemDefinitionId=@FID689),0);

        DECLARE @Amt692 DECIMAL(22,2) = ISNULL((SELECT CorrectedValue FROM MizanDB.dbo.AutoTransferCleansing
                                                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                                                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                                                  AND FinancialItemDefinitionId=@FID692),0);

        -- 1) 590 > 692 → fark kadar 590’dan eksilt, 570’e ekle
        IF @Amt590 > @Amt692
        BEGIN
            DECLARE @Diff1 DECIMAL(22,2) = @Amt590 - @Amt692;
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FID590,'590',@Diff1,'-',N'Rule26: 590 > 692 fark';
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FID570,'570',@Diff1,'+',N'Rule26: 590 > 692 fark';
        END

        -- 2) 590 < 692 → fark kadar 689 ve c2’ye ekle
        IF @Amt590 < @Amt692
        BEGIN
            DECLARE @Diff2 DECIMAL(22,2) = @Amt692 - @Amt590;
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FID689,'689',@Diff2,'+',N'Rule26: 590 < 692 fark';
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FIDc2,'c2',@Diff2,'+',N'Rule26: 590 < 692 fark';
        END

        -- 3) 591 + 692 > 0 → toplam kadar 689 ve c2’ye ekle
        IF (@Amt591 + @Amt692) > 0
        BEGIN
            DECLARE @Diff3 DECIMAL(22,2) = @Amt591 + @Amt692;
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FID689,'689',@Diff3,'+',N'Rule26: 591 + 692 > 0';
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FIDc2,'c2',@Diff3,'+',N'Rule26: 591 + 692 > 0';
        END

        -- 4) 591 + 692 < 0 → abs(toplam) kadar 591 ve 570’e ekle
        IF (@Amt591 + @Amt692) < 0
        BEGIN
            DECLARE @Diff4 DECIMAL(22,2) = ABS(@Amt591 + @Amt692);
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FID591,'591',@Diff4,'+',N'Rule26: 591 + 692 < 0';
            EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                           @FID570,'570',@Diff4,'+',N'Rule26: 591 + 692 < 0';
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_26 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_ApplyRule_27
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE 
            @FID590 INT, @FID591 INT, @FID570 INT, @FID679 INT;
        DECLARE @Amt NUMERIC(22,2)

        -- FID'ler
        SELECT
            @FID590 = MAX(CASE WHEN Code = N'590' THEN FinancialItemDefinitionId END),
            @FID591 = MAX(CASE WHEN Code = N'591' THEN FinancialItemDefinitionId END),
            @FID570 = MAX(CASE WHEN Code = N'570' THEN FinancialItemDefinitionId END),
            @FID679 = MAX(CASE WHEN Code = N'679' THEN FinancialItemDefinitionId END)
        FROM MizanDB.ALT.FinancialItemDefinition WITH (NOLOCK)
        WHERE Code IN (N'590',N'591',N'570',N'679');

        IF @FID590 IS NULL OR @FID591 IS NULL OR @FID570 IS NULL OR @FID679 IS NULL
            RAISERROR('Rule27: Gerekli FID (590,591,570,679) bulunamadı.', 16, 1);

        /* 679 ağacındaki LEAF hesapları bul ve isim filtreleriyle topla */
        WITH Tree AS (
            SELECT d.AccountCode, d.ParentAccountCode, d.AccountName,
                   CAST(ISNULL(d.DebitBalance,0)  AS DECIMAL(22,2)) AS DebitBalance,
                   CAST(ISNULL(d.CreditBalance,0) AS DECIMAL(22,2)) AS CreditBalance
            FROM MizanDB.dbo.CustomerDetailedTrialBalance d WITH (NOLOCK)
            WHERE d.AccountNumber=@AccountNumber AND d.PeriodId=@PeriodId AND d.AccountCode = N'679'
            UNION ALL
            SELECT c.AccountCode, c.ParentAccountCode, c.AccountName,
                   CAST(ISNULL(c.DebitBalance,0)  AS DECIMAL(22,2)),
                   CAST(ISNULL(c.CreditBalance,0) AS DECIMAL(22,2))
            FROM MizanDB.dbo.CustomerDetailedTrialBalance c WITH (NOLOCK)
            JOIN Tree t
              ON c.AccountNumber=@AccountNumber AND c.PeriodId=@PeriodId
             AND c.ParentAccountCode = t.AccountCode
        ),
        Leaves AS (
            SELECT t.*
            FROM Tree t
            WHERE NOT EXISTS (
                SELECT 1 FROM MizanDB.dbo.CustomerDetailedTrialBalance x WITH (NOLOCK)
                WHERE x.AccountNumber=@AccountNumber AND x.PeriodId=@PeriodId
                  AND x.ParentAccountCode = t.AccountCode
            )
        )
        SELECT @Amt = ISNULL(SUM(l.DebitBalance - l.CreditBalance),0)
        FROM Leaves l
        WHERE l.AccountName LIKE N'%sat geri kirala%'
           OR l.AccountName LIKE N'%sale and leaseback%'
           OR l.AccountName LIKE N'%leaseback%';

        IF @Debug = 1
            PRINT CONCAT('Rule27 | 679 leaf filtre toplamı (net): ', @Amt);

        IF @Amt > 0
        BEGIN
            DECLARE @Bal590 DECIMAL(22,2) =
                ISNULL((
                    SELECT SUM(CorrectedValue) 
                    FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
                    WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                      AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                      AND FinancialItemDefinitionId=@FID590
                ),0);

            IF @Amt <= @Bal590
            BEGIN
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                               @FID590,N'590',@Amt,'-',N'Rule27: Leaseback geliri kadar 590 düşüldü';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                               @FID570,N'570',@Amt,'+',N'Rule27: Leaseback geliri kadar 570 eklendi';
            END
            ELSE
            BEGIN
                DECLARE @Diff DECIMAL(22,2) = @Amt - @Bal590;

                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                               @FID590,N'590',@Bal590,'-',N'Rule27: Leaseback → 590 eldeki kadar düşüldü';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                               @FID591,N'591',@Diff,'+',N'Rule27: Leaseback farkı 591''e eklendi';
                EXEC dbo.sp_ATC_TransferAmount @RuleId,@FirmType,@GroupNumber,@AccountNumber,@PeriodId,
                                               @FID570,N'570',@Amt,'+',N'Rule27: Leaseback toplamı 570''e eklendi';
            END
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(4000)=ERROR_MESSAGE(), @ErrSeverity INT = ERROR_SEVERITY(), @ErrState INT = ERROR_STATE();
        RAISERROR('sp_ATC_ApplyRule_27 failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE   PROCEDURE dbo.sp_ATC_InitData
(
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF @Debug = 1
            PRINT CONCAT('InitData started | FirmType=', @FirmType,
                         ', GroupNumber=', @GroupNumber,
                         ', AccountNumber=', @AccountNumber,
                         ', PeriodId=', @PeriodId);

        -- Kaynak satır sayısını ölç
        DECLARE @SourceCount INT;
        SELECT @SourceCount = COUNT(*)
        FROM MizanDB.ALT.CustomerFinancialItem WITH (NOLOCK)
        WHERE FirmType = @FirmType
          AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber
          AND PeriodId = @PeriodId;

        IF @Debug = 1
            PRINT CONCAT('Source rows found: ', @SourceCount);

        -- Mevcut kayıtları sil (aynı müşteri + dönem)
        DECLARE @Deleted INT;
        DELETE FROM MizanDB.dbo.AutoTransferCleansing
        WHERE FirmType = @FirmType
          AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber
          AND PeriodId = @PeriodId;

        SET @Deleted = @@ROWCOUNT;

        IF @Debug = 1
            PRINT CONCAT('Deleted rows from AutoTransferCleansing: ', @Deleted);

        -- Insert işlemi
        INSERT INTO MizanDB.dbo.AutoTransferCleansing
        (
            FirmType,
            GroupNumber,
            AccountNumber,
            PeriodId,
            FinancialItemDefinitionId,
            OriginalValue,
            CorrectedValue
        )
        SELECT
            FirmType,
            GroupNumber,
            AccountNumber,
            PeriodId,
            FinancialItemDefinitionId,
            OriginalValue,
            OriginalValue
        FROM MizanDB.ALT.CustomerFinancialItem WITH (NOLOCK)
        WHERE FirmType = @FirmType
          AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber
          AND PeriodId = @PeriodId;

        DECLARE @Inserted INT = @@ROWCOUNT;

        IF @Debug = 1
            PRINT CONCAT('Inserted rows into AutoTransferCleansing: ', @Inserted);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_InitData failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_TransferAmount
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,
    @FID           INT,
    @AccountCode   NVARCHAR(50),
    @Amount        DECIMAL(22,2),
    @Process       CHAR(1), -- '+' veya '-'
    @Description   NVARCHAR(500)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Amount IS NULL OR @Amount = 0
        RETURN;

    BEGIN TRY
        -- History'ye ekle
        INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
        (
            RuleId, AccountNumber, PeriodId,
            FinancialItemDefinitionId, AccountCode,
            Amount, Process, Description
        )
        VALUES
        (
            @RuleId, @AccountNumber, @PeriodId,
            @FID, @AccountCode,
            @Amount, @Process, @Description
        );

        -- CorrectedValue güncelle
        UPDATE MizanDB.dbo.AutoTransferCleansing
        SET CorrectedValue =
            CASE WHEN @Process = '+'
                 THEN CorrectedValue + @Amount
                 ELSE CorrectedValue - @Amount
            END
        WHERE FirmType = @FirmType
          AND GroupNumber = @GroupNumber
          AND AccountNumber = @AccountNumber
          AND PeriodId = @PeriodId
          AND FinancialItemDefinitionId = @FID;

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        RAISERROR('sp_ATC_TransferAmount failed: %s', @ErrSeverity, @ErrState, @ErrMsg);
    END CATCH
END;

CREATE PROCEDURE dbo.sp_ATC_TransferCascade
(
    @RuleId        INT,
    @FirmType      TINYINT,
    @GroupNumber   INT,
    @AccountNumber INT,
    @PeriodId      INT,

    @Need          DECIMAL(22,2),     -- Hedefte ihtiyaç duyulan tutar
    @SourceCodes   NVARCHAR(200),     -- Virgüllü liste: '120,121,127' ya da '136,120,121,127'
    @TargetCode    NVARCHAR(10),      -- Örn: '128' veya '138'
    @Debug         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Not: Bu SP’nin içinde TRAN başlatmıyorum; çağıran prosedür (Rule 7) zaten TRAN içinde.
    BEGIN TRY
        /* 0) Kaynak kodları sırayla tabloya aç (STRING_SPLIT with ordinal) */
        DECLARE @Src TABLE (
            Ord  INT,
            Code NVARCHAR(10)
        );

        -- Boşlukları kırpıp ekle
        INSERT INTO @Src(Ord, Code)
        SELECT s.ordinal, LTRIM(RTRIM(s.value))
        FROM STRING_SPLIT(@SourceCodes, ',', 1) AS s
        WHERE NULLIF(LTRIM(RTRIM(s.value)), N'') IS NOT NULL;

        IF NOT EXISTS (SELECT 1 FROM @Src)
            RETURN;

        /* 1) Gerekli FID'leri çek (kaynaklar + hedef) */
        DECLARE @FIDTarget INT;

        -- Tüm kodları (kaynak + hedef) tek set olarak al
        ;WITH AllCodes AS
        (
            SELECT Code FROM @Src
            UNION
            SELECT @TargetCode
        )
        SELECT
            @FIDTarget = MAX(CASE WHEN f.Code = @TargetCode THEN f.FinancialItemDefinitionId END)
        FROM AllCodes ac
        JOIN MizanDB.ALT.FinancialItemDefinition f WITH (NOLOCK)
             ON f.Code = ac.Code;

        IF @FIDTarget IS NULL
            RAISERROR('sp_ATC_TransferCascade: Target FID bulunamadı (%s).', 16, 1, @TargetCode);

        /* 2) Hedef satırı yoksa oluştur (CorrectedValue biriktireceğiz) */
        IF NOT EXISTS (
            SELECT 1
            FROM MizanDB.dbo.AutoTransferCleansing
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDTarget
        )
        BEGIN
            INSERT INTO MizanDB.dbo.AutoTransferCleansing
            (FirmType, GroupNumber, AccountNumber, PeriodId, FinancialItemDefinitionId, OriginalValue, CorrectedValue)
            VALUES
            (@FirmType, @GroupNumber, @AccountNumber, @PeriodId, @FIDTarget, 0, 0);
        END

        /* 3) Sırayla kaynaklardan aktar */
        DECLARE @Remain DECIMAL(22,2) = ISNULL(@Need,0);
        DECLARE @SrcCode NVARCHAR(10), @FIDSrc INT, @Avail DECIMAL(22,2), @Take DECIMAL(22,2);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT Code FROM @Src ORDER BY Ord;

        OPEN cur;
        FETCH NEXT FROM cur INTO @SrcCode;

        WHILE @@FETCH_STATUS = 0 AND @Remain > 0
        BEGIN
            -- Kaynağın FID'sini al
            SELECT @FIDSrc = f.FinancialItemDefinitionId
            FROM MizanDB.ALT.FinancialItemDefinition f WITH (NOLOCK)
            WHERE f.Code = @SrcCode;

            IF @FIDSrc IS NULL
            BEGIN
                IF @Debug = 1 PRINT CONCAT('Kaynak FID bulunamadı: ', @SrcCode);
                FETCH NEXT FROM cur INTO @SrcCode;
                CONTINUE;
            END

            -- Kaynaktaki mevcut düzeltilmiş bakiye
            SELECT @Avail = COALESCE(SUM(CorrectedValue),0)
            FROM MizanDB.dbo.AutoTransferCleansing WITH (NOLOCK)
            WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
              AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
              AND FinancialItemDefinitionId=@FIDSrc;

            SET @Take = CASE WHEN @Avail >= @Remain THEN @Remain ELSE @Avail END;

            -- History: her durumda kayıt (Take sıfır olsa bile)
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FIDSrc,   @SrcCode,   ISNULL(@Take,0), '-', 
             N'Rule7 Cascade: ' + @SrcCode + N' → ' + @TargetCode + N' aktarım denemesi. Kalan ihtiyaç=' + CONVERT(NVARCHAR(50), @Remain)),
            (@RuleId, @AccountNumber, @PeriodId, @FIDTarget, @TargetCode, ISNULL(@Take,0), '+', 
             N'Rule7 Cascade: ' + @SrcCode + N' → ' + @TargetCode + N' aktarıldı.');

            -- Gerçekten aktarılacak bir şey varsa güncelle
            IF @Take > 0
            BEGIN
                -- Kaynaktan düş
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue - @Take
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FIDSrc;

                -- Hedefe ekle
                UPDATE MizanDB.dbo.AutoTransferCleansing
                SET CorrectedValue = CorrectedValue + @Take
                WHERE FirmType=@FirmType AND GroupNumber=@GroupNumber
                  AND AccountNumber=@AccountNumber AND PeriodId=@PeriodId
                  AND FinancialItemDefinitionId=@FIDTarget;

                SET @Remain = @Remain - @Take;

                IF @Debug = 1
                    PRINT CONCAT('Kaynak=', @SrcCode, ' Avail=', @Avail, ' Take=', @Take, ' Remain=', @Remain);
            END

            FETCH NEXT FROM cur INTO @SrcCode;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- Kalan ihtiyaç varsa bilgi amaçlı history (hareket yok)
        IF @Remain > 0
        BEGIN
            INSERT INTO MizanDB.dbo.AutoTransferCleansingHistory
            (RuleId, AccountNumber, PeriodId, FinancialItemDefinitionId, AccountCode, Amount, Process, Description)
            VALUES
            (@RuleId, @AccountNumber, @PeriodId, @FIDTarget, @TargetCode, 0, '+',
             N'Rule7 Cascade: Kaynaklar yetersiz. Karşılanamayan bakiye=' + CONVERT(NVARCHAR(50), @Remain));
            IF @Debug = 1
                PRINT CONCAT('UYARI: Kaynaklar yetersiz. Karşılanamayan bakiye: ', @Remain);
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000)=ERROR_MESSAGE();
        RAISERROR('sp_ATC_TransferCascade failed: %s', 16, 1, @ErrMsg);
    END CATCH
END;