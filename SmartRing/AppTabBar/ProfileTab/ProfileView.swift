//
//  ProfileView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var ble = BluetoothViewModel.shared
    @State private var showUnitPopup = false
    @State private var selectedUnit = "Metric (cm/kg)"
    @State private var showFAQ = false
    
    // Health Monitoring States
    @State private var hrInterval = "60Min"
    @State private var spo2Enabled = true
    @State private var stressEnabled = true
    @State private var hrvEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.cyan)
                        .shadow(color: .cyan.opacity(0.6), radius: 10)

                    Text("My Profile")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Manage your Smart Ring, Units, and Health Monitoring")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 20)

                // MARK: - Connected Ring Info
                if let ring = ble.savedRing {
                    CardBackground {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Connected Ring", systemImage: "dot.radiowaves.left.and.right")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name: \(ring.name)")
                                Text("UUID: \(ring.id.uuidString.prefix(8))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Label(ble.isConnected ? "Status: Connected" : "Status: Disconnected",
                                      systemImage: ble.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(ble.isConnected ? .green : .red)
                            }

                            HStack {
                                Button {
                                    ble.disconnect()
                                } label: {
                                    Label("Disconnect", systemImage: "bolt.slash.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)

                                Button {
                                    ble.forgetSavedRing()
                                } label: {
                                    Label("Forget", systemImage: "trash")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            .padding(.top, 8)
                        }
                    }
                }

                // MARK: - Units Settings
                CardBackground {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Units", systemImage: "ruler")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(selectedUnit) {
                                showUnitPopup.toggle()
                            }
                            .font(.subheadline)
                            .foregroundColor(.cyan)
                            .buttonStyle(.plain)
                            .confirmationDialog("Select Measurement Units", isPresented: $showUnitPopup, titleVisibility: .visible) {
                                Button("Metric (cm/kg)") { selectedUnit = "Metric (cm/kg)" }
                                Button("Imperial (ft/lb)") { selectedUnit = "Imperial (ft/lb)" }
                                Button("Cancel", role: .cancel) {}
                            }
                        }
                        Text("Change measurement system for weight, height, and distance.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Health Monitoring
                CardBackground {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Health Monitoring", systemImage: "heart.text.square.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Full-day Heart Rate")
                                    .foregroundColor(.white)
                                Spacer()
                                Menu(hrInterval) {
                                    Button("30Min") { hrInterval = "30Min" }
                                    Button("60Min") { hrInterval = "60Min" }
                                    Button("90Min") { hrInterval = "90Min" }
                                }
                                .foregroundColor(.cyan)
                            }
                            
                            Toggle(isOn: $spo2Enabled) {
                                VStack(alignment: .leading) {
                                    Text("SPO₂ Detection")
                                        .foregroundColor(.white)
                                    Text("Monitor once every hour")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Toggle(isOn: $stressEnabled) {
                                VStack(alignment: .leading) {
                                    Text("Full-day Stress Monitoring")
                                        .foregroundColor(.white)
                                    Text("Monitor every 30 minutes")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Toggle(isOn: $hrvEnabled) {
                                VStack(alignment: .leading) {
                                    Text("Scheduled HRV Monitoring")
                                        .foregroundColor(.white)
                                    Text("Monitor once every hour")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }

                // MARK: - System Settings
                CardBackground {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("System Settings", systemImage: "gearshape.2.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 10) {
                            ProfileRow(icon: "antenna.radiowaves.left.and.right", title: "Bluetooth", subtitle: "Manage ring connection")
                            ProfileRow(icon: "bell.badge.fill", title: "Notifications", subtitle: "Manage alerts and permissions")
                            ProfileRow(icon: "lock.shield", title: "Permissions", subtitle: "Location & background access")
                        }
                    }
                }

                // MARK: - Developer Tools
                CardBackground {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Developer Tools", systemImage: "hammer.fill")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 10) {
                            ProfileRow(icon: "antenna.radiowaves.left.and.right",
                                       title: "Find My Ring",
                                       subtitle: "Make ring blink",
                                       action: { ble.sendFindDeviceCommand() })
                            ProfileRow(icon: "lightbulb.fill",
                                       title: "Blink Twice",
                                       subtitle: "Test ring response",
                                       action: { ble.sendBlinkTwiceCommand() })
                        }
                    }
                }

                // MARK: - FAQs
                CardBackground {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("FAQs", systemImage: "questionmark.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button("View All") { showFAQ.toggle() }
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("• How do I connect my ring?")
                            Text("• Why is my data not syncing?")
                            Text("• How to update firmware?")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                .sheet(isPresented: $showFAQ) {
                    FAQSheetView()
                }

                Text("SmartRing v1.0.0")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 30)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.25),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Reusable Row
struct ProfileRow: View {
    var icon: String
    var title: String
    var subtitle: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            if let action = action {
                Button(action: action) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .foregroundColor(.cyan)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - FAQ Popup Sheet
struct FAQSheetView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Connection")) {
                    Text("How to pair your Smart Ring with the app.")
                    Text("Troubleshooting Bluetooth issues.")
                }
                Section(header: Text("Data & Sync")) {
                    Text("How often does the ring sync data?")
                    Text("Can I export my health records?")
                }
                Section(header: Text("Battery & Updates")) {
                    Text("How to check battery level.")
                    Text("Firmware update procedure.")
                }
            }
            .navigationTitle("FAQs")
        }
    }
}
