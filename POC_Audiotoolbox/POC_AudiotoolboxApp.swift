//
//  POC_AudiotoolboxApp.swift
//  POC_Audiotoolbox
//
//  Created by Caio Soares on 07/11/22.
//

import SwiftUI

@main
struct POC_AudiotoolboxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().task {
                Services.buildInstrument()
            }
        }
    }
}
