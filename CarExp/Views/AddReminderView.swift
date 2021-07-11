//
//  AddReminderView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 29.11.2020.
//

import SwiftUI
import Combine

enum ReminderType: String, CaseIterable {
    case byDistance = "By Distance"
    case byDate = "By Date"
}

struct Reminder {
    var id: UUID?
    var type: ReminderType
    var distance: Int32?
    var date: Date?
}

var reminder: Reminder? = nil


struct AddReminderView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode
    
    @State private var reminderType: ReminderType = .byDate
    @State private var distanceText = ""
    @State private var date = Date().addOneDay
    @State private var showAddExpenseView = false
    
    private var reminders: Reminders? = nil
    
    init() { }
    
    init(_ rem: Reminders?) {
        guard rem != nil else { return }
        
        self.reminders = rem
        self._reminderType = State(initialValue: loadReminderType(rem!.type) ?? .byDate)
        self._date = State(initialValue: rem!.date ?? Date().addOneDay)
        self._distanceText = State(initialValue: String(rem!.distance))
    }
    
    var body: some View {
        Form {
            Picker(selection: self.$reminderType, label: EmptyView()) {
                ForEach(ReminderType.allCases, id: \.self) { reminderType in
                    Text(LocalizedStringKey(reminderType.rawValue))
                }
            }.pickerStyle(SegmentedPickerStyle())
            
            switch self.reminderType {
            case .byDistance:
                HStack {
                    Text("Every")
                    TextField("", text: self.$distanceText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onReceive(Just(self.distanceText)) { _ in
                            let textLimit = 6
                            if self.distanceText.count > textLimit {
                                self.distanceText = String(self.distanceText.prefix(textLimit))
                            }
                        }
                    Text("km")
                }
            case .byDate:
                DatePicker("Remind".localize,
                           selection: self.$date,
                           in: (Date().addOneDay)... ,
                           displayedComponents: .date)
            }
            
            if self.reminders != nil {
                    Button(action: {
                        setReminder()
                        self.showAddExpenseView.toggle()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "plus")
                            Text("Add Expense")
                            Spacer()
                        }.padding(10.0).overlay(RoundedRectangle(cornerRadius: 10.0).stroke(lineWidth: 2.0))
                    }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(self.reminders == nil ? "New Reminder" : "Change Reminder")
        .navigationBarItems(
            leading: cancelButton(showButton: self.reminders != nil, presentationMode: presentationMode),
            trailing:
                Button("Save") {
                    reminder = Reminder(id: nil,
                                        type: self.reminderType,
                                        distance: (self.reminderType == .byDistance ? Int32(self.distanceText) : nil),
                                        date: (self.reminderType == .byDate ? self.date : nil))
                    self.presentationMode.wrappedValue.dismiss()
                })
        .onAppear(perform: {
            if reminder == nil { return }
            self.reminderType = reminder!.type
            
            switch self.reminderType {
            case .byDistance:
                self.distanceText = String(reminder!.distance ?? 0)
            case .byDate:
                self.date = reminder!.date ?? Date().addOneDay
            }
            
            if self.distanceText == "0" { self.distanceText = "" }
        })
        .sheet(isPresented: self.$showAddExpenseView) {
            let newExp = (self.reminders!.expId == nil ? nil : UserData(self.context).getExpenses(self.reminders!.expId!))
            NavigationView { AddExpenseView(newExp: newExp, self).environment(\.managedObjectContext, self.context) }
        }
    }

    func setReminder() {
        guard let baseReminder = self.reminders,
              let reminderType = loadReminderType(baseReminder.type)
        else { return }

        var date = baseReminder.date ?? Date()
        date = (date < Date() ? Date() : date)
        reminder = Reminder(id: nil, type: reminderType, distance: baseReminder.distance, date: date)
    }
}

//struct AddReminderView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddReminderView()
//    }
//}
