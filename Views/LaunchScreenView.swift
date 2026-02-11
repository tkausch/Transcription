//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import SwiftUI

struct LaunchScreenView: View {

    // Matches the AccentColor in the asset catalog
    private let appBlue = Color(red: 0.118, green: 0.498, blue: 0.949)

    var body: some View {
        ZStack {
            appBlue.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.white)

                Text("TranscribeApp")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Spacer()

                Text("© 2026 Thomas Kausch. All rights reserved.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    LaunchScreenView()
}
