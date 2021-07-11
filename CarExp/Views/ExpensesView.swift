//
//  ExpensesView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI

var tappedExp: Expenses? = nil
let dateColor = Color(.systemRed)

enum ExpensesType: LocalizedStringKey, CaseIterable {
    case fuel = "Fuel"
    case service = "Service"
    case other = "Other"
}

struct ExpensesView: View {
    var viewName: LocalizedStringKey
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Expenses.date, ascending: false)],
                  predicate: NSPredicate(format: "type = %@", "\(ExpensesType.fuel)"),
                  animation: .default) private var fuelExpenses: FetchedResults<Expenses>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Expenses.date, ascending: false)],
                  predicate: NSPredicate(format: "type = %@", "\(ExpensesType.service)"),
                  animation: .default) private var serviceExpenses: FetchedResults<Expenses>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Expenses.date, ascending: false)],
                  predicate: NSPredicate(format: "type = %@", "\(ExpensesType.other)"),
                  animation: .default) private var otherExpenses: FetchedResults<Expenses>
    
    @State private var isFuelExpanded: Bool = true
    @State private var isServiceExpanded: Bool = true
    @State private var isOtherExpanded: Bool = true
    @State private var showingDetail = false
    
    @State var selTag: String?
    
    private let currSumbol = UserDef().getCurrencySumbol()
    
    
    var body: some View {
        NavigationView {
            List {
                if !self.fuelExpenses.isEmpty {
                    Section(header: SectionHeader(imageName: "categoryFuel",
                                                  text: ExpensesType.fuel.rawValue,
                                                  isExpanded: self.isFuelExpanded)
                                    .onTapGesture{ self.isFuelExpanded.toggle() },
                            content: {
                                if self.isFuelExpanded {
                                    ForEach(self.fuelExpenses, id: \.self.id) { expense in
                                        HStack{
                                            DateAndDistancePart(expense: expense, inSelf: self)
                                            Divider()
                                            MainInfo(text: "\(expense.liters.toRoundedStr(1)) \("liters".localize)",
                                                     subText: expense.fuelType.loadFuelType!.rawValue.stringValue(),
                                                     price: expense.price,
                                                     fullTank: expense.fullTank)
                                            Spacer()
                                            VStack {
                                                if expense.info != nil {
                                                    Image(systemName: "text.bubble")
                                                        .resizable().frame(width: 16, height: 16)
                                                }
                                                Spacer()
                                            }
                                        }.onTapGesture{
                                            tappedExp = expense
                                            reminder = UserData(self.context).getReminder(expId: expense.id!)
                                            self.showingDetail = true
                                        }
                                    }.onDelete(perform: { indexSet in
                                        for index in indexSet {
                                            let expense = fuelExpenses[index]
                                            context.delete(expense)
                                            UserData(self.context).saveContext()
                                        }
                                    })
                                }
                            }).contentShape(Rectangle())
                }
                if !self.serviceExpenses.isEmpty {
                    Section(header: SectionHeader(imageName: "categoryService",
                                                  text: ExpensesType.service.rawValue,
                                                  isExpanded: self.isServiceExpanded)
                                    .onTapGesture{ self.isServiceExpanded.toggle() },
                            content: {
                                if self.isServiceExpanded {
                                    ForEach(self.serviceExpenses, id: \.self.id) { expense in
                                        HStack{
                                            DateAndDistancePart(expense: expense, inSelf: self)
                                            Divider()
                                            MainInfo(text: expense.caption ?? "", price: expense.price)
                                            if expense.info != nil {
                                                Spacer()
                                                VStack {
                                                    Image(systemName: "text.bubble")
                                                    Spacer()
                                                }
                                            }
                                        }.onTapGesture {
                                            tappedExp = expense
                                            reminder = UserData(self.context).getReminder(expId: expense.id!)
                                            self.showingDetail = true
                                        }
                                    }.onDelete(perform: { indexSet in
                                        for index in indexSet {
                                            let expense = serviceExpenses[index]
                                            context.delete(expense)
                                            UserData(self.context).saveContext()
                                        }
                                    })
                                }
                            }).contentShape(Rectangle())
                }
                if !self.otherExpenses.isEmpty {
                    Section(header: SectionHeader(imageName: "categoryOther",
                                                  text: ExpensesType.other.rawValue,
                                                  isExpanded: self.isOtherExpanded)
                                    .onTapGesture{ self.isOtherExpanded.toggle() },
                            content: {
                                if self.isOtherExpanded {
                                    ForEach(self.otherExpenses, id: \.self.id) { expense in
                                        HStack{
                                            DateAndDistancePart(expense: expense, inSelf: self)
                                            Divider()
                                            MainInfo(text: expense.caption ?? "", price: expense.price)
                                            if expense.info != nil {
                                                Spacer()
                                                VStack {
                                                    Image(systemName: "text.bubble")
                                                    Spacer()
                                                }
                                            }
                                        }.onTapGesture {
                                            tappedExp = expense
                                            reminder = UserData(self.context).getReminder(expId: expense.id!)
                                            self.showingDetail = true
                                        }
                                    }.onDelete(perform: { indexSet in
                                        for index in indexSet {
                                            let expense = otherExpenses[index]
                                            context.delete(expense)
                                            UserData(self.context).saveContext()
                                        }
                                    })
                                }
                            }).contentShape(Rectangle())
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(viewName)
            .navigationBarItems(
                leading:
                    AddExpenseButton(),
                trailing:
                    HStack {
                        if !fuelExpenses.isEmpty || !serviceExpenses.isEmpty || !otherExpenses.isEmpty {
                            SearchButton()
                            EditButton()
                        }
                    }
            )
            .sheet(isPresented: self.$showingDetail) {
                NavigationView { AddExpenseView(tappedExp).environment(\.managedObjectContext, self.context) }
            }
        }
    }
    
    
    struct SectionHeader: View {
        let imageName: String
        let text: LocalizedStringKey
        let isExpanded: Bool
        
        var body: some View {
            HStack {
                Image(imageName)
                Text(text).font(.title3).bold()
                Spacer()
                Image(systemName: isExpanded ? "minus" : "plus")
            }
        }
    }
    
    
    struct MainInfo: View {
        private let text, subText: String
        private let price: Double
        private let fullTank: Bool
        private let currSumbol = UserDef().getCurrencySumbol()
        
        init(text: String, subText: String = "", price: Double, fullTank: Bool = false) {
            self.text = text
            self.subText = subText
            self.price = price
            self.fullTank = fullTank
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(text).font(.headline)
                    if self.fullTank { Image(systemName: "arrow.up.to.line") }
                    if self.subText != "" { Text("(\(self.subText))").font(.caption).foregroundColor(.gray) }
                }
                if price != 0 {
                    Text("\(self.price.toRoundedStr(2)) \(self.currSumbol)").bold().font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

        }
    }
    
    
    struct SpeedometrText: View {
        var value: String
        private let w: CGFloat = 14
        private let h: CGFloat = 16
        var body: some View {
            HStack {
                switch value.count {
                case 1:
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                case 2:
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                case 3:
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                case 4:
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                case 5:
                    Image(systemName: "0.square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                case 6:
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.index(after: index)
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                    let index = value.startIndex
                    Image(systemName: "\(value[index]).square").resizable().frame(width: w, height: h).padding(-5)
                default:
                    EmptyView()
                }
            }
        }
    }
    
    
    struct DateAndDistancePart: View {
        var expense: Expenses
        var inSelf: ExpensesView
        var body: some View{
            VStack(alignment: .center) {
                Text(self.expense.date.toString).bold().font(.headline).foregroundColor(dateColor)
                SpeedometrText(value: String(expense.distance))
            }.frame(width: 75).padding(.bottom, 8)
        }
    }
    
    
    struct AddExpenseButton: View {
        @State private var showSearchView = false
        @State var tag: String?
        @Environment(\.managedObjectContext) var context
        
        var body: some View {
            Button(
                action: {
                    reminder = nil
                    self.tag = "AddExpenseView" },
                label: { Image(systemName: "plus") }
            ).background(
                NavigationLink(
                    destination: AddExpenseView().environment(\.managedObjectContext, self.context),
                    tag: "AddExpenseView",
                    selection: self.$tag,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    
    struct SearchButton: View {
        @State private var showSearchView = false
        @State var tag: String?
        @Environment(\.managedObjectContext) var context
        
        var body: some View {
            Button(
                action: { self.tag = "SearchView" },
                label: { Image(systemName: "magnifyingglass") }
            ).background(
                NavigationLink(
                    destination: SearchView().environment(\.managedObjectContext, self.context),
                    tag: "SearchView",
                    selection: self.$tag,
                    label: { EmptyView() }
                )
            )
        }
    }
}


struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesView(viewName: "Expenses")
    }
}
