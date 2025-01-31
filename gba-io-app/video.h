#pragma once

#define CAPTURE_DXGI

#include <functional>
#include <thread>
#include <wrl.h>
#ifdef CAPTURE_GDI
#elif defined(CAPTURE_DX9)
#include <d3d9.h>
#pragma comment(lib, "d3d9.lib")
#elif defined(CAPTURE_DXGI)
#include <d3d11.h>
#pragma comment(lib, "d3d11.lib")
#include <dxgi1_2.h>
#endif

using Microsoft::WRL::ComPtr;

class VideoCapture {
public:
	VideoCapture(std::function<void(uint8_t*, size_t, uint8_t*, size_t)> videoFeedProcessor);
	~VideoCapture();
private:
	static const size_t GBA_SCREEN_WIDTH = 240;
	static const size_t GBA_SCREEN_HEIGHT = 160;
	static const size_t GBA_VIDEO_FEED_VRAM_SIZE = 0x18000; // 96KB
	static const size_t VIDEO_FEED_BG_MODE_OFFSET = 0x18400;
	static const size_t GBA_VIDEO_FEED_FRAME_SIZE = 0x20000; // = 0x18000 Bytes + 0x400 Bytes + 1 Byte + 0x7BFF Padding Bytes

	std::function<void(uint8_t*, size_t, uint8_t*, size_t)> videoFeedProcessor;
#ifdef CAPTURE_GDI
	HDC hScreenDC;
	HDC hMemoryDC;
	HBITMAP hBitmap;
	BITMAPINFO bmi;
#elif defined(CAPTURE_DX9)
	IDirect3D9* d3d;
	D3DDISPLAYMODE mode;
	D3DPRESENT_PARAMETERS parameters;
	IDirect3DDevice9* device;
	IDirect3DSurface9* surface;
	D3DLOCKED_RECT lock;
#elif defined(CAPTURE_DXGI)
	ComPtr<ID3D11Device> device;
	ComPtr<ID3D11DeviceContext> deviceContext;
	ComPtr<IDXGIOutputDuplication> outputDuplication;
	ComPtr<ID3D11Texture2D> tex2dStaging;
	D3D11_TEXTURE2D_DESC desc;
#endif
	int screenWidth, screenHeight;
	uint8_t* RawPixels4x8;

	uint8_t* GBAVideoFeedFrame;
	std::atomic<bool> Running;
	std::thread CaptureThread;
	void CaptureThreadFunction();
};
