#pragma once

#include <mmdeviceapi.h>
#include <audioclient.h>
#include <functional>
#include <thread>
#include <atomic>


class SoundCapture {
public:
	SoundCapture(std::function<void(uint8_t*, uint8_t*, size_t)> soundFeedProcessor);
	~SoundCapture();
private:
	static const size_t GBA_SOUND_FEED_FRAME_SIZE = 0x10;

	std::function<void(uint8_t*, uint8_t*, size_t)> soundFeedProcessor;
	IMMDeviceEnumerator* pEnumerator;
	IMMDevice* pDevice;
	IAudioClient* pAudioClient;
	IAudioCaptureClient* pCaptureClient;
	WAVEFORMATEX m_CaptureFormat{};

	uint8_t* DMA1_FIFO;
	uint8_t* DMA2_FIFO;
	std::atomic<bool> Running;
	std::thread CaptureThread;
	void CaptureThreadFunction();
};
