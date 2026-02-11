//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

// MARK: - Page Model

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        systemImage: "waveform.circle.fill",
        title: "Welcome to Transcribe",
        subtitle: "Turn your audio into text — fast, private, and entirely on-device.",
        gradient: [.blue, .cyan]
    ),
    OnboardingPage(
        systemImage: "brain.head.profile",
        title: "Accurate Transcriptions",
        subtitle: "Powered by OpenAI Whisper, one of the most accurate speech recognition models available.",
        gradient: [.purple, .indigo]
    ),
    OnboardingPage(
        systemImage: "square.and.arrow.down.fill",
        title: "Import Any Audio",
        subtitle: "Supports MP3, M4A, WAV, and MP4 files from anywhere on your device.",
        gradient: [.orange, .pink]
    ),
    OnboardingPage(
        systemImage: "globe",
        title: "Language Detection",
        subtitle: "Automatically detects the spoken language in your recordings — no configuration needed.",
        gradient: [.green, .teal]
    ),
    OnboardingPage(
        systemImage: "arrow.right.circle.fill",
        title: "Get Started",
        subtitle: "Download the Whisper model once to enable transcriptions. No data ever leaves your device.",
        gradient: [.blue, .purple]
    ),
]

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLast: Bool
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(
                    LinearGradient(
                        colors: page.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: page.gradient.first?.opacity(0.4) ?? .clear, radius: 20, x: 0, y: 10)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Spacer()

            if isLast {
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: page.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.bottom, 8)
            } else {
                // Spacer to keep layout consistent across pages
                Color.clear
                    .frame(height: 56 + 8)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    let onDismiss: () -> Void

    @State private var currentPage = 0

    private var isLast: Bool { currentPage == pages.count - 1 }

    var body: some View {
#if os(iOS)
        let lastIndex = pages.count - 1
        TabView(selection: $currentPage) {
            ForEach(0..<pages.count, id: \.self) { index in
                OnboardingPageView(
                    page: pages[index],
                    isLast: index == lastIndex,
                    onGetStarted: onDismiss
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)
#else
        macOSBody
#endif
    }

#if !os(iOS)
    /// Custom paged layout for macOS with prev/next buttons and dot indicators.
    private var macOSBody: some View {
        VStack(spacing: 0) {
            // Page content
            OnboardingPageView(
                page: pages[currentPage],
                isLast: isLast,
                onGetStarted: onDismiss
            )
            .animation(.easeInOut, value: currentPage)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            .id(currentPage)

            // Navigation bar: Back · dots · Next
            HStack(spacing: 24) {
                Button(action: { withAnimation { currentPage -= 1 } }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .disabled(currentPage == 0)

                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                Button(action: {
                    if isLast { onDismiss() } else { withAnimation { currentPage += 1 } }
                }) {
                    Image(systemName: isLast ? "checkmark" : "chevron.right")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 24)
        }
    }
#endif
}

// MARK: - Platform Cover Modifier

/// Presents OnboardingView as a full-screen cover on iOS and a sheet on macOS.
struct OnboardingCoverModifier: ViewModifier {
    let appSettings: AppSettings

    private var isPresented: Binding<Bool> {
        Binding(
            get: { !appSettings.hasSeenOnboarding },
            set: { _ in }
        )
    }

    private func dismiss() {
        appSettings.hasSeenOnboarding = true
        // TranscriptionListViewModel.onAppear() opens Settings automatically
        // if the model has not been downloaded yet.
    }

    func body(content: Content) -> some View {
        content
#if os(iOS)
            .fullScreenCover(isPresented: isPresented) {
                OnboardingView(onDismiss: dismiss)
            }
#else
            .sheet(isPresented: isPresented) {
                OnboardingView(onDismiss: dismiss)
                    .frame(minWidth: 480, minHeight: 600)
            }
#endif
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onDismiss: {})
}
