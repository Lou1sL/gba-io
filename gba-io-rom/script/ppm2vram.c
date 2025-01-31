
// This is for testing GBA BG MODE_3
// gcc -o script\\ppm2vram script\\ppm2vram.c && script\\ppm2vram script\\fill.pbm && del script\\ppm2vram.exe
// Note: If you are editing the image in Photoshop, use Image > Mode > RGB, 8bit per channel, then save as PBM

#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define VIDEO_FEED_VRAM_SIZE           0x18000
#define VIDEO_FEED_PALETTE_RAM_SIZE    0x400
#define VIDEO_FEED_FRAME_SIZE          0x20000 // = 0x18000 Bytes + 0x400 Bytes + 1 Byte + 0x7BFF Padding Bytes
#define VIDEO_FEED_SIZE                0x00E00000 // = VIDEO_FEED_FRAME_SIZE * 112 Frames

int DecodePBM(uint8_t *PBMBuffer, uint16_t *VRAM)
{
    // https://en.wikipedia.org/wiki/Netpbm
    char *token;
    
    token = strtok((char *)PBMBuffer, "\n");
    if (strcmp(token, "P6") != 0) {
        printf("Invalid PPM file\n");
        return -1;
    }
    token = strtok(NULL, "\n");
    while (token[0] == '#') token = strtok(NULL, "\n");
    int width = atoi(token);
    token = strtok(NULL, "\n");
    int height = atoi(token);
    if(width > 240 || height > 160)
    {
        printf("Image is too big, max 240w*160h\n");
        return -1;
    }
    token = strtok(NULL, "\n");
    int maxval = atoi(token);
    if (maxval != 255) {
        printf("Invalid PPM file\n");
        return -1;
    }

    int pixelCount = width * height;
    uint8_t *pixelData = token + strlen(token) + strlen("\n");

    for (int i = 0; i < pixelCount; i++) {
        VRAM[i] = (pixelData[i * 3] >> 3) | ((pixelData[i * 3 + 1] >> 3) << 5) | ((pixelData[i * 3 + 2] >> 3) << 10);
    }

    return 0;
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "rb");
    if (!file) {
        perror("Error opening the input file");
        return 1;
    }
    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    fseek(file, 0, SEEK_SET);
    uint8_t *fileData = (uint8_t *)malloc(fileSize);
    fread(fileData, 1, fileSize, file);
    fclose(file);

    uint8_t *VRAM = (uint8_t *)malloc(VIDEO_FEED_VRAM_SIZE);
    memset(VRAM, 0, VIDEO_FEED_VRAM_SIZE);
    uint16_t *PaletteRAM = (uint16_t *)malloc(VIDEO_FEED_PALETTE_RAM_SIZE);
    memset(PaletteRAM, 0, VIDEO_FEED_PALETTE_RAM_SIZE);
    int result = DecodePBM(fileData, (uint16_t *)VRAM);
    if (result != 0) return result;

    FILE *outputFile = fopen(".\\data\\fill.vram.bin", "wb");
    for(int32_t i = 0; i < VIDEO_FEED_SIZE; i += VIDEO_FEED_FRAME_SIZE)
    {
        fprintf(stdout, "0x%05x... \n", i);
        fwrite(VRAM, VIDEO_FEED_VRAM_SIZE, 1, outputFile);
        fwrite(PaletteRAM, VIDEO_FEED_PALETTE_RAM_SIZE, 1, outputFile);
        const uint8_t MODE_3 = 3;
        fwrite(&MODE_3, sizeof(uint8_t), 1, outputFile);
        const uint8_t ZERO = 0;
        fwrite(&ZERO, (VIDEO_FEED_FRAME_SIZE - VIDEO_FEED_VRAM_SIZE - VIDEO_FEED_PALETTE_RAM_SIZE - 1), 1, outputFile);
    }
    fclose(outputFile);

    free(fileData);
    free(PaletteRAM);
    free(VRAM);
    
    fprintf(stdout, "Done\n");
}
