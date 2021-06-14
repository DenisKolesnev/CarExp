//
//  SettingsView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 17.10.2020.
//

import SwiftUI

struct SettingsView: View {
    var viewName: LocalizedStringKey
    @State private var averageDistanceStr = ""
    @State private var actualDistanceStr = ""
    
    var body: some View {
        NavigationView {
            Form{
                TextField("Текущий пробег", text: self.$actualDistanceStr)
            }
            .navigationTitle(viewName)
            .navigationBarItems(
                trailing:
                    Button("Save", action: {
                        UserDef().setActualDistance(Int32(self.actualDistanceStr) ?? 0)
                    })
            ).onAppear(perform: {
                self.actualDistanceStr = UserDef().getActualDistance()
            })
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewName: "")
    }
}
