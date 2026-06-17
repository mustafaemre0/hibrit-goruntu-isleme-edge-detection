#ifndef EDGE_DETECTION_H
#define EDGE_DETECTION_H

#ifdef _WIN32
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT
#endif

/**
 * Sobel kenar tespiti filtresi.
 * Girdi: Ham piksel dizisi olarak BGR goruntu (unsigned char).
 * Cikti: Gri ton edge map (tek kanal, width*height byte).
 *
 * @param input   Girdi goruntu verisi isaretcisi (BGR, 3 kanal)
 * @param output  Cikti edge map isaretcisi (grayscale, 1 kanal)
 * @param width   Goruntu genisligi (piksel)
 * @param height  Goruntu yuksekligi (piksel)
 * @param channels Girdideki kanal sayisi (BGR icin genelde 3)
 */
EXPORT void sobel_filter(unsigned char *input, unsigned char *output, int width, int height, int channels);

#endif /* EDGE_DETECTION_H */
