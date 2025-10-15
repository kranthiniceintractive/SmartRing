//
//  BluetoothView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI
import CoreBluetooth

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
