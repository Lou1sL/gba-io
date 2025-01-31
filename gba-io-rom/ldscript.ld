
SECTIONS
{
    .video_feed ALIGN(4) : AT (0x09000000) {
        _video_feed_start = .;
        KEEP(fill.vram.o(.video_feed))
        _video_feed_end = .;
    }
    .sound_feed ALIGN(4) : AT (0x09E00000) {
        _sound_feed_start = .;
        KEEP(fill.fifo.o(.sound_feed))
        _sound_feed_end = .;
    }
}
