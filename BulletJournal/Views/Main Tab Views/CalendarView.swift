import SwiftUI
import SwiftData

struct CalendarView: View {
   @Environment(\.modelContext) private var modelContext
   @Environment(\.horizontalSizeClass) var horizontalSizeClass
   @Query private var dayLogs: [DayLog]
   
   @Binding var currentDate: Date
   @Binding var selectedTab: Int
   @Binding var displayedMonth: Date
   var onDateSelected: ((Date) -> Void)? = nil
   
   var isLandscape: Bool = false  // Add this parameter
   var onGoToDay: ((Date) -> Void)? = nil
   
   @State private var selectedDate: Date? = Date()
   
   private var cellHeight: CGFloat {
       if horizontalSizeClass == .regular && isLandscape {
           return 50  // iPad landscape
       } else if horizontalSizeClass == .regular {
           return 80  // iPad portrait
       } else {
           return 40  // iPhone (was 60)
       }
   }
   
   private var isIPad: Bool {
      horizontalSizeClass == .regular
   }
   
   var body: some View {
      NavigationStack {
         ZStack {
            AppTheme.primaryBackground
               .ignoresSafeArea()
            VStack(spacing: 0) {
               // Month/Year Header
               monthHeader
               
               Divider()
               
               // Calendar Grid
               calendarGrid
               
               Divider()
//                  .padding(.vertical, 8)
               
               // Task Details Section
               taskDetailsSection
            }
//            .navigationTitle("Calendar")  //we dont need this. takes up too much room
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
         }
      }
   }
   
   // MARK: - Month Header
   
   private var monthHeader: some View {
      HStack {
         Button(action: { changeMonth(by: -1) }) {
            Image(systemName: "chevron.left")
               .font(.title3)
               .frame(width: 44, height: 44)
         }
         
         Spacer()
         
         Text(displayedMonth.monthAndYear)
            .font(.title3)
            .fontWeight(.semibold)
         
         Spacer()
         
         Button(action: { changeMonth(by: 1) }) {
            Image(systemName: "chevron.right")
               .font(.title3)
               .frame(width: 44, height: 44)
         }
      }
      .padding(.horizontal)
      .padding(.vertical, 16)
      .background(AppTheme.secondaryBackground)
      .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
   }
   
   // MARK: - Calendar Grid
   
   private var calendarGrid: some View {
      VStack(spacing: 0) {
         // Days of week header
         HStack(spacing: 0) {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
               Text(day)
                  .font(.caption)
                  .fontWeight(.semibold)
                  .frame(maxWidth: .infinity)
                  .foregroundColor(.secondary)
            }
         }
         .padding(.vertical, 8)
         
         // Calendar days
         let daysInMonth = generateDaysInMonth()
         LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(daysInMonth.indices, id: \.self) { index in
               if let date = daysInMonth[index] {
                  DayCell(
                     date: date,
                     isSelected: selectedDate?.isSameDay(as: date) ?? false,
                     isToday: date.isSameDay(as: Date()),
                     dayLog: getDayLog(for: date),
                     isLandscape: isLandscape
                  )
                  .onTapGesture {
                     withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                        // NEW: Call callback if provided (Mac cross-pane navigation)
                            onDateSelected?(date)
                     }
                  }
               } else {
                  Color.clear
                     .frame(height: cellHeight)
               }
            }
         }
         .padding(.horizontal, 8)
      }
      .padding(.bottom)
   }
   
   // MARK: - Task Details Section
   
   private var taskDetailsSection: some View {
      VStack(alignment: .leading, spacing: 12) {
         HStack {
            if let selectedDate = selectedDate {
               VStack(alignment: .leading, spacing: 4) {
                  Text("Tasks")
                     .font(.headline)
                  Text(selectedDate, style: .date)
                     .font(.subheadline)
                     .foregroundColor(.secondary)
               }
            } else {
               Text("Tasks")
                  .font(.headline)
            }
            
            Spacer()
            
            if selectedDate != nil {
               Button(action: goToDayView) {
                  HStack(spacing: 4) {
                     Text("Go to Day")
                        .font(.subheadline)
                     Image(systemName: "arrow.right")
                        .font(.caption)
                  }
                  .foregroundColor(.blue)
               }
            }
         }
         .padding(.horizontal)
         .padding(.top, 8)
         
         Divider()
            .padding(.horizontal)
         
         ScrollView {
            if let selectedDate = selectedDate {
               if let dayLog = getDayLog(for: selectedDate), let tasks = dayLog.tasks, !tasks.isEmpty {
                  VStack(alignment: .leading, spacing: 12) {
                     ForEach(dayLog.tasks ?? []) { task in
                        HStack(spacing: 8) {
                           Circle()
                              .fill(Color.fromString(task.color!))
                              .frame(width: 12, height: 12)
                           
                           VStack(alignment: .leading, spacing: 2) {
                              Text(task.name!)
                                 .font(.body)
                              
                              if !task.notes!.isEmpty {
                                 Text(task.notes!)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                              }
                           }
                           
                           Spacer()
                           
                           // Status badge
                           taskStatusBadge(for: task.status!)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                     }
                  }
               } else {
                  VStack(spacing: 12) {
                     Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                     Text("No tasks for this day")
                        .foregroundColor(.secondary)
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.top, 40)
               }
            } else {
               Text("Select a day to view tasks")
                  .foregroundColor(.secondary)
                  .frame(maxWidth: .infinity)
                  .padding()
            }
         }
      }
      .frame(maxHeight: .infinity)
      #if os(iOS)
      .background(Color(uiColor: .systemGroupedBackground))
      #else
      .background(Color(nsColor: .controlBackgroundColor))
      #endif
   }
   
   // MARK: - Helper Views
   
   @ViewBuilder
   private func taskStatusBadge(for status: TaskStatus) -> some View {
      switch status {
         case .normal:
            EmptyView()
         case .inProgress:
            Image(systemName: "clock.fill")
               .font(.caption)
               .foregroundColor(.green)
         case .complete:
            Image(systemName: "checkmark.circle.fill")
               .font(.caption)
               .foregroundColor(.green)
         case .notCompleted:
            Image(systemName: "xmark.circle.fill")
               .font(.caption)
               .foregroundColor(.red)
      }
   }
   
   // MARK: - Helper Methods
   
   private func changeMonth(by value: Int) {
      if let newDate = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
         withAnimation {
            displayedMonth = newDate
         }
      }
   }
   
   private func getDayLog(for date: Date) -> DayLog? {
      dayLogs.first { $0.date?.isSameDay(as: date) ?? false }
   }
   
   private func generateDaysInMonth() -> [Date?] {
      let calendar = Calendar.current
      let components = calendar.dateComponents([.year, .month], from: displayedMonth)
      guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
      
      let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
      let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
      
      var days: [Date?] = []
      
      // Add empty cells for days before the first day of the month
      for _ in 1..<firstWeekday {
         days.append(nil)
      }
      
      // Add all days of the month
      for day in 1...daysInMonth {
         if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
            days.append(date)
         }
      }
      
      return days
   }
   
   private func goToDayView() {
      #if os(macOS)
      onGoToDay?(currentDate)
      #else
      guard let selectedDate = selectedDate else { return }
      currentDate = selectedDate
      selectedTab = 0 // Switch to iPhone Day View tab
      onGoToDay?(currentDate) //Switch to correct sidebar item on iPad
      #endif
   }
}

// MARK: - Day Cell

struct DayCell: View {
   @Environment(\.horizontalSizeClass) var horizontalSizeClass
   @Environment(\.verticalSizeClass) var verticalSizeClass
   
   let date: Date
   let isSelected: Bool
   let isToday: Bool
   let dayLog: DayLog?
   let isLandscape: Bool
   
   private var cellHeight: CGFloat {
       if horizontalSizeClass == .regular && isLandscape {
//          print("ipad landscape")
           return 50  // iPad landscape
       } else if horizontalSizeClass == .regular {
//          print("ipad portrait")
           return 80  // iPad portrait
       } else {
//          print("iphone")
           return 40  // iPhone old = 60
       }
   }
   
   var body: some View {
      VStack(spacing: 4) {
         Text("\(Calendar.current.component(.day, from: date))")
            .font(.system(size: horizontalSizeClass == .regular ? 20 : 16))
            .fontWeight(isToday ? .bold : .regular)
            .foregroundColor(textColor)
         
         // Color dots for tasks
         if let dayLog = dayLog, let tasks = dayLog.tasks, !tasks.isEmpty {
            HStack(spacing: 3) {
               ForEach(getUniqueTaskColors(), id: \.self) { color in
                  Circle()
                     .fill(Color.fromString(color))
                     .frame(width: 6, height: 6)
               }
            }
            .padding(.top, 2)
         } else {
            // Empty space to maintain consistent cell height
            Spacer()
               .frame(height: 8)
         }
      }
      .frame(height: cellHeight)
      .frame(maxWidth: .infinity)
      .background(backgroundColor)
      .cornerRadius(8)
      .overlay(
         RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: isToday ? 2 : 0)
      )
   }
   
   private var textColor: Color {
      if isSelected {
         return .white
      } else if isToday {
         return .blue
      } else {
         return .primary
      }
   }
   
   private var backgroundColor: Color {
      if isSelected {
         return .blue
      } else {
#if os(iOS)
return Color(uiColor: .systemBackground)
#else
return Color(nsColor: .windowBackgroundColor)
#endif
      }
   }
   
   private var borderColor: Color {
      if isToday && !isSelected {
         return .blue.opacity(0.5)
      } else {
         return .clear
      }
   }
   
   private func getUniqueTaskColors() -> [String] {
      guard let dayLog = dayLog, let tasks = dayLog.tasks else { return [] }
      
      // Maintain order of first occurrence of each color
      var seenColors = Set<String>()
      var orderedColors: [String] = []
      
      for task in tasks {
         if !seenColors.contains(task.color!) {
            seenColors.insert(task.color!)
            orderedColors.append(task.color!)
         }
      }
      
      // Limit to 3 dots to prevent overcrowding
      return Array(orderedColors.prefix(3))
   }
}

#Preview {
   #if os(iOS)
   MainTabView()
      .environmentObject(DeepLinkManager())
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
   #elseif os(macOS)
   MacMainView()
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
   #endif
}
