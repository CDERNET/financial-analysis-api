USE [MizanDB]
GO

CREATE FUNCTION [ALT].[fGetCustomerInfo](
    @GroupNumber INT,
    @AccountNumber INT,
    @AllotmentMainId INT)
RETURNS @CustomerInfo TABLE
(
    [FirmType] [TINYINT] NULL,
    [AccountNumber] [INT] NULL,
    [GroupNumber] [INT] NOT NULL,
    [AllotmentMainId] [INT] NOT NULL,
    [Consolidation] [TINYINT] NULL,
    [ConsolidationPercent] [TINYINT] NULL,
    [EffectiveFirm] [TINYINT] NULL,
    [PubliclyTradedRatio] [NUMERIC](10,2) NULL,
    [BalanceSheet] [TINYINT] NOT NULL
)
AS
BEGIN

    /*IF(@GroupNumber IS NULL)
	   SET @GroupNumber = 0

    IF(@AccountNumber IS NULL)
	   SET @AccountNumber = 0

    IF(@AllotmentMainId IS NULL)
	   SET @AllotmentMainId = 0

    IF @AllotmentMainId > 0  
    BEGIN  
	   IF @AccountNumber = 0
		  IF @GroupNumber = 0
			 INSERT INTO @CustomerInfo 
			 (
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet
			 )  
			 SELECT 
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet  
			 FROM BOA.ALT.CustomerInfo WITH (NOLOCK ,INDEX=NCIX_CustomerInfo_AllotmentMainId_FirmType_GroupNumber_AccountNumber ,FORCESEEK)  
			 WHERE AllotmentMainId = @AllotmentMainId 
				AND FirmType = 1
		  ELSE
			 INSERT INTO @CustomerInfo 
			 (
				FirmType ,
				AccountNumber , 
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet
			 )  
			 SELECT 
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet  
			 FROM BOA.ALT.CustomerInfo WITH (NOLOCK ,INDEX=NCIX_CustomerInfo_AllotmentMainId_FirmType_GroupNumber_AccountNumber ,FORCESEEK)  
			 WHERE AllotmentMainId = @AllotmentMainId 
				AND @GroupNumber = GroupNumber 
				AND FirmType = 1
		  ELSE IF @GroupNumber = 0
			 INSERT INTO @CustomerInfo 
			 (
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet
			 )  
			 SELECT 
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet  
			 FROM BOA.ALT.CustomerInfo WITH (NOLOCK ,INDEX=NCUX_CustomerInfo_AccountNumber_AllotmentMainId ,FORCESEEK)  
			 WHERE AllotmentMainId = @AllotmentMainId 
				AND @AccountNumber = AccountNumber 
				AND FirmType=1
		  ELSE
			 INSERT INTO @CustomerInfo 
			 (
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet
			 )  
			 SELECT 
				FirmType ,
				AccountNumber ,
				GroupNumber ,
				AllotmentMainId ,
				Consolidation ,
				ConsolidationPercent ,
				EffectiveFirm ,
				PubliclyTradedRatio ,
				BalanceSheet  
			 FROM BOA.ALT.CustomerInfo WITH (NOLOCK,INDEX=NCIX_CustomerInfo_AllotmentMainId_FirmType_GroupNumber_AccountNumber ,FORCESEEK)  
			 WHERE AllotmentMainId = @AllotmentMainId 
				AND @AccountNumber = AccountNumber 
				AND @GroupNumber = GroupNumber 
				AND FirmType = 1
	   RETURN  
    END

  

    IF @GroupNumber = 0
    BEGIN

        SELECT @GroupNumber = crg.Roleid
        FROM BOA.CUS.CustomerRiskGROUP AS crg WITH (NOLOCK)
        WHERE crg.AccountNumber2 = @AccountNumber AND
              crg.StateId NOT IN ( 1,3,9 ) AND
              crg.IsActive = 1

        SET @GroupNumber = ISNULL(@GroupNumber,0)

    END

    IF @GroupNumber > 0
    BEGIN

        DECLARE @CorporateCustomerCount INT
        DECLARE @Consolidation TINYINT = 0

        SELECT @CorporateCustomerCount = COUNT(crg.AccountNumber2)
        FROM BOA.CUS.CustomerRiskGROUP AS crg WITH (NOLOCK)
        INNER JOIN BOA.CUS.Customer AS c WITH (NOLOCK) ON c.Customerid = crg.AccountNumber2
        INNER JOIN BOA.CUS.CustomerToPerson AS ctp WITH (NOLOCK) ON ctp.Customerid = c.Customerid AND
                                                                    ctp.isDefault = 1
        INNER JOIN BOA.CUS.Person AS p WITH (NOLOCK) ON p.Personid = ctp.Personid
        WHERE crg.Roleid = @GroupNumber AND
              c.StateNo NOT IN ( 1,3,9 ) AND
              (p.PersonType = 1 OR
               (p.PersonType = 0 AND ISNULL(c.Firmid,0) > 0))

        IF ISNULL(@CorporateCustomerCount,0) IN ( 0,1 )
            SET @Consolidation = 0

        INSERT INTO @CustomerInfo
               (FirmType,
                [AccountNumber],
                [GroupNumber],
                [AllotmentMainId],
                [Consolidation],
                [ConsolidationPercent],
                [EffectiveFirm],
                [PubliclyTradedRatio],
                [BalanceSheet])
        SELECT ISNULL(ci.FirmType,1),
               ISNULL(ci.AccountNumber,crg.AccountNumber2),
               @GroupNumber,--ISNULL(ci.GroupNumber,@GroupNumber),
               ISNULL(ci.AllotmentMainId,0),
               ISNULL(ci.Consolidation,@Consolidation),
               CASE
                   WHEN ci.CustomerInfoId IS NULL AND
                        @Consolidation = 1 THEN 100
                   ELSE ci.ConsolidationPercent
               END,
               (CASE
                    WHEN crg.AccountNumber = crg.AccountNumber2 THEN 1
                    ELSE 0
                END),
               ISNULL(ci.PubliclyTradedRatio,0),
               ISNULL(ci.BalanceSheet,1)
        FROM BOA.CUS.CustomerRiskGROUP AS crg WITH (NOLOCK)
        INNER JOIN BOA.CUS.Customer AS c WITH (NOLOCK) ON c.Customerid = crg.AccountNumber2
        INNER JOIN BOA.CUS.CustomerToPerson AS ctp WITH (NOLOCK) ON ctp.Customerid = c.Customerid AND
                                                                    ctp.isDefault = 1
        INNER JOIN BOA.CUS.Person AS p WITH (NOLOCK) ON p.Personid = ctp.Personid
        LEFT JOIN BOA.ALT.CustomerInfo AS ci WITH (NOLOCK,INDEX=NCUX_CustomerInfo_AccountNumber_AllotmentMainId) ON ci.AccountNumber = crg.AccountNumber2 AND
                                                              ci.AllotmentMainId = 0--ISNULL(@AllotmentMainId,0)
        WHERE crg.Roleid = @GroupNumber AND
            (ISNULL(@AccountNumber,0) = 0 OR crg.AccountNumber2 = ISNULL(@AccountNumber,0)) AND
            (p.PersonType = 1 OR (p.PersonType = 0 AND ISNULL(c.Firmid,0) > 0)) AND
            c.StateNo NOT IN ( 1,3,9 )
		  OPTION ( USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'))  

    END
    ELSE
    BEGIN
        INSERT INTO @CustomerInfo
               (FirmType,
                [AccountNumber],
                [GroupNumber],
                [AllotmentMainId],
                [Consolidation],
                [ConsolidationPercent],
                [EffectiveFirm],
                [PubliclyTradedRatio],
                [BalanceSheet])
        SELECT ISNULL(ci.FirmType,1),
               ISNULL(ci.AccountNumber,C.Customerid),
               ISNULL(ci.GroupNumber,@GroupNumber),
               ISNULL(ci.AllotmentMainId,0),
               ISNULL(ci.Consolidation,0),
               ci.ConsolidationPercent,
               ISNULL(ci.EffectiveFirm,1),
               ISNULL(ci.PubliclyTradedRatio,0),
               ISNULL(ci.BalanceSheet,1)
        FROM BOA.CUS.Customer AS c WITH (NOLOCK)
        INNER JOIN BOA.CUS.CustomerToPerson AS ctp WITH (NOLOCK) ON ctp.Customerid = c.Customerid AND
                                                                    ctp.isDefault = 1
        INNER JOIN BOA.CUS.Person AS p WITH (NOLOCK) ON p.Personid = ctp.Personid
        LEFT JOIN BOA.ALT.CustomerInfo AS ci WITH (NOLOCK,INDEX=NCUX_CustomerInfo_AccountNumber_AllotmentMainId) ON ci.AccountNumber = c.Customerid AND
                                                              ci.AllotmentMainId = 0--ISNULL(@AllotmentMainId,0)
        WHERE c.Customerid = @AccountNumber AND
              (p.PersonType = 1 OR
               (p.PersonType = 0 AND
                ISNULL(c.Firmid,0) > 0)) AND
              c.StateNo NOT IN ( 1,3,9 )

    END
*/
    RETURN
END

GO


CREATE FUNCTION [ALT].[fCompareFirstTwoWords_ATC]
(
    @text1 NVARCHAR(4000),
    @text2 NVARCHAR(4000)
)
RETURNS TABLE
AS
RETURN
    -- Tek satır, tek kolon (Result) döndüren inline TVF
    SELECT 
        Result = CAST(
            CASE 
                WHEN ISNULL(w1_1, '') = ISNULL(w2_1, '')
                 AND ISNULL(w1_2, '') = ISNULL(w2_2, '')
                THEN 1 
                ELSE 0 
            END AS BIT
        )
    FROM (
        -- Metinleri normalize et (baş/son boşlukları kırp, . yerine boşluk koy)
        SELECT
            t1 = LTRIM(RTRIM(REPLACE(@text1, '.', ' '))),
            t2 = LTRIM(RTRIM(REPLACE(@text2, '.', ' ')))
    ) base
    CROSS APPLY (
        -- 1. metnin 1. kelimesi ve geri kalanı
        SELECT
            w1_1 = LEFT(t1, CHARINDEX(' ', t1 + ' ') - 1),
            rest1 = LTRIM(SUBSTRING(t1, CHARINDEX(' ', t1 + ' ') + 1, 4000)),
            -- 2. metnin 1. kelimesi ve geri kalanı
            w2_1 = LEFT(t2, CHARINDEX(' ', t2 + ' ') - 1),
            rest2 = LTRIM(SUBSTRING(t2, CHARINDEX(' ', t2 + ' ') + 1, 4000))
    ) s1
    CROSS APPLY (
        -- 1. metnin 2. kelimesi
        SELECT
            w1_2 = LEFT(rest1, CHARINDEX(' ', rest1 + ' ') - 1),
            -- 2. metnin 2. kelimesi
            w2_2 = LEFT(rest2, CHARINDEX(' ', rest2 + ' ') - 1)
    ) s2;

GO

CREATE FUNCTION [ALT].[fn_NormalizeCompany_First2_Scalar]
(
    @Title NVARCHAR(4000)
)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @t NVARCHAR(4000);
    DECLARE @w1 NVARCHAR(100), @w2 NVARCHAR(100);

    SET @t = LOWER(REPlACE(REPlACE(REPlACE(REPLACE(REPLACE(@Title, '.', ' '),'(',''),')',''),',',''),':',''));

    SET @t = REPLACE(@t, '(iflas nedeniyle)', '');
    SET @t = REPLACE(@t, 'iflas nedeniyle', '');
    SET @t = REPLACE(@t, 'tasfiye halinde', '');
    SET @t = REPLACE(@t, 'tasfiye', '');

    SET @t = LTRIM(RTRIM(@t));

    SET @w1 = LEFT(@t, CHARINDEX(' ', @t + ' ') - 1);
    SET @t  = LTRIM(SUBSTRING(@t, CHARINDEX(' ', @t + ' ') + 1, 4000));
    SET @w2 = LEFT(@t, CHARINDEX(' ', @t + ' ') - 1);

    RETURN @w1 + '|' + @w2;
END;

GO

CREATE FUNCTION [ALT].[fGetDetailedTrialBalanceLeafSums_ATC]    
(    
      @AccountNumber INT    
    , @Period        INT    
    , @RootCode      NVARCHAR(50)    
    , @ExcludeRoot   BIT = 1              -- 1: kök hariç, 0: kök dahil  
    , @DescContains  NVARCHAR(200) = NULL -- Virgülle ayrılmış kelime/ifade listesi  
)    
RETURNS @Result TABLE
(
    DebitSum_Leaves  DECIMAL(22,2),
    CreditSum_Leaves DECIMAL(22,2),
    NetSum_Leaves    DECIMAL(22,2)
)
AS
BEGIN
 
    ---------------------------------------------------------
    -- Root var mı? (klasik mod mu, prefix mod mu)
    ---------------------------------------------------------
    DECLARE @RootExists BIT =
    (
        SELECT CASE WHEN EXISTS
        (
            SELECT 1
            FROM ALT.CustomerDetailedTrialBalance r WITH (NOLOCK)
            WHERE r.AccountNumber = @AccountNumber
              AND r.Period        = @Period
              AND r.AccountCode   = @RootCode
        ) THEN 1 ELSE 0 END
    );

    ---------------------------------------------------------
    -- Ağaç: root varsa klasik, yoksa prefix
    ---------------------------------------------------------
    DECLARE @Tree TABLE
    (
        AccountCode        VARCHAR(50)   NOT NULL,
        ParentAccountCode  VARCHAR(50)   NULL,
        AccountDescription VARCHAR(500)  NULL,
        DebitBalance       DECIMAL(22,2) NULL,
        CreditBalance      DECIMAL(22,2) NULL,
        CleanDesc          NVARCHAR(1000) NULL
    );

    IF @RootExists = 1
    BEGIN
        ;WITH Tree AS
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
                CAST(c.DebitBalance  AS DECIMAL(22,2)),
                CAST(c.CreditBalance AS DECIMAL(22,2))
            FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
            JOIN Tree t
              ON  c.AccountNumber     = @AccountNumber
              AND c.Period            = @Period
              AND c.ParentAccountCode = t.AccountCode
        )
        INSERT INTO @Tree (AccountCode, ParentAccountCode, AccountDescription, DebitBalance, CreditBalance)
        SELECT AccountCode, ParentAccountCode, AccountDescription, DebitBalance, CreditBalance
        FROM Tree;
    END
    ELSE
    BEGIN
        INSERT INTO @Tree (AccountCode, ParentAccountCode, AccountDescription, DebitBalance, CreditBalance)
        SELECT
            c.AccountCode,
            c.ParentAccountCode,
            c.AccountDescription,
            CAST(c.DebitBalance  AS DECIMAL(22,2)),
            CAST(c.CreditBalance AS DECIMAL(22,2))
        FROM ALT.CustomerDetailedTrialBalance c WITH (NOLOCK)
        WHERE c.AccountNumber = @AccountNumber
          AND c.Period        = @Period
          AND c.AccountCode LIKE @RootCode + '%';
    END

    -- Ağaç boşsa direkt 0 döndür
    IF NOT EXISTS (SELECT 1 FROM @Tree)
    BEGIN
        INSERT INTO @Result VALUES (0,0,0);
        RETURN;
    END

    ---------------------------------------------------------
    -- Yaprak seti (çocuk hesabı olmayanlar)
    ---------------------------------------------------------
    DECLARE @Leaves TABLE
    (
        AccountCode        VARCHAR(50)   NOT NULL,
        ParentAccountCode  VARCHAR(50)   NULL,
        AccountDescription VARCHAR(500)  NULL,
        DebitBalance       DECIMAL(22,2) NULL,
        CreditBalance      DECIMAL(22,2) NULL
    );

    INSERT INTO @Leaves (AccountCode, ParentAccountCode, AccountDescription, DebitBalance, CreditBalance)
    SELECT
        t.AccountCode,
        t.ParentAccountCode,
        t.AccountDescription,
        t.DebitBalance,
        t.CreditBalance
    FROM @Tree t
    WHERE NOT EXISTS
          (
              SELECT 1
              FROM @Tree x
              WHERE x.ParentAccountCode = t.AccountCode
          );

    ---------------------------------------------------------
    -- @DescContains NULL ise: klasik davranış (tüm yapraklar)
    ---------------------------------------------------------
    IF @DescContains IS NULL
    BEGIN
        INSERT INTO @Result
        SELECT
            CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE DebitBalance  END) AS DECIMAL(22,2)) AS DebitSum_Leaves,
            CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE CreditBalance END) AS DECIMAL(22,2)) AS CreditSum_Leaves,
			CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE 
		                                                                           CASE WHEN DebitBalance>CreditBalance THEN (DebitBalance - CreditBalance) 
																				   ELSE (CreditBalance-DebitBalance ) END END) AS DECIMAL(22,2)) AS NetSum_Leaves
        FROM @Leaves;

        RETURN;
    END

    ---------------------------------------------------------
    -- Açıklama bazlı filtre devrede (@DescContains DOLU)
    ---------------------------------------------------------

    -- 1) Keyword / Phrase listesi
    DECLARE @Keywords TABLE
    (
        Keyword  NVARCHAR(200) NOT NULL,
        IsPhrase BIT           NOT NULL
    );

    INSERT INTO @Keywords (Keyword, IsPhrase)
    SELECT
        UPPER(LTRIM(RTRIM(value))),
        CASE WHEN CHARINDEX(N' ', UPPER(LTRIM(RTRIM(value)))) > 0 THEN 1 ELSE 0 END
    FROM STRING_SPLIT(@DescContains, ',')
    WHERE @DescContains IS NOT NULL;

    -- 2) Tree üzerinde açıklamaları temizle (CleanDesc)
    UPDATE t
    SET CleanDesc =
        UPPER(
            REPLACE(
            REPLACE(
            REPLACE(ISNULL(AccountDescription, N''), N'.', N' ')
            , N',', N' ')
            , N'-', N' ')
        )
    FROM @Tree t;

    -- 3) Kelime bazlı çözümleme (tek kelime keyword için)
    DECLARE @TreeWords TABLE
    (
        AccountCode        VARCHAR(50)   NOT NULL,
        ParentAccountCode  VARCHAR(50)   NULL,
        AccountDescription VARCHAR(500)  NULL,
        DebitBalance       DECIMAL(22,2) NULL,
        CreditBalance      DECIMAL(22,2) NULL,
        CleanDesc          NVARCHAR(1000) NULL,
        Word               NVARCHAR(200) NOT NULL
    );

    INSERT INTO @TreeWords (AccountCode, ParentAccountCode, AccountDescription, DebitBalance, CreditBalance, CleanDesc, Word)
    SELECT
        ct.AccountCode,
        ct.ParentAccountCode,
        ct.AccountDescription,
        ct.DebitBalance,
        ct.CreditBalance,
        ct.CleanDesc,
        UPPER(LTRIM(RTRIM(w.value))) AS Word
    FROM @Tree ct
    CROSS APPLY STRING_SPLIT(ct.CleanDesc, N' ') w;

    -- 4) Aday hesaplar (tek kelime + phrase)
    DECLARE @Candidates TABLE
    (
        AccountCode VARCHAR(50) NOT NULL
    );

    -- 4.a) Tek kelimelik keyword eşleşmeleri (WORD bazlı)
    INSERT INTO @Candidates (AccountCode)
 SELECT DISTINCT tw.AccountCode
    FROM @TreeWords tw
    JOIN @Keywords k
      ON k.IsPhrase = 0
     AND tw.Word <> N''
     AND tw.Word LIKE k.Keyword + N'%'          -- kökle başlasın
     AND LEN(tw.Word) <= LEN(k.Keyword) + 3    -- max 3 harf ek
    WHERE (tw.DebitBalance > 0 OR tw.CreditBalance > 0);

    -- 4.b) Çok kelimeli ifadeler ("SAYILI KANUN" gibi) – phrase bazlı
    INSERT INTO @Candidates (AccountCode)
    SELECT DISTINCT t.AccountCode
    FROM @Tree t
    JOIN @Keywords k
      ON k.IsPhrase = 1
     AND k.Keyword <> N''
     AND CHARINDEX(k.Keyword, t.CleanDesc) > 0
    WHERE (t.DebitBalance > 0 OR t.CreditBalance > 0);

    ---------------------------------------------------------
    -- 5) Candidate + alt kırılımlar (hierarchy)
    ---------------------------------------------------------
    ;WITH DistinctCandidates AS
    (
        SELECT DISTINCT AccountCode FROM @Candidates
    ),
    CandidateHierarchy AS
    (
        SELECT
            t.AccountCode,
            t.ParentAccountCode,
            t.AccountDescription,
            t.DebitBalance,
            t.CreditBalance
        FROM @Tree t
        JOIN DistinctCandidates c
          ON c.AccountCode = t.AccountCode

        UNION ALL

        SELECT
            child.AccountCode,
            child.ParentAccountCode,
            child.AccountDescription,
            child.DebitBalance,
            child.CreditBalance
        FROM @Tree child
        JOIN CandidateHierarchy parent
          ON child.ParentAccountCode = parent.AccountCode
    ),
    LeafFiltered AS
    (
        -- Candidate alt ağacındaki yapraklar
        SELECT DISTINCT ch.AccountCode,
               ch.ParentAccountCode,
               ch.AccountDescription,
               ch.DebitBalance,
               ch.CreditBalance
        FROM CandidateHierarchy ch
        WHERE NOT EXISTS
              (
                  SELECT 1
                  FROM @Tree child
                  WHERE child.ParentAccountCode = ch.AccountCode
              )
    )
    INSERT INTO @Result
    SELECT
        CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE DebitBalance  END) AS DECIMAL(22,2)) AS DebitSum_Leaves,
        CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE CreditBalance END) AS DECIMAL(22,2)) AS CreditSum_Leaves,
        CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE 
		                                                                           CASE WHEN DebitBalance>CreditBalance THEN (DebitBalance - CreditBalance) 
																				   ELSE (CreditBalance-DebitBalance ) END END) AS DECIMAL(22,2)) AS NetSum_Leaves
    FROM LeafFiltered;
    RETURN;
END

GO
CREATE FUNCTION [ALT].[fGetDetailedTrialBalanceContainesGroupsLeafSums_ATC]  
(  
      @AccountNumber INT  
    , @Period        INT  
    , @RootCode      NVARCHAR(50)  
    , @ExcludeRoot   BIT = 1              -- 1: kök hariç (alt kırılımlar), 0: kök dahil (kök de yapraksa)
    , @DescContains  NVARCHAR(200) = NULL -- Virgülle ayrılmış kelime listesi: Örn: N'Çek,Senet'
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
---------------------------------------------------------  
-- Klasik ağaç (kök mevcutsa)  
---------------------------------------------------------  
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
---------------------------------------------------------  
-- Prefix modu (kök yoksa)  
---------------------------------------------------------  
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
        FROM PrefixSet x  
        WHERE x.ParentAccountCode = s.AccountCode  
          AND x.AccountCode LIKE @RootCode + '%'  
    )  
),  
    
Candidates_Classical AS  
(  
    SELECT DISTINCT   
        tw.AccountCode,  
        tw.ParentAccountCode,  
        tw.AccountDescription,  
        tw.DebitBalance,  
        tw.CreditBalance  
    FROM Tree tw  
    CROSS APPLY ALT.fCompareFirstTwoWords_ATC(tw.AccountDescription, @DescContains) cmp
    WHERE @DescContains IS NOT NULL  
      AND (tw.DebitBalance  > 0 OR tw.CreditBalance > 0)  
	  and cmp.Result = 1
),  
CandidateHierarchy_Classical AS  
(  
    SELECT t.*  
    FROM Tree t  
    INNER JOIN Candidates_Classical c  
            ON  t.AccountCode = c.AccountCode  
  
    UNION ALL  
  
    SELECT child.*  
    FROM Tree child  
    INNER JOIN CandidateHierarchy_Classical parent  
            ON  child.ParentAccountCode = parent.AccountCode  
),  
Leaf_Classical_Filtered AS  
(  
    SELECT DISTINCT ch.*  
    FROM   CandidateHierarchy_Classical ch  
    WHERE NOT EXISTS  
          (  
              SELECT 1  
              FROM Tree child  
              WHERE child.ParentAccountCode = ch.AccountCode  
          )  
),  
  
Candidates_Prefix AS  
(  
    SELECT DISTINCT   
        pw.AccountCode,  
        pw.ParentAccountCode,  
        pw.AccountDescription,  
        pw.DebitBalance,  
        pw.CreditBalance  
    FROM PrefixSet pw  
    CROSS APPLY ALT.fCompareFirstTwoWords_ATC(pw.AccountDescription, @DescContains) cmp
    WHERE @DescContains IS NOT NULL  
      AND (pw.DebitBalance  > 0 OR pw.CreditBalance > 0)  
	   and cmp.Result = 1
),  
CandidateHierarchy_Prefix AS  
(  
    SELECT s.*  
    FROM PrefixSet s  
    INNER JOIN Candidates_Prefix c  
            ON  s.AccountCode = c.AccountCode  
  
    UNION ALL  
  
    SELECT child.*  
    FROM PrefixSet child  
    INNER JOIN CandidateHierarchy_Prefix parent  
            ON  child.ParentAccountCode = parent.AccountCode  
),  
Leaf_Prefix_Filtered AS  
(  
    SELECT DISTINCT ch.*  
    FROM   CandidateHierarchy_Prefix ch  
    WHERE NOT EXISTS  
          (  
              SELECT 1  
              FROM PrefixSet child  
              WHERE child.ParentAccountCode = ch.AccountCode  
                AND child.AccountCode LIKE @RootCode + '%'  
          )  
),  
---------------------------------------------------------  
-- Nihai yaprak seti:  
--  - @DescContains NULL ise: eski davranış (Leaves_Classical / Leaves_Prefix)  
--  - @DescContains DOLU ise: varlık tespiti ile filtrelenmiş yapraklar  
---------------------------------------------------------  
FinalSet AS  
(  
    -- Root varsa, klasik mod  
    SELECT l.*  
    FROM Leaves_Classical l  
    CROSS JOIN Mode m  
    WHERE m.RootExists = 1  
      AND (  
            @DescContains IS NULL  
         OR EXISTS  
            (  
                SELECT 1  
                FROM Leaf_Classical_Filtered f  
                WHERE f.AccountCode = l.AccountCode  
            )  
          )  
  
    UNION ALL  
  
    -- Root yoksa, prefix mod  
    SELECT p.*  
    FROM Leaves_Prefix p  
    CROSS JOIN Mode m  
    WHERE m.RootExists = 0  
      AND (  
            @DescContains IS NULL  
         OR EXISTS  
            (  
                SELECT 1  
                FROM Leaf_Prefix_Filtered f  
                WHERE f.AccountCode = p.AccountCode  
            )  
          )  
)  
---------------------------------------------------------  
-- Sonuç: Debit, Credit, Net (yaprak toplamları)  
---------------------------------------------------------  
SELECT  
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE DebitBalance  END) AS DECIMAL(22,2)) AS DebitSum_Leaves,  
    CAST(SUM(CASE WHEN @ExcludeRoot=1 AND AccountCode=@RootCode THEN 0 ELSE CreditBalance END) AS DECIMAL(22,2)) AS CreditSum_Leaves, 
	CAST(SUM(CASE WHEN @ExcludeRoot = 1 AND AccountCode = @RootCode THEN 0 ELSE CASE WHEN DebitBalance>CreditBalance THEN (DebitBalance - CreditBalance) 
																				   ELSE (CreditBalance-DebitBalance ) END END) AS DECIMAL(22,2)) AS NetSum_Leaves
FROM FinalSet;
