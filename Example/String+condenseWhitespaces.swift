//
//  String+condenseWhitespaces.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 07.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

extension String {
    func condenseWhitespaces() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter({ !$0.isEmpty }).joined(separator: " ")
    }
}
