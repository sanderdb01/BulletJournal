//
//  HarborDotWidgetBundle.swift
//  HarborDotWidget
//
//  Created by David Sanders on 10/3/25.
//

import WidgetKit
import SwiftUI

@main
struct HarborDotWidgetBundle: WidgetBundle {
    var body: some Widget {
        HarborDotWidget()
        HarborDotWidgetControl()
        HarborDotWidgetLiveActivity()
    }
}
