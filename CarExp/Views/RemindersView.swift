//
//  RemindersView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI
import CoreData

var tapReminder: Reminders? = nil

struct RemindersView: View {
    var viewName: LocalizedStringKey
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Reminders.date, ascending: false)])
    private var reminders: FetchedResults<Reminders>
    
    @State private var showingDetail = false
    
    private func getExpCaption(expId: UUID?) -> String {
        if expId == nil { return "" }
        guard let exp = UserData(self.context).getExpenses(expId!) else { return "" }
        guard let caption = exp.caption else { return "" }
        return caption
    }
    
    private func getReminderColor(_ reminder: Reminders, _ context: NSManagedObjectContext) -> Color {
        return reminderIsMiss(reminder, context) ? Color(.systemRed) : Color(.label)
    }

    var body: some View {
        NavigationView {
            GeometryReader{ geometry in
                List {
                ForEach(self.reminders, id: \.self.id) { reminder in
                    let reminderColor = getReminderColor(reminder, self.context)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "bell")
                                .resizable()
                                .frame(width: geometry.size.width/8, alignment: .center)
                                .foregroundColor(reminderColor)
                            VStack{
                                HStack{
                                    Text(getExpCaption(expId: reminder.expId))
                                        .bold()
                                        .foregroundColor(reminderColor)
                                        .font(.title2)
                                    Spacer()
                                }
                                HStack(spacing: 0) {
                                    Text("(")
                                    ReminderDateText(inSelf: UserData(self.context).getReminders(id: reminder.id!)!)
                                    Text(")")
                                    Spacer()
                                }.foregroundColor(Color(.secondaryLabel))
                            }
                        }.padding(8)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(lineWidth: 2).foregroundColor(reminderColor))
                    .onTapGesture{
                        tapReminder = reminder
                        self.showingDetail = true
                    }
                }
                    .onDelete(perform: { indexSet in
                        for index in indexSet {
                            let reminder = reminders[index]
                            context.delete(reminder)
                            UserData(self.context).saveContext()
                        }
                    })
                }
            }
            .navigationTitle(viewName)
            .navigationBarItems(trailing: VStack{if !reminders.isEmpty { EditButton() }})
            .sheet(isPresented: self.$showingDetail) {
                NavigationView { AddReminderView(tapReminder).environment(\.managedObjectContext, self.context) }
            }
        }
    }
    
    
    struct ReminderDateText: View {
        var inSelf: Reminders
        @Environment(\.managedObjectContext) var context
        
        var body: some View {
            switch loadReminderType(inSelf.type) {
            case .byDate:
                let dateDiff = Date().days(to: inSelf.date!)
                switch dateDiff {
                case 1...:
                    Text("After")
                    Text("\(dateDiff)").padding(4)
                    Text("days")
                case ...(-1):
                    Text("Missed")
                    Text("\(-dateDiff)").padding(4)
                    Text("days")
                default: Text("Today") // dateDiff == 0
                }

            case .byDistance:
                let distance = getReminderDistance(inSelf, self.context)
                switch distance {
                case 1...:
                    Text("After")
                    Text("\(distance)").padding(4)
                    Text("km")
                case ...(-1):
                    Text("Missed")
                    Text("\(-distance)").padding(4)
                    Text("km")
                default: Text("Now") // distance == 0
                }

            default: EmptyView()
            }
        }
    }
}



struct RemindersView_Previews: PreviewProvider {
    static var previews: some View {
        RemindersView(viewName: "")
    }
}
