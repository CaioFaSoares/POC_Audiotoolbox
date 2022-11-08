//
//  ContentView.swift
//  POC_Audiotoolbox
//
//  Created by Caio Soares on 07/11/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button  {
                Services.buildInstrument()
            } label: {
                Text("Ukulele")
            }

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
