import CoreBluetooth
import Foundation

final class BLEPeripheral: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager!
    private var statusCharacteristic: CBMutableCharacteristic?
    private var notificationTimer: Timer?
    private var pendingNotification: Data?
    private var batteryLevel = 90
    private var isServiceConfigured = false

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Bluetooth powered on")
            configureServiceIfNeeded()
        case .poweredOff:
            print("Bluetooth powered off")
            stopNotifications()
        case .unauthorized:
            print("Bluetooth access is unauthorized")
        case .unsupported:
            print("Bluetooth LE is unsupported on this Mac")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unhandled Bluetooth state: \(peripheral.state.rawValue)")
        }
    }

    private func configureServiceIfNeeded() {
        guard !isServiceConfigured else { return }

        let characteristic = CBMutableCharacteristic(
            type: CBUUID(string: BLEConfiguration.statusCharacteristicUUIDString),
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )

        let service = CBMutableService(
            type: CBUUID(string: BLEConfiguration.serviceUUIDString),
            primary: true
        )
        service.characteristics = [characteristic]

        statusCharacteristic = characteristic
        isServiceConfigured = true
        peripheralManager.add(service)
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {
        if let error {
            print("Failed to add GATT service: \(error.localizedDescription)")
            return
        }

        print("GATT service added: \(BLEConfiguration.serviceUUIDString)")

        peripheral.startAdvertising([
            CBAdvertisementDataLocalNameKey: BLEConfiguration.deviceName,
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: BLEConfiguration.serviceUUIDString)]
        ])
    }

    func peripheralManagerDidStartAdvertising(
        _ peripheral: CBPeripheralManager,
        error: Error?
    ) {
        if let error {
            print("Advertising failed: \(error.localizedDescription)")
            return
        }

        print("Advertising as \(BLEConfiguration.deviceName)")
        print("Service UUID: \(BLEConfiguration.serviceUUIDString)")
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        guard characteristic.uuid == CBUUID(string: BLEConfiguration.statusCharacteristicUUIDString) else {
            return
        }

        print("Central subscribed: \(central.identifier.uuidString)")
        startNotifications()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        guard characteristic.uuid == CBUUID(string: BLEConfiguration.statusCharacteristicUUIDString) else {
            return
        }

        print("Central unsubscribed: \(central.identifier.uuidString)")
        stopNotifications()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        guard request.characteristic.uuid == CBUUID(string: BLEConfiguration.statusCharacteristicUUIDString) else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        do {
            request.value = try encodedStatus()
            peripheral.respond(to: request, withResult: .success)
            print("Status read request served")
        } catch {
            peripheral.respond(to: request, withResult: .unlikelyError)
            print("Failed to encode status: \(error.localizedDescription)")
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard
            let pendingNotification,
            let statusCharacteristic
        else {
            return
        }

        if peripheral.updateValue(
            pendingNotification,
            for: statusCharacteristic,
            onSubscribedCentrals: nil
        ) {
            self.pendingNotification = nil
            print("Queued notification sent")
        }
    }

    private func startNotifications() {
        stopNotifications()

        notificationTimer = Timer.scheduledTimer(
            timeInterval: BLEConfiguration.notificationInterval,
            target: self,
            selector: #selector(handleNotificationTimer),
            userInfo: nil,
            repeats: true
        )

        sendStatusNotification()
    }


    @objc
    private func handleNotificationTimer() {
        sendStatusNotification()
    }

    private func stopNotifications() {
        notificationTimer?.invalidate()
        notificationTimer = nil
        pendingNotification = nil
    }

    private func sendStatusNotification() {
        guard let statusCharacteristic else { return }

        updateBatteryLevel()

        do {
            let data = try encodedStatus()
            let sent = peripheralManager.updateValue(
                data,
                for: statusCharacteristic,
                onSubscribedCentrals: nil
            )

            if sent {
                print("Notify: \(String(decoding: data, as: UTF8.self))")
            } else {
                pendingNotification = data
                print("Notification queued; waiting for Bluetooth stack")
            }
        } catch {
            print("Failed to encode notification: \(error.localizedDescription)")
        }
    }

    private func encodedStatus() throws -> Data {
        let status = DeviceStatus(status: "active", battery: batteryLevel)
        return try JSONEncoder().encode(status)
    }

    private func updateBatteryLevel() {
        batteryLevel -= 1
        if batteryLevel < 20 {
            batteryLevel = 90
        }
    }
}
