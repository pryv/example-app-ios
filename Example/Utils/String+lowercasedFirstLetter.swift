//
//  String+lowercasedFirstLetter.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 10.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public extension String {
    func lowercasedFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    mutating func lowercasedFirstLetter() {
        self = self.lowercasedFirstLetter()
    }
}
