#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <avrt.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <functional>
#include <chrono>
#include <thread>
#include <sstream>
#include <iomanip>
#include <atomic>
#include <audioclientactivationparams.h>

#pragma comment(lib, "avrt.lib")

#include "sound.h"

SoundCapture::SoundCapture(std::function<void(uint8_t*, uint8_t*, size_t)> soundFeedProcessor)
	: soundFeedProcessor(soundFeedProcessor) {

	HRESULT hr;

	hr = CoInitialize(NULL);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " CoInitialize failed");

	hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator), (void**)&pEnumerator);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " CoCreateInstance failed");

	hr = pEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &pDevice);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " GetDefaultAudioEndpoint failed");

	AUDIOCLIENT_ACTIVATION_PARAMS audioclientActivationParams = {};
	audioclientActivationParams.ActivationType = AUDIOCLIENT_ACTIVATION_TYPE_PROCESS_LOOPBACK;
	audioclientActivationParams.ProcessLoopbackParams.ProcessLoopbackMode = PROCESS_LOOPBACK_MODE_EXCLUDE_TARGET_PROCESS_TREE;
	audioclientActivationParams.ProcessLoopbackParams.TargetProcessId = 1;

	PROPVARIANT activateParams = {};
	activateParams.vt = VT_BLOB;
	activateParams.blob.cbSize = sizeof(audioclientActivationParams);
	activateParams.blob.pBlobData = (BYTE*)&audioclientActivationParams;

	hr = pDevice->Activate(__uuidof(IAudioClient), CLSCTX_ALL, &activateParams, (void**)&pAudioClient);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " Device Activate failed");

	m_CaptureFormat.wFormatTag = WAVE_FORMAT_PCM;
	m_CaptureFormat.nChannels = 2;
	m_CaptureFormat.nSamplesPerSec = 65536;
	m_CaptureFormat.wBitsPerSample = 8;
	m_CaptureFormat.nBlockAlign = m_CaptureFormat.nChannels * m_CaptureFormat.wBitsPerSample / 8;
	m_CaptureFormat.nAvgBytesPerSec = m_CaptureFormat.nSamplesPerSec * m_CaptureFormat.nBlockAlign;

	hr = pAudioClient->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_LOOPBACK | AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM, 200000, 0, &m_CaptureFormat, nullptr);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " AudioClient Initialize failed");

	hr = pAudioClient->GetService(__uuidof(IAudioCaptureClient), (void**)&pCaptureClient);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " GetService failed");

	hr = pAudioClient->Start();
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " AudioClient Start failed");

	DMA1_FIFO = new uint8_t[GBA_SOUND_FEED_FRAME_SIZE];
	std::fill(DMA1_FIFO, DMA1_FIFO + GBA_SOUND_FEED_FRAME_SIZE, 0);
	DMA2_FIFO = new uint8_t[GBA_SOUND_FEED_FRAME_SIZE];
	std::fill(DMA2_FIFO, DMA2_FIFO + GBA_SOUND_FEED_FRAME_SIZE, 0);

	Running = true;
	CaptureThread = std::thread(&SoundCapture::CaptureThreadFunction, this);
}

SoundCapture::~SoundCapture() {
	Running = false;
	CaptureThread.join();
	delete[] DMA1_FIFO;
	delete[] DMA2_FIFO;

	pAudioClient->Stop();
	pCaptureClient->Release();
	pAudioClient->Release();
	pDevice->Release();
	pEnumerator->Release();
	CoUninitialize();
}



void SoundCapture::CaptureThreadFunction() {

	std::cout << "Capturing audio..." << std::endl;

	HRESULT hr;
	UINT32 packetLength = 0;
	// This frame means a single sample that contains all the channels
	// Completly different thing from the sound feed frame of the sound buffer for the GBA I/O project
	UINT32 numFramesAvailable;
	BYTE* pData;
	DWORD captureFlags;
	size_t copiedSize = 0;

	while (Running) {

		hr = pCaptureClient->GetNextPacketSize(&packetLength);
		if (FAILED(hr)) {
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " GetNextPacketSize failed") << std::endl;
			return;
		}

		// When there's no application that's playing audio, the packet length will stuck at 0
		while (packetLength != 0) {
			hr = pCaptureClient->GetBuffer(&pData, &numFramesAvailable, &captureFlags, 0, 0);
			if (FAILED(hr)) {
				std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " GetBuffer failed") << std::endl;
				return;
			}

			for (UINT32 i = 0; i < numFramesAvailable; ++i) {
				if (copiedSize < GBA_SOUND_FEED_FRAME_SIZE) {
					DMA1_FIFO[copiedSize] = pData[i * m_CaptureFormat.nBlockAlign] - 128;
					DMA2_FIFO[copiedSize] = pData[i * m_CaptureFormat.nBlockAlign + 1] - 128;
					copiedSize++;
				}
				if (copiedSize == GBA_SOUND_FEED_FRAME_SIZE) {
					soundFeedProcessor(DMA1_FIFO, DMA2_FIFO, GBA_SOUND_FEED_FRAME_SIZE);
					copiedSize = 0;
				}
			}

			hr = pCaptureClient->ReleaseBuffer(numFramesAvailable);
			if (FAILED(hr)) {
				std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " ReleaseBuffer failed") << std::endl;
				return;
			}

			hr = pCaptureClient->GetNextPacketSize(&packetLength);
			if (FAILED(hr)) {
				std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " GetNextPacketSize failed") << std::endl;
				return;
			}
		}
	}
}
