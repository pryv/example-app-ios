//
//  PryvStream.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 07.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import HealthKit
import PryvApiSwiftKit

class PryvStream {
    public var streamId: String
    private var type: String
    
    // MARK: - public library
    
    /// Create a bridge from Pryv's event to the data in HealthKit
    /// - Parameters:
    ///   - streamId: ths streamId of the events in Pryv
    ///   - type: the type of the events in Pryv
    public init(streamId: String, type: String) {
        self.streamId = streamId
        self.type = type
    }
    
    /// Create an `HKSample` from a Pryv event
    /// - Parameter content: the content of the event
    /// - Returns: an `HKSample` containing the same data as in the Pryv event
    public func healthKitSample(from content: Double) -> HKSample? {
        switch streamId {
        case "weight", "height":
            let quantityAmount = HKQuantity(unit: hkUnit()!, doubleValue: content)
            return HKQuantitySample(type: hkSampleType() as! HKQuantityType, quantity: quantityAmount, start: Date(), end: Date())
        default: // You can add as many stream as you want to better match your pryv lab
            return nil
        }
    }
    
    /// Translate the Pryv's stream id to an health kit sample type
    /// - Returns: an `HKSampleType` corresponding to `event["streamId"]`
    public func hkSampleType() -> HKSampleType? {
        switch streamId {
        case "weight":
            return HKQuantityType.quantityType(forIdentifier: .bodyMass)
        case "height":
            return HKQuantityType.quantityType(forIdentifier: .height)
        default: // You can add as many stream as you want to better match your pryv lab
            return nil
        }
    }
    
    // MARK: - private helpers functions for the library
    
    /// Translate the Pryv's event type to an health kit sample type
    /// - Returns: an `HKUnit` corresponding to `event["type"]` unit
    private func hkUnit() -> HKUnit? {
        switch streamId {
        case "weight":
            return HKUnit.gramUnit(with: .kilo)
        case "height":
            return HKUnit.meterUnit(with: .centi)
        default: // You can add as many stream as you want to better match your pryv lab
            return nil
        }
    }
}
