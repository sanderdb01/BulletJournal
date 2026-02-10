//
//  MacTimePicker.swift
//  HarborDot
//
//  Created by David Sanders on 2/10/26.
//

import SwiftUI
import SwiftData

// MARK: - Custom Time Picker for Mac
struct MacTimePicker: View {
    @Binding var time: Date
    
    private var hour12: Int {
        let hour24 = Calendar.current.component(.hour, from: time)
        if hour24 == 0 { return 12 }
        if hour24 > 12 { return hour24 - 12 }
        return hour24
    }
    
    private var isPM: Bool {
        Calendar.current.component(.hour, from: time) >= 12
    }
    
    private var minute: Int {
        Calendar.current.component(.minute, from: time)
    }
    
    var body: some View {
        HStack {
            Text("Time")
            Spacer()
            
            // Hour picker (1-12)
            Picker("Hour", selection: Binding(
                get: { hour12 },
                set: { newHour in
                    updateTime(hour12: newHour, minute: minute, isPM: isPM)
                }
            )) {
                ForEach(1...12, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 60)
            
            Text(":")
            
            // Minute picker
            Picker("Minute", selection: Binding(
                get: { minute },
                set: { newMinute in
                    updateTime(hour12: hour12, minute: newMinute, isPM: isPM)
                }
            )) {
                ForEach(0..<60, id: \.self) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 60)
           
            // AM/PM picker
            Picker("Period", selection: Binding(
                get: { isPM },
                set: { newIsPM in
                    updateTime(hour12: hour12, minute: minute, isPM: newIsPM)
                }
            )) {
                Text("AM").tag(false)
                Text("PM").tag(true)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 60)
        }
    }
    
    private func updateTime(hour12: Int, minute: Int, isPM: Bool) {
        var hour24 = hour12
        
        // Convert 12-hour to 24-hour
        if isPM && hour12 != 12 {
            hour24 = hour12 + 12
        } else if !isPM && hour12 == 12 {
            hour24 = 0
        }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: time)
        components.hour = hour24
        components.minute = minute
        
        if let newDate = Calendar.current.date(from: components) {
            time = newDate
        }
    }
}
