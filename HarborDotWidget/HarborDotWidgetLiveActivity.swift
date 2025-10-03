//
//  HarborDotWidgetLiveActivity.swift
//  HarborDotWidget
//
//  Created by David Sanders on 10/3/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HarborDotWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HarborDotWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HarborDotWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HarborDotWidgetAttributes {
    fileprivate static var preview: HarborDotWidgetAttributes {
        HarborDotWidgetAttributes(name: "World")
    }
}

extension HarborDotWidgetAttributes.ContentState {
    fileprivate static var smiley: HarborDotWidgetAttributes.ContentState {
        HarborDotWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HarborDotWidgetAttributes.ContentState {
         HarborDotWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HarborDotWidgetAttributes.preview) {
   HarborDotWidgetLiveActivity()
} contentStates: {
    HarborDotWidgetAttributes.ContentState.smiley
    HarborDotWidgetAttributes.ContentState.starEyes
}
