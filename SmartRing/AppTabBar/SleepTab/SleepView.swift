//
//  SleepView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI

struct SleepView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("😴 Sleep")
                .font(.largeTitle)
                .bold()
            Text("View your sleep quality and duration.")
                .foregroundColor(.gray)
        }
    }
}
