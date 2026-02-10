//
//  TutorialOverlay.swift
//  HarborDot
//
//  Created by David Sanders on 1/30/26.
//


import SwiftUI

/// Overlay that shows contextual tutorial hints
struct TutorialOverlay: ViewModifier {
    @StateObject private var tutorialManager = TutorialManager.shared
    let step: TutorialStep
    let targetFrame: CGRect
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if tutorialManager.currentTutorialStep == step {
                    TutorialHintView(
                        step: step,
                        targetFrame: targetFrame,
                        onNext: {
                            tutorialManager.advanceTutorialStep()
                        },
                        onSkip: {
                            tutorialManager.skipTutorial()
                        }
                    )
                }
            }
    }
}

/// Visual hint bubble with pointer
struct TutorialHintView: View {
    let step: TutorialStep
    let targetFrame: CGRect
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onNext()
                }
            
            // Spotlight on target
            Rectangle()
                .fill(.clear)
                .frame(width: targetFrame.width + 20, height: targetFrame.height + 20)
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .shadow(color: .white.opacity(0.5), radius: 20)
            
            // Hint bubble
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: targetFrame.maxY + 40)
                
                VStack(spacing: 16) {
                    // Icon
                    if let icon = step.icon {
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    // Message
                    Text(step.message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button("Skip") {
                            onSkip()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Button(action: onNext) {
                            HStack {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 20)
                )
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Tooltip for feature discovery (smaller, dismissible)
struct FeatureTooltipView: View {
    let tooltip: TooltipType
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -20
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: tooltip.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tooltip.title)
                        .font(.headline)
                    Text(tooltip.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 8)
            )
            .padding(.horizontal)
        }
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1.0
            }
        }
    }
}

// MARK: - View Extension for Easy Use

extension View {
    func tutorialHint(step: TutorialStep, targetFrame: CGRect) -> some View {
        modifier(TutorialOverlay(step: step, targetFrame: targetFrame))
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        TutorialHintView(
            step: .highlightAddTaskButton,
            targetFrame: CGRect(x: 100, y: 500, width: 200, height: 50),
            onNext: {},
            onSkip: {}
        )
    }
}