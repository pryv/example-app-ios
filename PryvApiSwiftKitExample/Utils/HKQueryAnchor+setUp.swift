//
//  HKAnchorQuery+setUp.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 02.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation
import HealthKit

public extension HKQueryAnchor {
    
    /// Init the anchor or retrieve it from the user objects, if existing
    /// - Returns: the new anchor
    static func setUp() -> HKQueryAnchor {
        var anchor = HKQueryAnchor.init(fromValue: 0)
        
        if UserDefaults.standard.object(forKey: "Anchor") != nil {
            let data = UserDefaults.standard.object(forKey: "Anchor") as! Data
            anchor = try! NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)!
        }
        
        return anchor
    }
    
    /// Change the value of the anchor and set it to the user objects
    /// - Parameter newValue
    /// - Returns: the new value 
    static func changeValue(_ newValue: HKQueryAnchor?) -> HKQueryAnchor {
        let data = try! NSKeyedArchiver.archivedData(withRootObject: newValue! as Any, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: "Anchor")
        return newValue!
    }
}
