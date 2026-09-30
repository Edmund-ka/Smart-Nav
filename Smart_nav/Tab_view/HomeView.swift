//
//  HomeView.swift
//  Smart_nav
//
//  Created by Edmund Afunyah on 9/30/26.
//

import SwiftUI

struct HomeView: View {

    var body: some View {

        VStack(spacing: 20) {

            Text("Smart Nav")
                .font(.largeTitle)
                .bold()

            Text("Accessible Navigation System")
                .font(.title3)

            Text("Use the tabs below to explore the iPhone sensors used by Smart Nav.")

        }
        .padding()
    }
}

#Preview {
    HomeView()
}
