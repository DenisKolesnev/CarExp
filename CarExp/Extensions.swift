//
//  Extensions.swift
//  CarExp
//
//  Created by Денис Колеснёв on 26.05.2021.
//

import SwiftUI

extension Optional where Wrapped == String {
    var loadFuelType: FuelType? {
        for fuelType in FuelType.allCases {
            if "\(fuelType)" == self {
                return fuelType
            }
        }
        return nil
    }
    
    func loadType<T: CaseIterable>() -> T? {
        for item in T.allCases {
            if "\(item)" == self {
                return item
            }
        }
        return nil
    }
}

extension Optional where Wrapped == Date {
    func toString(format: String) -> String {
        return self?.toString(format: format) ?? ""
    }
    
    var toString: String {
        return self?.toString ?? ""
    }
}

extension Date {
    func toString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    var toString: String {
        return self.toString(format: "dd.MM.yy")
    }
    
    func addDays(_ days: Int16) -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self) ?? self
    }
    
    var addOneDay: Date {
        self.addDays(1)
    }
    
    func days(to secondDate: Date, calendar: Calendar = Calendar.current) -> Int {
        return calendar.dateComponents([.day], from: self, to: secondDate).day!
    }
}

extension String {
    static func localizedString(for key: String, locale: Locale = .current) -> String {
        let language = locale.languageCode
        let path = Bundle.main.path(forResource: language, ofType: "lproj")!
        let bundle = Bundle(path: path)!
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        return localizedString
    }
    
    func localize(locale: Locale = .current) -> String {
        let language = locale.languageCode
        let path = Bundle.main.path(forResource: language, ofType: "lproj")!
        let bundle = Bundle(path: path)!
        let localizedString = NSLocalizedString(self, bundle: bundle, comment: "")
        return localizedString
    }
    
    var localize: String {
        return localize()
    }
}

extension LocalizedStringKey {
    var stringKey: String {
        let description = "\(self)"
        let components = description.components(separatedBy: "key: \"")
            .map { $0.components(separatedBy: "\",") }

        return components[1][0]
    }
    
    func stringValue(locale: Locale = .current) -> String {
        return .localizedString(for: self.stringKey, locale: locale)
    }
}

extension Double {
    func toRoundedStr(_ exp: Int8) -> String {
        return String(format: "%.\(exp)f", locale: .current, self)
    }
}

extension String {
    var doubleValue: Double {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.number(from: self)
        return (number == nil ? 0 : number!.doubleValue)
    }
}

