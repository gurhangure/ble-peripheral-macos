# BLE Peripheral for macOS

A small native macOS BLE peripheral built with Swift and CoreBluetooth.

It acts as a controllable GATT device for testing BLE client applications such as the companion Flutter project [`ble-device-monitor`](https://github.com/gurhangure/ble-device-monitor).

## Features

- Advertises as `BLE Demo Device`
- Publishes a custom BLE GATT service (`FFF0`)
- Exposes a readable and notifiable status characteristic (`FFF1`)
- Sends JSON status notifications every two seconds
- Simulates a changing battery level
- Handles notification backpressure through `peripheralManagerIsReady(toUpdateSubscribers:)`
- Logs advertising state, subscriptions, read requests, and outgoing notifications

## GATT Contract

| Type | UUID | Behavior |
| --- | --- | --- |
| Primary service | `FFF0` | Demo device service |
| Status characteristic | `FFF1` | Read + Notify |

Example notification payload:

```json
{
  "status": "active",
  "battery": 87
}
```

## Requirements

- macOS 13 or later
- Swift 6 toolchain
- Xcode command-line tools
- Bluetooth enabled on the Mac

## Build

From the repository root:

```bash
swift build
```

## Run

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

This peripheral is designed to work with the Flutter BLE client:

[`ble-device-monitor`](https://github.com/gurhangure/ble-device-monitor)

The Flutter client handles discovery, connection management, GATT service discovery, live notifications, device status display, and automatic reconnection after unexpected connection loss.

## Purpose

This repository is a focused demonstration project for native BLE peripheral development and testing on macOS.

It is not intended to emulate any specific commercial device or proprietary protocol.