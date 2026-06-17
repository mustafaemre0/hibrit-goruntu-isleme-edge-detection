#include "edge_detection.h"
#include <stdlib.h>
#include <math.h>

/**
 * Sobel Edge Detection - Pointer aritmetigi kullanan saf C uygulamasi.
 *
 * Algoritma:
 * 1. BGR girdiyi gri tona donustur
 * 2. 3x3 Sobel kernellerini (Gx, Gy) konvolusyonla uygula
 * 3. Gradyan buyuklugunu hesapla: sqrt(gx^2 + gy^2)
 * 4. Sonucu [0, 255] araligina sinirla
 */

/* Sobel kernelleri */
static const int sobel_gx[3][3] = {
    {-1,  0,  1},
    {-2,  0,  2},
    {-1,  0,  1}
};

static const int sobel_gy[3][3] = {
    {-1, -2, -1},
    { 0,  0,  0},
    { 1,  2,  1}
};

/**
 * Tek bir BGR pikseli parlaklik formulu ile gri tona donusturur.
 * gray = 0.299*R + 0.587*G + 0.114*B
 * OpenCV BGR sirasi kullanir: *(ptr+0)=B, *(ptr+1)=G, *(ptr+2)=R
 */
static unsigned char bgr_to_gray(unsigned char *pixel) {
    double blue  = (double)(*(pixel + 0));
    double green = (double)(*(pixel + 1));
    double red   = (double)(*(pixel + 2));
    double gray  = 0.114 * blue + 0.587 * green + 0.299 * red;
    return (unsigned char)(gray + 0.5); /* yuvarla */
}

EXPORT void sobel_filter(unsigned char *input, unsigned char *output, int width, int height, int channels) {
    int x, y;
    int kx, ky;
    unsigned char *gray_buffer;
    unsigned char *gray_ptr;
    unsigned char *out_ptr;
    unsigned char *in_ptr;

    /* Adim 1: Gecici gri ton tamponu ayir */
    gray_buffer = (unsigned char *)malloc(width * height * sizeof(unsigned char));
    if (gray_buffer == NULL) {
        return;
    }

    /* Adim 2: Tum goruntuyu pointer aritmetigiyle gri tona donustur */
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            in_ptr = input + (y * width + x) * channels;
            gray_ptr = gray_buffer + (y * width + x);
            *gray_ptr = bgr_to_gray(in_ptr);
        }
    }

    /* Adim 3: Sobel filtresini konvolusyonla uygula */
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            out_ptr = output + (y * width + x);

            /* Sinir pikselleri: 0 ata (3x3 kernel uygulanamaz) */
            if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
                *out_ptr = 0;
                continue;
            }

            /* Sobel kernelleri ile konvolusyon */
            int sum_gx = 0;
            int sum_gy = 0;

            for (ky = -1; ky <= 1; ky++) {
                for (kx = -1; kx <= 1; kx++) {
                    unsigned char pixel_val = *(gray_buffer + ((y + ky) * width + (x + kx)));
                    sum_gx += pixel_val * sobel_gx[ky + 1][kx + 1];
                    sum_gy += pixel_val * sobel_gy[ky + 1][kx + 1];
                }
            }

            /* Gradyan buyuklugu */
            double magnitude = sqrt((double)(sum_gx * sum_gx + sum_gy * sum_gy));

            /* [0, 255] araligina sinirla */
            if (magnitude > 255.0) {
                magnitude = 255.0;
            }

            *out_ptr = (unsigned char)(magnitude + 0.5);
        }
    }

    /* Adim 4: Gecici tamponu serbest birak */
    free(gray_buffer);
}
