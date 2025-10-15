//
//  BluetoothViewModel.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit

// MARK: - Ring Model
struct RingDevice: Codable, Identifiable {
    let id: UUID
    let name: String
    let rxUUID: String?
    let txUUID: String?
}

final class BluetoothViewModel: NSObject, ObservableObject {
    static let shared = BluetoothViewModel()
    
    // Published States
    @Published var peripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isConnected = false
    @Published var statusMessage = "Idle"
    
    @Published var isConnectingSavedRing = false
    @Published var animationRotation = 0.0
    private var animationTimer: Timer?

    // Internal
    private var centralManager: CBCentralManager!
    private var peripheralCharacteristics: [UUID: (rx: CBCharacteristic, tx: CBCharacteristic?)] = [:]
    private var shouldAutoReconnect = false
    
    // MARK: - Additional Big Data Characteristics
    private var bigDataWriteCharacteristic: CBCharacteristic?
    private var bigDataNotifyCharacteristic: CBCharacteristic?
    
    // Persisted Ring
    private let savedRingKey = "savedRingDevice"
    public var savedRing: RingDevice? {
        didSet { persistRing() }
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        loadSavedRing()
    }
}

// MARK: - CoreBluetooth Delegate
extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth ON"
            
            // Auto reconnect if saved ring exists
            if let saved = savedRing {
                print("🔄 Attempting auto-reconnect to saved ring: \(saved.name)")
                let peripherals = centralManager.retrievePeripherals(withIdentifiers: [saved.id])
                if let found = peripherals.first {
                    connect(to: found)
                    return
                }
            }
            // Otherwise, start scanning
            startScan()
            
        case .poweredOff:
            statusMessage = "⚠️ Bluetooth is OFF"
            DispatchQueue.main.async {
                self.showBluetoothSettingsAlert()
            }
        default:
            statusMessage = "Bluetooth unavailable"
        }
    }
    
    func showBluetoothSettingsAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }

        let alert = UIAlertController(
            title: "Bluetooth is Off",
            message: "Turn on Bluetooth to connect your Smart Ring.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        root.present(alert, animated: true)
    }
    
    func tryAutoReconnect() {
        guard centralManager.state == .poweredOn else {
            print("⚠️ Bluetooth not powered on yet.")
            return
        }

        if let saved = savedRing {
            isConnectingSavedRing = true
            print("🔄 Attempting auto-reconnect to saved ring: \(saved.name)")
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: [saved.id])
            if let found = peripherals.first {
                connect(to: found)
            } else {
                startScan()
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    self.isConnectingSavedRing = false
                }
            }
        } else {
            startScan()
        }
    }

    func startLoadingAnimation() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            self.animationRotation += 2
            if self.animationRotation > 360 { self.animationRotation = 0 }
        }
    }


    // MARK: Scan & Discover
    func startScan() {
        peripherals.removeAll()
        statusMessage = "Scanning..."
        centralManager.scanForPeripherals(withServices: nil,
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty else { return }
        
        // ✅ Fitness filter by names or known UUIDs
        let fitnessHints = ["ring", "band", "fit", "watch", "r02", "smart"]
        if fitnessHints.contains(where: { name.lowercased().contains($0) }) {
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                peripherals.append(peripheral)
                print("✅ Found fitness-capable device: \(name)")
            }
        } else {
            print("❌ Ignored non-fitness device: \(name)")
        }
    }
    
    // MARK: Connect & Discover
    func connect(to peripheral: CBPeripheral) {
        stopScan()
        statusMessage = "Connecting to \(peripheral.name ?? "Device")..."
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func stopScan() {
        centralManager.stopScan()
        statusMessage = "Scan stopped"
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ didConnect triggered for \(peripheral.name ?? "Unknown")")
        isConnected = true
        isConnectingSavedRing = false // stop the animation
        connectedPeripheral = peripheral
        statusMessage = "Connected to \(peripheral.name ?? "Device")"
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("⚠️ Disconnected from \(peripheral.name ?? "Device")")
        isConnected = false
        connectedPeripheral = nil
        statusMessage = "Disconnected"
        
        // Retry reconnect automatically
        if shouldAutoReconnect, let saved = savedRing {
            print("🔁 Auto-reconnecting to \(saved.name)...")
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: [saved.id])
            if let found = peripherals.first {
                connect(to: found)
            } else {
                startScan()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Write failed: \(error.localizedDescription)")
        } else {
            print("✅ Write successful to \(characteristic.uuid)")
        }
    }
    
    // MARK: Service & Characteristic discovery
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("🔍 Found Service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }

        var rxChar: CBCharacteristic?
        var txChar: CBCharacteristic?
        print("🔍 Found Service: \(service.uuid)")
        for char in characteristics {
            print("   ↳ Characteristic: \(char.uuid)")
            // === Command Service (for blink, camera, etc.) ===
            if service.uuid == CBUUID(string: "6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E") {
                if char.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
                    rxChar = char
                    print("✅ Command RX characteristic found")
                }
                if char.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
                    txChar = char
                    peripheral.setNotifyValue(true, for: char)
                    print("📡 Command TX notifications enabled")
                }
            }
            // === Big-Data Service (for sleep, HRV, etc.) ===
            if service.uuid == CBUUID(string: "DE5BF728-D711-4E47-AF26-65E3012A5DC7") {
                if char.uuid == CBUUID(string: "DE5BF72A-D711-4E47-AF26-65E3012A5DC7") {
                    bigDataWriteCharacteristic = char
                    print("💾 Big-Data WRITE characteristic found")
                }
                if char.uuid == CBUUID(string: "DE5BF729-D711-4E47-AF26-65E3012A5DC7") {
                    bigDataNotifyCharacteristic = char
                    peripheral.setNotifyValue(true, for: char)
                    print("📡 Big-Data NOTIFY characteristic found")
                }
            }
        }
        // ✅ Only save the Command RX/TX pair for blink commands
        if let rx = rxChar {
            peripheralCharacteristics[peripheral.identifier] = (rx, txChar)
            let ring = RingDevice(
                id: peripheral.identifier,
                name: peripheral.name ?? "Unknown",
                rxUUID: rx.uuid.uuidString,
                txUUID: txChar?.uuid.uuidString
            )
            savedRing = ring
            shouldAutoReconnect = true
            print("💾 Saved COMMAND ring characteristic for \(ring.name)")
        }
    }
}
// MARK: - Persistence
extension BluetoothViewModel {
    private func persistRing() {
        guard let ring = savedRing else { return }
        if let data = try? JSONEncoder().encode(ring) {
            UserDefaults.standard.set(data, forKey: savedRingKey)
        }
    }
    
    private func loadSavedRing() {
        if let data = UserDefaults.standard.data(forKey: savedRingKey),
           let ring = try? JSONDecoder().decode(RingDevice.self, from: data) {
            savedRing = ring
            print("💾 Loaded saved ring: \(ring.name)")
        }
    }
    // MARK: - Disconnect
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            print("🧲 Disconnected from \(peripheral.name ?? "Unknown") manually")
        } else {
            print("⚠️ No peripheral to disconnect")
        }
        
        connectedPeripheral = nil
        isConnected = false
        statusMessage = "Disconnected"
    }
    func forgetSavedRing() {
        UserDefaults.standard.removeObject(forKey: savedRingKey)
        savedRing = nil
        connectedPeripheral = nil
        isConnected = false
        statusMessage = "Saved device removed. Please scan for new rings."
        print("🗑️ Saved ring removed.")
        centralManager.stopScan()
    }
}
// MARK: - Send Commands
extension BluetoothViewModel {
    func sendFindDeviceCommand() {
        guard let peripheral = connectedPeripheral,
              let characteristic = peripheralCharacteristics[peripheral.identifier]?.rx else {
            print("⚠️ No connected peripheral or RX characteristic.")
            return
        }

        var findCmd = [UInt8](repeating: 0x00, count: 16)
        findCmd[0] = 0x50 // Command ID 80
        findCmd[1] = 0x55
        findCmd[2] = 0xAA
        findCmd[15] = findCmd.reduce(0, +) & 0xFF // simple checksum
        let data = Data(findCmd)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("🔍 Sent Find Device (LED Blink) command")
    }
}
// MARK: - Ring Command Extensions
extension BluetoothViewModel {
    func makeBlinkTwicePacket() -> Data {
        var packet = Data(repeating: 0, count: 16)
        packet[0] = 0x10
        let checksum = packet.prefix(15).reduce(0, +) % 255
        packet[15] = UInt8(checksum)
        return packet
    }
    func sendBlinkTwiceCommand() {
        guard let peripheral = connectedPeripheral,
              let rx = peripheralCharacteristics[peripheral.identifier]?.rx else {
            print("⚠️ Not ready — no connected ring or RX characteristic.")
            return
        }

        let bytes: [UInt8] = [0x10, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x10]
        let data = Data(bytes)
        let hex = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")

        print("💡 Sending BlinkTwice → \(hex)")
        print("📤 Writing to characteristic: \(rx.uuid.uuidString)")
        print("🧩 For peripheral: \(peripheral.name ?? "Unknown")")

        peripheral.writeValue(data, for: rx, type: .withoutResponse)
    }

}
