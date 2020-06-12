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
    
    public init() {
        
    }
    
    public func eventToString(_ json: Json) -> String {
        let array: [String] = json.compactMap({ (key, value) -> String in
            return "\(key):\(value)"
        }) as Array
        
        return array.joined(separator: "\n")
    }
    
}
