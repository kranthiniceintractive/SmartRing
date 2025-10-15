//
//  HomeView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI
import Charts

struct HomeView: View {
    @State private var ringData: RingData? = .dummy
    @ObservedObject private var ble = BluetoothViewModel.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let data = ringData {
                        if let activity = data.activity {
                            ActivityCard(activity: activity)
                                .onTapGesture { ble.sendBlinkTwiceCommand() }
                        }
                        if let sleep = data.sleep {
                            SleepCard(sleep: sleep)
                                .onTapGesture { ble.sendFindDeviceCommand() }
                        }
                        if let heartRate = data.heartRate {
                            HeartRateChartCard(heartRate: heartRate)
                        }
                        if let hrv = data.hrv {
                            NavigationLink {
                                HRVListView()
                            } label: {
                                HRVChartCard(hrv: hrv)
                            }
                            .buttonStyle(.plain) // prevents tap animation
                        }
                        if let bloodOxygen = data.bloodOxygen {
                            BloodOxygenChartCard(oxygen: bloodOxygen)
                        }
                        if let stress = data.stress {
                            StressCard(stress: stress)
                        }
                    } else {
                        EmptyPlaceholderView()
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [
                    Color.blue.opacity(0.2),
                    Color.black.opacity(0.1)
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct EmptyPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Connect your ring to view your latest stats.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 100)
    }
}

struct RingData {
    var activity: ActivityData?
    var sleep: SleepData?
    var heartRate: HeartRateData?
    var hrv: HRVData?
    var bloodOxygen: BloodOxygenData?
    var stress: StressData?
}

struct ActivityData {
    var date: String
    var score: Int
    var calories: Int
    var steps: Int
    var distanceKm: Double
}

struct SleepData {
    var date: String
    var score: Int
    var duration: String
}

struct HeartRateData {
    var date: String
    var bpm: Int
    var range: String
}

struct HRVData {
    var date: String
    var ms: Int
    var condition: String
}

struct BloodOxygenData {
    var date: String
    var percent: Int
    var range: String
}

struct StressData {
    var date: String
    var score: Int
    var average: Int
    var range: String
}

// Dummy preview data
extension RingData {
    static let dummy = RingData(
        activity: ActivityData(date: "Oct 15, 2025", score: 100, calories: 73, steps: 2591, distanceKm: 1.71),
        sleep: SleepData(date: "Oct 08, 2025", score: 91, duration: "08H 27M"),
        heartRate: HeartRateData(date: "Oct 15, 2025", bpm: 61, range: "61–61 bpm"),
        hrv: HRVData(date: "Oct 15, 2025", ms: 39, condition: "Normal"),
        bloodOxygen: BloodOxygenData(date: "Oct 15, 2025", percent: 99, range: "99–99%"),
        stress: StressData(date: "Oct 15, 2025", score: 22, average: 34, range: "22–53")
    )
}
// MARK: Activity
struct ActivityCard: View {
    let activity: ActivityData
    var body: some View {
        CardBackground {
            VStack(spacing: 8) {
                HStack {
                    Text("Activity").bold()
                    Spacer()
                    Text(activity.date).font(.caption).foregroundColor(.secondary)
                }
                .padding(.bottom, 4)
                
                ProgressArc(value: 100)
                    .frame(height: 120)
                
                Text("Excellent")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 40) {
                    MetricView(icon: "flame.fill", value: "\(activity.calories)", unit: "Kcal")
                    MetricView(icon: "figure.walk", value: "\(activity.steps)", unit: "Steps")
                    MetricView(icon: "location.fill", value: String(format: "%.2f", activity.distanceKm), unit: "Km")
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: Sleep
struct SleepCard: View {
    let sleep: SleepData
    var body: some View {
        CardBackground {
            VStack(spacing: 8) {
                HStack {
                    Text("Sleep").bold()
                    Spacer()
                    Text(sleep.date).font(.caption).foregroundColor(.secondary)
                }
                ProgressArc(value: Double(sleep.score))
                    .frame(height: 120)
                Text("Excellent")
                    .font(.headline)
                Text(sleep.duration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: Stress
struct StressCard: View {
    let stress: StressData
    var body: some View {
        CardBackground {
            VStack(spacing: 8) {
                HStack {
                    Text("Stress").bold()
                    Spacer()
                    Text(stress.date).font(.caption).foregroundColor(.secondary)
                }
                ProgressArc(value: Double(stress.score))
                    .frame(height: 120)
                Text("Relax")
                    .font(.headline)
                HStack {
                    VStack {
                        Text("Daily Average")
                            .font(.caption)
                        Text("\(stress.average)")
                            .font(.headline)
                    }
                    Spacer()
                    VStack {
                        Text("Daily Range")
                            .font(.caption)
                        Text(stress.range)
                            .font(.headline)
                    }
                }
            }
        }
    }
}
struct CardBackground<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            content.padding()
        }
        .padding(.horizontal, 4)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
}

struct MetricView: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
            Text(value)
                .font(.headline)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProgressArc: View {
    var value: Double
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(value / 100))
                .stroke(AngularGradient(gradient: Gradient(colors: [.blue, .green]), center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(value))")
                .font(.system(size: 36, weight: .bold))
        }
    }
}
// MARK: - Chart Components

struct HeartRateChartCard: View {
    let heartRate: HeartRateData
    var body: some View {
        CardBackground {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Heart Rate").bold()
                    Spacer()
                    Text(heartRate.date).font(.caption).foregroundColor(.secondary)
                }
                Chart(heartRate.dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("BPM", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.red)
                    PointMark(
                        x: .value("Time", point.time),
                        y: .value("BPM", point.value)
                    )
                    .foregroundStyle(.red)
                }
                .frame(height: 160)
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(.red)
                    Text("\(heartRate.bpm) bpm").font(.title2).bold()
                    Spacer()
                    Text(heartRate.range).font(.footnote).foregroundColor(.secondary)
                }
            }
        }
    }
}

struct HRVChartCard: View {
    let hrv: HRVData
    var body: some View {
        CardBackground {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("HRV").bold()
                    Spacer()
                    Text(hrv.date).font(.caption).foregroundColor(.secondary)
                }
                Chart(hrv.dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("HRV", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.cyan)
                    PointMark(
                        x: .value("Time", point.time),
                        y: .value("HRV", point.value)
                    )
                    .foregroundStyle(.cyan)
                }
                .frame(height: 160)
                HStack {
                    Image(systemName: "waveform.path.ecg").foregroundColor(.cyan)
                    Text("\(hrv.ms) ms").font(.title2).bold()
                    Spacer()
                    Text(hrv.condition).font(.footnote).foregroundColor(.secondary)
                }
            }
        }
    }
}

struct BloodOxygenChartCard: View {
    let oxygen: BloodOxygenData
    var body: some View {
        CardBackground {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Blood Oxygen").bold()
                    Spacer()
                    Text(oxygen.date).font(.caption).foregroundColor(.secondary)
                }
                Chart(oxygen.dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("SpO₂", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    PointMark(
                        x: .value("Time", point.time),
                        y: .value("SpO₂", point.value)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 160)
                HStack {
                    Image(systemName: "lungs.fill").foregroundColor(.blue)
                    Text("\(oxygen.percent)%").font(.title2).bold()
                    Spacer()
                    Text(oxygen.range).font(.footnote).foregroundColor(.secondary)
                }
            }
        }
    }
}

// Dummy chart data for previews
extension HeartRateData {
    var dataPoints: [ChartPoint] {
        [ChartPoint(time: "08:00", value: 61), ChartPoint(time: "09:00", value: 70), ChartPoint(time: "10:00", value: 76), ChartPoint(time: "11:00", value: 65)]
    }
}
extension HRVData {
    var dataPoints: [ChartPoint] {
        [ChartPoint(time: "08:00", value: 39), ChartPoint(time: "09:00", value: 45), ChartPoint(time: "10:00", value: 32), ChartPoint(time: "11:00", value: 37)]
    }
}
extension BloodOxygenData {
    var dataPoints: [ChartPoint] {
        [ChartPoint(time: "08:00", value: 99), ChartPoint(time: "09:00", value: 98), ChartPoint(time: "10:00", value: 99), ChartPoint(time: "11:00", value: 99)]
    }
}

struct ChartPoint: Identifiable {
    var id = UUID()
    var time: String
    var value: Double
}
