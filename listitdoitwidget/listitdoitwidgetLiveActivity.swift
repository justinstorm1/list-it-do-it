//
//  listitdoitwidgetLiveActivity.swift
//  listitdoitwidget
//
//  Created by Justin Storm on 8/23/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct listitdoitwidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct listitdoitwidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: listitdoitwidgetAttributes.self) { context in
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

extension listitdoitwidgetAttributes {
    fileprivate static var preview: listitdoitwidgetAttributes {
        listitdoitwidgetAttributes(name: "World")
    }
}

extension listitdoitwidgetAttributes.ContentState {
    fileprivate static var smiley: listitdoitwidgetAttributes.ContentState {
        listitdoitwidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: listitdoitwidgetAttributes.ContentState {
         listitdoitwidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: listitdoitwidgetAttributes.preview) {
   listitdoitwidgetLiveActivity()
} contentStates: {
    listitdoitwidgetAttributes.ContentState.smiley
    listitdoitwidgetAttributes.ContentState.starEyes
}
