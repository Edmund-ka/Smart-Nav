//
//  ContentView.swift
//  Argus
//
//  Created by Edmund Afunyah on 9/16/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {

        TabView {

            HomeView()
               .tabItem {

                   Image(systemName: "map")

                   Text("Home")
               }


            SensorView()
                .tabItem {

                    Image(systemName: "waveform.path.ecg")

                    Text("Sensors")
                }
        }
    }
}

#Preview {
    ContentView()
}
