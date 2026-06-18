# Proje Kurulum Adimlari (Windows)

Bu dokuman, projeyi nasil kurdugumu ve `setup.ps1` icine eklenen yeni adimlari ozetler.

## 1) Kurulumu calistirma

PowerShell script policy engeli olursa su komutla kurulum calistirilir:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Normal kosulda proje klasorunde su komut da yeterlidir:

```powershell
.\setup.ps1
```

## 2) Kurulumda yapilanlar

`setup.ps1` artik su adimlari uygular:

1. Python ve gcc araclarini kontrol eder.
2. Proje icinde `.venv` sanal ortamini hazirlar (varsayilan).
3. `requirements.txt` paketlerini bu ortama kurar.
4. C kodunu derleyip `build/edge_detection.dll` dosyasini olusturur.
5. DLL yukleme smoke testini calistirir.

## 3) Neden `.venv` eklendi?

Kurulum sirasinda daha once olusmus bir `.venv` ortaminin, eski/silinmis Python yoluna bagli kalmasi nedeniyle calistirma hatasi gorulebilir.

Guncellenen script:

- bozuk `.venv` tespit ederse otomatik silip yeniden olusturur,
- saglikliysa mevcut `.venv`'i tekrar kullanir.

## 4) Kurulumdan sonra calistirma

```powershell
.\.venv\Scripts\python.exe src/main.py
```

## 5) Venv kullanmak istemezsen

Global Python ile kurulum icin:

```powershell
.\setup.ps1 -NoVenv
```

Bu durumda paketler global Python ortamina kurulur.
