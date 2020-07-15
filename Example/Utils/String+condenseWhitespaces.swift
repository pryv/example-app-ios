//
//  String+condenseWhitespaces.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 07.07.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

extension String {
    
    /// Condense multiple whitespaces into a single whitespace
    /// - Returns: the current string with its whitespaces condensed
    func condenseWhitespaces() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter({ !$0.isEmpty }).joined(separator: " ")
    }
    
}
