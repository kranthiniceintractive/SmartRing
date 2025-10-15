//
//  BluetoothView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI
import CoreBluetooth
import Combine

struct BluetoothView: View {
    
    @StateObject private var viewModel = BluetoothViewModel.shared
    var body: some View {
        if viewModel.isConnected {
            // ✅ Once connected, move to Main tab
            MainTabView()
        } else if let savedRing = viewModel.savedRing {
            // ✅ Saved ring exists — try connecting
            connectingToSavedRingView(ring: savedRing)
        } else {
            // ✅ No saved ring — regular scanner
            connectionListView
        }
    }

    // MARK: - 1️⃣ Saved Ring Animation + Options
    private func connectingToSavedRingView(ring: RingDevice) -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Rotating glowing ring
                ZStack {
                    Circle()
                        .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 10)
                        .blur(radius: 20)
                        .frame(width: 260, height: 260)

                    Image("Gold_ring")
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(Angle(degrees: viewModel.animationRotation))
                        .frame(width: 220, height: 220)
                        .shadow(color: .cyan.opacity(0.7), radius: 10, x: 0, y: 0)
                        .onAppear { viewModel.startLoadingAnimation() }
                }

                VStack(spacing: 8) {
                    Text("Reconnecting to your Smart Ring")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(ring.name)
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                    .scaleEffect(1.6)
                    .padding(.top, 10)

                Text("Please keep your ring nearby to complete the connection.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 10)

                HStack(spacing: 20) {
                    Button {
                        viewModel.forgetSavedRing()
                    } label: {
                        Label("Forget Device", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button {
                        viewModel.forgetSavedRing()
                        viewModel.startScan()
                    } label: {
                        Label("Find New", systemImage: "magnifyingglass.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.horizontal, 10)
            }
            .padding(.all, 20)
        }
        .onAppear {
            viewModel.tryAutoReconnect()
        }
    }
    // MARK: - 2️⃣ Regular Scanner View (no saved ring)
    private var connectionListView: some View {
        VStack {
            Text(viewModel.statusMessage)
                .font(.headline)
                .padding(.top, 8)

            if viewModel.peripherals.isEmpty {
                Spacer()
                ProgressView("Scanning for fitness devices...")
                    .padding()
                Spacer()
            } else {
                List(viewModel.peripherals, id: \.identifier) { device in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name ?? "Unknown")
                                .font(.headline)
                            Text(device.identifier.uuidString)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button("Connect") {
                            viewModel.connect(to: device)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }

            HStack {
                Button(viewModel.statusMessage.contains("Scanning") ? "Stop Scan" : "Scan") {
                    viewModel.statusMessage.contains("Scanning")
                    ? viewModel.stopScan()
                    : viewModel.startScan()
                }
                .padding()
                .buttonStyle(.borderedProminent)

                if viewModel.connectedPeripheral != nil {
                    Button("Disconnect") {
                        viewModel.disconnect()
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding(.bottom)
        }
        .onAppear {
            viewModel.tryAutoReconnect()
        }
    }
}
// MARK: - HRV Weekly Fetch Logic
extension BluetoothViewModel {

    func requestHRVWeek() {
        guard connectedPeripheral != nil else {
            print("⚠️ No connected peripheral.")
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        print("📅 Starting HRV 7-day fetch...")

        var allResults: [HRVDayData] = []

        func fetchDay(_ offset: Int) {
            guard offset < 7 else {
                DispatchQueue.main.async {
                    self.hrvWeekData = allResults
                }
                print("✅ Finished HRV requests for 7 days.")
                return
            }

            guard let dayDate = calendar.date(byAdding: .day, value: -offset, to: today) else { return }
            let unixTime = UInt32(dayDate.timeIntervalSince1970)
            print("➡️ Sending HRV request for \(dayDate) (\(offset) days ago)")

            sendHRVCommand(unixTime: unixTime) { samples in
                allResults.append(HRVDayData(date: dayDate, samples: samples))
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    fetchDay(offset + 1)
                }
            }
        }

        fetchDay(0)
    }

    private func sendHRVCommand(unixTime: UInt32, completion: @escaping ([HRVSample]) -> Void) {
        guard let peripheral = connectedPeripheral,
              let rx = bigDataWriteCharacteristic ?? peripheralCharacteristics[peripheral.identifier]?.rx else {
            print("⚠️ HRV command cannot be sent — RX missing.")
            return
        }

        // 16-byte command (ID = 0x39 / 57)
        var cmd = [UInt8](repeating: 0x00, count: 16)
        cmd[0] = 0x39
        cmd[1] = 0x00
        cmd[2] = UInt8(unixTime & 0xFF)
        cmd[3] = UInt8((unixTime >> 8) & 0xFF)
        cmd[4] = UInt8((unixTime >> 16) & 0xFF)
        cmd[5] = UInt8((unixTime >> 24) & 0xFF)
        for i in 6..<15 { cmd[i] = 0x00 }
        let checksum = Array(cmd[0..<15]).reduce(0) { Int($0) + Int($1) } & 0xFF
        cmd[15] = UInt8(checksum)

        let data = Data(cmd)
        print("📤 HRV Command:", cmd.map { String(format: "%02X", $0) }.joined(separator: " "))

        peripheral.writeValue(data, for: rx, type: .withResponse)

        var collectedSamples: [UInt8] = []
        self.onHRVData = { [weak self] dataBytes in
            guard let self = self else { return }
            guard dataBytes.count >= 3 else { return }

            let index = dataBytes[1]
            // MARK: - Case 1: Metadata
            if index == 0x00 {
                print("🧭 HRV Metadata received")
                return
            }

            // MARK: - Case 2: No data
            if index == 0xFF {
                print("⚠️ HRV Response: No data for this day.")
                completion([])
                self.onHRVData = nil
                return
            }

            // MARK: - Case 3: Data chunks
            if index > 0x00 && index < 0xFF {
                let startIndex = 2
                let endIndex = max(0, dataBytes.count - 1)
                let values = Array(dataBytes[startIndex..<endIndex])
                collectedSamples.append(contentsOf: values)
            }

            // MARK: - Case 4: When enough samples collected → complete
            if collectedSamples.count >= 100 { // adjust threshold as needed
                let parsedValues: [HRVSample] = stride(from: 0, to: collectedSamples.count, by: 2).compactMap { i in
                    guard i + 1 < collectedSamples.count else { return nil }
                    let combined = UInt16(collectedSamples[i]) | (UInt16(collectedSamples[i + 1]) << 8)
                    return HRVSample(value: Int(combined))
                }

                print("✅ Parsed \(parsedValues.count) HRV samples.")
                completion(parsedValues)
                self.onHRVData = nil
            }
        }
    }
}
