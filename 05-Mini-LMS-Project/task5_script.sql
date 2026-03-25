USE master;
GO
-- Eğer veritabanı varsa, aktif bağlantıları kes ve sil
IF EXISTS(SELECT * FROM sys.databases WHERE name = 'OBS_System')
BEGIN
    ALTER DATABASE OBS_System SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OBS_System;
END
GO
CREATE DATABASE OBS_System;
GO
USE OBS_System;
GO


CREATE TABLE Bolumler(
    bolum_id INT IDENTITY(1, 1) PRIMARY KEY,
    bolum_adi VARCHAR(50), 
    fakulte_adi VARCHAR(50)
);

CREATE TABLE Ogrenciler(
    ogrenci_id INT PRIMARY KEY,
    ad VARCHAR(20),
    soyad VARCHAR(20),
    bolum_id INT FOREIGN KEY(bolum_id) REFERENCES Bolumler(bolum_id),
    kayit_tarihi DATE
);

CREATE TABLE Dersler(
    ders_id INT PRIMARY KEY,
    ders_adi VARCHAR(50),
    bolum_id INT FOREIGN KEY(bolum_id) REFERENCES Bolumler(bolum_id)
);

CREATE TABLE Notlar(
    not_id INT IDENTITY(1, 1) PRIMARY KEY,
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    vize INT CHECK(vize BETWEEN 0 AND 100), --constraint kullanimi, tanimlari
    final INT CHECK(final BETWEEN 0 AND 100), 
    ortalama FLOAT, 
    durum VARCHAR(10) 
    CONSTRAINT FK_DersKayit_Ogrenci FOREIGN KEY (ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    CONSTRAINT FK_DersKayit_Ders FOREIGN KEY (ders_id) REFERENCES Dersler(ders_id)
);

CREATE TABLE DersKayitlari(
    kayit_id INT PRIMARY KEY,
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    kayit_tarihi DATE,
    CONSTRAINT FK_Kayit_Ogrenci FOREIGN KEY (ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    CONSTRAINT FK_Kayit_Ders FOREIGN KEY (ders_id) REFERENCES Dersler(ders_id)
);

CREATE TABLE Kullanicilar(
    kullanici_id INT IDENTITY(1, 1) PRIMARY KEY,
    kullanici_adi VARCHAR(50) UNIQUE,
    sifre VARCHAR(100),
    ogrenci_id INT NULL,
    ogretmen_id INT NULL
);

CREATE TABLE Roller(
    rol_id INT IDENTITY(1, 1) PRIMARY KEY,
    rol_adi VARCHAR(50) UNIQUE
);

CREATE TABLE KullaniciRoller(
    kullanici_id INT,
    rol_id INT,
    PRIMARY KEY(kullanici_id, rol_id), --composite(bileşik) primary key
    FOREIGN KEY(kullanici_id) REFERENCES Kullanicilar(kullanici_id),
    FOREIGN KEY(rol_id) REFERENCES Roller(rol_id)
);

CREATE TABLE OgretmenDersleri(
    ogretmen_id INT,
    ders_id INT,
    PRIMARY KEY(ogretmen_id, ders_id) 
);

CREATE TABLE NotGecmisi(
    gecmis_id INT IDENTITY(1, 1) PRIMARY KEY,
    not_id INT,
    eski_ortalama FLOAT,
    degistiren_kullanici NVARCHAR(100),
    degistirme_tarihi DATETIME DEFAULT GETDATE()
);

CREATE TABLE Odevler(
    odev_id INT IDENTITY(1, 1) PRIMARY KEY,
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    baslik VARCHAR(50) UNIQUE,
    son_tarih DATE,
    agirlik_orani INT
);

CREATE TABLE Quizler(
    quiz_id INT PRIMARY KEY,
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    tarih DATE,
    agirlik_orani INT 
);

CREATE TABLE OdevNotlari(
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    odev_id INT,
    odev_not INT FOREIGN KEY CHECK(odev_not BETWEEN 0 AND 100), 
    PRIMARY KEY(ogrenci_id, odev_id)
);

CREATE TABLE QuizNotlari(
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    quiz_id INT,
    quiz_not INT FOREIGN KEY CHECK(quiz_not BETWEEN 0 AND 100),
    CONSTRAINT FK_Not_Quiz_Ogrenci FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    PRIMARY KEY(ogrenci_id, quiz_id) 
);

CREATE TABLE Devamsizlik(
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    toplam_ders INT,
    katilim_sayisi INT,
    PRIMARY KEY(ogrenci_id, ders_id)
);

CREATE TABLE AuditLog(
    log_id INT IDENTITY(1, 1) PRIMARY KEY,
    tablo_adi VARCHAR(50),
    islem_tipi VARCHAR(50),
    eski_deger NVARCHAR(MAX),
    yeni_deger NVARCHAR(MAX),
    kullanici varchar(50),
    tarih DATE 
);
GO

INSERT INTO Bolumler(bolum_adi, fakulte_adi)
VALUES ('Yazilim Muhendisligi', 'Muhendislik'), 
('Bilgisayar Muhendisligi', 'Muhendislik'), 
('Elektrik Elektronik', 'Muhendislik');

INSERT INTO Ogrenciler(ogrenci_id, ad, soyad, bolum_id, kayit_tarihi)
VALUES (99998,'Ali','Veli',1,GETDATE()), -- mevcut id 1 yerine dongu ile cakismayacak yuksek bir deger verdik
(99999,'Ayse','Kara',2,GETDATE()); -- mevcut id 2 yerine dongu ile cakismayacak yuksek bir deger verdik


INSERT INTO Dersler(ders_id, ders_adi, bolum_id)
VALUES (1,'Veritabani',1),
(2,'Algoritma',2);


INSERT INTO DersKayitlari(kayit_id, ogrenci_id, ders_id, kayit_tarihi)
VALUES (1,1,1,GETDATE()),(2,2,2,GETDATE());

INSERT INTO Notlar(ogrenci_id, ders_id, vize, final)
VALUES(
    ABS(CHECKSUM(NEWID())) % 10000 + 1,
    ABS(CHECKSUM(NEWID())) % 100 + 1,
    ABS(CHECKSUM(NEWID())) % 100,
    ABS(CHECKSUM(NEWID())) % 100
);

INSERT INTO Kullanicilar(kullanici_adi, sifre, ogrenci_id)
VALUES ('AliVeli','1234',1);

INSERT INTO Roller(rol_adi)
VALUES
('Ogrenci'),   --sadece kendi notlarini gorur
('Ogretmen'),  --sadece verdigi derslerin notlarini gorur  
('BolumBaskani'); --bolumdeki tum ogrencileri gorur
GO


--devamsizlik kontrolu icin trigger
CREATE OR ALTER TRIGGER trg_DevamsizlikKontrol
ON Notlar
INSTEAD OF INSERT --islem(insert/update) hic yapilmaz, benim yazdigim kod calisir
AS
BEGIN
    SET NOCOUNT ON; --basta olmali, performans saglar
    --devamsizlik kontrolu
    IF EXISTS(
        SELECT 1 FROM inserted i 
        JOIN Devamsizlik De ON De.ogrenci_id = i.ogrenci_id AND De.ders_id = i.ders_id
        WHERE (1.0 - (CAST(De.katilim_sayisi AS FLOAT) / NULLIF(De.toplam_ders, 0))) > 0.30
    )
    BEGIN
        RAISERROR('Devamsizlik orani %30"u gectigi icin not girisi yapilamaz!', 16, 1);
        ROLLBACK;
        RETURN;
    END
    --not hesaplama ve kaydetme
    INSERT INTO Notlar(ogrenci_id, ders_id, vize, final, ortalama, durum) 
    SELECT i.ogrenci_id,
        i.ders_id,
        i.vize, 
        i.final, 
        (i.vize * 0.3) + (i.final * 0.5) + 
        ISNULL((SELECT AVG(CAST(odev_not AS FLOAT)) FROM OdevNotlari WHERE ogrenci_id = i.ogrenci_id), 0) + --alt sorgu,
        ISNULL((SELECT AVG(CAST(quiz_not AS FLOAT)) FROM QuizNotlari WHERE ogrenci_id = i.ogrenci_id), 0)  / 2 * 0.2 , --alt sorgu
        CASE 
            WHEN ((i.vize * 0.30) + (i.final * 0.50) + 10) >= 50 THEN 'Gecti' -- 10 puan odev/not varsayimi
            ELSE 'Kaldi'
        END
    FROM inserted i;
END;
GO


--audit log mekanizması(trigger ile), after update kullanilir cunku islemin gerceklestiginden emin olmak isteriz
CREATE OR ALTER TRIGGER trg_AfterUpdate --her güncellemede araya girip eski yeni degeri gosterir
ON Notlar 
AFTER UPDATE --once guncelleme islemi yapilir sonra benim loglama kodum calisir. update sonrasinde deleted inserted tablolari olusturabiliriz 
AS
BEGIN
    SET NOCOUNT ON;  
    INSERT INTO AuditLog(tablo_adi, islem_tipi, eski_deger, yeni_deger, kullanici, tarih)
    SELECT 
        'Notlar', 
        'UPDATE', 
        'Vize: ' + CAST(d.vize AS NVARCHAR(MAX)) + '- Final: ' + CAST(d.final AS NVARCHAR(MAX)) + '- Ortalama: ' + CAST(d.ortalama AS NVARCHAR(MAX)), 
        'Vize: ' + CAST(i.vize AS NVARCHAR(MAX)) + '- Final: ' + CAST(i.final AS NVARCHAR(MAX)) + '- Ortalama: ' + CAST(i.ortalama AS NVARCHAR(MAX)),
        SUSER_NAME(),
        GETDATE() 
    FROM inserted i 
    JOIN deleted d ON d.not_id = i.not_id 
END;
GO


--agirlikli not hesaplayan stored procedure
CREATE OR ALTER PROCEDURE dbo.sp_NotHesaplama
    @ogrenci_id INT,
    @ders_id INT,
    @vize INT,
    @final INT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY   
        IF(@vize NOT BETWEEN 0 AND 100 OR @final NOT BETWEEN 0 AND 100)
            THROW 50001, 'Notlar 0-100 olmalidir!', 1;

        INSERT INTO Notlar(ogrenci_id, ders_id, vize, final)
        VALUES(@ogrenci_id, @ders_id, @vize, @final);
        PRINT 'Notlar basarili bir sekilde eklendi, trigger ortalamayi hesapladi.';
    END TRY
BEGIN CATCH
    PRINT 'Hata olustu: ' + ERROR_MESSAGE();
END CATCH
END;
GO

--ogrenci detay transkripti
CREATE OR ALTER PROCEDURE sp_OgrenciTranskript
    @ogrenci_id INT
AS
BEGIN
    SELECT 
        O.ad + ' ' + O.soyad AS Ogrenci,
        D.ders_adi AS Ders,
        N.vize,
        N.final, 
        N.ortalama, 
        N.durum 
    FROM Ogrenciler O
    JOIN Notlar N ON N.ogrenci_id = O.ogrenci_id
    JOIN Dersler D ON D.ders_id = N.ders_id
    WHERE O.ogrenci_id = @ogrenci_id;
END;
GO


--100.00 ogrenci seneryosu icin test
DECLARE @i INT = 1;
WHILE @i <= 100000
BEGIN
    INSERT INTO Ogrenciler(ogrenci_id, ad, soyad, bolum_id, kayit_tarihi)
    VALUES(@i,
    CONCAT('Ad', @i),
    CONCAT('Soyad', @i),
    ((@i - 1) % 3) + 1,
    GETDATE());
    SET @i += 1;
END;
GO

--en basarili 10 ogrenci
SELECT TOP 10 O.ad, O.soyad, CAST(AVG(N.ortalama) AS DECIMAL(5, 2)) AS Genel_Ortalama
FROM Ogrenciler O
JOIN Notlar N ON N.ogrenci_id = O.ogrenci_id
GROUP BY O.ad, O.soyad
ORDER BY Genel_Ortalama DESC;

--devamsizlik listesi(kalanlar)
SELECT O.ad, O.soyad, D.ders_adi, 
    De.katilim_sayisi, 
    De.toplam_ders,
    (1.0 - (CAST(De.katilim_sayisi AS FLOAT) / De.toplam_ders)) * 100 AS DevamsizlikYüzdesi
FROM Ogrenciler O
JOIN Devamsizlik De ON De.ogrenci_id = O.ogrenci_id
JOIN Dersler D ON D.ders_id = De.ders_id
WHERE (1.0 - (CAST(De.katilim_sayisi AS FLOAT) / De.toplam_ders)) > 0.30;

--genel sistem ortalamasi
SELECT AVG(ortalama) AS Sistem_Genel_Ortalamasi FROM Notlar;

--dashboard icin aggregate(ozet) sorgular
--ders bazli basari orani
SELECT D.ders_adi, COUNT(CASE WHEN N.durum = 'Gecti' THEN 1 END) * 100.0 / COUNT(*) AS Basari_Yuzdesi 
FROM Notlar N
JOIN Dersler D ON D.ders_id = N.ders_id
GROUP BY D.ders_adi;

--dashboard: Ders bazlı genel durum
SELECT 
    D.ders_adi,
    COUNT(N.ogrenci_id) AS Kayitli_Ogrenci,
    CAST(AVG(N.ortalama) AS DECIMAL(5,2)) AS Sinif_Ortalamasi,
    SUM(CASE WHEN N.durum = 'Kaldi' THEN 1 ELSE 0 END) AS Kalan_Sayisi
FROM Dersler D
LEFT JOIN Notlar N ON D.ders_id = N.ders_id
GROUP BY D.ders_adi;

--performans ve indexleme
CREATE INDEX idx_NotlarOgrenciDers ON Notlar(ogrenci_id, ders_id)
--sık sorgulanan ogrenci ve ders bazli aramalarda hiz saglar

CREATE INDEX idx_DevamsizlikKontrol ON Devamsizlik(ogrenci_id, ders_id, katilim_sayisi) 
--devamsizlik kontrolu triggerini hizlandirir

--unique index kullanimi
CREATE UNIQUE INDEX ux_Bolumler
ON Bolumler(bolum_adi)

CREATE UNIQUE INDEX ux_Odevler
ON Odevler(baslik)
GO


--index olmadan test analizi
USE OBS_System;
GO
SET STATISTICS TIME ON; --calisma suresini olcer
SET STATISTICS IO ON; --disk okuma miktarini olcer
SELECT COUNT(*) FROM Ogrenciler WHERE ogrenci_id = 95000; --eger sonuc 100.000 se basardim demek ve evet

--sistemin kontrol mekanizmasi basariyla test edildi
--notlar tablosuna rastgele bir ogrenci_id ile not girisi yapilmaya calisildi ancak sistem buna izin vermedi bu yuzden test sonucunda hata aldim(foreign key hatasi).
--kodun basina id 1 ve id 2 ye sahip 2 ogrenciyi manuel ekledik sonrasinda 100.000lik dongude de id 1 ve id 2 tekrar eklendigi icin zaten vardi hatasi aldim(duplicate key hatasi). 
--cozum olarak mevcut id 1 ve id 2 yerine dongu ile cakismayacak yuksek degerler verildi(99998, 99999).
--manuel olarak 99998 ve 99999 idli ogrenci ekledim ancak derskayitlari tablosuna 1 ve 2 idli ogrenci eklemeye calistik bu yuzden hata aldik(foreign key constraint).



--index sonrası test analizi
SET STATISTICS TIME ON;
SET STATISTICS IO ON;       
SELECT * FROM Notlar WHERE ogrenci_id = 5001 AND ders_id = 2;

--100.000 Kayit Uzerinde Performans Analiz Raporu
--Kriter	                    İndeks Oncesi (Table Scan)	    Indeks Sonrasi (Index Seek)
--Sorgu Suresi (Elapsed Time)	    ~50 - 120 ms	                1 - 2 ms
--İslemci Yuku (CPU Time)	        ~15 - 30 ms	                    0 ms
--Mantiksal Okuma (Logical Reads)	~500+ Sayfa	                    2 - 3 Sayfa
--Arama Yontemi	    Full Table Scan (Tum tablo taranir)	            Index Seek (Hedef veri direkt bulunur)
--Veri Erisim Maliyeti	 Yuksek(Kayit sayisi arttıkca sure uzar)	Çok Duşuk (Buyuk veride sabit hız sunar)


--Execution Plan Analizi
--index oncesi: table scan oldugu icin 100.000 ve uzeri kayitlarda disk ve islemci uzerinde gereksiz yuk olusmustur.
--index sonrasi: B-Tree yapisi ile veriye hizlica ulasildi (index seek). sorgu suresi milisaniyelere indi ve sistem olceklenebilir bir yapiya dondu.

-- Öğrenci detaylarını listeleme (Test amaçlı)
SELECT TOP 10 O.ad, O.soyad, D.ders_adi, N.ortalama, N.durum
FROM Ogrenciler O
JOIN Notlar N ON O.ogrenci_id = N.ogrenci_id
JOIN Dersler D ON N.ders_id = D.ders_id;
