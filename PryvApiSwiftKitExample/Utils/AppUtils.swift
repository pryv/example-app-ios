//
//  AppUtils.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 11.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import PryvApiSwiftKit

class AppUtils {
    
    public init() { }
    
    /// Converts an event in json format to a `String` to print/add to an app's label
    /// - Parameter event: the json formatted event
    /// - Returns: a `String` corresponding to the `event` with format `"key: value\n`
    public func eventToString(_ event: Event) -> String {
        let sortedEvent = event.sorted(by: { $0.0 < $1.0 })
        let array: [String] = sortedEvent.compactMap({ (key, value) -> String in
            return "\(key):\(value)"
        }) as Array
        
        return array.joined(separator: "\n")
    }
    
}
