//
//  WelcomeCarouselView.swift
//  HarborDot
//
//  Created by David Sanders on 1/30/26.
//


import SwiftUI

struct WelcomeCarouselView: View {
    @StateObject private var tutorialManager = TutorialManager.shared
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to HarborDot",
            description: "Your privacy-first task manager that keeps you organized, one day at a time.",
            imageName: "checkmark.circle.fill",
            imageColor: .blue
        ),
        OnboardingPage(
            title: "Day-Based Organization",
            description: "Focus on today's tasks. Use color tags to organize and visualize your work.",
            imageName: "calendar.circle.fill",
            imageColor: .green
        ),
        OnboardingPage(
            title: "Sync Across Devices",
            description: "Your data syncs securely via iCloud. Everything stays private on Apple's servers.",
            imageName: "icloud.circle.fill",
            imageColor: .purple
        ),
        OnboardingPage(
            title: "Ready to Start?",
            description: "Let's create your first task and explore what HarborDot can do!",
            imageName: "sparkles",
            imageColor: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        tutorialManager.skipTutorial()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Last page - show Get Started
                        Button(action: {
                            tutorialManager.completeWelcomeCarousel()
                        }) {
                            HStack {
                                Text("Get Started")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    } else {
                        // Other pages - show Next
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let imageColor: Color
}

// MARK: - Individual Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(page.imageColor)
                .padding(.bottom, 8)
            
            // Title
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    WelcomeCarouselView()
}