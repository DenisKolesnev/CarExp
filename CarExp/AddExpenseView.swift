//
//  AddExpanseView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 19.10.2020.
//

import SwiftUI
import Combine

enum FuelType: LocalizedStringKey, CaseIterable {
    case petrol = "Petrol"
    case diesel = "Diesel"
    case gas = "Gas"
}


struct AddExpenseView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedExpenseType: ExpensesType = .fuel
    @State private var fuelType: FuelType = .petrol
    
    @State private var caption = ""
    @State private var info = ""
    @State private var distanceStr = "0"
    @State private var date = Date()
    @State private var priceStr = "0.00"
    @State private var litersStr = "0"
    
    @State private var showAlert = false
    @State private var alertMessage: LocalizedStringKey = ""
    @State private var showReminderView = false
    @State private var fullTank = false
    @State private var needRefresh = false
    
    // Запись, передаваемая при редактировании затрат. Редактирует выбранную запись
    private var expense: Expenses? = nil
    
    // Запись, передаваемая при добавлении затраты из окна напоминаний. Добавляет новую запись. Копирует некаторые поля.
    private var newExpense: Expenses? = nil
    private var reminderView: AddReminderView? = nil
    
    init() {}
    
    init (_ exp: Expenses?) {
        guard exp != nil else { return }
        self.expense = exp
        self._date = State(initialValue: exp!.date ?? Date())
        self._litersStr = State(initialValue: exp!.litres.toRoundedStr(1))
        self._caption = State(initialValue: exp!.caption ?? "")
        self._info = State(initialValue: exp!.info ?? "")
        self._distanceStr = State(initialValue: String(exp!.distance))
        self._priceStr = State(initialValue: exp!.price.toRoundedStr(2))
        self._selectedExpenseType = State(initialValue: exp!.type.loadType() ?? .other)
        self._fuelType = State(initialValue: exp!.fuelType.loadType() ?? .petrol)
        self._fullTank = State(initialValue: exp!.fullTank)
    }
    
    init(newExp: Expenses?, _ reminderView: AddReminderView?) {
        self.newExpense = newExp
        self.reminderView = reminderView
        self._caption = State(initialValue: newExp!.caption ?? "")
        self._info = State(initialValue: newExp!.info ?? "")
        self._priceStr = State(initialValue: newExp!.price.toRoundedStr(2))
        self._selectedExpenseType = State(initialValue: newExp!.type.loadType() ?? .other)
        self._fuelType = State(initialValue: newExp!.fuelType.loadType() ?? .petrol)
    }
    

    var body: some View {
        Form {
            Picker(selection: self.$selectedExpenseType, label: EmptyView()) {
                ForEach(ExpensesType.allCases, id: \.self) { expensesType in
                    Text(expensesType.rawValue)
                }
            }.pickerStyle(SegmentedPickerStyle())
            
            VStack {
                HStack {
                    Text("Date:").frame(width: 120, height: 40, alignment: .leading)
                    DatePicker("", selection: self.$date, in: ...Date(), displayedComponents: .date).labelsHidden()
                    Spacer()
                }
                
                HStack {
                    Text("Distance:").frame(width: 120, height: 40, alignment: .leading)
                    TextField("Distance", text: self.$distanceStr)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onReceive(Just(self.distanceStr)) { _ in
                            let textLimit = 6
                            if self.distanceStr.count > textLimit {
                                self.distanceStr = String(self.distanceStr.prefix(textLimit))
                            }
                        }
                        .onTapGesture{
                            if self.distanceStr == "0" {
                                self.distanceStr = ""
                            }
                        }
                    Text("km")
                }
                
                if self.selectedExpenseType == .fuel {
                    HStack {
                        Picker(selection: self.$fuelType, label: EmptyView()) {
                            ForEach(FuelType.allCases, id: \.self) { fuelType in
                                Text(fuelType.rawValue)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Liters:").frame(width: 120, height: 40, alignment: .leading)
                        TextField("Liters", text: self.$litersStr)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .onReceive(Just(self.litersStr)) { _ in
                                let textLimit = 4
                                if self.litersStr.count > textLimit {
                                    self.litersStr = String(self.litersStr.prefix(textLimit))
                                }
                            }
                            .onTapGesture{
                                if self.litersStr == "0" {
                                    self.litersStr = ""
                                }
                            }
                        Text("liters")
                    }
                    Toggle("Full Tank", isOn: $fullTank)
                } else {
                    HStack {
                        Text("Caption:").frame(width: 100, height: 40, alignment: .leading)
                        TextField("Caption", text: self.$caption).textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                HStack {
                    Text("Price:").frame(width: 120, height: 40, alignment: .leading)
                    TextField("Write Price", text: self.$priceStr)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .onTapGesture{
                            if self.priceStr == "0.00" {
                                self.priceStr = ""
                            }
                        }
                }
                
                HStack {
                    Text("Info:").frame(width: 120, height: 40, alignment: .leading)
                    TextField("Write Information", text: self.$info).textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            if self.selectedExpenseType != .fuel {
                NavigationLink(destination: AddReminderView()) {
                    VStack(alignment: .leading) {
                        Text("Reminder")
                        
                        if reminder != nil {
                            let reminderText = getReminderText()
                            Text(reminderText).font(.subheadline).foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(self.expense == nil ? "New Expense" : "Change Expense")
        .navigationBarItems(
            leading: cancelButton(showButton: self.expense != nil || self.newExpense != nil,
                                  presentationMode: presentationMode),
            trailing: saveButton(inSelf: self).alert(isPresented: self.$showAlert) {
                Alert(title: Text(LocalizedStringKey("Fields are not filled")),
                      message: Text(self.alertMessage),
                      dismissButton: .none)})
    }
    
    
    struct saveButton: View {
        var inSelf: AddExpenseView
        var body: some View {
            Button("Save") {
                // ------------------------- Save Expense ------------------------- \\
                let exp = inSelf.expense ?? Expenses(context: inSelf.context)
                
                let litres = inSelf.litersStr.doubleValue
                let distance = Int32(inSelf.distanceStr) ?? 0
                
                if inSelf.selectedExpenseType == .fuel && litres == 0 {
                    inSelf.alertMessage = "Field \"Litres\" are not filled"
                    inSelf.showAlert = true
                }
                
                if [.service, .other].contains(inSelf.selectedExpenseType) && inSelf.caption == "" {
                    inSelf.alertMessage = "Field \"Caption\" are not filled"
                    inSelf.showAlert = true
                }

                
                if distance == 0 {
                    inSelf.alertMessage = "Field \"Distance\" are not filled"
                    inSelf.showAlert = true
                }
                
                let expId = (inSelf.expense == nil ? UUID() : inSelf.expense!.id!)
                
                if !inSelf.showAlert {
                    exp.id = expId
                    exp.caption = inSelf.caption
                    exp.date = inSelf.date
                    exp.distance = distance
                    exp.price = inSelf.priceStr.doubleValue
                    exp.type = "\(inSelf.selectedExpenseType)"
                    exp.info = inSelf.info
                    exp.fullTank = inSelf.fullTank
                    
                    if inSelf.selectedExpenseType == .fuel {
                        exp.litres = litres
                        exp.fuelType = "\(inSelf.fuelType)"
                    } else {
                        exp.litres = 0
                        exp.fuelType = nil
                    }
                    
                    // ------------------------- Save Reminder ------------------------- \\
                    if reminder != nil {
                        let reminders = getReminders(expId: expId, inSelf.context) ?? Reminders(context: inSelf.context)
                        reminders.id = UUID()
                        reminders.expId = expId
                        reminders.type = reminder!.type.rawValue

                        reminders.date = nil
                        reminders.period = 0
                        reminders.distance = 0
                        
                        switch reminder!.type {
                        case .byDate:
                            reminders.date = reminder!.date
                        case .byDistance:
                            reminders.distance = reminder!.distance!
                        }
                    }
                    // ----------------------------------------------------------------- \\
                    
                    saveContext(inSelf.context)
                    inSelf.presentationMode.wrappedValue.dismiss()
                    inSelf.reminderView?.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    func getReminderText() -> String {
        guard let reminder = reminder,
              let distance = reminder.distance
        else { return "" }
        
        switch reminder.type {
        case .byDate:
            return reminder.date.toString(format: "d MMMM yyyy")
        case .byDistance:
            return "Every".localize + " \(distance) " + "km".localize
        }
    }
}


struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddExpenseView()
                .preferredColorScheme(.dark)
        }
    }
}
