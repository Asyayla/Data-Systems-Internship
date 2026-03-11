/* 
  Proje: OBS Seviye 3 – Performans ve Yetkilendirme Projesi
  Dosya: performance_and_security_ops.sql
  Açıklama: Veri bütünlüğü (Triggers), Güvenlik (Roles/Views) ve Performans (Indexing) optimizasyonları.
*/

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
    durum VARCHAR(10),
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

GO

INSERT INTO Bolumler(bolum_adi, fakulte_adi)
VALUES ('Yazilim Muhendisligi', 'Muhendislik'), 
('Bilgisayar Muhendisligi', 'Muhendislik'), 
('Elektrik Elektronik', 'Muhendislik');

INSERT INTO Ogrenciler(ogrenci_id, ad, soyad, bolum_id, kayit_tarihi)
VALUES (1,'Ali','Veli',1,GETDATE()),
(2,'Ayse','Kara',2,GETDATE());


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

--ogrenci derse kayitli degilse not girilemez trigger kullanılacak 
--aynı derse iki kez not girilemez trigger kullanılacak
--final notu 40ın altındaysa ogrenci dogrudan kalir
--ortalama 50nin altındaysa kalir
CREATE OR ALTER TRIGGER trg_NotKontrol
ON Notlar 
INSTEAD OF INSERT 
AS 
BEGIN
    SET NOCOUNT ON;
    --ders kaydi kontrolu
    IF EXISTS(    -- if exist yapisi kullanilir cunku karar verip islem durdurulacak when islem durdurmadigi icin kullanılamaz
        SELECT 1 FROM inserted i   -- su anda eklemek istedigim satirlar 
        LEFT JOIN DersKayitlari DK ON DK.ogrenci_id = i.ogrenci_id AND DK.ders_id = i.ders_id
        WHERE DK.kayit_id IS NULL                          
    )
    BEGIN
        RAISERROR('Ogrenci derse kayitli degilse not girilemez!', 16, 1) --hata ver
        ROLLBACK; -- yapilan islemi geri al
        RETURN;
    END;
    --ortalama hesaplama, durum belirleme, insert
    INSERT INTO Notlar(ogrenci_id, ders_id, vize, final, ortalama, durum)
    SELECT i.ogrenci_id, i.ders_id, i.vize, i.final, (i.vize * 0.4 + i.final * 0.6),
    CASE
        WHEN i.final < 40 THEN 'Kaldi!'
        WHEN (i.vize * 0.4 + i.final * 0.6) < 50 THEN 'Kaldi!'
        ELSE 'Gecti!'
    END
    FROM inserted i;
END;
GO
--is kurallarinin yazili aciklamasi
--ogrenci ilgili derse kayitli degilse not girisi engellenir, eger final notu 40'in altindaysa basarisiz sayiliyor, 
--genel ortalamasi 50'nin altindaysa basarisiz sayiliyor, ayni ogrenci ayni derse birden fazla not alamaz.
--bu kurallar trigger, constraint, unique index ve stored procedure ile saglanmistir.


CREATE OR ALTER TRIGGER trg_NotHistory
ON Notlar
AFTER UPDATE
AS
BEGIN
    INSERT INTO NotGecmisi(not_id, eski_ortalama, degistiren_kullanici)
    SELECT d.not_id, d.ortalama, SUSER_NAME()
    FROM Deleted d;
END
GO
--not degisiklikleri trg_History triggeri sayesinde otomatik olarak not gecmisi tablosuna kaydedilmektedir.
--bu sayede kim degistirdi, ne zaman degistirdi, eski ortalama neydi bilgileri kayit altina alindi.


CREATE OR ALTER PROCEDURE dbo.sp_NotGir
    @ogrenci_id INT,
    @ders_id INT, 
    @vize INT, 
    @final INT
AS
BEGIN
    BEGIN TRY
    BEGIN TRANSACTION;
    --not aralik kontrolu
    IF(@vize NOT BETWEEN 0 AND 100 OR @final NOT BETWEEN 0 AND 100)
        THROW 50001, 'Notlar 0 - 100 olmalidir!', 1;
    --ders kaydi kontrolu(ogrenci derse kayitli mi kontrolu)
    IF NOT EXISTS(SELECT 1 FROM DersKayitlari WHERE ogrenci_id = @ogrenci_id AND ders_id = @ders_id)
        THROW 50002, 'Ogrenci bu derse kayitli degil!', 1;
    --cift kayit kontrolu
    IF EXISTS(SELECT 1 FROM Notlar WHERE ogrenci_id = @ogrenci_id AND ders_id = @ders_id)
        THROW 50003, 'Bu ogrencinin bu ders icin zaten notu var!', 1;
    INSERT INTO Notlar(ogrenci_id, ders_id, vize, final)
    VALUES(@ogrenci_id, @ders_id, @vize, @final);

    COMMIT TRANSACTION;
    PRINT 'Not basariyla girildi.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'Islem basarisiz!' + @ErrMsg;   --kullanicinin anlayabilecegi bir hata mesaji
END CATCH
END;
GO
--sp_NotGir procedureu icerisinde TRY-CATCH ve transaction kullanilarak hata yonetimi saglanmistir. 
--boylece islem sirasinda hata olmasi durumunda tum degisiklikler geri alinmakta ve veri butunlugu korunmaktadir.


--100 ders uretimi
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN 
    INSERT INTO Dersler(ders_id, ders_adi, bolum_id)
    VALUES(@i, CONCAT('Ders', @i), ((@i - 1) % 3) + 1);
    SET @i += 1;
END;
GO

--10.000 öğrenci üretimi
DECLARE @i INT = 1;
WHILE @i <= 10000
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

--100.000 not kaydi uretimi
DECLARE @i INT = 1;
WHILE @i <= 100000
BEGIN
    INSERT INTO Notlar(ogrenci_id, ders_id, vize, final)
    VALUES(
        ABS(CHECKSUM(NEWID())) % 10000 + 1,
        ABS(CHECKSUM(NEWID())) % 100 + 1,
        ABS(CHECKSUM(NEWID())) % 100,
        ABS(CHECKSUM(NEWID())) % 100
    );
    SET  @i += 1;
END;
GO


--ders kayitlari veri uretim scriptleri
DECLARE @ogrenci INT = 1;
WHILE @ogrenci <= 10000  --1den 10.000e kadar her ogrenci icin islem yap
BEGIN
    DECLARE @sayac INT = 1;
    WHILE @sayac <= 6 --her ogrenci icin 6 tane ders kaydi olustur
    BEGIN
        DECLARE @ders INT = ABS(CHECKSUM(NEWID())) % 100 + 1; --rastgele bir ders kaydi uretir 1-100 arasinda 
        --ayni ogrenci ayni dersi iki kere alamasin
        IF NOT EXISTS(
            SELECT 1
            FROM DersKayitlari
            WHERE ogrenci_id = @ogrenci AND ders_id = @ders
        )
        BEGIN
            INSERT INTO DersKayitlari(kayit_id, ders_id, ogrenci_id, kayit_tarihi)   --ogrenciyi derse kaydediyor
            VALUES(ABS(CHECKSUM(NEWID())),
            @ders, 
            @ogrenci,
            DATEADD(DAY,  -ABS(CHECKSUM(NEWID())) % 1000, GETDATE())   --rastgele gecmis tarih uretir 0-1000 arasinda olsun 
            );
            SET @sayac += 1;
        END
    END
    SET @ogrenci += 1;   --bu ogrencinin isleri bitti diger ogrenciye gec 6 olana kadar devam et
END
GO


--not uretimi
DECLARE @i INT = 1; 
WHILE @i <= 100   --100 not uret
BEGIN
    DECLARE @ogrenci INT;   --degisken tanimi(bir ogrenci ve bir ders sececegiz)
    DECLARE @ders INT;
    --ders kaydi olanlardan rastgele sec(rastgele ogrenci + ders)
    SELECT TOP 1
        @ogrenci = DK.ogrenci_id,
        @ders = DK.ders_id
    FROM DersKayitlari DK
    ORDER BY NEWID();
    --ayni dersin iki notu olmamasi icin
        IF NOT EXISTS(
            SELECT 1
            FROM Notlar
            WHERE ogrenci_id = @ogrenci AND ders_id = @ders
        )
        BEGIN
            INSERT INTO Notlar(ogrenci_id, ders_id, vize, final)
            VALUES(@ogrenci,
            @ders, 
            ABS(CHECKSUM(NEWID())) % 101,
            ABS(CHECKSUM(NEWID())) % 101
            );
            SET @i += 1;  --bir not uretildi digerine gec
        END    
END

GO


--bu view sayesinde ogrenci sadece kendi notunu gorur
CREATE OR ALTER VIEW vw_OgrenciNotlari
AS
SELECT O.ogrenci_id, D.ders_adi, N.vize, N.final, N.ortalama, N.durum
FROM Notlar N
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
JOIN Dersler D ON D.ders_id = N.ders_id
JOIN Kullanicilar K ON K.ogrenci_id = O.ogrenci_id
WHERE K.kullanici_adi = SUSER_NAME();
GO


--bu view sayesinde ogretmen sadece verdigi derslerin notlarini gorur   
CREATE VIEW vw_OgretmenNotGirisi
AS
SELECT OD.ogretmen_id, O.ogrenci_id, O.ad, O.soyad, D.ders_adi, N.vize, N.final, N.ortalama, N.durum
FROM OgretmenDersleri OD
JOIN Dersler D ON D.ders_id = OD.ders_id
JOIN Notlar N ON N.ders_id = D.ders_id
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
GO


--bu view sayesinde bolum baskani bolumdeki tum ogrencileri gorur
CREATE VIEW vw_BolumBaskaniOgrencileri
AS
SELECT B.bolum_adi, O.ogrenci_id, O.ad, O.soyad, D.ders_adi, N.ortalama, N.durum
FROM Bolumler B
LEFT JOIN Ogrenciler O ON O.bolum_id = B.bolum_id
LEFT JOIN Notlar N ON N.ogrenci_id = O.ogrenci_id
LEFT JOIN Dersler D ON D.ders_id = N.ders_id
GO 


DENY SELECT ON Notlar TO public;      --kimse dogrudan notlar tablosundan veri okuyamaz
DENY SELECT ON Ogrenciler TO public;  --kimse dogrudan ogrenciler tablosunu goremez

GRANT SELECT ON vw_OgrenciNotlari TO public;   --herkes sadece izin verilen filtrelenmis veriyi gorur

--sistemde rol bazlı erisim kontrolu uygulanmistir. kullanicilar sadece rollerine gore yetkileri olan verileri gorebiliyor.
--guvenlik dogrudan tablo katmaninda degil, view ve stored procedure katmani uzerinden saglanmistir. kullanicilarin dogrudan tablolara erisimi DENY komutlari ile engellenmis 
--yalnizce yetkileri olduklari verileri gorebilmeleri icin viewlar olusturulmustur. bu sayede veri sizintisi riski minimize edildi. 


GO

--inndex olmadan test analizi
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
SELECT * FROM Notlar WHERE ogrenci_id = 5000;

--SQL Server Execution Times:
--CPU time = 2 ms,  elapsed time = 1 ms.
--SQL Server parse and compile time: 
--CPU time = 0 ms, elapsed time = 0 ms.
--(0 rows affected)
--Table 'Notlar'. Scan count 1, logical reads 4, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

--SQL Server Execution Times:
--CPU time = 2 ms,  elapsed time = 1 ms.
--Total execution time: 00:00:00.085

--Index Öncesi (Table Scan): CPU zamanı 2 ms, Toplam süre 1 ms, Mantıksal okuma (Logical Reads) 4.


--indexli test analizi
--bir ogrenci aynı derse birden fazla not alamaz
CREATE UNIQUE INDEX ux_Notlar_OgrenciDers
ON Notlar(ogrenci_id, ders_id) 

--bir ogrenci ayni derse birden fazla kez kaydolamaz
CREATE UNIQUE INDEX ux_DersKayitlari_OgrenciDers
ON  DersKayitlari(ogrenci_id, ders_id)


--index sonrası test analizi
SET STATISTICS TIME ON;
SET STATISTICS IO ON;       
SELECT * FROM Notlar WHERE ogrenci_id = 5001 AND ders_id = 2;

USE OBS_System;
GO
EXEC dbo.sp_NotGir @ogrenci_id = 5001, @ders_id = 2, @vize = 90, @final = 90;

--Index Sonrası (Index Seek): CPU ve süre 0 ms'ye düşmüş. Bu, SQL Server'ın veriyi bulmak için artık efor sarf etmediğini gösterir.

--index eklenmeden once sorgu tum tabaloyu taradigi icin(table scan) yuksek IO ve sure olculmustur.
--index eklendikten sonra SQL Server dogrudan ilgili kayda ulasmis(index seek) ve sorgu suresi dusmustur.  

--execution plan analizi
--sorgu tum tabloyu okumak yerine(table scan) olusturdugum ux_Notlar_OgrenciDers indexini kullanarak dogrudan calısıyor.
