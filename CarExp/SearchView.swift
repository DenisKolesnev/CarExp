//
//  SearchView.swift
//  CarExp
//
//  Created by Денис Колеснёв on 09.05.2021.
//

import SwiftUI

struct SearchView: View {
    
    @State private var searchText = ""

    
    func search(text: String) -> FetchedResults<Expenses> {
        let fetchRequest = FetchRequest<Expenses>(
                                        sortDescriptors: [],
                                        predicate: NSPredicate(format: "caption = %@", "\(text)"),
                                        animation: .default)
        return fetchRequest.wrappedValue
    }
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
