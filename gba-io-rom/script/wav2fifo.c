
// gcc -o script\\wav2fifo script\\wav2fifo.c && script\\wav2fifo script\\fill.wav && del script\\wav2fifo.exe

#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define SOUND_FEED_SIZE 0x00100000

// http://soundfile.sapp.org/doc/WaveFormat/
// https://learn.microsoft.com/en-us/previous-versions/dd757713(v=vs.85)?redirectedfrom=MSDN
typedef struct
{
    uint32_t chunk0Id; // Should be 'RIFF'
    uint32_t chunk0Size;
    uint32_t chunk0Format; // Should be 'WAVE'
    uint32_t chunk1Id; // Should be 'fmt '
    uint32_t chunk1Size; // Should be 16 for PCM
    uint16_t chunk1Format; // Should be 1 for PCM
    uint16_t chunk1NumChannels; // Only supports 2 for stereo, 1 is for mono
    uint32_t chunk1SampleRate; // Only supports 65536
    uint32_t chunk1ByteRate; // Only supports 131072 = SampleRate * NumChannels * BitsPerSample / 8
    uint16_t chunk1BlockAlign; // Only supports 2 = NumChannels * BitsPerSample / 8
    uint16_t chunk1BitsPerSample; // Only supports 8
    uint32_t chunk2Id; // Should be 'data'
    uint32_t chunk2Size; // NumSamples * NumChannels * BitsPerSample / 8
} __attribute__((packed)) wav_header;

int DecodePCMWAV(uint8_t *WAVBuffer, int8_t *DMA1_FIFO, int8_t *DMA2_FIFO, uint32_t *NumSamples)
{
    wav_header *header = (wav_header *)WAVBuffer;
    if(
        (header->chunk0Id != 0x46464952) || 
        (header->chunk0Format != 0x45564157) || 
        (header->chunk1Id != 0x20746D66) || 
        (header->chunk1Size != 16) ||
        (header->chunk1Format != 1) ||
        (header->chunk1NumChannels != 2) ||
        (header->chunk1SampleRate != 65536) ||
        (header->chunk1ByteRate != 131072) ||
        (header->chunk1BlockAlign != 2) ||
        (header->chunk1BitsPerSample != 8) ||
        (header->chunk2Id != 0x61746164)
    )
    {
        printf("Invalid PCM WAV file\n");
        return -1;
    }
    uint32_t singleChannelSize = header->chunk2Size / header->chunk1NumChannels;
    uint32_t singleChannelSizeCapped = singleChannelSize;
    if(singleChannelSize > SOUND_FEED_SIZE)
    {
        printf("Sound file is too large, excessing part will be truncated\n");
        singleChannelSizeCapped = SOUND_FEED_SIZE;
    }

    *NumSamples = singleChannelSizeCapped / header->chunk1BitsPerSample * 8;
    printf("NumSamples: %d\n", *NumSamples);

    int32_t copyCount = *NumSamples;

    for (int32_t i = 0; i < copyCount; i++)
    {
        uint8_t l = WAVBuffer[sizeof(wav_header) + i * 2];
        uint8_t r = WAVBuffer[sizeof(wav_header) + i * 2 + 1];
        DMA1_FIFO[i] = (int8_t)(l - 128);
        DMA2_FIFO[i] = (int8_t)(r - 128);
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
        perror("Error opening file");
        return 1;
    }
    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    fseek(file, 0, SEEK_SET);
    uint8_t *wav = (uint8_t *)malloc(fileSize);
    fread(wav, 1, fileSize, file);
    fclose(file);
    
    int8_t *DMA1_FIFO = (int8_t *)malloc(SOUND_FEED_SIZE);
    memset(DMA1_FIFO, 0, SOUND_FEED_SIZE);
    int8_t *DMA2_FIFO = (int8_t *)malloc(SOUND_FEED_SIZE);
    memset(DMA2_FIFO, 0, SOUND_FEED_SIZE);
    uint32_t NumSamples = 0;
    int result = DecodePCMWAV(wav, DMA1_FIFO, DMA2_FIFO, &NumSamples);
    if (result != 0) return result;

    FILE *outputFile = fopen(".\\data\\fill.fifo.bin", "wb");
    fwrite(DMA1_FIFO, SOUND_FEED_SIZE, 1, outputFile);
    fwrite(DMA1_FIFO, SOUND_FEED_SIZE, 1, outputFile);
    fclose(outputFile);
    free(wav);

    free(DMA1_FIFO);
    free(DMA2_FIFO);
}
