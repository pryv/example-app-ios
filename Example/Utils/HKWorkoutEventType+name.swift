//
//  HKWorkoutEventType+name.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import HealthKit

public extension HKWorkoutEventType {
    
    /// Mapping from the workout event type to its human readable name
    var name: String {
        switch self {
        case .motionPaused: return "motionPaused"
        case .lap: return "lap"
        case .marker: return "marker"
        case .motionResumed: return "motionResumed"
        case .pause: return "pause"
        case .pauseOrResumeRequest: return "pauseOrResumeRequest"
        case .resume: return "resume"
        case .segment: return "segment"
        default: return "other"
        }
    }
}
