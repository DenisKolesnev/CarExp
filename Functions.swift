//
//  Functions.swift
//  CarExp
//
//  Created by Денис Колеснёв on 23.05.2021.
//

//import Foundation
import SwiftUI
import CoreData


func loadReminderType(_ value: String?) -> ReminderType? {
    if value == nil { return nil }
    for item in ReminderType.allCases {
        if item.rawValue == value {
            return item
        }
    }
    return nil
}


func getReminderDistance(_ reminder: Reminders, _ context: NSManagedObjectContext) -> Int32 {
    guard let expId = reminder.expId else { return 0 }
    guard let exp = UserData(context).getExpenses(expId) else { return 0 }
    return exp.distance + reminder.distance - UserDef().getActualDistance()
}


func reminderIsMiss(_ reminder: Reminders, _ context: NSManagedObjectContext) -> Bool {
    switch loadReminderType(reminder.type) {
    case .byDate:
        let dateDiff = Date().days(to: reminder.date!)
        return dateDiff < 0
    case .byDistance:
        let distance = getReminderDistance(reminder, context)
        return distance < 0
    default: return false
    }
}

