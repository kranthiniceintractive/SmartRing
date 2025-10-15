//
//  ActivityView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("💪 Activity")
                .font(.largeTitle)
                .bold()
            Text("Track your steps, calories, and workouts.")
                .foregroundColor(.gray)
        }
    }
}
