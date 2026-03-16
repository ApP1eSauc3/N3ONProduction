//
//  SearchView.swift
//  N3ON
//
//  Created by liam howe on 25/5/2024.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchIsActive = false
    var body: some View {
        //searchbar
        
        Text("")
            .navigationTitle("")
            .searchable(text: $searchText)
            
            
        
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
        )
    }
}
