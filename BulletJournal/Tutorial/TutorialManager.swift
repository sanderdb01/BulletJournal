//
//  TutorialManager.swift
//  HarborDot
//
//  Created by David Sanders on 1/30/26.
//


import Foundation
import SwiftUI
internal import Combine

/// Manages the onboarding tutorial state and progress
class TutorialManager: ObservableObject {
    // UserDefaults keys
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let hasCreatedFirstTaskKey = "hasCreatedFirstTask"
    private let hasViewedCalendarKey = "hasViewedCalendar"
    private let hasViewedNotebookKey = "hasViewedNotebook"
    private let hasReorderedTasksKey = "hasReorderedTasks"
    private let hasSharedTaskKey = "hasSharedTask"
    private let hasViewedSettingsKey = "hasViewedSettings"
    private let hasExportedDataKey = "hasExportedData"
    
    // Published properties for reactive UI
    @Published var showWelcomeCarousel: Bool = false
    @Published var currentTutorialStep: TutorialStep?
    @Published var showTooltip: TooltipType?
    
    // Singleton
    static let shared = TutorialManager()
    
    private init() {
        // Check if this is first launch
        if !UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) {
            showWelcomeCarousel = true
        }
    }
    
    // MARK: - Onboarding State
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }
    
    var hasCreatedFirstTask: Bool {
        get { UserDefaults.standard.bool(forKey: hasCreatedFirstTaskKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCreatedFirstTaskKey) }
    }
    
    var hasViewedCalendar: Bool {
        get { UserDefaults.standard.bool(forKey: hasViewedCalendarKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasViewedCalendarKey) }
    }
    
    var hasViewedNotebook: Bool {
        get { UserDefaults.standard.bool(forKey: hasViewedNotebookKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasViewedNotebookKey) }
    }
    
    var hasReorderedTasks: Bool {
        get { UserDefaults.standard.bool(forKey: hasReorderedTasksKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasReorderedTasksKey) }
    }
    
    var hasSharedTask: Bool {
        get { UserDefaults.standard.bool(forKey: hasSharedTaskKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSharedTaskKey) }
    }
    
    var hasViewedSettings: Bool {
        get { UserDefaults.standard.bool(forKey: hasViewedSettingsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasViewedSettingsKey) }
    }
    
    var hasExportedData: Bool {
        get { UserDefaults.standard.bool(forKey: hasExportedDataKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasExportedDataKey) }
    }
    
    // MARK: - Tutorial Flow Control
    
    func completeWelcomeCarousel() {
        showWelcomeCarousel = false
        // Start interactive tutorial
        currentTutorialStep = .highlightAddTaskButton
    }
    
    func advanceTutorialStep() {
        guard let current = currentTutorialStep else { return }
        
        switch current {
        case .highlightAddTaskButton:
            currentTutorialStep = .showTaskNameHint
        case .showTaskNameHint:
            currentTutorialStep = .showColorTagHint
        case .showColorTagHint:
            currentTutorialStep = .showNotesHint
        case .showNotesHint:
            currentTutorialStep = .showSaveHint
        case .showSaveHint:
            currentTutorialStep = .showCompleteTaskHint
        case .showCompleteTaskHint:
            currentTutorialStep = .showSwipeActionsHint
        case .showSwipeActionsHint:
            currentTutorialStep = .showReorderHint
        case .showReorderHint:
            currentTutorialStep = nil
            hasCompletedOnboarding = true
        }
    }
    
    func skipTutorial() {
        currentTutorialStep = nil
        showWelcomeCarousel = false
        hasCompletedOnboarding = true
    }
    
    // MARK: - Feature Discovery
    
    func checkAndShowTooltip(for feature: TooltipType) {
        switch feature {
        case .calendar:
            if !hasViewedCalendar {
                showTooltip = feature
                hasViewedCalendar = true
            }
        case .notebook:
            if !hasViewedNotebook {
                showTooltip = feature
                hasViewedNotebook = true
            }
        case .settings:
            if !hasViewedSettings {
                showTooltip = feature
                hasViewedSettings = true
            }
        case .export:
            if !hasExportedData {
                showTooltip = feature
            }
        case .reorder:
            if !hasReorderedTasks {
                showTooltip = feature
            }
        }
    }
    
    func dismissTooltip() {
        showTooltip = nil
    }
    
    // MARK: - Reset (for testing)
    
    func resetTutorial() {
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.removeObject(forKey: hasCreatedFirstTaskKey)
        UserDefaults.standard.removeObject(forKey: hasViewedCalendarKey)
        UserDefaults.standard.removeObject(forKey: hasViewedNotebookKey)
        UserDefaults.standard.removeObject(forKey: hasReorderedTasksKey)
        UserDefaults.standard.removeObject(forKey: hasSharedTaskKey)
        UserDefaults.standard.removeObject(forKey: hasViewedSettingsKey)
        UserDefaults.standard.removeObject(forKey: hasExportedDataKey)
        
        showWelcomeCarousel = true
        currentTutorialStep = nil
        showTooltip = nil
    }
}

// MARK: - Tutorial Steps

enum TutorialStep: String, Codable {
    case highlightAddTaskButton
    case showTaskNameHint
    case showColorTagHint
    case showNotesHint
    case showSaveHint
    case showCompleteTaskHint
    case showSwipeActionsHint
    case showReorderHint
    
    var message: String {
        switch self {
        case .highlightAddTaskButton:
            return "Tap here to create your first task"
        case .showTaskNameHint:
            return "Give your task a name"
        case .showColorTagHint:
            return "Choose a color tag to organize your tasks"
        case .showNotesHint:
            return "Add notes or details (optional)"
        case .showSaveHint:
            return "Tap Save when you're ready"
        case .showCompleteTaskHint:
            return "Tap the circle to mark tasks complete"
        case .showSwipeActionsHint:
            return "Swipe left on a task to edit or delete"
        case .showReorderHint:
            return "Tap the three-line icon to reorder tasks"
        }
    }
    
    var icon: String? {
        switch self {
        case .highlightAddTaskButton:
            return "plus.circle.fill"
        case .showTaskNameHint:
            return "text.cursor"
        case .showColorTagHint:
            return "tag.fill"
        case .showNotesHint:
            return "note.text"
        case .showSaveHint:
            return "checkmark.circle.fill"
        case .showCompleteTaskHint:
            return "circle"
        case .showSwipeActionsHint:
            return "hand.draw"
        case .showReorderHint:
            return "line.3.horizontal"
        }
    }
}

// MARK: - Tooltip Types

enum TooltipType: String, Codable {
    case calendar
    case notebook
    case settings
    case export
    case reorder
    
    var title: String {
        switch self {
        case .calendar:
            return "Calendar View"
        case .notebook:
            return "Notebook"
        case .settings:
            return "Settings"
        case .export:
            return "Export Your Data"
        case .reorder:
            return "Reorder Tasks"
        }
    }
    
    var message: String {
        switch self {
        case .calendar:
            return "See all your tasks across different days in calendar view"
        case .notebook:
            return "Create notes with markdown formatting support"
        case .settings:
            return "Manage tags, export data, and customize your experience"
        case .export:
            return "Backup your data by exporting to JSON. You can import it later on any device."
        case .reorder:
            return "Drag tasks to rearrange their order"
        }
    }
    
    var icon: String {
        switch self {
        case .calendar:
            return "calendar"
        case .notebook:
            return "book.fill"
        case .settings:
            return "gearshape.fill"
        case .export:
            return "square.and.arrow.up"
        case .reorder:
            return "line.3.horizontal"
        }
    }
}
