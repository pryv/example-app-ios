//
//  HKBridge.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 03.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import HealthKit
import PryvApiSwiftKit

struct HKStream {
    let type: HKObjectType!
    let unit: HKUnit?
    let updateFrequency: HKUpdateFrequency!
}

class HKEvent {
    private let HKStream: HKStream!
    
    init(HKStream: HKStream) {
        self.HKStream = HKStream
    }
    
    public func streamId() -> String {
        // TODO: type.identifier
    }
    
    public func content(from sample: HKSample) -> Any {
        // TODO: if unit { (sample as? HKQuantitySample)!.quantity.doubleValue(for: unit) }
        // TODO: else { (sample as? HKCategorySample).value }
        // TODO: ... depending on type
    }
    
    public func needsBackgroundDelivery() -> Bool {
        // TODO: true for all except if type == Characteristic
    }
    
    public func type() -> String {
        // TODO: match each type and unit to a type in https://api.pryv.com/event-types/#complex-types
    }
    
    public func event(from sample: HKSample) -> APICall {
         return [
             "method": "events.create",
             "params": [
                 "streamId": streamId(),
                 "type": type(),
                 "tags": [String(describing: sample.uuid)],
                 "content": content(from: sample)
             ]
         ]
    }
}
