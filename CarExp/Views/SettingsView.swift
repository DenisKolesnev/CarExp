//
//  SettingsView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    var viewName: LocalizedStringKey
    @State private var averageDistanceStr = ""
    @State private var actualDistanceStr = ""
    @State private var currencySymbol = String()
    
    var body: some View {
        NavigationView {
            Form{
                TextField("Текущий пробег", text: self.$actualDistanceStr)
                
                TextField("Знак валюты", text: self.$currencySymbol)
                    .onReceive(Just(self.currencySymbol)) { _ in
                        let textLimit = 3
                        if self.currencySymbol.count > textLimit {
                            self.currencySymbol = String(self.currencySymbol.prefix(textLimit))
                        }
                    }

            }
            .navigationTitle(viewName)
            .navigationBarItems(
                trailing:
                    Button("Save", action: {
                        UserDef().setActualDistance(Int32(self.actualDistanceStr) ?? 0)
                        UserDef().setCurrencySubmol(self.currencySymbol.uppercased())
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                    })
            ).onAppear(perform: {
                self.actualDistanceStr = UserDef().getActualDistance()
                self.currencySymbol = UserDef().getCurrencySumbol()
            })
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewName: "")
    }
}
