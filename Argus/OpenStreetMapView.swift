//
//  OpenStreetMapView.swift
//  Argus
//
//  Created by Edmund Afunyah on 9/30/26.
//

import SwiftUI
import MapLibre

struct OpenStreetMapView: UIViewRepresentable {

    @Binding var latitude: Double
    @Binding var longitude: Double


    func makeCoordinator() -> Coordinator {

        Coordinator(self)
    }


    func makeUIView(context: Context) -> MLNMapView {

        let mapView = MLNMapView()

        // Let the Coordinator respond to map events
        mapView.delegate = context.coordinator


        // Center the map around TSU
        let tsuCoordinate = CLLocationCoordinate2D(
            latitude: 36.1676,
            longitude: -86.8303
        )

        mapView.setCenter(
            tsuCoordinate,
            zoomLevel: 16,
            animated: false
        )


        // Detect when the user taps the map
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.mapTapped(_:))
        )

        mapView.addGestureRecognizer(tapGesture)


        return mapView
    }


    func updateUIView(_ mapView: MLNMapView, context: Context) {

    }


    class Coordinator: NSObject, MLNMapViewDelegate {

        var parent: OpenStreetMapView


        init(_ parent: OpenStreetMapView) {

            self.parent = parent
        }


        // MARK: - Load OpenStreetMap

        func mapView(
            _ mapView: MLNMapView,
            didFinishLoading style: MLNStyle
        ) {

            let tileURL =
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png"


            let source = MLNRasterTileSource(
                identifier: "openstreetmap",
                tileURLTemplates: [tileURL],
                options: [
                    .tileSize: 256
                ]
            )


            style.addSource(source)


            let layer = MLNRasterStyleLayer(
                identifier: "openstreetmap-layer",
                source: source
            )


            style.addLayer(layer)
        }


        // MARK: - Marker Appearance

        func mapView(
            _ mapView: MLNMapView,
            viewFor annotation: MLNAnnotation
        ) -> MLNAnnotationView? {

            let identifier = "marker"

            var annotationView =
                mapView.dequeueReusableAnnotationView(
                    withIdentifier: identifier
                )

            if annotationView == nil {

                annotationView = MLNAnnotationView(
                    reuseIdentifier: identifier
                )

                annotationView?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: 36,
                    height: 36
                )

                let imageView = UIImageView(
                    image: UIImage(systemName: "mappin.circle.fill")
                )

                imageView.frame = annotationView?.bounds ?? .zero

                imageView.contentMode = .scaleAspectFit

                imageView.tintColor = .systemRed

                annotationView?.addSubview(imageView)
            }

            return annotationView
        }


        // MARK: - Map Tap

        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {

            guard let mapView = gesture.view as? MLNMapView else {
                return
            }


            // Find where the user tapped on the screen
            let tappedPoint = gesture.location(in: mapView)


            // Convert screen location into latitude and longitude
            let coordinate = mapView.convert(
                tappedPoint,
                toCoordinateFrom: mapView
            )


            // Send the coordinates back to HomeView
            parent.latitude = coordinate.latitude
            parent.longitude = coordinate.longitude


            // Remove the previous marker
            if let oldAnnotations = mapView.annotations {

                mapView.removeAnnotations(oldAnnotations)
            }


            // Create a new marker
            let marker = MLNPointAnnotation()

            marker.coordinate = coordinate

            marker.title = "Selected Location"

            marker.subtitle =
                "Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)"


            // Add the marker to the map
            mapView.addAnnotation(marker)
        }
    }
}
