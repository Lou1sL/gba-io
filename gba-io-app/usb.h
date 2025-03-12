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

	static const UCHAR TRANS_OUT_CODE = 0x81;
	static const UCHAR TRANS_OUT_V_BUFFER = 0x82;
	static const UCHAR TRANS_OUT_SL_BUFFER = 0x83;
	static const UCHAR TRANS_OUT_SR_BUFFER = 0x84;
	static const UCHAR TRANS_IN_KEY_AND_STATUS = 0x45;

	static const LONG  TRANS_SIZE_CODE = 0x1000000;
	static const LONG  TRANS_SIZE_V_BUFFER = 0x20000;
	static const LONG  TRANS_SIZE_S_BUFFER = 0x10;
	static const LONG  TRANS_SIZE_KEY_AND_STATUS = 0x20;

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

	void SendTransType(UCHAR transType);
};
