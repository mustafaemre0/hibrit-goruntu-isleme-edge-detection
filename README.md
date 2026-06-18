# Hibrit Goruntu Isleme ve Edge Detection Hatti

Bu proje, kamera goruntusu uzerinde anlik kenar tespiti yapan hibrit bir hattir.

- Python (OpenCV): Kamera yakalama, goruntu birlestirme ve gosterim
- C: Sobel edge detection algoritmasinin dusuk seviyede uygulanmasi
- ctypes: Python ile C kutuphanesi arasindaki bellek seviyesinde kopru

## Duyuru Maddelerine Uyum Ozeti

Bu README ve ek teknik rapor dosyasi, final duyurusundaki basliklarla uyumludur:

1. Projenin amaci ve tanimi: Gercek zamanli edge detection isleminin hibrit mimari ile gerceklenmesi
2. Sistem mimarisi ve akis mantigi: Python tarafinda I/O, C tarafinda hesaplama
3. Teknik detaylar ve kod yapisi: Pointer aritmetigi, fonksiyon yapisi, ctypes imza tanimlari
4. Karsilasilan zorluklar ve cozumler: Kurulum, arac bagimliliklari ve .venv yonetimi

Ayrintili ve akademik dilde hazirlanan teknik rapor icin: [docs/TEKNIK_RAPOR.md](docs/TEKNIK_RAPOR.md)

## Sistem Mimarisi

```text
Python (src/main.py)
     1) OpenCV ile kameradan BGR frame al
     2) Frame pointer'ini ctypes ile C fonksiyonuna gonder
     3) C'den gelen edge map'i al
     4) Orijinal + edge sonucunu yan yana goster

C (src/edge_detection.c)
     1) BGR -> Grayscale donusumu
     2) 3x3 Sobel (Gx, Gy) konvolusyonu
     3) sqrt(gx^2 + gy^2) ile gradyan buyuklugu
     4) [0, 255] araligina clamp
```

## Gereksinimler

- Python 3.8 veya uzeri
- GCC (Windows icin MinGW veya setup.ps1 tarafindan kurulan WinLibs)
- requirements.txt icindeki Python paketleri (OpenCV, NumPy)

## Kurulum

Kurulum adimlari README icerigine entegre edilmistir ve ayrica detayli dokuman olarak da verilmistir.

- Referans: [docs/KURULUM_ADIMLARI.md](docs/KURULUM_ADIMLARI.md)

Hizli kurulum (Windows PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Normal kosulda:

```powershell
.\setup.ps1
```

Kurulum scripti su adimlari otomatik uygular:

1. Python ve gcc kontrolu
2. Proje icinde .venv ortami olusturma (varsayilan)
3. requirements.txt paket kurulumu
4. C kodunu derleyip build/edge_detection.dll olusturma
5. DLL yukleme smoke testini calistirma

Not: .venv bozuksa script ortami temizleyip yeniden olusturur.

## Calistirma

Venv ile:

```powershell
.\.venv\Scripts\python.exe src/main.py
```

NoVenv secenegiyle kurulum yaptiysaniz:

```powershell
python src/main.py
```

Arayuzde solda orijinal kamera goruntusu, sagda Sobel edge detection cikisi gosterilir.
Cikis icin q tusuna basin.

## Proje Yapisi

```text
opencv/
     src/
          edge_detection.c
          edge_detection.h
          main.py
     build/
     docs/
          KURULUM_ADIMLARI.md
          TEKNIK_RAPOR.md
     setup.ps1
     Makefile
     requirements.txt
     README.md
```

## Teknik Detaylar

### Sobel Kernelleri

```text
Gx = | -1  0  1 |    Gy = | -1 -2 -1 |
           | -2  0  2 |         |  0  0  0 |
           | -1  0  1 |         |  1  2  1 |
```

### Pointer Aritmetigi

```c
unsigned char *in_ptr = input + (y * width + x) * channels;
unsigned char pixel_val = *(gray_buffer + ((y + ky) * width + (x + kx)));
```

### Python-C Baglantisi (ctypes)

```python
lib.sobel_filter.argtypes = [
          ctypes.POINTER(ctypes.c_ubyte),
          ctypes.POINTER(ctypes.c_ubyte),
          ctypes.c_int,
          ctypes.c_int,
          ctypes.c_int,
]
```

## Kaynak Kod ve Rapor Baglantilari

- GitHub: https://github.com/mustafaemre0/hibrit-goruntu-isleme-edge-detection
- Teknik rapor: [docs/TEKNIK_RAPOR.md](docs/TEKNIK_RAPOR.md)
- Kurulum referansi: [docs/KURULUM_ADIMLARI.md](docs/KURULUM_ADIMLARI.md)

## Lisans

Bu proje egitim amaclidir ve YBS102 Bilgisayar Programlama dersi final projesi kapsaminda hazirlanmistir.
