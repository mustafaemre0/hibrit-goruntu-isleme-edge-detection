"""
Hibrit Goruntu Isleme ve Edge Detection Hatti
Python (OpenCV) + C (ctypes uzerinden Sobel filtresi)

Kamera goruntusu uzerinde anlik kenar tespiti yapar.
Filtreleme tamamen C'deki pointer aritmetigi ve dongulerle yapilir.
"""

import ctypes
import numpy as np
import cv2
import os
import sys
import platform


def load_library():
    """C paylasimli kutuphanesini yukle."""
    if platform.system() == "Windows":
        lib_name = "edge_detection.dll"
    else:
        lib_name = "edge_detection.so"

    # Kutuphane yolu: proje kok dizini/build/
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    lib_path = os.path.join(project_root, "build", lib_name)

    if not os.path.exists(lib_path):
        print(f"HATA: Kutuphane bulunamadi: {lib_path}")
        print("Lutfen once 'make' komutu ile C kodunu derleyin.")
        sys.exit(1)

    lib = ctypes.CDLL(lib_path)

    # Fonksiyon imzasini tanimla
    lib.sobel_filter.argtypes = [
        ctypes.POINTER(ctypes.c_ubyte),  # girdi
        ctypes.POINTER(ctypes.c_ubyte),  # cikti
        ctypes.c_int,                     # genislik
        ctypes.c_int,                     # yukseklik
        ctypes.c_int                      # kanal sayisi
    ]
    lib.sobel_filter.restype = None

    return lib


def apply_sobel(lib, frame):
    """
    Frame'i C Sobel filtresine gonder ve edge map'i dondur.

    Parametreler:
        lib: ctypes kutuphane nesnesi
        frame: OpenCV BGR frame'i (numpy array, uint8)

    Donus:
        edge_map: Gri ton edge detection sonucu (numpy array, uint8)
    """
    height, width, channels = frame.shape

    # Girdi frame'in bellekte surekli (contiguous) oldugunu garanti et
    if not frame.flags['C_CONTIGUOUS']:
        frame = np.ascontiguousarray(frame)

    # Cikti buffer'i olustur (tek kanal, grayscale)
    output = np.zeros((height, width), dtype=np.uint8)

    # NumPy array'leri ctypes pointer'a donustur
    input_ptr = frame.ctypes.data_as(ctypes.POINTER(ctypes.c_ubyte))
    output_ptr = output.ctypes.data_as(ctypes.POINTER(ctypes.c_ubyte))

    # C fonksiyonunu cagir
    lib.sobel_filter(input_ptr, output_ptr, width, height, channels)

    return output


def main():
    """Ana program: Kamera yakalama ve edge detection dongusu."""
    print("Hibrit Edge Detection Pipeline baslatiliyor...")
    print("Cikis icin 'q' tusuna basin.")
    print("-" * 50)

    # C kutuphanesini yukle
    lib = load_library()
    print("[OK] C kutuphanesi yuklendi.")

    # Kamerayi ac (Windows'ta DirectShow arkaucu daha iyi calisir)
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    if not cap.isOpened():
        # Yedek secenek: varsayilan arkaucu
        cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("HATA: Kamera acilamadi!")
        sys.exit(1)

    # Kamera ayarlari
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    # Kameranin isinmasi icin ilk 30 frame'i at (pozlama ayari)
    print("[...] Kamera isinmasi bekleniyor...")
    for _ in range(30):
        cap.read()
    print("[OK] Kamera acildi.")

    # Pencere olustur
    window_name = "Hybrid Edge Detection Pipeline"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)

    while True:
        # Kullanici pencereyi X ile kapattiysa donguden cik.
        if cv2.getWindowProperty(window_name, cv2.WND_PROP_VISIBLE) < 1:
            break

        ret, frame = cap.read()
        if not ret:
            print("HATA: Frame okunamadi!")
            break

        # C Sobel filtresini uygula
        edge_map = apply_sobel(lib, frame)

        # Edge map'i 3 kanala cevir (yan yana gosterim icin)
        edge_bgr = cv2.cvtColor(edge_map, cv2.COLOR_GRAY2BGR)

        # Orijinal ve edge sonucunu yan yana birlestir
        combined = np.hstack((frame, edge_bgr))

        # Ekranda goster
        cv2.imshow(window_name, combined)

        # 'q' tusuna basilirsa cik
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # Kaynaklari serbest birak
    cap.release()
    cv2.destroyAllWindows()
    print("\nProgram sonlandirildi.")


if __name__ == "__main__":
    main()
