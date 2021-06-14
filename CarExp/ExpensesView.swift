//
//  ExpensesView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI

var tappedExp: Expenses? = nil

enum ExpensesType: LocalizedStringKey, CaseIterable {
    case fuel = "Fuel"
    case service = "Service"
    case other = "Other"
}

struct ExpensesView: View {
    var viewName: LocalizedStringKey
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Expenses.date, ascending: false)])
        private var expenses: FetchedResults<Expenses>
    
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
    
    
    var body: some View {
        NavigationView {
            List {
                if !self.fuelExpenses.isEmpty {
                    Section(header:
                                HStack {
                                    Image("categoryFuel")
                                    Text(ExpensesType.fuel.rawValue).font(.headline)
                                    Spacer()
                                    if self.isFuelExpanded {
                                        Image(systemName: "minus")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }.onTapGesture{ self.isFuelExpanded.toggle() },
                            content: {
                                if self.isFuelExpanded {
                                    ForEach(self.fuelExpenses, id: \.self.id) { expense in
                                        HStack{
                                            VStack(alignment: .leading) {
                                                HStack{
                                                    Image(systemName: "calendar")
                                                    Text(expense.date.toString).bold()
                                                }
                                                HStack{
                                                    Image(systemName: "speedometer")
                                                    Text("\(expense.distance)")
                                                }
                                            }.padding(.trailing, 4)
                                            Divider()
                                            VStack(alignment: .leading) {
                                                HStack(spacing: 4) {
                                                    Text(expense.litres.toRoundedStr(1)).bold()
                                                    Text(LocalizedStringKey("liters")).bold()
                                                }
                                                Text(expense.fuelType.loadFuelType?.rawValue ?? "")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }.padding(.horizontal, 4)
                                            Spacer()
                                            Divider()
                                            HStack{
                                                Image(systemName: "sum")
                                                Text(expense.price.toRoundedStr(2)).bold()
                                            }
                                        }.onTapGesture{
                                            tappedExp = expense
                                            reminder = getReminder(expId: expense.id!, self.context)
                                            self.showingDetail = true
                                        }
                                    }.onDelete(perform: { indexSet in
                                        for index in indexSet {
                                            let expense = expenses[index]
                                            context.delete(expense)
                                            saveContext(self.context)
                                        }
                                    })
                                }
                            }).contentShape(Rectangle())
                }
                if !self.serviceExpenses.isEmpty {
                    Section(header:
                                HStack {
                                    Image("categoryService")
                                    Text(ExpensesType.service.rawValue).font(.headline)
                                    Spacer()
                                    if self.isServiceExpanded {
                                        Image(systemName: "minus")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }.onTapGesture{ self.isServiceExpanded.toggle() },
                            content: {
                                if self.isServiceExpanded {
                                    ForEach(self.serviceExpenses, id: \.self.id) { expense in
                                        HStack{
                                            VStack(alignment: .leading) {
                                                HStack{
                                                    Image(systemName: "calendar")
                                                    Text(expense.date.toString).bold()
                                                }
                                                HStack{
                                                    Image(systemName: "speedometer")
                                                    Text("\(expense.distance)")
                                                }
                                            }.padding(.trailing, 4)
                                            Divider()
                                            Text(expense.caption ?? "").padding(.horizontal, 4)
                                            Spacer()
                                            Divider()
                                            HStack{
                                                Image(systemName: "sum")
                                                Text(expense.price.toRoundedStr(2)).bold()
                                            }
                                        }
                                        .onTapGesture {
                                            tappedExp = expense
                                            reminder = getReminder(expId: expense.id!, self.context)
                                            self.showingDetail = true
                                        }
                                    }.onDelete(perform: { indexSet in
                                        for index in indexSet {
                                            let expense = expenses[index]
                                            context.delete(expense)
                                            saveContext(self.context)
                                        }
                                    })
                                }
                            }).contentShape(Rectangle())
                }
                if !self.otherExpenses.isEmpty {
                    Section(header:
                                HStack {
                                    Image("categoryOther")
                                    Text(ExpensesType.other.rawValue).font(.headline)
                                    Spacer()
                                    if self.isOtherExpanded {
                                        Image(systemName: "minus")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }.onTapGesture{ self.isOtherExpanded.toggle() },
                            content: {
                                if self.isOtherExpanded {
                                    ForEach(self.otherExpenses, id: \.self.id) { expense in
                                        HStack{
                                            VStack(alignment: .leading) {
                                                HStack{
                                                    Image(systemName: "calendar")
                                                    Text(expense.date.toString).bold()
                                                }
                                                HStack{
                                                    Image(systemName: "speedometer")
                                                    Text("\(expense.distance)")
                                                }
                                            }.padding(.trailing, 4)
                                            Divider()
                                            VStack(alignment: .leading) {
                                                Text(expense.caption ?? "")
                                                if expense.info != nil && expense.info != "" {
                                                    Text(expense.info!).font(.subheadline).foregroundColor(.gray)
                                                }
                                            }.padding(.horizontal, 4)
                                            Spacer()
                                            Divider()
                                            HStack{
                                                Image(systemName: "sum")
                                                Text(expense.price.toRoundedStr(2)).bold()
                                            }
                                        }
                                        .onTapGesture {
                                            tappedExp = expense
                                            reminder = getReminder(expId: expense.id!, self.context)
                                            self.showingDetail = true
                                        }
                                    }.onDelete(perform: { indexSet in
                                        for index in indexSet {
                                            let expense = expenses[index]
                                            context.delete(expense)
                                            saveContext(self.context)
                                        }
                                    })
                                }
                            }).contentShape(Rectangle())
                }
            }.padding()
            .listStyle(GroupedListStyle())
            .navigationTitle(viewName)
            .navigationBarItems(
                leading:
                    AddExpenseButton(),
                trailing:
                    HStack{
                        if !expenses.isEmpty {
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
