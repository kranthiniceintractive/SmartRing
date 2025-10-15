//
//  ProfileView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("👤 Profile")
                .font(.largeTitle)
                .bold()
            Text("Manage your Smart Ring settings and profile.")
                .foregroundColor(.gray)
        }
    }
}
