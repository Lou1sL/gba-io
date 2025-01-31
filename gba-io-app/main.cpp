
//#define GENERATE_GBA_IO_ROM

#include <Windows.h>
#include <iostream>
#include <fstream>
#include <csignal>

#include "key.h"
#include "sound.h"
#include "video.h"
#include "usb.h"

constexpr size_t GBA_VIDEO_FEED_SIZE = 0x00E00000; // = VIDEO_FEED_FRAME_SIZE * 112 Frames
constexpr size_t GBA_SOUND_FEED_SIZE = 0x00100000; // = 0x8000 Bytes * 32 Batches

#ifdef GENERATE_GBA_IO_ROM
std::ofstream vFile;
std::ofstream sFile;
#else
USB* usb;
#endif
VideoCapture* videoCapture;
SoundCapture* soundCapture;
KeyReceive* keyReceive;

static void INTERRUPT_HANDLER(int) {
	std::cout << "Exiting..." << std::endl;
	delete videoCapture;
	delete soundCapture;
	delete keyReceive;
#ifdef GENERATE_GBA_IO_ROM
	vFile.close();
	sFile.close();
#else
	delete usb;
#endif
	exit(0);
}

int wmain(int argc, wchar_t* argv[]) {

	signal(SIGINT, INTERRUPT_HANDLER);
	signal(SIGTERM, INTERRUPT_HANDLER);
	signal(SIGABRT, INTERRUPT_HANDLER);
	signal(SIGFPE, INTERRUPT_HANDLER);
	signal(SIGILL, INTERRUPT_HANDLER);
	signal(SIGSEGV, INTERRUPT_HANDLER);

	try {

#ifdef GENERATE_GBA_IO_ROM
		vFile = std::ofstream("..\\gba-io-rom\\data\\fill.vram.bin", std::ios::binary);
		size_t v = 0;
		sFile = std::ofstream("..\\gba-io-rom\\data\\fill.fifo.bin", std::ios::binary);
		size_t s = 0;
		size_t k = 0;
#else
		usb = new USB();
		usb->WriteCode("..\\gba-io-rom\\target\\gba-io-rom.gba");
		std::this_thread::sleep_for(std::chrono::milliseconds(1000));
#endif

#ifdef NDEBUG
		std::cout << "The capture will start in 10 seconds..." << std::endl;
		std::this_thread::sleep_for(std::chrono::milliseconds(10000));
		ShowWindow(GetConsoleWindow(), SW_MINIMIZE);
#endif

		videoCapture = new VideoCapture([&](uint8_t* raw, size_t rawSize, uint8_t* feed, size_t feedSize) {
#ifdef GENERATE_GBA_IO_ROM
			if (v >= GBA_VIDEO_FEED_SIZE) return;
			vFile.write(reinterpret_cast<const char*>(feed), feedSize);
			v += feedSize;
#else
			usb->WriteVBuffer(feed);
#endif
		});

		soundCapture = new SoundCapture([&](uint8_t* dma1, uint8_t* dma2, size_t feedSize) {
#ifdef GENERATE_GBA_IO_ROM
			if (s >= GBA_SOUND_FEED_SIZE) return;
			sFile.seekp(s, std::ios::beg);
			sFile.write(reinterpret_cast<const char*>(dma1), feedSize);
			sFile.seekp(GBA_SOUND_FEED_SIZE + s, std::ios::beg);
			sFile.write(reinterpret_cast<const char*>(dma2), feedSize);
			s += feedSize;
#else
			usb->WriteSLAndSRBuffer(dma1, dma2);
#endif
		});

		keyReceive = new KeyReceive({
			{ GBA_KEY::KEY_A, { INPUT_TYPE::KEYBOARD, EVENTF::KEY_KEYDOWN, VK::A, {0, 0} } },
			{ GBA_KEY::KEY_B, { INPUT_TYPE::KEYBOARD, EVENTF::KEY_KEYDOWN, VK::B, {0, 0} } },
			{ GBA_KEY::KEY_SELECT, { INPUT_TYPE::KEYBOARD, EVENTF::KEY_KEYDOWN, VK::C, {0, 0} } },
			{ GBA_KEY::KEY_START, { INPUT_TYPE::KEYBOARD, EVENTF::KEY_KEYDOWN, VK::D, {0, 0} } },
			{ GBA_KEY::KEY_RIGHT, { INPUT_TYPE::MOUSE, EVENTF::MOUSE_MOVE, VK::NONE, {10, 0} } },
			{ GBA_KEY::KEY_LEFT, { INPUT_TYPE::MOUSE, EVENTF::MOUSE_MOVE, VK::NONE, {-10, 0} } },
			{ GBA_KEY::KEY_UP, { INPUT_TYPE::MOUSE, EVENTF::MOUSE_MOVE, VK::NONE, {0, -10} } },
			{ GBA_KEY::KEY_DOWN, { INPUT_TYPE::MOUSE, EVENTF::MOUSE_MOVE, VK::NONE, {0, 10} } },
			{ GBA_KEY::KEY_R, { INPUT_TYPE::MOUSE, EVENTF::MOUSE_RIGHTDOWN, VK::NONE, {0, 0} } },
			{ GBA_KEY::KEY_L, { INPUT_TYPE::MOUSE, EVENTF::MOUSE_LEFTDOWN, VK::NONE, {0, 0} } }
			}, [&]() -> uint16_t {
#ifdef GENERATE_GBA_IO_ROM
			k += 16;
			if ((k / 1000) % 2 == 0) {
				return ~(static_cast<uint16_t>(GBA_KEY::KEY_LEFT) | static_cast<uint16_t>(GBA_KEY::KEY_UP));
			}
			else {
				return ~(static_cast<uint16_t>(GBA_KEY::KEY_RIGHT) | static_cast<uint16_t>(GBA_KEY::KEY_DOWN));
			}
#else
			return usb->ReadKeyAndStatus()->keyFeedRaw;
#endif
		});

#ifdef GENERATE_GBA_IO_ROM
		while (v < GBA_VIDEO_FEED_SIZE || s < GBA_SOUND_FEED_SIZE) {
			std::cout << "v: " << v << " / " << GBA_VIDEO_FEED_SIZE << ", s: " << s << " / " << GBA_SOUND_FEED_SIZE << std::endl;
			std::this_thread::sleep_for(std::chrono::milliseconds(1000));
		}
		vFile.close();
		sFile.close();
#else
		while (true) {
			std::this_thread::sleep_for(std::chrono::milliseconds(1000));
		}
		delete usb;
#endif
		delete keyReceive;
		delete soundCapture;
		delete videoCapture;
	}
	catch (std::exception& e) {
		std::cout << "Exiting Error Reason: " << e.what() << std::endl;
		return 1;
	}
	return 0;
}
