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


func getReminders(expId: UUID, _ context: NSManagedObjectContext) -> Reminders? {
    do {
        let fetchRequest: NSFetchRequest<Reminders> = Reminders.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "expId = %@", "\(expId)")
        let fetchedResults = try context.fetch(fetchRequest)
        guard let rem = fetchedResults.first else { return nil }
        return rem
    } catch { return nil }
}


func getReminder(expId: UUID, _ context: NSManagedObjectContext) -> Reminder? {
    guard let rem = getReminders(expId: expId, context) else { return nil }
    guard let reminderType: ReminderType = loadReminderType(rem.type) else { return nil }
    return Reminder(id: rem.id, type: reminderType, distance: rem.distance, date: rem.date)
}


func getReminders(id: UUID, _ context: NSManagedObjectContext) -> Reminders? {
    do {
        let fetchRequest: NSFetchRequest<Reminders> = Reminders.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", "\(id)")
        let fetchedResults = try context.fetch(fetchRequest)
        return fetchedResults.first
    } catch { return nil }
}



func getExpenses(_ expId: UUID, _ context: NSManagedObjectContext) -> Expenses? {
    do {
        let fetchRequest: NSFetchRequest<Expenses> = Expenses.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", "\(expId)")
        let fetchedResults = try context.fetch(fetchRequest)
        guard let exp = fetchedResults.first else { return nil }
        return exp
    } catch { return nil }
}


func saveContext(_ context: NSManagedObjectContext) {
    do {
        try context.save()
    } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
    
    setActualDistance(context)
}


func setActualDistance(_ context: NSManagedObjectContext) {
    do {
        let fetchRequest: NSFetchRequest<Expenses> = Expenses.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "distance == max(distance)")
        let fetchedResults = try context.fetch(fetchRequest)

        let actualDistance = (fetchedResults.isEmpty ? 0 : fetchedResults[0].distance)
        UserDef().setActualDistance(actualDistance)
    } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
}


func getReminderDistance(_ reminder: Reminders, _ context: NSManagedObjectContext) -> Int32 {
    let exp = getExpenses(reminder.expId!, context)!
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


func getMissedReminders(_ context: NSManagedObjectContext) -> [Reminders] {
    do {
        let fetchRequest: NSFetchRequest<Reminders> = Reminders.fetchRequest()
        let fetchedResults = try context.fetch(fetchRequest)

        var result = [Reminders]()
        for reminder in fetchedResults {
            if reminderIsMiss(reminder, context) {
                result.append(reminder)
            }
        }
        return result
    } catch { return [] }
}
