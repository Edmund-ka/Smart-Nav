//
//  HomeView.swift
//  Argus
//
//  Created by Edmund Afunyah on 9/30/26.
//

import SwiftUI

struct HomeView: View {

    @State var selectedLatitude: Double = 0
    @State var selectedLongitude: Double = 0

    var body: some View {

        VStack(spacing: 0) {

            // App Title
            Text("Argus")
                .font(.title)
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 10)


            // Map
            OpenStreetMapView(
                latitude: $selectedLatitude,
                longitude: $selectedLongitude
            )
            .frame(maxWidth: .infinity)
            .frame(height: 500)


            // Selected Location Card
            VStack(spacing: 8) {

                Text("Selected Location")
                    .font(.headline)

                HStack {

                    VStack(alignment: .leading) {

                        Text("Latitude")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(
                            "\(selectedLatitude, specifier: "%.6f")"
                        )
                        .font(.body)
                        .bold()
                    }


                    Spacer()


                    VStack(alignment: .leading) {

                        Text("Longitude")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(
                            "\(selectedLongitude, specifier: "%.6f")"
                        )
                        .font(.body)
                        .bold()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.12))
            .cornerRadius(12)
            .padding()


            Text("Tap anywhere on the map to select a location.")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
