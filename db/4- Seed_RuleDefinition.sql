Use [MizanDB]
GO
SET NOCOUNT ON;
INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Aktarım Arındırma Data Aktarım (Customer FİnancialItem to Cleansing)', 'ALT.upd_ATC_ApplyRule_00', 10, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Fiktif kasa bakiyesi', 'ALT.upd_ATC_ApplyRule_01', 20, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('101 hesabının 121 hesabına aktarımı', 'ALT.upd_ATC_ApplyRule_02', 30, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('102 hesabında takip edilen çek-senetler', 'ALT.upd_ATC_ApplyRule_03', 40, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('103 hesabının 321 hesabına aktarımı', 'ALT.upd_ATC_ApplyRule_04', 50, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('120 hesaplarındaki ters bakiyelerin bilançoya ekletilmesi', 'ALT.upd_ATC_ApplyRule_05', 60, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('120 ve 320 hesaplarında aynı firmaların bulunması', 'ALT.upd_ATC_ApplyRule_06', 70, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Birebir şüpheli ticari alacak veya diğer alacak karşılığı ayırma', 'ALT.upd_ATC_ApplyRule_07', 80, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Kısa vadeli donuk ticari alacak ve diğer alacak kontrolü', 'ALT.upd_ATC_ApplyRule_08', 90, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Gri listede yer alan firmaların şüpheli alacak hesabına aktarılması', 'ALT.upd_ATC_ApplyRule_09', 75, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('101 hesabındaki karşılıksız çek ve 121 hesabındaki protestolu senet', 'ALT.upd_ATC_ApplyRule_10', 25, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('BDDK risk grubunda veya firma ortaklık yapılarında yer alan kişilerden ve firmalardan alacaklar', 'ALT.upd_ATC_ApplyRule_11', 120, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('131/231-Ortaklardan Alacakların Özkaynaktan düşülmesi', 'ALT.upd_ATC_ApplyRule_12', 130, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('180-280 hesaplarındaki faiz giderlerinin 30’lu ve 40’lı hesaplar ile mahsuplaştırılması', 'ALT.upd_ATC_ApplyRule_13', 140, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('191 ve 391 hesaplarının karşılıklı mahsuplaştırılması', 'ALT.upd_ATC_ApplyRule_14', 150, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('192 ve 392 hesaplarının karşılıklı mahsuplaştırılması', 'ALT.upd_ATC_ApplyRule_15', 160, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Peşin ödenen vergi ve karşılığının ayrılması', 'ALT.upd_ATC_ApplyRule_16', 170, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Bağlı Menkul Kıymetler, İştirakler ve Bağlı Ortaklıklar hesabındaki şerefiye bakiyesi', 'ALT.upd_ATC_ApplyRule_17', 180, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('262-Kuruluş ve Örgütlenme Giderleri, 263-Araştırma ve Geliştirme Giderleri, 264-Özel Maliyetler, 271-Arama Giderleri, 272-Hazırlık ve Geliştirme Giderleri, 277-Diğer Özel Tükenmeye Tabi Varlıklar, 279-Verilen Avanslar hesaplarındaki bakiyelerinin özkaynaklardan düşülmesi', 'ALT.upd_ATC_ApplyRule_18', 190, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('296-Geçici Hesap’ta matrah arttırımı', 'ALT.upd_ATC_ApplyRule_19', 200, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Satıcılar hesabında takip edilen faktoring borçlarının doğru hesaba aktarılması', 'ALT.upd_ATC_ApplyRule_20', 210, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Memzuç düzenlemesinin yapılması', 'ALT.upd_ATC_ApplyRule_21', 220, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('320 hesaplarındaki ters bakiyelerin bilançoya ekletilmesi', 'ALT.upd_ATC_ApplyRule_22', 230, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('331 hesabının 431 hesabına aktarımı', 'ALT.upd_ATC_ApplyRule_23', 215, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Sadece 2023 yılsonu mali verilerde olmak üzere gelir tablosundaki dönem net karı veya zararı ile bilançodaki dönem net karı veya zararı arasında farklılık', 'ALT.upd_ATC_ApplyRule_24', 250, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Gelir tablosundaki 648 ve 658 bakiyelerindeki tutarların özkaynaklara aktarımı', 'ALT.upd_ATC_ApplyRule_25', 260, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Bilanço-Gelir Tablosu arasında kar-zarar farkının bulunması', 'ALT.upd_ATC_ApplyRule_26', 270, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('İlave aktarma arındırma kuralı', 'ALT.upd_ATC_ApplyRule_27', 280, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('240/242/245 hesaplarının 500 hesabı ile tenzilatı', 'ALT.upd_ATC_Discount_01', 20, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('241/243/246/247 hesaplarının 501 hesabı ile tenzilatı', 'ALT.upd_ATC_Discount_02', 30, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Ticari Alacak (120, 127, 220)+Diğer Alacak (131, 132, 133, 136, 231, 232, 233, 236) hesaplarındaki grup içi bakiyenin karşı firmanın Ticari Borçlar (320, 329, 420, 429)+Diğer Borç (331, 332, 333, 336, 431, 432, 433, 436) bakiyesi ile tenzil edilmesi ', 'ALT.upd_ATC_Discount_03', 40, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Tenzilat Data Aktarım (Customer FİnancialItem to Cleansing)', 'ALT.upd_ATC_Discount_00', 10, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Aktarım Arındırma Data Aktarım AutoTransferCleansing to CustomerFinancialItem', 'ALT.upd_ATC_ApplyRule_SendData', 290, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Tenzilat Data Aktarım AutoTransferCleansing to CustomerFinancialItem', 'ALT.upd_ATC_Discount_SendData', 50, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Mizandan Beyannameye Amortisman Aktarım', 'ALT.ins_CustomerFinancialItemAmortisman', 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO [ALT].[AutoTransferCleansingRuleDefinition] ([RuleName], [SpName], [ExecutionOrder], [UserDescription], [Status], [UserName], [HostName], [SystemDate], [UpdateUserName], [UpdateHostName], [UpdateSystemDate], [HostIP])
VALUES ('Gri liste Cache Tablosu doldurma', 'ALT.ins_FillGreyListCacheAtc', 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
