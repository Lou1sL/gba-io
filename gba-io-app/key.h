#pragma once

#include <map>
#include <functional>
#include <thread>

#include "input.h"

// https://problemkaputt.de/gbatek.htm#gbakeypadinput
enum class GBA_KEY : uint16_t {
	NONE = 0,
	KEY_A = (1 << 0),
	KEY_B = (1 << 1),
	KEY_SELECT = (1 << 2),
	KEY_START = (1 << 3),
	KEY_RIGHT = (1 << 4),
	KEY_LEFT = (1 << 5),
	KEY_UP = (1 << 6),
	KEY_DOWN = (1 << 7),
	KEY_R = (1 << 8),
	KEY_L = (1 << 9),
};

class KeyReceive {
public:
	KeyReceive(
		std::map<GBA_KEY, std::tuple<INPUT_TYPE, EVENTF, VK, std::tuple<int, int>>> bindingMap,
		std::function<uint16_t(void)> keyFeedProcessor);
	~KeyReceive();
private:
	std::map<GBA_KEY, std::tuple<INPUT_TYPE, EVENTF, VK, std::tuple<int, int>>> bindingMap;
	std::function<uint16_t(void)> keyFeedProcessor;
	uint16_t prevInvertedKeyFeed;
	std::atomic<bool> Running;
	std::thread ReceiveThread;
	void ReceiveThreadFunction();
};
