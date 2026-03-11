/* 
    Proje: Öğrenci Bilgi Sistemi (OBS) Gelişmiş Raporlama Projesi 
    Açıklama: Ders kayıt sistemi entegrasyonu, Stored Procedure, View yapıları ve gelişmiş başarı analizleri.
*/

USE master
GO 
IF EXISTS(SELECT * FROM sys.databases WHERE name = 'OBS_System')
BEGIN 
    ALTER DATABASE OBS_System SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OBS_System
END
GO


CREATE DATABASE OBS_System;
GO
USE OBS_System;
GO

CREATE TABLE Bolumler(
    bolum_id INT PRIMARY KEY,
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
    not_id INT PRIMARY KEY,
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    vize INT,
    final INT
);

CREATE TABLE DersKayitlari(
    kayit_id INT PRIMARY KEY,
    ogrenci_id INT FOREIGN KEY(ogrenci_id) REFERENCES Ogrenciler(ogrenci_id),
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler(ders_id),
    kayit_tarihi DATE
);


INSERT INTO Bolumler VALUES
(100, 'Yazılım Mühendisliği', 'Mühendislik Fakültesi'),
(101, 'Bilgisayar Mühendisliği', 'Mühendislik Fakültesi');

INSERT INTO Ogrenciler VALUES
(1, 'Asya', 'Yayla', 100, '2022-09-17'),
(2, 'Ayşe', 'Yılmaz', 101, '2023-09-17');

INSERT INTO Dersler VALUES
(50, 'Operating System', 100),
(51, 'Statistics', 101);

INSERT INTO Notlar VALUES
(200, 1, 50, 80, 90);

INSERT INTO DersKayitlari VALUES
(20, 1, 50, '2024-10-10'),
(21, 2, 51, '2024-11-11');


--3.1 ogrenci transkript raporu
DECLARE @ogrenci_id INT = 1; 
SELECT O.ad, O.soyad, B.bolum_adi, D.ders_adi,
    ISNULL(CAST(N.vize AS VARCHAR), '-') AS vize,
    ISNULL(CAST(N.final AS VARCHAR), '-') AS final,
CASE 
    WHEN N.vize IS NULL OR N.final IS NULL THEN 'NOT GIRILMEDI'
    WHEN (N.vize * 0.4 + N.final * 0.6) >= 50 THEN 'GECTI'
    ELSE 'KALDI'
END AS durum,
CASE 
    WHEN N.vize IS NULL OR N.final IS NULL THEN NULL
    ELSE (N.vize * 0.4 + N.final * 0.6)
END AS ortalama
FROM Ogrenciler O
JOIN Bolumler B ON B.bolum_id = O.bolum_id
JOIN DersKayitlari DK ON DK.ogrenci_id = O.ogrenci_id
JOIN Dersler D ON D.ders_id = DK.ders_id  
LEFT JOIN Notlar N ON N.ogrenci_id = O.ogrenci_id AND N.ders_id = D.ders_id   --left join çünkü kayitli olmayan dersler de listelenecek  
WHERE O.ogrenci_id = @ogrenci_id
ORDER BY D.ders_id;


--3.2 bolum basari raporu
SELECT B.bolum_adi,
COUNT(DISTINCT O.ogrenci_id) AS toplam_ogrenci, --bolumdeki toplam ogrenci sayisi distinct ile tek defa sayiliyor 
COUNT(DISTINCT DK.ogrenci_id) AS ders_alan_ogrenci, --en az bir ders kaydi olan ogrenci sayisi, ders almayan sayilmaz
CAST(AVG(T.ogr_ortalama) AS DECIMAL(5, 2)) AS bolum_ortalama, --bolumdeki ogrencilerin genel not ortalamasi, T ogrencilerin bireysel ortalamalarinin olduğu alt sorgu, cast kusuratli sonuc ver 

MAX( -- en basarili ogrenciyi bulma kismi
    CASE 
        WHEN T.ogr_ortalama = M.max_ortalama --T.ogr_ortalama ogrencinin ortalamasi, M.max_ortalama bolumdeki en yuksek ortalama
        THEN O.ad + ' ' + O.soyad
    END
) AS en_basarili_ogrenci,
CAST(MAX(M.max_ortalama) AS DECIMAL(5, 2)) AS en_yuksek_ortalama --bolumun en yuksek ortalamasi 

FROM Bolumler B --her sey bolumden basliyor
LEFT JOIN Ogrenciler O ON O.bolum_id = B.bolum_id --bolum -> ogrencileri bagla, left join cunku ogrencisi olmayan bolum de listelensin
LEFT JOIN DersKayitlari DK ON DK.ogrenci_id = O.ogrenci_id --ogrenciler -> aldigi dersler 
LEFT JOIN( --her ogrencinin ortalamasini hesapliyor 
    SELECT ogrenci_id, AVG(vize * 0.4 + final * 0.6) AS ogr_ortalama
    FROM Notlar 
    GROUP BY ogrenci_id
) T ON T.ogrenci_id = O.ogrenci_id 

LEFT JOIN( --bolumun en yuksek ortalamasi
    SELECT O2.bolum_id, MAX(T2.ogr_ortalama) AS max_ortalama
    FROM Ogrenciler O2
    LEFT JOIN(
        SELECT ogrenci_id, AVG(vize * 0.4 + final * 0.6) AS ogr_ortalama
        FROM Notlar 
        GROUP BY ogrenci_id
    )T2 ON T2.ogrenci_id = O2.ogrenci_id
    GROUP BY O2.bolum_id
)M ON M.bolum_id = B.bolum_id

GROUP BY B.bolum_adi --her sey bolum bazli gruplaniyor
ORDER BY bolum_ortalama DESC; --en basarili bolum ustte

--3.3 ders bazli analiz
-- dersi alan ogrenci sayisi
--ortalama not
--basari orani(gecen ogrenci yuzdesi)
SELECT D.ders_adi, 
COUNT(DISTINCT DK.ogrenci_id) AS dersi_alan_ogrenci,
CAST(AVG(vize * 0.4 + final * 0.6) AS DECIMAL(5, 2)) AS ortalama_not,
CAST(SUM(
        CASE
            WHEN(vize * 0.4 + final * 0.6) >= 50 THEN 1
            ELSE 0
        END
    ) * 100.00 / NULLIF(COUNT(DISTINCT(DK.ogrenci_id)), 0) AS DECIMAL(5, 2)) AS basari_orani --gecen ogrenci/toplam ogrenci * 100

FROM Dersler D 
LEFT JOIN DersKayitlari DK ON DK.ders_id = D.ders_id
LEFT JOIN Notlar N ON N.ogrenci_id = DK.ogrenci_id  AND N.ders_id = DK.ders_id
GROUP BY D.ders_adi;

--4 stored procedure gorevi
--belirtilen bolumdeki ortalamasi verilen degerin uzerinde olan ogrencileri listelemelidir
--join group by, having case when kullanimi zorunlu 
--ogrenci bolum notlar 
GO
CREATE PROCEDURE sp_OgrenciBasariRaporu
    @bolum_id INT,
    @min_ortalama FLOAT
AS
BEGIN 
    SELECT O.ogrenci_id,
    O.ad,
    O.soyad,
    B.bolum_adi,
    AVG(N.vize * 0.4 + N.final * 0.6) AS ortalama,
    CASE 
        WHEN AVG(N.vize * 0.4 + N.final * 0.6) >= 50 THEN 'Gecti'
        ELSE 'Kaldi'
    END AS durum
    FROM Ogrenciler O
    JOIN Bolumler B ON B.bolum_id = O.bolum_id 
    JOIN Notlar N ON N.ogrenci_id = O.ogrenci_id
    WHERE O.bolum_id = @bolum_id
    GROUP BY 
        O.ogrenci_id, O.ad, O.soyad, B.bolum_adi
    HAVING AVG(N.vize * 0.4 + N.final * 0.6) >= @min_ortalama
END;
GO

--5 yazili olarak cevaplanacak sorular
--1 Final notu olmayan ogrenci gecebilir mi?
--SQL'de NULL ile yapılan matematiksel işlemlerin sonucu NULL döner. Not girişi tamamlanmadığı için hesaplanamaz

--2 Hic ders almayan ogrenci raporlara dahil edilmeli mi? 
--Bölüm Başarı Raporu"nda toplam öğrenci sayısında görünmeli ama "Ders Analizi"nde görünmemelidir.

--3 Ortalama hesaplamasi sorguda mi, view'da mi yapilmalidir? Neden?
-- view tekrar tekrar kullanilan sorgulari tek bir yerde toblo gibi tutup kullanmamizi sağlar. Bu sorgu için de ortalama hesaplama kismini view olarak yazarsak 
--kod tekrarı yapmadan kullanilabilir. Bu da sorgulari daha kisa, kullanılabilir ve efektif hale getirir. Yapilmalidir.


--6
--vw_OgrenciNotOrtalamalari adli bir view oluştur 
--notlar ve ders kayitlari tablolari için uygun indexlerin yazilmasi
CREATE VIEW vw_OgrenciNotOrtalamalari AS
SELECT O.ogrenci_id, O.ad, O.soyad, AVG(N.vize * 0.4 + N.final * 0.6) AS ortalama
FROM Ogrenciler O
JOIN Notlar N ON N.ogrenci_id = O.ogrenci_id
JOIN DersKayitlari DK ON DK.ogrenci_id = O.ogrenci_id AND DK.ders_id = N.ders_id
GROUP BY O.ogrenci_id, O.ad, O.soyad

CREATE INDEX IX_Notlar_OgrenciDers ON Notlar(ogrenci_id, ders_id);
CREATE INDEX IX_DersKayit_OgrenciDers ON DersKayitlari(ogrenci_id, ders_id);
--Index performans ve hizi maximize etmek icin kullanildi
