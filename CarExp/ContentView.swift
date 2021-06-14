//
//  ContentView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    private let badgePos: CGFloat = 2
    private let tabsCount: CGFloat = 4
    @State private var badgeNumber: Int = 0
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                
                TabView {
                    ExpensesView(viewName: "Expenses")
                        .tabItem {
                            Text("Expenses")
                            Image(systemName: "list.bullet.rectangle")
                        }
                    
                    RemindersView(viewName: "Reminders")
                        .tabItem {
                            Text("Reminders")
                            Image(systemName: "bell")
                        }
                    
                    StatisticsView()
                        .tabItem {
                            Text("Statistic")
                            Image(systemName: "chart.bar.xaxis")
                        }

                    SettingsView(viewName: "Settings")
                        .tabItem {
                            Text("Settings")
                            Image(systemName: "gearshape.fill")
                        }
                }
                
                ZStack {
                    Circle().foregroundColor(Color(.systemRed))
                    Text("\(self.badgeNumber)")
                        .foregroundColor(.white)
                        .font(Font.system(size: 12))
                }
                .frame(width: 20, height: 20)
                .offset(x: ((2 * self.badgePos) - 1) * (geometry.size.width / (2 * self.tabsCount)), y: -30)
                .opacity(self.badgeNumber == 0 ? 0 : 1)
                .onAppear(perform: { self.badgeNumber = getMissedReminders(self.context).count })
            }.ignoresSafeArea(/*@START_MENU_TOKEN@*/.keyboard/*@END_MENU_TOKEN@*/)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
