//
//  Date+startOf+endOf.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 25.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

extension Date {
    
    
    /// User’s current calendar.
    var calendar: Calendar {
        return Calendar.current
    }
    
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        if Calendar.current.isDateInToday(self) {
            return self
        }
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    /// Month.
    var month: Int {
        get {
            return calendar.component(.month, from: self)
        }
        set {

        }
    }
    
    /// Day.
    var day: Int {
        get {
            return calendar.component(.day, from: self)
        }
        set {
  
        }
    }
    
    /// Year.
    var year: Int {
        get {
            return calendar.component(.year, from: self)
        }
        set {
      
        }
    }
    
    
    
    /// Check if date is in today.
    var isInToday: Bool {
        return self.day == Date().day && self.month == Date().month && self.year == Date().year
    }
    
    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Monday
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components)!
    }

    var endOfWeek: Date {
        return Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)!
    }

    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
}
