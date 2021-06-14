//
//  Structs.swift
//  CarExp
//
//  Created by Денис Колеснёв on 24.05.2021.
//

import SwiftUI

struct UserDef {
    private let userDefaults = UserDefaults.standard
    private let actualDistanceKey = "ActualDistance"
    
    func setActualDistance(_ value: Int32) { userDefaults.setValue(value, forKeyPath: actualDistanceKey) }
    func getActualDistance() -> Int32 { Int32(userDefaults.integer(forKey: actualDistanceKey)) }
    func getActualDistance() -> String { userDefaults.string(forKey: actualDistanceKey) ?? "" }
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

