#include <iostream>
#include <fstream>
#include <chrono>
#include <thread>
#include <vector>
#include <algorithm>
#include <array>
#include <filesystem>
#include <map>
#include <cstddef>

#include "usb.h"

USB::USB()
{
	std::cout << "Waiting for the connection of the GBA I/O USB device..." << std::endl;
	USBDevice = new CCyUSBDevice(&DeviceHandle, CYUSBDRV_GUID, true);
	bool searching = true;
	while (searching) {
		for (UCHAR i = 0; i < USBDevice->DeviceCount(); ++i) {
			USBDevice->Open(i);
			if (USBDevice->VendorID == 0x04B4 && USBDevice->ProductID == 0x00F1) {
				std::cout << "A CYUSB3014 device has been found and chosen." << std::endl;
				searching = false;
				break;
			}
		}
		std::this_thread::sleep_for(std::chrono::seconds(1));
	}

	UCHAR intfcCnt = USBDevice->AltIntfc() + 1;
	if (intfcCnt > 1) {
		std::cout << "The selected USB device has more than one interface. The first interface will be chosen." << std::endl;
	}
	if (!USBDevice->SetAltIntfc(0)) throw std::runtime_error("Failed to set to USB interface 0.");

	std::map<UCHAR, std::string> attrMap = {
		{ 0, "Control" },
		{ 1, "Isochronous" },
		{ 2, "Bulk" },
		{ 3, "Interrupt" }
	};
	// https://fmt.dev/latest/syntax/#format-examples
	std::cout << std::endl;
	std::cout << " ┌─────────────────────────────────────────────────────────────────────────────────────┐" << std::endl;
	std::cout << " │ USB Device Information                                                              │" << std::endl;
	std::cout << " ├──────────────────┬───────────┬────────────────────────────┬─────────────────────────┤" << std::endl;
	std::cout << " │ EndPoint Address │ Direction │ Transfer Type / Attributes │ Max Packet Size (Bytes) │" << std::endl;
	std::cout << " ├──────────────────┼───────────┼────────────────────────────┼─────────────────────────┤" << std::endl;
	UCHAR eptCnt = USBDevice->EndPointCount();
	for (UCHAR e = 0; e < eptCnt; e++)
	{
		CCyUSBEndPoint* ept = USBDevice->EndPoints[e];
		std::cout <<
			" │ " << std::format("{:<17}", std::format("{:#02x}", ept->Address)) <<
			"│ " << std::format("{:<10}", (ept->bIn ? "0x8X IN" : "0x0X OUT")) <<
			"│ " << std::format("{:<27}", (attrMap[ept->Attributes] + " " + std::to_string(ept->Attributes))) <<
			"│ " << std::format("{:<24}", (std::format("{:#x}", ept->MaxPktSize) + " = " + std::to_string(ept->MaxPktSize))) <<
			"│ " << std::endl;
	}
	std::cout << " └─────────────────────────────────────────────────────────────────────────────────────┘" << std::endl;
	std::cout << std::endl;

	FIFODataTxEndPt = USBDevice->EndPointOf(FIFO_DATA_TX_ENDPOINT_ADDRESS);
	FIFODataRxEndPt = USBDevice->EndPointOf(FIFO_DATA_RX_ENDPOINT_ADDRESS);
	FIFOCtrlTxEndPt = USBDevice->EndPointOf(FIFO_CTRL_TX_ENDPOINT_ADDRESS);
	FIFOCtrlRxEndPt = USBDevice->EndPointOf(FIFO_CTRL_RX_ENDPOINT_ADDRESS);

	std::cout << "Checking device fingerprint..." << std::endl;

	if (FIFOCtrlRxEndPt == nullptr)
		throw std::runtime_error("The fifo_ctrl_rx endpoint could not be found.");
	std::array<UCHAR, 8> fingerprint{};
	LONG len = 8;
	if (!FIFOCtrlRxEndPt->XferData(fingerprint.data(), len))
		throw std::runtime_error("Failed to read the fingerprint from the fifo_ctrl_rx endpoint.");
	std::string fingerprintStr(fingerprint.begin(), fingerprint.end());
	if (fingerprintStr != FIFO_CTRL_RX_ENDPOINT_FINGERPRINT)
		throw std::runtime_error("The fingerprint does not match.");

	pCode = new UCHAR[TRANS_SIZE_CODE];
	pKeyAndStatus = new KeyAndStatus();
}

USB::~USB()
{
	USBDevice->Close();
	delete USBDevice;
	delete[] pCode;
	delete pKeyAndStatus;
}

void USB::SendTransCode(uint8_t transType, uint32_t address, uint32_t size)
{
	LONG len = 9;
	uint8_t data[9]{};
	data[0] = transType;
	data[1] = (address >> 24) & 0xFF;
	data[2] = (address >> 16) & 0xFF;
	data[3] = (address >> 8) & 0xFF;
	data[4] = address & 0xFF;
	data[5] = (size >> 24) & 0xFF;
	data[6] = (size >> 16) & 0xFF;
	data[7] = (size >> 8) & 0xFF;
	data[8] = size & 0xFF;
	if (!FIFOCtrlTxEndPt->XferData(data, len)) {
		std::cout << "Failed to send the transmission type to the fifo_ctrl_tx." << std::endl;
	}
}

void USB::WriteCode(std::string GBAIOROMPath)
{
	std::lock_guard<std::mutex> lock(mutex);
	std::cout << "Reading the GBA I/O ROM file..." << std::endl;
	std::ifstream romFile(GBAIOROMPath, std::ios::binary);
	if (!romFile.is_open()) {
		std::cout << ("The GBA I/O ROM file at " + GBAIOROMPath + " could not be opened.") << std::endl;
		return;
	}
	std::streamsize sz = std::filesystem::file_size(GBAIOROMPath);
	if (sz > TRANS_SIZE_CODE) {
		sz = TRANS_SIZE_CODE;
		std::cout << "The GBA I/O ROM file is too large. Only the first " << TRANS_SIZE_CODE << " bytes will be transferred." << std::endl;
	}
	if (!romFile.read(reinterpret_cast<char*>(pCode), sz)) {
		std::cout << "Failed to read the ROM file." << std::endl;
		return;
	}
	romFile.close();

	std::cout << "Transferring GBA I/O ROM to the GBA I/O USB device..." << std::endl;
	SendTransCode(TRANS_TYPE_OUT_TX, TRANS_ADDRESS_CODE, TRANS_SIZE_CODE);
	LONG len = TRANS_SIZE_CODE;
	if (!FIFODataTxEndPt->XferData(pCode, len)) {
		std::cout << "Failed to transfer ROM data to the device." << std::endl;
		return;
	}
	std::cout << "The GBA I/O ROM has been successfully transferred. You can insert the GBA I/O USB device to the GBA cartridge port or reboot the GBA console now." << std::endl;
}

void USB::WriteVBuffer(uint8_t* v)
{
	std::lock_guard<std::mutex> lock(mutex);
	SendTransCode(TRANS_TYPE_OUT_TX, TRANS_ADDRESS_V_BUFFER, TRANS_SIZE_V_BUFFER);
	LONG len = TRANS_SIZE_V_BUFFER;
	if (!FIFODataTxEndPt->XferData(v, len)) {
		std::cout << "Failed to write to the V_Buffer." << std::endl;
	}
}

void USB::WriteSLAndSRBuffer(uint8_t* sl, uint8_t* sr)
{
	std::lock_guard<std::mutex> lock(mutex);
	SendTransCode(TRANS_TYPE_OUT_TX, TRANS_ADDRESS_SL_BUFFER, TRANS_SIZE_S_BUFFER);
	LONG len = TRANS_SIZE_S_BUFFER;
	if (!FIFODataTxEndPt->XferData(sl, len)) {
		std::cout << "Failed to write to the SL_Buffer." << std::endl;
	}
	SendTransCode(TRANS_TYPE_OUT_TX, TRANS_ADDRESS_SR_BUFFER, TRANS_SIZE_S_BUFFER);
	if (!FIFODataTxEndPt->XferData(sr, len)) {
		std::cout << "Failed to write to the SR_Buffer." << std::endl;
	}
}

KeyAndStatus* USB::ReadKeyAndStatus()
{
	std::lock_guard<std::mutex> lock(mutex);
	SendTransCode(TRANS_TYPE_IN_RX, TRANS_ADDRESS_KEY_AND_STATUS, TRANS_SIZE_KEY_AND_STATUS);
	LONG len = TRANS_SIZE_KEY_AND_STATUS;
	if (!FIFODataRxEndPt->XferData(reinterpret_cast<PUCHAR>(pKeyAndStatus), len)) {
		std::cout << "Failed to read from the KEY_AND_STATUS." << std::endl;
	}
	return pKeyAndStatus;
}

void USB::TEST_WriteKeyFeedRaw(uint16_t key)
{
	std::lock_guard<std::mutex> lock(mutex);
	SendTransCode(TRANS_TYPE_OUT_TX, TRANS_ADDRESS_KEY_AND_STATUS + offsetof(KeyAndStatus, key), 2);
	LONG len = 2;
	if (!FIFODataTxEndPt->XferData(reinterpret_cast<PUCHAR>(&key), len)) {
		std::cout << "Failed to write to the KeyFeedRaw value of the KEY_AND_STATUS." << std::endl;
	}
}
