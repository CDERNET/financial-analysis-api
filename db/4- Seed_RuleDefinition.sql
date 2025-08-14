INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(1, N'Fiktif kasa bakiyesi', N'sp_ATC_ApplyRule_01', 1, 1, N'100-Kasa hesabinda net satislarin %2’si kadar üst sinir max 5.000.000 TL olacak sekilde Kasa’da bakiye kalabilir. Üzeri tutar 563 hesabina aktarilarak özkaynaklardan düsülür.
o	BDR / Beyanname verisinden hesaplanacaktir
o	Eger, #100 > #600 * 0.02 veya #100 > 5,000,000 TL ise, 
#100 – min (#600 * 0.02; 5,000,000 TL) farki #100’den eksiltilecek, #563’e eklenecek.
', '2025-08-04 20:30:45.632', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(2, N'101 hesabinin 121 hesabina aktarimi', N'sp_ATC_ApplyRule_02', 2, 1, N'101-Alinan Çekler hesabindaki tutarlarin 121-Alacak Senetleri hesabina aktarilmasi,
o	BDR / Beyanname verisinden hesaplanacaktir
o	#101’deki tüm tutar #101’den eksiltilip #121’e eklenecek. 
', '2025-08-04 20:30:45.637', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(3, N'102 hesabinda takip edilen çek-senetler', N'sp_ATC_ApplyRule_03', 3, 1, N'Henüz vadesi gelmemis ancak bankalara tahsile verilen ticari nitelikli çek/senetler 102 hesabinda görülüyorsa 121 hesabina aktarilmalidir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#102 hesabinin alt kalemlerinde “Çek” ve “Senet” ifadeleri aranacak, bulunan bakiyeler toplanarak #102’den eksiltilecek, #121’e eklenecek.
o	Mizan verisinde aranacak “Çek” ve “Senet” ifadeleri için parametre olusturulacaktir. ', '2025-08-04 20:30:45.642', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(4, N'103 hesabinin 321 hesabina aktarimi', N'sp_ATC_ApplyRule_04', 4, 1, N'103-Verilen Çekler ve Ödeme Emirleri hesabindaki tutarlarin 321-Borç Senetleri hesabina aktarilmasi,
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#103’teki tüm tutar #103’ten eksiltilip #321’e eklenecek.', '2025-08-04 20:30:45.642', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(5, N'120 hesaplarindaki ters bakiyelerin bilançoya ekletilmesi', N'sp_ATC_ApplyRule_05', 5, 1, N'Alicilar hesabinin borç bakiyesi toplami ile alacak bakiyesi toplami arasindaki fark 120 hesabin bakiyesi olarak yazilmamalidir. Borç bakiye toplami 120 - Alicilar, alacak bakiyeleri toplami ise pasifte 340 - Alinan Siparis Avanslari hesabina yazilmalidir.
Hem alacak bakiye hem de borç bakiye içeren formatlarda çalisacak.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	Hem alacak bakiye hem de borç bakiye içeren formatlarda çalisacak, diger mizan formatlarinda çalismayacaktir. 
o	#120 hesabinin alt kalemleri için alacak bakiye kolonundaki tutarlar toplanarak ana kalemin alacak bakiye kolonundaki tutarla farki (alt kalem toplami – ana kalem) bulunacak. Bulunan fark tutari #120’ye ve #340’a eklenecek.', '2025-08-04 20:30:45.642', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(6, N'120 ve 320 hesaplarinda ayni firmalarin bulunmasi', N'sp_ATC_ApplyRule_06', 6, 1, N'Ayni detay mizanda 120 ve 320 hesaplarinda ayni firmanin karsilikli bulunmasi halinde ilgili bakiyelerden küçük olani digerinde tenzil edilmeli,
*Önce 120-320 arasinda bu kontrolü yapsin sonra donuk alacaga baksin. 
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#120 alt kalemlerindeki unvanlar ile #320 alt kalemlerindeki unvanlar karsilastirilacak
o	Eslesen herbir kayit için;
?	#120 alt kalemindeki tutar <= #320 alt kalemindeki tutar ise, #120 alt kalemindeki tutar hem #120’den hem de #320’den eksiltilecek
?	#120 alt kalemindeki tutar > #320 alt kalemindeki tutar ise, #320 alt kalemindeki tutar hem #120’den hem de #320’den eksiltilecek', '2025-08-04 20:30:45.647', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(7, N'Birebir süpheli ticari alacak veya diger alacak karsiligi ayirma', N'sp_ATC_ApplyRule_07', 7, 1, N'128 hesabindaki tutar 129 hesabindaki tutardan büyükse; 128 hesabindaki tutar kadar 129 hesabinda da tutar bulunacak sekilde karsilik ayrilmasi ve ayrilan karsilik kadar 562 hesabi çalistirilarak özkaynaklardan düsümünün saglanmasi,
129 hesabindaki tutar 128 hesabindaki tutardan büyükse; öncelikle 120 hesabindan, ilgili hesapta yeterli bakiye yoksa sirasiyla 121 veya 127 hesaplarindan 128 hesabina bakiye aktararak 129 hesabindaki tutarla denklestirme yapilmasi,
138 hesabindaki tutar 139 hesabindaki tutardan büyükse; 138 hesabindaki tutar kadar 139 hesabinda da tutar bulunacak sekilde karsilik ayrilmasi ve ayrilan karsilik kadar 562 hesabi çalistirilarak özkaynaklardan düsümünün saglanmasi,
139 hesabindaki tutar 138 hesabindaki tutardan büyükse; öncelikle 136 hesabindan, ilgili hesapta yeterli bakiye yoksa sirasiyla 120, 121 veya 127 hesaplarindan 138 hesabina bakiye aktararak 139 hesabindaki tutarla denklestirme yapilmasi,
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#128 > #129 ise, #128 - #129 farki #128’den eksiltilecek, #562’ye eklenecek.
o	#128 < #129 ise, 
?	#129 - #128 <= #120 ise, #129 - #128 farki #120’den eksiltilecek, #128’e eklenecek
?	#129 - #128 <= #120 + #121 ise, 
•	#120’deki tutarin tamami #120’den eksiltilecek, #128’e eklenecek
•	#129 - #128- #120 farki #121’den eksiltilecek, #128’e eklenecek
?	#129 - #128 <= #120 + #121 + #127 ise, 
•	#120’deki tutarin tamami #120’den eksiltilecek, #128’e eklenecek
•	#121’deki tutarin tamami #121’den eksiltilecek, #128’e eklenecek
•	#129 - #128 - #120 - #121 farki #127’den eksiltilecek, #128’e eklenecek
o	#138 > #139 ise, #138 - #139 farki #138’den eksiltilecek, #562’ye eklenecek
o	#138 < #139 ise, 
?	#139 - #138 <= #136 ise, #139 - #138 farki #136’den eksiltilecek, #138’e eklenecek
?	#139 - #138 <= #136 + #120 ise, 
•	#136’daki tutarin tamami #136’dan eksiltilecek, #138’e eklenecek
•	#139 - #138 - #136 farki #120’den eksiltilecek, #138’e eklenecek
?	#139 - #138 <= #136 + #120 + #121 ise, 
•	#136’daki tutarin tamami #136’dan eksiltilecek, #138’e eklenecek
•	#120’deki tutarin tamami #120’den eksiltilecek, #138’e eklenecek
•	#139 - #138 - #136 - #120 - #121 farki #121’den eksiltilecek, #138’e eklenecek
?	#139 - #138 <= #136 + #120 + #121 + #127 ise, 
•	#136’daki tutarin tamami #136’dan eksiltilecek, #138’e eklenecek
•	#120’deki tutarin tamami #120’den eksiltilecek, #138’e eklenecek
•	#121’deki tutarin tamami #121’den eksiltilecek, #138’e eklenecek
•	#139 - #138 - #136 - #120 - #121 - #127 farki #127’den eksiltilecek, #138’e eklenecek', '2025-08-04 20:30:45.647', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(8, N'Kisa vadeli donuk ticari alacak ve diger alacak kontrolü', N'sp_ATC_ApplyRule_08', 8, 1, N'120, 127 ve 136 hesaplarinda asagidaki dönemlere ve kriterlere göre donuk alacak tespiti yapilip 120 ve 127 hesaplarindaki donuk alacaklarin 128 hesabina aktarilmasi ve akabinde süpheli ticari alacaklara birebir karsilik ayrilmasi için 129-562 hesaplarinin çalistirilmasi, 136 hesabindaki donuk alacaklarin 138 hesabina aktarilmasi ve akabinde süpheli ticari alacaklara birebir karsilik ayrilmasi için 139-562 hesaplarinin çalistirilmasi gerekmektedir.
Donuk alacak bakiye tespiti;
4 dönem mali veri incelemesi yapilmaktadir. Asagidaki kurallar belirli dönemleri baz alarak donuk alacak tespiti yapmakla birlikte asagidaki kurallara göre donuk oldugu tespit edilen firmalar 4 dönem de süpheli alacaga aktarilip karsilik ayrilmalidir.
En son analiz dönemi 1. 2. veya 3. çeyrekler ise 120, 127, 136 hesaplarinda alacak kolonunda tutar bulunmayan veya 10.000 TL altinda tutari bulunan firmalarin önceki son 2 tam yilda ticari veya diger alacak bakiyesi alt kirilimlarina bakilir ve geçmis dönemlerde de bakiye girisi olmamissa veya bakiye girisi 10.000 TL altindaysa ilgili bakiye donuk olarak kabul edilir.
En son analiz dönemi 4. çeyrekler ise 120, 127, 136 hesaplarinda alacak kolonunda tutar bulunmayan veya 10.000 TL altinda tutari bulunan firmalarin önceki son tam yilda ticari veya diger alacak bakiyesi alt kirilimlarina bakilir ve geçmis dönemde de bakiye girisi olmamissa veya bakiye girisi 10.000 TL altindaysa ilgili bakiye donuk olarak kabul edilir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.', '2025-08-04 20:30:45.647', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(9, N'Gri listede yer alan firmalarin süpheli alacak hesabina aktarilmasi', N'sp_ATC_ApplyRule_09', 9, 1, N'Bankamizda gri listede yer alan firmalarin BOA’ya yüklenen mizanlar içerisinde 120, 127, 131, 132, 133, 136 hesaplarinda yer almasi durumunda 128 hesabina aktarilmasi ve akabinde 129-562 hesaplarinin çalistirilarak özkaynaklardan düsümünün yapilmasi gerekmektedir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	Kurum veri tabaninda Gri Liste’de yer alan tüm firmalarin unvanlari bir listede toplanacak
o	#120 hesabinin alt kalemlerinde listedeki unvanlarla eslesme varsa, eslesen satirlardaki bakiyelerin toplami #120’den eksiltilecek, #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	#127 hesabinin alt kalemlerinde listedeki unvanlarla eslesme varsa, eslesen satirlardaki bakiyelerin toplami #127’den eksiltilecek, #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	#131 hesabinin alt kalemlerinde listedeki unvanlarla eslesme varsa, eslesen satirlardaki bakiyelerin toplami #131’den eksiltilecek, #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	#132 hesabinin alt kalemlerinde listedeki unvanlarla eslesme varsa, eslesen satirlardaki bakiyelerin toplami #132’den eksiltilecek, #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	#133 hesabinin alt kalemlerinde listedeki unvanlarla eslesme varsa, eslesen satirlardaki bakiyelerin toplami #133’den eksiltilecek, #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	#136 hesabinin alt kalemlerinde listedeki unvanlarla eslesme varsa, eslesen satirlardaki bakiyelerin toplami #136’den eksiltilecek, #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek', '2025-08-04 20:30:45.652', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(10, N'101 hesabindaki karsiliksiz çek ve 121 hesabindaki protestolu senet', N'sp_ATC_ApplyRule_10', 10, 1, N'101 hesabindaki karsiliksiz çek ve 121 hesabindaki protestolu senetlerin 128 hesabina aktarilmasi ve akabinde 129-562 hesaplari çalistirilarak karsilik ayrilmasi,
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#101 hesabi alt kalemlerinde “Karsiliksiz” ifadesi aranacak, eslesen kayitlarin bakiyeleri toplami #101’den eksiltilecek, , #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	#121 hesabi alt kalemlerinde “Protestolu” ifadesi aranacak, eslesen kayitlarin bakiyeleri toplami #101’den eksiltilecek, , #128’e eklenecek, #129’a eklenecek, #562’ye eklenecek
o	Mizan verisinde aranacak “Karsiliksiz” ve “Protestolu” ifadeleri için parametre olusturulacaktir', '2025-08-04 20:30:45.652', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(11, N'BDDK risk grubunda veya firma ortaklik yapilarinda yer alan kisilerden ve firmalardan alacaklar', N'sp_ATC_ApplyRule_11', 11, 1, N'Otomatik aktarma-arindirma ile grubun bagli oldugu BDDK risk grubunda yer alan firmalardan alacaklar(120, 121, 127, 136, 159 kalemlerinde olabilir) 132 hesabina, borçlar(320, 321, 329, 3336, 340) 332 hesabina aktarilmalidir.
Otomatik aktarma-arindirma ile grubun bagli oldugu BDDK risk grubunda yer alan gerçek kisilerden alacaklar 131 hesaplarinda, borçlar 331 hesaplarinda bakiye varsa karsilikli düsülmeli ve karsilikli düsülme sonucu bakiye kalirsa kalan bakiye 561 hesabina aktarilmalidir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	Müsterinin (grup ise gruptaki tüm müsterilerin) bagli oldugu BDDK Risk gruplarinda ve ortaklik yapilarinda yer alan tüzel kisi müsterilerin unvanlari ve gerçek kisi müsterilerin isimleri bir listede toplanir
o	#120 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #120’den eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #132’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #131’e eklenecek
o	#121 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #121’den eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #132’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #131’e eklenecek
o	#127 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #127’den eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #132’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #131’e eklenecek
o	#136 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #136’dan eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #132’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #131’e eklenecek
o	#159 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #159’dan eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #132’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #131’e eklenecek
o	#320 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #320’den eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #332’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #331’e eklenecek
o	#321 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #321’den eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #332’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #331’e eklenecek
o	#329 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #329’dan eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #332’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #331’e eklenecek
o	#336 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #336’dan eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #332’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #331’e eklenecek
o	#340 hesabinin alt kalemlerinde listedeki unvanlarla / isimlerle eslesme varsa, eslesen satirlardaki bakiyelerin toplami #340’tan eksiltilecek, tüzel kisi eslesmelerine ait toplam bakiye #332’ye eklenecek, gerçek kisi eslesmelerine ait toplam bakiye #331’e eklenecek', '2025-08-04 20:30:45.652', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(12, N'131/231-Ortaklardan Alacaklarin Özkaynaktan düsülmesi', N'sp_ATC_ApplyRule_12', 12, 1, N'131 ve 231 hesaplarindaki bakiyelerin 331 ve 431 hesaplarinda bakiye varsa karsilikli düsülmesi ve karsilikli düsülme sonucu 131 veya 231’de bakiye kalirsa kalan bakiyenin 561 hesabina aktarilmasi, 
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#131 <= #331 ise, #131’deki bakiyenin tamami hem #131’den hem de #331’den eksiltilecek
o	#231 <= #431 ise, #231’deki bakiyenin tamami hem #231’den hem de #431’den eksiltilecek
o	#131 > #331 ise, #131’deki bakiyenin tamami #131’den eksiltilecek, #331’deki bakiyenin tamami #331’den eksiltilecek, #131 - #331 farki #561’e eklenecek
o	#231 > #431 ise, #231’deki bakiyenin tamami #231’den eksiltilecek, #431’deki bakiyenin tamami #431’den eksiltilecek, #231 - #431 farki #561’e eklenecek', '2025-08-04 20:30:45.652', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(13, N'180-280 hesaplarindaki faiz giderlerinin 30’lu ve 40’li hesaplar ile mahsuplastirilmasi', N'sp_ATC_ApplyRule_13', 13, 1, N'180 ve 280 hesaplarinda gelecek aylara ait faiz giderleri varsa 30’lu ve 40’li hesaplardan mahsuplastirilmasi yapilmalidir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#180 hesabinin alt kalemlerinde “Faiz” ve “Borçlanma” ifadeleri aranacak, eslesen kayitlarin bakiyeleri toplami hem #180’den hem de #300’den eksiltilecek
o	#280 hesabinin alt kalemlerinde “Faiz” ve “Borçlanma” ifadeleri aranacak, eslesen kayitlarin bakiyeleri toplami hem #280’den hem de #400’den eksiltilecek
o	Mizan verisinde aranacak ““Faiz” ve “Borçlanma” ifadeleri için parametre olusturulacaktir.', '2025-08-04 20:30:45.657', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(14, N'191 ve 391 hesaplarinin karsilikli mahsuplastirilmasi', N'sp_ATC_ApplyRule_14', 14, 1, N'191-Indirilecek KDV ve 391 Hesaplanan KDV hesaplarindaki bakiyeler karsilikli mahsuplastirilmalidir.
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#191 <= #391 ise, #191’deki bakiyenin tamami hem #191’den hem de #391’den eksiltilecek
o	#191 > #391 ise, #391’deki bakiyenin tamami hem #191’den hem de #391’den eksiltilecek', '2025-08-04 20:30:45.657', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(15, N'192 ve 392 hesaplarinin karsilikli mahsuplastirilmasi', N'sp_ATC_ApplyRule_15', 15, 1, N'192-Diger KDV ve 392-Diger KDV hesaplarindaki bakiyeler karsilikli mahsuplastirilmalidir.
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#192 <= #392 ise, #192’deki bakiyenin tamami hem #192’den hem de #392’den eksiltilecek
o	#192 > #392 ise, #392’deki bakiyenin tamami hem #192’den hem de #392’den eksiltilecek', '2025-08-04 20:30:45.657', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(16, N'Pesin ödenen vergi ve karsiliginin ayrilmasi', N'sp_ATC_ApplyRule_16', 16, 1, N'370-371 toplaminin 0 olacak kadar 193''den 371''e aktarma yapilmadir. 371 kalemi 370’den büyükse aradaki fark 193’e eklenir. 
o	BDR / Beyanname verisinden hesaplanacaktir.
o	#370 > #371 ise, #370 - #371 farki #193’ten eksiltilecek, #371’e eklenecek
o	#370 < #371 ise, #371 - #370 farki #193’e eklenecek, #371’den eksiltilecek', '2025-08-04 20:30:45.662', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(17, N'Bagli Menkul Kiymetler, Istirakler ve Bagli Ortakliklar hesabindaki serefiye bakiyesi', N'sp_ATC_ApplyRule_17', 17, 1, N'240-Bagli Menkul Kiymetler, 242-Istirakler, 245-Bagli Ortakliklar hesaplarindaki degerleme ve enflasyon muhasebesi bakiyeleri 562 hesabina aktarilarak özkaynaktan düsülmelidir. 
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#240 hesabinin alt kalemlerinde “Enf” ile baslayan ifadeler aratilacak, eslesen kayitlarin bakiyelerinin toplami #240’tan eksiltilecek, #562’ye eklenecek
o	#242 hesabinin alt kalemlerinde “Enf” ile baslayan ifadeler aratilacak, eslesen kayitlarin bakiyelerinin toplami #242’den eksiltilecek, #562’ye eklenecek
o	#245 hesabinin alt kalemlerinde “Enf” ile baslayan ifadeler aratilacak, eslesen kayitlarin bakiyelerinin toplami #245’ten eksiltilecek, #562’ye eklenecek', '2025-08-04 20:30:45.662', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(18, N'262-Kurulus ve Örgütlenme Giderleri, 263-Arastirma ve Gelistirme Giderleri, 264-Özel Maliyetler, 271-Arama Giderleri, 272-Hazirlik ve Gelistirme Giderleri, 277-Diger Özel Tükenmeye Tabi Varliklar, 279-Verilen Avanslar hesaplarindaki bakiyelerinin özkaynaklardan düsülmesi', N'sp_ATC_ApplyRule_18', 18, 1, N'262-Kurulus ve Örgütlenme Giderleri, 263-Arastirma ve Gelistirme Giderleri, 264-Özel Maliyetler, 271-Arama Giderleri, 272-Hazirlik ve Gelistirme Giderleri, 277-Diger Özel Tükenmeye Tabi Varliklar, 279-Verilen Avanslar hesaplarindaki bakiyeler 563 hesabina aktarilmalidir. 278-Birikmis Tükenme Paylari hesabindaki tutar ise 563 hesabindan düsülmelidir.
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#262’deki tutarin tamami #262’den eksiltilecek, #563’e eklenecek
o	#263’teki tutarin tamami #263’ten eksiltilecek, #563’e eklenecek
o	#264’teki tutarin tamami #264’ten eksiltilecek, #563’e eklenecek
o	#271’deki tutarin tamami #271’den eksiltilecek, #563’e eklenecek
o	#272’deki tutarin tamami #272’den eksiltilecek, #563’e eklenecek
o	#277’deki tutarin tamami #277’den eksiltilecek, #563’e eklenecek
o	#279’daki tutarin tamami #279’dan eksiltilecek, #563’e eklenecek
o	#278’deki tutarin tamami hem #278’den hem de  #563’ten eksiltilecek', '2025-08-04 20:34:51.492', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(19, N'296-Geçici Hesap’ta matrah arttirimi', N'sp_ATC_ApplyRule_19', 19, 1, N'296-Geçici Hesap kodunun alt kiriliminda matrah arttirimi ile ilgili bir ibarenin yer almasi durumunda ilgili tutar 563 hesabina aktarilarak özkaynaklardan düsümü saglanmalidir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#296 hesabinin alt kalemlerinde “Matrah Art” ile baslayan ifadeler aratilacak, eslesen kayitlarin bakiyelerinin toplami #296’dan eksiltilecek, #563’e eklenecek', '2025-08-04 20:30:45.662', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(20, N'Memzuç düzenlemesinin yapilmasi', N'sp_ATC_ApplyRule_20', 20, 1, N'Memzuç tablosunda ilgili dönemde Kisa Risk+Orta Risk+Faiz Tahakkuku+Faiz Reeskontu tutari kadar 30-Mali Borçlar hesabina 40-Mali Borçlar’dan bakiye aktarimi yapilmasi, eger 40-Mali Borçlar hesabinda yeterli bakiye yoksa 331 ve 431 hesaplarindan bakiye aktarimi yapilmasi, yine 331 ve 431 hesaplarinda da bakiye yoksa aktif tarafta 296-Geçici Hesap çalistirilarak bilançoya bakiye eklenmesi,
Akabinde memzuçta Uzun Risk bakiyesi ile 40-Mali Borçlar kontrolünün yapilmasi ve 40-Mali Borçlar hesabinda memzuç Uzun Risk kadar bakiye yoksa 331 ve 431 hesaplarindan bakiye aktarimi yapilmasi, yine 331 ve 431 hesaplarinda da bakiye yoksa aktif tarafta 296-Geçici Hesap çalistirilarak bilançoya bakiye eklenmesi,
Leasing borçlari için; ayni kurallarin kisa+orta+faiz reeskont 301’e, uzun vadeli olanlar 401’e eklenerek 
*Tahvil ve bono, leasing ve faktöring için de çalistiralim. 
o	Beyanname verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.', '2025-08-04 20:30:45.662', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(21, N'Saticilar hesabinda takip edilen faktoring borçlarinin dogru hesaba aktarilmasi', N'sp_ATC_ApplyRule_21', 21, 1, N'320 ve 420 hesaplarinda faktoring sirketinden kaynakli bakiye bulunmasi halinde 307 hesabina aktariminin yapilmasi gerekmektedir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#320 hesabinin alt kalemlerinde “Faktoring” ifadesi aratilacak, eslesen kayitlarin bakiyelerinin toplami #320’den eksiltilecek, #307’ye eklenecek
o	#420 hesabinin alt kalemlerinde “Faktoring” ifadesi aratilacak, eslesen kayitlarin bakiyelerinin toplami #420’den eksiltilecek, #307’ye eklenecek', '2025-08-04 20:30:45.667', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(22, N'320 hesaplarindaki ters bakiyelerin bilançoya ekletilmesi', N'sp_ATC_ApplyRule_22', 22, 1, N'Saticilar hesabinin alacak bakiyesi toplami ile borç bakiyesi toplami arasindaki fark 320 hesabin bakiyesi olarak yazilmamalidir. Alacak bakiye toplami 320 - Saticilar, borç bakiyeleri toplami ise aktifte 159 - Verilen Siparis Avanslari hesabina yazilmalidir.
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	Hem alacak bakiye hem de borç bakiye içeren formatlarda çalisacak, diger mizan formatlarinda çalismayacaktir. 
o	#320 hesabinin alt kalemleri için alacak bakiye kolonundaki tutarlar toplanarak ana kalemin alacak bakiye kolonundaki tutarla farki (alt kalem toplami – ana kalem) bulunacak. Bulunan fark tutari #320’ye ve #159’a eklenecek.', '2025-08-04 20:30:45.667', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(23, N'331 hesabinin 431 hesabina aktarimi', N'sp_ATC_ApplyRule_23', 23, 1, N'331 hesabindaki bakiyenin tamaminin 431 hesabina aktarilmasi gerekmektedir.
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#331’deki tutarin tamami #331’den eksiltilecek, #431’e eklenecek', '2025-08-04 20:30:45.667', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(24, N'Sadece 2023 yilsonu mali verilerde olmak üzere gelir tablosundaki dönem net kari veya zarari ile bilançodaki dönem net kari veya zarari arasinda farklilik', N'sp_ATC_ApplyRule_24', 24, 1, N'Eger 2023 yili gelir tablosunda X TL net dönem kari varsa yapilacak aktarma arindirma islemi;
590-dönem net kari kalemine X TL ekle 
580-geçmis yil zararlari hesabina X TL ekle	
Eger 2023 yili gelir tablosunda X TL net dönem zarari varsa yapilacak aktarma arindirma islemi; 
591-dönem net zarari kalemine X TL ekle 
570-geçmis yil karlari hesabina X TL ekle
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	Sadece 202341 ve 202342 dönemleri için çalistirilacaktir.
o	#692 > 0 ise, #692 kadar hem #590’a hem de #580’e eklenecek
o	#692 < 0 ise, #692 kadar hem #591’e hem de #570’e eklenecek', '2025-08-04 20:30:45.667', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(25, N'Gelir tablosundaki 648 ve 658 bakiyelerindeki tutarlarin özkaynaklara aktarimi', N'sp_ATC_ApplyRule_25', 25, 1, N'648-Enflasyon Düzeltmesi Karlari hesabinda bakiye bulunmasi halinde önce 590-Dönem Net Kari hesabinin kontrol edilerek bakiye varsa düsülmesi, yeterli bakiye yoksa 591-Dönem Net Zarari hesabina eklenmesi ve aktif-pasif esitligini saglamak için 648-Enflasyon Düzeltmesi Karlari bakiyesi kadar 570-Geçmis Yillar Karlari hesabina bakiye eklenmesi,
658-Enflasyon Düzeltmesi Zararlari hesabinda bakiye bulunmasi halinde önce 591-Dönem Net Zarari hesabinin kontrol edilerek bakiye varsa düsülmesi, yeterli bakiye yoksa 590-Dönem Net Karlari hesabina eklenmesi ve aktif-pasif esitligini saglamak için 648-Enflasyon Düzeltmesi Karlari bakiyesi kadar 570-Geçmis Yillar Karlari hesabindan bakiyenin düsülmesi,
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#648 > 0 ve #658 > 0 ise, min (#648,#658) kadar hem #648’den hem de #658’den eksiltilecek
o	#648 > 0 ve #648 <= #590 ise, #648 kadar #590’dan eksiltilecek, #570’e eklenecek
o	#648 > 0 ve #648 > #590 ise, #590 kadar #590’dan eksiltilecek, #648 - #590 farki kadar #591’e eklenecek, #648 kadar #570’e eklenecek
o	#658 > 0 ve #658 <= #591 ise, #658 kadar hem #591’den hem de #570’ten eksiltilecek
o	#658 > 0 ve #658 > #591 ise, #591 kadar #591’den eksiltilecek, #658 - #591 farki kadar #590’a eklenecek, #648 kadar #570’ten eksiltilecek', '2025-08-04 20:30:45.672', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(26, N'Bilanço-Gelir Tablosu arasinda kar-zarar farkinin bulunmasi', N'sp_ATC_ApplyRule_26', 26, 1, N'Bilanço ve gelir tablosu arasinda dönem net kari veya zarari farkinin bulunmasi durumunda;
Bilançodaki net kar gelir tablosundaki net kardan büyükse aradaki fark 570-Geçmis Yillar Karlari hesabina aktarilmali,
Gelir tablosundaki net kar bilançodaki net kardan büyükse 689 ve c2 hesaplarina karsilikli ekleme yapilarak gelir tablosundaki kar azaltilmali,
Bilançodaki net zarar gelir tablosundaki net zarardan büyükse aradaki fark 689 ve c2 hesaplarina karsilikli ekleme yapilarak gelir tablosundaki zarar arttirilmali,
Gelir tablosundaki net zarar bilançodaki net zarardan büyükse bilançodaki olumlu fark 570-Geçmis Yillar Karlari hesabina aktarilarak bilançodaki net zarar arttirilmali,
o	BDR / Beyanname verisinden hesaplanacaktir. 
o	#590 > #692 ise, #590 - #692 kadar #590’dan eksiltilecek #570’e eklenecek
o	#590 < #692 ise, #692 - #590 kadar hem #689’a hem de #c2’ye eklenecek
o	#591 + #692 > 0 ise, #591 + #692 kadar hem #689’a hem de #c2’ye eklenecek
o	#591 + #692 < 0 ise, abs(#591 + #692) kadar hem #591’e hem de #570’e eklenecek', '2025-08-04 20:30:45.672', NULL);
INSERT INTO MizanDB.dbo.AutoTransferCleansingRuleDefinition
(Id, RuleName, ProcedureName, ExecutionOrder, IsActive, Description, CreatedAt, UpdatedAt)
VALUES(27, N'Ilave aktarma arindirma kurali', N'sp_ATC_ApplyRule_27', 27, 1, N'679 diger olagandisi gelir ve karlar kaleminde "sat geri kirala" veya "sale and leaseback" veya "leaseback" gibi bir ibare olmasi durumunda ilgili tutarin önce 590-Dönem Net Kari hesabinin kontrol edilerek bakiye varsa düsülmesi, yeterli bakiye yoksa 591-Dönem Net Zarari hesabina eklenmesi ve aktif-pasif esitligini saglamak için 679 kaleminden alinan tutar kadar 570-Geçmis Yillar Karlari hesabina bakiye eklenmesi
o	Mizan verisinden hesaplanacaktir. Konsolide BDR verisi olan gruplarda çalismayacaktir.
o	#679 hesabinin alt kalemlerinde “sat geri kirala”,  “sale and leaseback” ve  "leaseback" ifadeleri aratilacak, 
?	eslesen kayitlarin bakiyelerinin toplami (X) <= #590 ise, X kadar #590’dan eksiltilecek, #570’e eklenecek
?	eslesen kayitlarin bakiyelerinin toplami (X) >  #590 ise, #590 kadar #590’dan eksiltilecek, X - #590 farki kadar #591’e eklenecek, X kadar #570’e eklenecek', '2025-08-04 20:30:45.672', NULL);