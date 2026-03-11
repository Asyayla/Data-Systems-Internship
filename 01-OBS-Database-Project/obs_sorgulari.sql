/*
  Proje: Öğrenci Bilgi Sistemi (OBS) Mini Raporlama Projesi
  Açıklama: Veritabanı şeması oluşturma, veri girişi ve çeşitli raporlama görevleri.
*/

-- 1. Veritabanı ve Tablo Oluşturma (DDL)
USE master;
GO
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
    ders_id INT FOREIGN KEY(ders_id) REFERENCES Dersler (ders_id),
    vize INT,
    final INT
);
GO

-- 2. Örnek Veri Girişi (DML)
INSERT INTO Bolumler(bolum_id, bolum_adi, fakulte_adi)
VALUES(1, 'Yazılım Mühendisliği', 'Mühendislik Fakültesi');

INSERT INTO Ogrenciler(ogrenci_id, ad, soyad, bolum_id, kayit_tarihi)
VALUES 
(100, 'Asya', 'Yayla', 1, '2022-09-17');

INSERT INTO Dersler(ders_id, ders_adi, bolum_id)
VALUES(50, 'Operating System', 1);

INSERT INTO Notlar(not_id, ogrenci_id, ders_id, vize, final)
VALUES(70, 100, 50, 70, 80);
GO

-- 3. Raporlama Görevleri (DQL)

-- Görev 1: Tüm öğrencilerin ad, soyad, bölüm ve fakülte bilgilerini listele
SELECT O.ad, O.soyad, B.bolum_adi, B.fakulte_adi
FROM Ogrenciler O
JOIN Bolumler B ON B.bolum_id = O.bolum_id;

-- Görev 2: Öğrencilerin aldıkları dersleri listele
SELECT O.ad, O.soyad, D.ders_adi
FROM Notlar N
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
JOIN Dersler D ON D.ders_id = N.ders_id;

-- Görev 3: Vize, final notları ve hesaplanmış ortalamayı göster
SELECT O.ad, O.soyad, D.ders_adi, N.vize, N.final, (N.vize * 0.4 + N.final * 0.6) AS ortalama
FROM Dersler D
JOIN Notlar N ON N.ders_id = D.ders_id
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id;

-- Görev 4: Bölümlere göre öğrenci sayılarını listele
SELECT B.bolum_adi, COUNT(*) AS ogrenci_sayisi
FROM Ogrenciler O
JOIN Bolumler B ON B.bolum_id = O.bolum_id
GROUP BY B.bolum_adi;

-- Görev 5: Her öğrencinin genel ortalamasını hesapla
SELECT O.ad, O.soyad, AVG(N.vize * 0.4 + N.final * 0.6) AS ortalama
FROM Notlar N
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
GROUP BY O.ad, O.soyad;

-- Görev 6: Ortalaması 50'den düşük olanları listele (Alt Sorgu ile)
SELECT * FROM (SELECT O.ad, O.soyad, AVG(N.vize * 0.4 + N.final * 0.6) AS ortalama
      FROM Notlar N
      JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
      GROUP BY O.ad, O.soyad) t 
WHERE ortalama < 50;

-- Görev 7: En yüksek ortalamaya sahip ilk öğrenciyi getir
SELECT TOP 1 O.ad, O.soyad, AVG(N.vize * 0.4 + N.final * 0.6) AS ortalama
FROM Notlar N
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
GROUP BY O.ad, O.soyad
ORDER BY ortalama DESC;

-- Görev 8: En fazla derse giren öğrenciyi bul
SELECT TOP 1 O.ad, O.soyad, N.ogrenci_id, COUNT(*) AS max_ders
FROM Notlar N
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
GROUP BY O.ad, O.soyad, N.ogrenci_id
ORDER BY max_ders DESC;

-- Görev 9: Geçti/Kaldı Durumu Belirleme (CASE WHEN)
SELECT O.ad, O.soyad, AVG(N.vize * 0.4 + N.final * 0.6) AS ortalama,
CASE 
    WHEN AVG(N.vize * 0.4 + N.final * 0.6) >= 50 THEN 'Geçti'
    ELSE 'Kaldı'
END AS Durum
FROM Notlar N
JOIN Ogrenciler O ON O.ogrenci_id = N.ogrenci_id
GROUP BY O.ad, O.soyad;
