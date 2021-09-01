//
//  ContentView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI
import RxSwift

let badgeSequence = PublishSubject<Int>()

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    private let badgePos: CGFloat = 2
    private let tabsCount: CGFloat = 4
    private let bag = DisposeBag()
    @State private var badgeNumber = 0
    
    private func badgeSequenceSubscribe() {
        badgeSequence.subscribe(onNext: {
            self.badgeNumber = $0
        }).disposed(by: bag)
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                
                TabView {
                    ExpensesView(viewName: "Expenses")
                        .tabItem {
                            Label("Expenses", systemImage: "list.bullet.rectangle")
                        }
                    
                    RemindersView(viewName: "Reminders")
                        .tabItem {
                            Label("Reminders", systemImage: "bell")
                        }
                    
                    StatisticView(viewName: "Statistic")
                        .tabItem {
                            Label("Statistic", systemImage: "chart.bar.xaxis")
                        }

                    SettingsView(viewName: "Settings")
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
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
                .onAppear(perform: {
                    badgeSequenceSubscribe()
                    badgeSequence.onNext(UserData(self.context).getMissedReminders().count)
                })
            }.ignoresSafeArea(/*@START_MENU_TOKEN@*/.keyboard/*@END_MENU_TOKEN@*/)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
