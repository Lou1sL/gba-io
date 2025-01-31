
// This is for testing GBA BG MODE_4
// gcc -o script\\bmp2vram script\\bmp2vram.c && script\\bmp2vram script\\fill.bmp && del script\\bmp2vram.exe
// Note: If you are editing the image in Photoshop, use Image > Mode > Indexed Color, 8bit per channel, then save as Windows 8-bit depth format BMP.

#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define VIDEO_FEED_VRAM_SIZE           0x18000
#define VIDEO_FEED_PALETTE_RAM_SIZE    0x400
#define VIDEO_FEED_FRAME_SIZE          0x20000 // = 0x18000 Bytes + 0x400 Bytes + 1 Byte + 0x7BFF Padding Bytes
#define VIDEO_FEED_SIZE                0x00E00000 // = VIDEO_FEED_FRAME_SIZE * 112 Frames

// http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm
// https://en.wikipedia.org/wiki/BMP_file_format
typedef struct
{
    // Header
    uint16_t    signature; // Should be 'BM'
    uint32_t    fileSize; // Doesn't matter
    uint32_t    reserved; // Unused
    uint32_t    dataOffset; // Doesn't matter
    // InfoHeader
    uint32_t    infoHeaderSize; // Should be 40
    uint32_t    width;
    uint32_t    height;
    uint16_t    planes; // Should be 1
    uint16_t    bitsPerPixel; // Only supports 8
    uint32_t    compression; // Only supports 0
    uint32_t    imageSize; // Doesn't matter
    uint32_t    xPixelsPerMeter; // Doesn't matter
    uint32_t    yPixelsPerMeter; // Doesn't matter
    uint32_t    colorsUsed; // Only supports 256, since it's 256 when the bitsPerPixel is 8
    uint32_t    colorsImportant; // Should be 0
    uint8_t     colorTable[4 * 256]; // Only supports 4(r,g,b,reserved) * 256, since it's 4 * colorsUsed
} __attribute__((packed)) bmp_header;

int DecodeBMP(uint8_t *BMPBuffer, uint8_t *VRAM, uint16_t *PaletteRAM)
{
    bmp_header *header = (bmp_header *)BMPBuffer;
    if(
        (header->signature != 0x4D42) || 
        (header->infoHeaderSize != 40) ||
        (header->planes != 1) ||
        (header->bitsPerPixel != 8) ||
        (header->compression != 0) ||
        // (header->colorsUsed != 256) || // It's 0 when I try to export BMP with Photoshop hmmm...
        (header->colorsImportant != 0)
    )
    {
        printf("Invalid BMP file\n");
        return -1;
    }
    if(header->width > 240 || header->height > 160)
    {
        printf("Image is too big, max 240w*160h\n");
        return -1;
    }

    // Copy palette to a GBA format of xbbbbbgggggrrrrr
    // https://ia600405.us.archive.org/9/items/game-boy-advance-programming-manual-v-1.35_202305/Game%20Boy%20Advance%20Programming%20Manual%20v1.35.pdf
    // P.g., 63
    for (int i = 0; i < 256; i++)
    {
        uint8_t r = header->colorTable[i * 4 + 2];
        uint8_t g = header->colorTable[i * 4 + 1];
        uint8_t b = header->colorTable[i * 4 + 0];
        uint16_t color = ((r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10));
        *(PaletteRAM++) = color;
    }

    int width = header->width;
    int height = header->height;
    int readSize = width * height;

    // The system maps pixels beginning with the bottom scan line of the rectangular region and ending with the top scan line.
    uint8_t *pixelData = BMPBuffer + sizeof(bmp_header);
    uint8_t *rotatedPixelData = (uint8_t *)malloc(readSize);
    for (int y = 0; y < height; y++) {
        memcpy(rotatedPixelData + y * width, pixelData + (height - 1 - y) * width, width);
    }
    memcpy(pixelData, rotatedPixelData, readSize);
    free(rotatedPixelData);

    // Copy pixel data to VRAM
    for (int i = 0; i < readSize; i++) {
        VRAM[i] = pixelData[i];
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
    int result = DecodeBMP(fileData, VRAM, PaletteRAM);
    if (result != 0) return result;

    FILE *outputFile = fopen(".\\data\\fill.vram.bin", "wb");
    for(int32_t i = 0; i < VIDEO_FEED_SIZE; i += VIDEO_FEED_FRAME_SIZE)
    {
        fprintf(stdout, "0x%05x... \n", i);
        fwrite(VRAM, VIDEO_FEED_VRAM_SIZE, 1, outputFile);
        fwrite(PaletteRAM, VIDEO_FEED_PALETTE_RAM_SIZE, 1, outputFile);
        const uint8_t MODE_4 = 4;
        fwrite(&MODE_4, sizeof(uint8_t), 1, outputFile);
        const uint8_t ZERO = 0;
        fwrite(&ZERO, (VIDEO_FEED_FRAME_SIZE - VIDEO_FEED_VRAM_SIZE - VIDEO_FEED_PALETTE_RAM_SIZE - 1), 1, outputFile);
    }
    fclose(outputFile);

    free(fileData);
    free(PaletteRAM);
    free(VRAM);

    fprintf(stdout, "Done\n");
}
