#pragma once

#include <Windows.h>
#include <cstdint>
#include <mutex>
#include <thread>

#include "CyAPI.h"

#pragma pack(push, 1)
struct KeyAndStatus {
	uint32_t frameCounter;
	uint8_t reserved0[4];
	uint16_t videoFeedOccupyingIndex;
	uint16_t soundFeedOccupyingIndex;
	uint8_t reserved1[4];
	uint16_t keyFeedRaw;
	uint8_t reserved2[6];
	uint16_t keyFeedProcessedUp;
	uint16_t keyFeedProcessedDown;
	uint16_t keyFeedProcessedHeld;
	uint16_t keyFeedProcessedDownRepeat;
};
#pragma pack(pop)

class USB
{
public:
	USB();
	~USB();
	void WriteCode(std::string GBAIOROMPath);
	void WriteVBuffer(uint8_t* v);
	void WriteSLAndSRBuffer(uint8_t* sl, uint8_t* sr);
	KeyAndStatus* ReadKeyAndStatus();
	void TEST_WriteKeyFeedRaw(uint16_t key);
private:
	static const UCHAR ATTR_CONTROL = 0x00;
	static const UCHAR ATTR_ISOCHRONOUS = 0x01;
	static const UCHAR ATTR_BULK = 0x02;
	static const UCHAR ATTR_INTERRUPT = 0x03;

	static const UCHAR FIFO_DATA_TX_ENDPOINT_ADDRESS = 0x02;
	static const UCHAR FIFO_DATA_RX_ENDPOINT_ADDRESS = 0x86;
	static const UCHAR FIFO_CTRL_TX_ENDPOINT_ADDRESS = 0x04;
	static const UCHAR FIFO_CTRL_RX_ENDPOINT_ADDRESS = 0x88;

	const std::string FIFO_CTRL_RX_ENDPOINT_FINGERPRINT = "GBA I/O\n";

	static const uint8_t TRANS_TYPE_DISABLE = 0x00;
	static const uint8_t TRANS_TYPE_IN_RX = 0x40;
	static const uint8_t TRANS_TYPE_OUT_TX = 0x80;

    static const uint32_t TRANS_ADDRESS_CODE           = 0x00000000;
	static const uint32_t TRANS_SIZE_CODE              = 0x01000000;
    static const uint32_t TRANS_ADDRESS_V_BUFFER       = 0x01000000;
	static const uint32_t TRANS_SIZE_V_BUFFER          = 0x00020000;
    static const uint32_t TRANS_ADDRESS_SL_BUFFER      = 0x01E00000;
    static const uint32_t TRANS_ADDRESS_SR_BUFFER      = 0x01F00000;
	static const uint32_t TRANS_SIZE_S_BUFFER          = 0x00000010;
    static const uint32_t TRANS_ADDRESS_KEY_AND_STATUS = 0x02000000;
	static const uint32_t TRANS_SIZE_KEY_AND_STATUS    = 0x00000020;

	// The USB data transmission is not an atomic operation, hence the lock guard is required for thread safety.
	std::mutex mutex;

	CCyUSBDevice* USBDevice;
	HANDLE DeviceHandle;
	CCyUSBEndPoint* FIFODataTxEndPt;
	CCyUSBEndPoint* FIFODataRxEndPt;
	CCyUSBEndPoint* FIFOCtrlTxEndPt;
	CCyUSBEndPoint* FIFOCtrlRxEndPt;

	UCHAR* pCode;
	KeyAndStatus* pKeyAndStatus;

	void SendTransCode(uint8_t transType, uint32_t address, uint32_t size);
};
