//
//  Structs.swift
//  CarExp
//
//  Created by Денис Колеснёв on 24.05.2021.
//

import SwiftUI
import CoreData

typealias PointData = Dictionary<String, Double> // key - Month Index, value - Value in Month
struct ChartData {
    var pointData = PointData()
    var title: String
    var subTitle: String?
}

// ------------------------------------------------------------------------------------------------ \\
struct UserDef {
    private let userDefaults = UserDefaults.standard
    private let actualDistanceKey = "ActualDistance"
    private let currencySumbol = "CurrencySumbol"
    
    func setActualDistance(_ value: Int32) { userDefaults.setValue(value, forKey: actualDistanceKey) }
    func getActualDistance() -> Int32 { Int32(userDefaults.integer(forKey: actualDistanceKey)) }
    func getActualDistance() -> String { userDefaults.string(forKey: actualDistanceKey) ?? "" }
    
    func setCurrencySubmol(_ value: String) { userDefaults.setValue(value, forKey: currencySumbol)}
    func getCurrencySumbol() -> String { userDefaults.string(forKey: currencySumbol) ?? "" }
}

// ------------------------------------------------------------------------------------------------ \\
struct UserData {
    private let context: NSManagedObjectContext
    private let remindersRequest: NSFetchRequest<Reminders> = Reminders.fetchRequest()
    private let expensesRequest: NSFetchRequest<Expenses> = Expenses.fetchRequest()
    
    init(_ context: NSManagedObjectContext) {
        self.context = context
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getAllExpences() -> [Expenses] {
        do {
            return try self.context.fetch(expensesRequest)
        } catch {
            return []
        }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getReminders(expId: UUID) -> Reminders? {
        do {
            remindersRequest.predicate = NSPredicate(format: "expId = %@", "\(expId)")
            let fetchedResults = try self.context.fetch(remindersRequest)
            guard let rem = fetchedResults.first else { return nil }
            return rem
        } catch { return nil }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getReminder(expId: UUID) -> Reminder? {
        guard let rem = getReminders(expId: expId) else { return nil }
        guard let reminderType: ReminderType = loadReminderType(rem.type) else { return nil }
        return Reminder(id: rem.id, type: reminderType, distance: rem.distance, date: rem.date)
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getReminders(id: UUID) -> Reminders? {
        do {
            remindersRequest.predicate = NSPredicate(format: "id = %@", "\(id)")
            let fetchedResults = try self.context.fetch(remindersRequest)
            return fetchedResults.first
        } catch { return nil }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getExpenses(_ expId: UUID) -> Expenses? {
        do {
            expensesRequest.predicate = NSPredicate(format: "id = %@", "\(expId)")
            let fetchedResults = try self.context.fetch(expensesRequest)
            guard let exp = fetchedResults.first else { return nil }
            return exp
        } catch { return nil }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func saveContext() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        saveActualDistance()
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getActualDistance() -> Int32 {
        do {
            expensesRequest.predicate = NSPredicate(format: "distance == max(distance)")
            let fetchedResults = try self.context.fetch(expensesRequest)

            return (fetchedResults.isEmpty ? 0 : fetchedResults[0].distance)
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func saveActualDistance() {
        UserDef().setActualDistance(getActualDistance())
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getMissedReminders() -> [Reminders] {
        do {
            let fetchRequest: NSFetchRequest<Reminders> = Reminders.fetchRequest()
            let fetchedResults = try self.context.fetch(fetchRequest)

            var result = [Reminders]()
            for reminder in fetchedResults {
                if reminderIsMiss(reminder, context) {
                    result.append(reminder)
                }
            }
            return result
        } catch { return [] }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getPrices(_ year: Int, expType: ExpensesType? = nil) -> PointData {
        do {
            var result = PointData()
            let calendar = Calendar.current
//            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            
            for month in (1...12) {
                let monthName = calendar.standaloneMonthSymbols[month-1]
                if let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                   let lastDayOfMonth = firstDayOfMonth.endOfMonth {
                    
                    if expType == nil {
                        expensesRequest.predicate = NSPredicate(format: "date BETWEEN { %@ , %@ }",
                                                                firstDayOfMonth as NSDate,
                                                                lastDayOfMonth as NSDate)
                    } else {
                        expensesRequest.predicate = NSPredicate(format: "type == %@ AND date BETWEEN { %@ , %@ }",
                                                                "\(expType!)",
                                                                firstDayOfMonth as NSDate,
                                                                lastDayOfMonth as NSDate)
                    }
                    
                    let fetchedResults = try self.context.fetch(expensesRequest)

                    result[monthName] = fetchedResults.reduce(0) { $0 + $1.price }
                } else { return PointData() }
            }
            return result
        } catch { return PointData() }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getPrices() -> Double {
        do {
            let fetchedResults = try self.context.fetch(expensesRequest)
            return fetchedResults.reduce(0) { $0 + $1.price }
        } catch { return 0 }
    }
    // ------------------------------------------------------------------------------------------------ \\
    private func getConsumptionData(_ fetchedResults: [Expenses]) -> Double {
        if fetchedResults.count == 0 { return 0 }
        let lastLiters = fetchedResults.last!.liters // Последняя заправка в году
        let summLiters = fetchedResults.reduce(0) { $0 + $1.liters } - lastLiters
        guard let minDistance = fetchedResults.min(by: { $0.distance < $1.distance })?.distance else { return 0 }
        guard let maxDistance = fetchedResults.max(by: { $0.distance < $1.distance })?.distance else { return 0 }
        if minDistance - maxDistance == 0 || summLiters == 0 { return 0 }
        return summLiters / (Double(maxDistance) - Double(minDistance)) * 100
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getConsumption(_ year: Int?) -> Double { // Расход топлива
        do {
            let calendar = Calendar.current
//            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            
            guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return 0 }
            guard let endOfYear = startOfYear.endOfYear else { return 0 }
            
            let basePredicate = "date BETWEEN { %@ , %@ } AND type == %@"
            expensesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Expenses.date, ascending: true)]
            
            expensesRequest.predicate = NSPredicate(format: "\(basePredicate) AND fullTank == true",
                startOfYear as NSDate, endOfYear as NSDate, "\(ExpensesType.fuel)")
            let fetchedResultsFullTank = try self.context.fetch(expensesRequest)
            
            if fetchedResultsFullTank.count >= 2 { //  Если есть более двух заправок полного бака за год
                return getConsumptionData(fetchedResultsFullTank)
            } else {
                expensesRequest.predicate = NSPredicate(format: basePredicate,
                    startOfYear as NSDate, endOfYear as NSDate, "\(ExpensesType.fuel)")
                let fetchedResults = try self.context.fetch(expensesRequest)
                return getConsumptionData(fetchedResults)
            }
        } catch { return 0 }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getConsumption() -> Double {
        do {
            expensesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Expenses.date, ascending: true)]
            expensesRequest.predicate = NSPredicate(format: "fullTank == true")
            let expFullTank = try self.context.fetch(expensesRequest)
            if expFullTank.count > 2 { //  Если есть более двух заправок полного бака за год
               return getConsumptionData(expFullTank)
            } else {
                expensesRequest.predicate = nil
                let fetchedResults = try self.context.fetch(expensesRequest)
                return getConsumptionData(fetchedResults)
            }
        } catch { return 0 }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getDistance(_ year: Int) -> PointData {
        do {
            var result = PointData()
            let calendar = Calendar.current
//            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            
            for month in (1...12) {
                let monthName = calendar.standaloneMonthSymbols[month-1]
                let dateComp = DateComponents(year: year, month: month, day: 1)
                guard let startOfMonth = calendar.date(from: dateComp) else { return PointData() }
                guard let endOfMonth = startOfMonth.endOfMonth else { return PointData() }
                var distance: Double = 0
                expensesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Expenses.date, ascending: true)]
                
                expensesRequest.predicate = NSPredicate(format: "date BETWEEN { %@ , %@ }",
                                                        startOfMonth as NSDate, endOfMonth as NSDate)
                // Если есть записи за месяц
                if let firstRecOfMonth = try self.context.fetch(expensesRequest).first {
                    let lastRecOfMonth = try self.context.fetch(expensesRequest).last!
                    
                    distance += Double(lastRecOfMonth.distance - firstRecOfMonth.distance)
                    
                    // Получаем последнюю запись предшествующего периода
                    expensesRequest.predicate = NSPredicate(format: "date < %@", startOfMonth as NSDate)
                    // Если она есть, высчитываем пропорционально дням пробег от начала текущего месяца
                    // до даты первой записи текущего месяца
                    if let lastRecOfPrevPeriod = try self.context.fetch(expensesRequest).last {
                        let diffDay = lastRecOfPrevPeriod.date!.diffDay(to: firstRecOfMonth.date!)
                        let diffDayOfStartMonth = startOfMonth.diffDay(to: firstRecOfMonth.date!) + 1
                        let diffDistance = Double(firstRecOfMonth.distance - lastRecOfPrevPeriod.distance)
                        distance += diffDistance / Double(diffDay) * Double(diffDayOfStartMonth)
                    }
                    
                    // Получаем первую запись последующего периода
                    expensesRequest.predicate = NSPredicate(format: "date > %@", endOfMonth as NSDate)
                    // Если она есть, высчитываем пропорционально дням пробег от даты последней записи
                    // текущего месяца до конца текущего месяца
                    if let firstRecOfPastPeriod = try self.context.fetch(expensesRequest).first {
                        let diffDay = lastRecOfMonth.date!.diffDay(to: firstRecOfPastPeriod.date!) + 1
                        let diffDayOfEndMonth = lastRecOfMonth.date!.diffDay(to: endOfMonth)
                        let diffDistance = Double(firstRecOfPastPeriod.distance - lastRecOfMonth.distance)
                        distance += diffDistance / Double(diffDay) * Double(diffDayOfEndMonth)
                    }
                } else { // Если нет записей за месяц
                    var days = 0
                    var prevDistance: Int32 = 0
                    var pastDistance: Int32 = 0
                    // Получаем последнюю запись предшествующего периода
                    expensesRequest.predicate = NSPredicate(format: "date < %@", startOfMonth as NSDate)
                    // Если она есть, высчитываем количество дней от последней записи
                    // предшествующего периода до начала текущего месяца
                    if let lastRecOfPrevPeriod = try self.context.fetch(expensesRequest).last {
                        days += lastRecOfPrevPeriod.date!.diffDay(to: startOfMonth)
                        prevDistance = lastRecOfPrevPeriod.distance
                    }

                    // Получаем первую запись последующего периода
                    expensesRequest.predicate = NSPredicate(format: "date > %@", endOfMonth as NSDate)
                    // Если она есть, высчитываем количество дней от конца текушего месяца
                    // до первой записи последующего периода
                    if let firstRecOfPastPeriod = try self.context.fetch(expensesRequest).first {
                        days += endOfMonth.diffDay(to: firstRecOfPastPeriod.date!)
                        pastDistance = firstRecOfPastPeriod.distance
                    }
                    
                    let countDaysOfMonth = startOfMonth.diffDay(to: endOfMonth) + 1
                    let diffDistance = Double(pastDistance - prevDistance)
                    if diffDistance > 0 {
                        distance += diffDistance / Double(days + countDaysOfMonth) * Double(countDaysOfMonth)
                    }
                }
                                
                result[monthName] = distance
            }
            return result
        } catch { return PointData() }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getDistance() -> Int32 {
        do {
            expensesRequest.predicate = NSPredicate(format: "date = min(date)")
            guard let expMinDate = try self.context.fetch(expensesRequest).first else { return 0 }
            expensesRequest.predicate = NSPredicate(format: "date = max(date)")
            guard let expMaxDate = try self.context.fetch(expensesRequest).first else { return 0 }

            return expMaxDate.distance - expMinDate.distance
        } catch { return 0 }
    }
    // ------------------------------------------------------------------------------------------------ \\
    func getCostPerKm(_ year: Int) -> PointData {
        let prices = getPrices(year)
        let distance = getDistance(year)
        var result = PointData()
        
        for month in distance.keys {
            result[month] = (distance[month] == 0 ? 0 : (prices[month] ?? 0) / distance[month]!)
        }
        
        return result
    }
}

// ------------------------------------------------------------------------------------------------ \\
struct ChartComparer {
    private let year: Int
    private let context: NSManagedObjectContext
    // ------------------------------------------------------------------------------------------------ \\
    init(_ year: Int, _ context: NSManagedObjectContext) {
        self.year = year
        self.context = context
    }
    // ------------------------------------------------------------------------------------------------ \\
    func distanceLineChart() -> ChartData {
        var result = ChartData(title: "Distance".localize,
                               subTitle: "km".localize)
        result.pointData = UserData(self.context).getDistance(self.year)
        return result
    }
    // ------------------------------------------------------------------------------------------------ \\
    func pricesBarChart(_ expType: ExpensesType) -> ChartData {
        var result = ChartData(title: expType.rawValue.stringValue(),
                                subTitle: UserDef().getCurrencySumbol())
        result.pointData = UserData(self.context).getPrices(self.year, expType: expType)
        return result
    }
    // ------------------------------------------------------------------------------------------------ \\
    func costPerKm() -> ChartData {
        var result = ChartData(title: "Cost Per Kilometer".localize, subTitle: UserDef().getCurrencySumbol())
        result.pointData = UserData(self.context).getCostPerKm(self.year)
        return result
    }
}


struct cancelButton: View {
    var showButton: Bool
    var presentationMode: Binding<PresentationMode>
    var body: some View {
        if showButton {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(Color(.systemRed))
        } else {
            EmptyView()
        }
    }
}


