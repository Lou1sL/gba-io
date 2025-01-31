#include <windows.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <functional>
#include <chrono>
#include <thread>
#include <atomic>
#include <array>
#include <wrl.h>

#include "video.h"

VideoCapture::VideoCapture(std::function<void(uint8_t*, size_t, uint8_t*, size_t)> videoFeedProcessor)
	: videoFeedProcessor(videoFeedProcessor) {

#ifdef CAPTURE_GDI

	SetProcessDPIAware();
	screenWidth = GetSystemMetrics(SM_CXSCREEN);
	screenHeight = GetSystemMetrics(SM_CYSCREEN);
	std::cout << "Screen resolution: " << screenWidth << "x" << screenHeight << std::endl;
	hScreenDC = GetDC(NULL);
	hMemoryDC = CreateCompatibleDC(hScreenDC);
	hBitmap = CreateCompatibleBitmap(hScreenDC, screenWidth, screenHeight);
	SelectObject(hMemoryDC, hBitmap);
	bmi = { 0 };
	bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bmi.bmiHeader.biWidth = screenWidth;
	bmi.bmiHeader.biHeight = -screenHeight; // Negative to indicate top-down bitmap
	bmi.bmiHeader.biPlanes = 1;
	bmi.bmiHeader.biBitCount = 32;
	bmi.bmiHeader.biCompression = BI_RGB;

#elif defined(CAPTURE_DX9)

	HRESULT hr;

	d3d = Direct3DCreate9(D3D_SDK_VERSION);

	hr = d3d->GetAdapterDisplayMode(D3DADAPTER_DEFAULT, &mode);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " GetAdapterDisplayMode failed");
	screenWidth = mode.Width;
	screenHeight = mode.Height;
	std::cout << "Display Mode: " << screenWidth << "x" << screenHeight << " " << mode.RefreshRate << "Hz" << std::endl;

	parameters = { 0 };
	parameters.Windowed = TRUE;
	parameters.BackBufferCount = 1;
	parameters.BackBufferHeight = screenHeight;
	parameters.BackBufferWidth = screenWidth;
	parameters.SwapEffect = D3DSWAPEFFECT_DISCARD;
	parameters.hDeviceWindow = NULL;
	hr = d3d->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, NULL, D3DCREATE_SOFTWARE_VERTEXPROCESSING, &parameters, &device);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " CreateDevice failed");

	hr = device->CreateOffscreenPlainSurface(screenWidth, screenHeight, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, &surface, nullptr);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " CreateOffscreenPlainSurface failed");

	hr = surface->LockRect(&lock, NULL, 0);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " LockRect failed");
	if (lock.Pitch != screenWidth * 4) throw std::runtime_error("Pitch is not equal to Width * 4");

	hr = surface->UnlockRect();
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " UnlockRect failed");

#elif defined(CAPTURE_DXGI)

	HRESULT hr;

	hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, D3D11_CREATE_DEVICE_BGRA_SUPPORT, nullptr, 0, D3D11_SDK_VERSION, &device, nullptr, &deviceContext);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " D3D11CreateDevice failed");

	ComPtr<IDXGIDevice>dxgiDevice;
	hr = device.As(&dxgiDevice);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " QueryInterface failed");

	ComPtr<IDXGIAdapter> dxgiAdapter;
	hr = dxgiDevice->GetAdapter(&dxgiAdapter);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " GetAdapter failed");

	ComPtr<IDXGIOutput> dxgiOutput;
	hr = dxgiAdapter->EnumOutputs(0, &dxgiOutput);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " EnumOutputs failed");

	ComPtr<IDXGIOutput1> dxgiOutput1;
	hr = dxgiOutput.As(&dxgiOutput1);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " QueryInterface failed");

	hr = dxgiOutput1->DuplicateOutput(device.Get(), &outputDuplication);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " DuplicateOutput failed");

	DXGI_OUTDUPL_DESC duplDesc;
	outputDuplication->GetDesc(&duplDesc);
	screenWidth = duplDesc.ModeDesc.Width;
	screenHeight = duplDesc.ModeDesc.Height;
	std::cout << "Display Mode: " << screenWidth << "x" << screenHeight << " " << (duplDesc.ModeDesc.RefreshRate.Numerator / duplDesc.ModeDesc.RefreshRate.Denominator) << "Hz" << std::endl;

	desc = {};
	desc.Width = screenWidth;
	desc.Height = screenHeight;
	desc.MipLevels = 1;
	desc.ArraySize = 1;
	desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
	desc.SampleDesc.Count = 1;
	desc.Usage = D3D11_USAGE_STAGING;
	desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
	desc.BindFlags = 0;
	hr = device->CreateTexture2D(&desc, nullptr, &tex2dStaging);
	if (FAILED(hr)) throw std::runtime_error("0x" + std::format("{:x}", (unsigned long)hr) + " CreateTexture2D failed");
	if (tex2dStaging == nullptr) throw std::runtime_error("The staging texture is null.");


#endif
	RawPixels4x8 = new uint8_t[screenWidth * screenHeight * 4];

	GBAVideoFeedFrame = new uint8_t[GBA_VIDEO_FEED_FRAME_SIZE];
	std::fill(GBAVideoFeedFrame, GBAVideoFeedFrame + GBA_VIDEO_FEED_FRAME_SIZE, 0);
	Running = true;
	CaptureThread = std::thread(&VideoCapture::CaptureThreadFunction, this);
}

VideoCapture::~VideoCapture() {
	Running = false;
	CaptureThread.join();

	delete[] RawPixels4x8;
#ifdef CAPTURE_GDI
	DeleteObject(hBitmap);
	DeleteDC(hMemoryDC);
	ReleaseDC(NULL, hScreenDC);
#elif defined(CAPTURE_DX9)
	surface->Release();
	device->Release();
	d3d->Release();
#elif defined(CAPTURE_DXGI)
	delete[] GBAVideoFeedFrame;
	outputDuplication->ReleaseFrame();
	device.Reset();
	deviceContext.Reset();
#endif

}

void VideoCapture::CaptureThreadFunction() {

	std::cout << "Capturing display..." << std::endl;

	const int fps = 60;
	const int frameDuration = 1000 / fps;
	
	while (Running) {

		auto start = std::chrono::high_resolution_clock::now();

#ifdef CAPTURE_GDI

		BitBlt(hMemoryDC, 0, 0, screenWidth, screenHeight, hScreenDC, 0, 0, SRCCOPY);
		GetDIBits(hMemoryDC, hBitmap, 0, screenHeight, RawPixels4x8, &bmi, DIB_RGB_COLORS);

#elif defined(CAPTURE_DX9)

		HRESULT hr;

		hr = device->GetFrontBufferData(0, surface);
		if (FAILED(hr)) {
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " GetFrontBufferData failed") << std::endl;
			return;
		}

		hr = surface->LockRect(&lock, NULL, 0);
		if (FAILED(hr)) {
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " LockRect failed") << std::endl;
			return;
		}

		memcpy(RawPixels4x8, reinterpret_cast<uint8_t*>(lock.pBits), screenWidth * screenHeight * 4);
		hr = surface->UnlockRect();
		if (FAILED(hr)) {
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " UnlockRect failed") << std::endl;
			return;
		}

#elif defined(CAPTURE_DXGI)

		// Some DirectX9 games will fail the screen capture with DXGI_ERROR_ACCESS_LOST(0x887A0026) when switching to the exclusive full-screen mode.
		// Re-initiating the DXGI device may solve this problem.
		// Or, be lazy, we wait for 10 seconds and start the screen capturing only after the game has been switched to.

		HRESULT hr;

		DXGI_OUTDUPL_FRAME_INFO fi{};
		ComPtr<IDXGIResource> desktopResource;
		hr = outputDuplication->AcquireNextFrame(frameDuration, &fi, &desktopResource);
		if (FAILED(hr)) {
			if (hr == DXGI_ERROR_WAIT_TIMEOUT) {
				std::cout << "AcquireNextFrame timed out, retrying..." << std::endl;
				outputDuplication->ReleaseFrame();
				continue;
			}
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " AcquireNextFrame failed") << std::endl;
			return;
		}

		ComPtr<ID3D11Texture2D> acquiredDesktopImage;
		hr = desktopResource.As(&acquiredDesktopImage);
		if (FAILED(hr)) {
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " QueryInterface failed") << std::endl;
			return;
		}

		deviceContext->CopyResource(tex2dStaging.Get(), acquiredDesktopImage.Get());

		D3D11_MAPPED_SUBRESOURCE mapped;
		hr = deviceContext->Map(tex2dStaging.Get(), 0, D3D11_MAP_READ, 0, &mapped);
		if (FAILED(hr)) {
			std::cout << ("0x" + std::format("{:x}", (unsigned long)hr) + " Map failed") << std::endl;
			return;
		}
		if (mapped.DepthPitch != (screenWidth * screenHeight * 4)) {
			std::cout << ("The depth pitch is not equal to the width * height * 4.") << std::endl;
			return;
		}

		memcpy(RawPixels4x8, reinterpret_cast<uint8_t*>(mapped.pData), screenWidth * screenHeight * 4);

		deviceContext->Unmap(tex2dStaging.Get(), 0);
		outputDuplication->ReleaseFrame();

#endif


		for (int y = 0; y < GBA_SCREEN_HEIGHT; ++y) {
			for (int x = 0; x < GBA_SCREEN_WIDTH; ++x) {
				int srcX = x * screenWidth / GBA_SCREEN_WIDTH;
				int srcY = y * screenHeight / GBA_SCREEN_HEIGHT;
				int srcIndex = (srcY * screenWidth + srcX) * 4;

				int r = RawPixels4x8[srcIndex + 0],
					g = RawPixels4x8[srcIndex + 1],
					b = RawPixels4x8[srcIndex + 2];

				reinterpret_cast<uint16_t*>(GBAVideoFeedFrame)[y * GBA_SCREEN_WIDTH + x] = 
					(b >> 3) |
					((g >> 3) << 5) |
					((r >> 3) << 10);
			}
		}
		GBAVideoFeedFrame[VIDEO_FEED_BG_MODE_OFFSET] = 3;

		videoFeedProcessor(RawPixels4x8, screenWidth * screenHeight * 4, GBAVideoFeedFrame, GBA_VIDEO_FEED_FRAME_SIZE);

		auto end = std::chrono::high_resolution_clock::now();

		std::chrono::duration<double, std::milli> elapsed = end - start;

		if (elapsed.count() < frameDuration) {
			std::this_thread::sleep_for(std::chrono::milliseconds(frameDuration) - elapsed);
		}
		else {
			std::cout << "Frame took too long to capture: " << elapsed.count() << "ms" << std::endl;
		}
	}
}
