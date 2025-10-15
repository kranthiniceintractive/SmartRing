//
//  HRVListView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//


import SwiftUI

struct HRVListView: View {
    @ObservedObject var viewModel = BluetoothViewModel.shared

    var body: some View {
        List {
            ForEach(viewModel.hrvWeekData) { day in
                Section(header: Text(day.date.formatted(date: .abbreviated, time: .omitted))) {
                    ForEach(day.samples) { s in
                        HStack {
                            Text("HRV: \(s.value)")
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
