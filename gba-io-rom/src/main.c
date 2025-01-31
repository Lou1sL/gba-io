
#include "gba_video.h"
#include "gba_systemcalls.h"
#include "gba_input.h"
#include "gba_interrupt.h"
#include "gba_dma.h"
#include "gba_sound.h"
#include "gba_timers.h"
#include "fade.h"

#include <stdlib.h>
#include <string.h>

// From libtonc, see https://www.coranac.com/tonc/text/swi.htm
#define REG_IFBIOS                     (*(volatile uint16_t *)(REG_BASE - 0x0008))

/* PC -> GBA, use Cartridge ROM address space (total available: 0x2000000) */
#define VIDEO_FEED_ADDRESS             0x09000000
#define VIDEO_FEED_VRAM_SIZE           0x18000 // 96KB
#define VIDEO_FEED_PALETTE_RAM_SIZE    0x400 // 1KB
#define VIDEO_FEED_BG_MODE_OFFSET      0x18400
#define VIDEO_FEED_FRAME_SIZE          0x20000 // = 0x18000 Bytes + 0x400 Bytes + 1 Byte + 0x7BFF Padding Bytes
#define VIDEO_FEED_SIZE                0x00E00000 // = VIDEO_FEED_FRAME_SIZE * 112 Frames

#define SOUND_L_FEED_ADDRESS           0x09E00000
#define SOUND_R_FEED_ADDRESS           0x09F00000
#define SOUND_FEED_DMA_BATCH_SIZE      0x8000 // Max 0xFFFF
#define SOUND_FEED_SIZE                0x00100000 // = 0x8000 Bytes * 32 Batches

/* GBA -> PC, use Cartridge SRAM address space (total available: 0x10000) */
#define FRAME_COUNTER                  (*(volatile uint32_t *)0x0E000000)
#define VIDEO_FEED_OCCUPYING_INDEX     (*(volatile uint16_t *)0x0E000008)
#define SOUND_FEED_OCCUPYING_INDEX     (*(volatile uint16_t *)0x0E00000A)
#define KEY_FEED_RAW                   (*(volatile uint16_t *)0x0E000010)
#define KEY_FEED_PROCESSED_UP          (*(volatile uint16_t *)0x0E000018)
#define KEY_FEED_PROCESSED_DOWN        (*(volatile uint16_t *)0x0E00001A)
#define KEY_FEED_PROCESSED_HELD        (*(volatile uint16_t *)0x0E00001C)
#define KEY_FEED_PROCESSED_DOWNREPEAT  (*(volatile uint16_t *)0x0E00001E)

uint32_t CurrentSoundFeedOffset = 0;
uint32_t CurrentVideoFeedOffset = 0;

void VblankInterrupt()
{
    FRAME_COUNTER += 1;
    scanKeys();
}

// Priority: DMA0 > DMA1&2 > DMA3 > Interrupt
// We use DMA1&2 for transferring sounds instead of using the Interrupts,
// which will cause sound stuttering due to heavy DMA3 usage in this program
void Timer1Interrupt()
{
    CurrentSoundFeedOffset += SOUND_FEED_DMA_BATCH_SIZE;
    if(CurrentSoundFeedOffset >= SOUND_FEED_SIZE) CurrentSoundFeedOffset -= SOUND_FEED_SIZE;
    SOUND_FEED_OCCUPYING_INDEX = CurrentSoundFeedOffset / SOUND_FEED_DMA_BATCH_SIZE;

    REG_DMA1CNT &= ~DMA_ENABLE;
    REG_DMA1SAD = SOUND_L_FEED_ADDRESS + CurrentSoundFeedOffset;
    REG_DMA1CNT |= DMA_ENABLE;

    REG_DMA2CNT &= ~DMA_ENABLE;
    REG_DMA2SAD = SOUND_R_FEED_ADDRESS + CurrentSoundFeedOffset;
    REG_DMA2CNT |= DMA_ENABLE;

    REG_IF |= IRQ_TIMER1; // Acknowledge Timer1 Interrupt
    REG_IFBIOS |= IRQ_TIMER1;
}
void DMA3Interrupt()
{
    REG_IF |= IRQ_DMA3;
    REG_IFBIOS |= IRQ_DMA3;
}

int main(void)
{
    irqInit();
    irqSet(IRQ_VBLANK, VblankInterrupt);
    irqEnable(IRQ_VBLANK);


    /** PC -> SOUND FEED -> GBA */
    // http://www.belogic.com/gba/index.php
    // Gameboy Advance Programming Manual v1.1.pdf Page 101
    REG_SOUNDCNT_L = 0; // Disable SND1~4
    REG_SOUNDCNT_H = 0b0001001000001111; // DSFIFOB -> R & Timer0, DSFIFOA -> L & Timer0, DSA & B Full Range, Prohibit SND1~4 Synth
    REG_SOUNDCNT_X = 0b10000000; // Enable DS, Halt SND1~4
    SETSNDRES(0b01);

    // Gameboy Advance Programming Manual v1.1.pdf Page 113
    REG_DMA1SAD = SOUND_L_FEED_ADDRESS;
    REG_DMA1DAD = (uint32_t)&REG_FIFO_A;
    uint32_t REG_DMA1CNT_L = 0; // The word-count register setting is disabled in direct-sound FIFO transfer mode
    uint32_t REG_DMA1CNT_H = 0b1011011001000000; // DMA on, IRQ off, start on DSFIFO request, 32-bit, repeat, source addr inc, dest addr fixed(due to DSFIFO)
    REG_DMA1CNT = (REG_DMA1CNT_H << 16) | REG_DMA1CNT_L;

    REG_DMA2SAD = SOUND_R_FEED_ADDRESS;
    REG_DMA2DAD = (uint32_t)&REG_FIFO_B;
    REG_DMA2CNT = 0b1011011000000000 << 16; // Same as above

    // Gameboy Advance Programming Manual v1.1.pdf Page 106
    REG_TM1CNT_L = 0xFFFF - SOUND_FEED_DMA_BATCH_SIZE; // 0xFFFF - the number of samples to play
    REG_TM1CNT_H = 0b11000100; // Enable Timer1 & IRQ, cascade from Timer0

    // Gameboy Advance Programming Manual v1.1.pdf Page 157
    REG_IE |= IRQ_TIMER1; // Enable Timer1 Interrupt
    REG_IME = 0b1; // Interrupt Master Enabled
    // The above two lines are equivalent to irqEnable(IRQ_TIMER1)
    irqSet(IRQ_TIMER1, Timer1Interrupt);

    // Gameboy Advance Programming Manual v1.1.pdf Page 106
    // The CPU frequency is 16.78MHz ~= 0x1000000Hz, the sound frequency we use is 65.536kHz ~= 0x10000Hz
    REG_TM0CNT_L = 0xFEFF; // 0xFFFF - round(cpuFreq/playbackFreq)
    REG_TM0CNT_H = 0b10000000; // Enable Timer0


    REG_IE |= IRQ_DMA3; // Enable DMA3 Interrupt
    irqSet(IRQ_DMA3, DMA3Interrupt);

    while (1)
    {
        VBlankIntrWait();


        /** PC -> VIDEO FEED -> GBA */
        CurrentVideoFeedOffset += VIDEO_FEED_FRAME_SIZE;
        if(CurrentVideoFeedOffset >= VIDEO_FEED_SIZE) CurrentVideoFeedOffset -= VIDEO_FEED_SIZE;
        if(~REG_KEYINPUT & KEY_L) CurrentVideoFeedOffset = 0;
        if(~REG_KEYINPUT & KEY_R) CurrentVideoFeedOffset = VIDEO_FEED_FRAME_SIZE;
        VIDEO_FEED_OCCUPYING_INDEX = CurrentVideoFeedOffset / VIDEO_FEED_FRAME_SIZE;

        const u8 *VideoFeed = (const u8 *)(VIDEO_FEED_ADDRESS + CurrentVideoFeedOffset);
        const u8 BGMode = *(u8 *)(VIDEO_FEED_ADDRESS + CurrentVideoFeedOffset + VIDEO_FEED_BG_MODE_OFFSET);

        SetMode(BGMode | BG2_ON);

        // The slowest VRAM copy method
        // memcpy((u16 *)VRAM, (u8 *)VideoFeed, VIDEO_FEED_VRAM_SIZE);
        // A lot faster than memcpy, but still slow
        // asm volatile (
        //     "mov r0, %[dest]\n"
        //     "mov r1, %[src]\n"
        //     "mov r2, %[size]\n"
        //     "1:\n"
        //     "ldmia r1!, {r3-r6}\n"
        //     "stmia r0!, {r3-r6}\n"
        //     "sub r2, r2, #16\n" // 4 registers * 4 bytes per register
        //     "bgt 1b\n"
        //     :
        //     : [dest] "r" (VRAM), [src] "r" (VideoFeed), [size] "r" (VIDEO_FEED_VRAM_SIZE)
        //     : "r0", "r1", "r2", "r3", "r4", "r5", "r6", "memory"
        // );
        REG_DMA3SAD = (u32)VideoFeed;
        REG_DMA3DAD = (u32)VRAM;
        REG_DMA3CNT = (0b1100010000000000 << 16) | (VIDEO_FEED_VRAM_SIZE >> 2); // Same as above
        IntrWait(0, IRQ_DMA3);

        // In BG bitmap modes(which are 3,4 and 5), only mode 4 uses palette RAM
        if(BGMode == MODE_4)
        {
            // SetPalette() is too slow
            // SetPalette((u16 *)(VideoFeed + VIDEO_FEED_VRAM_SIZE));
            // The dmaCopy() wrapper does not support IRQ
            // dmaCopy((u16 *)(VideoFeed + VIDEO_FEED_VRAM_SIZE), (u16 *)BG_COLORS, VIDEO_FEED_PALETTE_RAM_SIZE);
            REG_DMA3SAD = (u32)(VideoFeed + VIDEO_FEED_VRAM_SIZE);
            REG_DMA3DAD = (u32)BG_COLORS;
            uint32_t REG_DMA3CNT_L = VIDEO_FEED_PALETTE_RAM_SIZE >> 2; // Maximum 0x40000 (256KB) in 32-bit mode
            uint32_t REG_DMA3CNT_H = 0b1100010000000000; // DMA on, IRQ on, start immediately, 32-bit, non-repeat, source addr inc, dest addr inc
            REG_DMA3CNT = REG_DMA3CNT_H << 16 | REG_DMA3CNT_L;
            IntrWait(0, IRQ_DMA3);
        }


        /** GBA -> KEY FEED -> PC */
        KEY_FEED_RAW = REG_KEYINPUT;
        KEY_FEED_PROCESSED_UP = keysUp();
        KEY_FEED_PROCESSED_DOWN = keysDown();
        KEY_FEED_PROCESSED_HELD = keysHeld();
        KEY_FEED_PROCESSED_DOWNREPEAT = keysDownRepeat();
    }
}
