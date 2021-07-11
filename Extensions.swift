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
    
    var startOfDay: Date? {
        guard let result = self else { return nil }
        return result.startOfDay
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
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        let dateComp = calendar.dateComponents([.day, .month, .year], from: self)
        return calendar.date(byAdding: DateComponents(year: dateComp.year, month: dateComp.month, day: 1),
                             to: self) ?? self
    }
    
    var endOfMonth: Date? {
        return Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: self)
    }
    
    func addMonth(to value: Int) -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: value), to: self) ?? self
    }
    
    var endOfYear: Date? {
        let components = Calendar.current.dateComponents([.year], from: self)
        let dateComp = DateComponents(year: components.year, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return Calendar.current.date(from: dateComp)
    }
    
    // Подсчитывает разницу месяцев между датами
    func diffMonth(in endDate: Date) -> Int {
        let calendar = Calendar.current
        let startDateComponents = calendar.dateComponents([.year, .month], from: self)
        let endDateComponents = calendar.dateComponents([.year, .month], from: endDate)
        return calendar.dateComponents([.month], from: startDateComponents, to: endDateComponents).month ?? 0
    }
    
    // Подсчитывает разницу дней между датами
    func diffDay(to endDate: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: self, to: endDate).day ?? 0
        return abs(days)
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

extension PointData where Key == String {
    var sum: Double {
        return self.reduce(0) { $0 + $1.value }
    }
    
    var sumIsZero: Bool {
        return sum == 0
    }
}


