# BLE Peripheral for macOS

A small native macOS BLE peripheral built with Swift and CoreBluetooth. It is designed to act as a controllable GATT device for testing BLE client applications such as the companion Flutter project `ble-device-monitor`.

## Features

- Advertises as `BLE Demo Device`
- Publishes a custom BLE GATT service (`FFF0`)
- Exposes a readable and notifiable status characteristic (`FFF1`)
- Sends JSON status notifications every two seconds
- Simulates a changing battery level
- Handles notification backpressure through `peripheralManagerIsReady(toUpdateSubscribers:)`
- Logs subscriptions, reads, advertising state, and outgoing notifications

## GATT Contract

| Type | UUID | Behavior |
| --- | --- | --- |
| Primary service | `FFF0` | Demo device service |
| Status characteristic | `FFF1` | Read + Notify |

Example notification payload:

```json
{"status":"active","battery":87}
```

## Requirements

- macOS 13 or later
- Swift 6 toolchain / Xcode command-line tools
- Bluetooth enabled on the Mac

## Run

From the repository root:

```bash
swift run ble-peripheral
```

On first use, macOS may request Bluetooth permission for the terminal or development environment running the executable.

Expected output:

```text
BLE Peripheral started
Press Control+C to stop
Bluetooth powered on
GATT service added: FFF0
Advertising as BLE Demo Device
Service UUID: FFF0
```

When a BLE central subscribes to `FFF1`, the peripheral begins sending live status notifications.

## Project Structure

```text
Sources/BLEPeripheral/
├── BLEConfiguration.swift
├── BLEPeripheral.swift
├── DeviceStatus.swift
└── main.swift
```

## Companion Client

This project is intended to work with the Flutter `ble-device-monitor` repository, which scans for the peripheral, connects to the GATT service, subscribes to live notifications, and handles unexpected disconnects with automatic reconnection.

## Purpose

This repository is a focused demonstration project for BLE development and testing. It is not intended to emulate any specific commercial device or proprietary protocol.
