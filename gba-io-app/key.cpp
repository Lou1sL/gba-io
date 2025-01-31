#include <windows.h>
#include <thread>
#include <chrono>
#include <iostream>

#include "key.h"

KeyReceive::KeyReceive(
	std::map<GBA_KEY, std::tuple<INPUT_TYPE, EVENTF, VK, std::tuple<int, int>>> bindingMap,
	std::function<uint16_t(void)> keyFeedProcessor)
	: bindingMap(bindingMap), keyFeedProcessor(keyFeedProcessor) {
	prevInvertedKeyFeed = 0;
	Running = true;
	ReceiveThread = std::thread(&KeyReceive::ReceiveThreadFunction, this);
}

KeyReceive::~KeyReceive() {
	Running = false;
	ReceiveThread.join();
}

void KeyReceive::ReceiveThreadFunction() {

	std::cout << "Receiving key..." << std::endl;

	const int fps = 60;
	const int frameDuration = 1000 / fps;

	while (Running) {

		auto start = std::chrono::high_resolution_clock::now();

		uint16_t invertedKeyFeed = ~keyFeedProcessor();

		for (auto const& [key, value] : bindingMap) {
			auto& [inputType, eventF, vk, xy] = value;
			auto& [x, y] = xy;
			int s = 0;
			if ((invertedKeyFeed & static_cast<uint16_t>(key)) && (EVENTF_OPPOSITE.at(eventF) == eventF)) {
				// This is a repeating event
				s = 1;
			}
			else if ((invertedKeyFeed & static_cast<uint16_t>(key)) && !(prevInvertedKeyFeed & static_cast<uint16_t>(key))) {
				// This is a toggling event, and the key is pressed
				s = 1;
			}
			else if (!(invertedKeyFeed & static_cast<uint16_t>(key)) && (prevInvertedKeyFeed & static_cast<uint16_t>(key))) {
				// This is a toggling event, and the key is released
				s = -1;
			}
			if (s == 0) continue;

			EVENTF e = (s > 0) ? eventF : EVENTF_OPPOSITE.at(eventF);
			INPUT ip{};
			ip.type = static_cast<DWORD>(inputType);
			if (inputType == INPUT_TYPE::KEYBOARD) {
				ip.ki.wVk = static_cast<WORD>(vk);
				ip.ki.wScan = 0;
				ip.ki.dwFlags = static_cast<DWORD>(e);
				ip.ki.time = 0;
				ip.ki.dwExtraInfo = 0;
			}
			else if (inputType == INPUT_TYPE::MOUSE) {
				ip.mi.dx = x;
				ip.mi.dy = y;
				ip.mi.mouseData = 0;
				ip.mi.dwFlags = static_cast<DWORD>(e);
				ip.mi.time = 0;
				ip.mi.dwExtraInfo = 0;
			}
			SendInput(1, &ip, sizeof(INPUT));
		}

		prevInvertedKeyFeed = invertedKeyFeed;

		auto end = std::chrono::high_resolution_clock::now();

		std::chrono::duration<double, std::milli> elapsed = end - start;

		if (elapsed.count() < frameDuration) {
			std::this_thread::sleep_for(std::chrono::milliseconds(frameDuration) - elapsed);
		}
		else {
			std::cout << "Keys took too long to capture: " << elapsed.count() << "ms" << std::endl;
		}
	}
}
