//
//  OpenStreetMapView.swift
//  Argus
//
//  Created by Edmund Afunyah on 9/30/26.
//

import SwiftUI
import MapLibre

// This creates a SwiftUI-compatible wrapper around MapLibre's UIKit map.
struct OpenStreetMapView: UIViewRepresentable {

    // These values come from HomeView.
    // @Binding lets this view READ and CHANGE them.
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var hasSelectedLocation: Bool


    // Creates the Coordinator object.
    // The Coordinator handles map events such as:
    // - map finishing loading
    // - user tapping the map
    // - drawing the marker
    func makeCoordinator() -> Coordinator {

        Coordinator(self)
    }


    // This function creates the actual MapLibre map.
    // SwiftUI calls this when the map view is first created.
    func makeUIView(context: Context) -> MLNMapView {

        // Create the MapLibre map object.
        let mapView = MLNMapView()


        // Tell the map that the Coordinator should receive map events.
        mapView.delegate = context.coordinator


        // Create a latitude/longitude coordinate near TSU.
        let tsuCoordinate = CLLocationCoordinate2D(
            latitude: 36.1676,
            longitude: -86.8303
        )


        // Move the map camera to TSU.
        mapView.setCenter(
            tsuCoordinate,
            zoomLevel: 16,
            animated: false
        )


        // Create something that can recognize a tap on the map.
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.mapTapped(_:))
        )


        // Attach the tap detector to the map.
        mapView.addGestureRecognizer(tapGesture)


        // Return the finished map to SwiftUI.
        return mapView
    }


    // SwiftUI calls this when it wants to update the UIKit map.
    // We do not need anything here right now.
    func updateUIView(_ mapView: MLNMapView, context: Context) {

    }


    // The Coordinator connects MapLibre's UIKit behavior
    // to our SwiftUI OpenStreetMapView.
    class Coordinator: NSObject, MLNMapViewDelegate {

        // This gives the Coordinator access to the parent
        // OpenStreetMapView and its latitude/longitude bindings.
        var parent: OpenStreetMapView


        // This initializer runs when the Coordinator is created.
        init(_ parent: OpenStreetMapView) {

            // Save a reference to the parent map view.
            self.parent = parent
        }


        // MARK: - Load OpenStreetMap


        // MapLibre calls this function automatically
        // after its map style has finished loading.
        func mapView(
            _ mapView: MLNMapView,
            didFinishLoading style: MLNStyle
        ) {

            // URL pattern for OpenStreetMap map tiles.
            // {z} = zoom level
            // {x} = horizontal tile number
            // {y} = vertical tile number
            let tileURL =
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png"


            // Create a raster tile source.
            // This tells MapLibre where the actual map images come from.
            let source = MLNRasterTileSource(
                identifier: "openstreetmap",
                tileURLTemplates: [tileURL],
                options: [
                    .tileSize: 256
                ]
            )


            // Register the OpenStreetMap source with the map style.
            style.addSource(source)


            // Create a visual layer that will display the tiles.
            let layer = MLNRasterStyleLayer(
                identifier: "openstreetmap-layer",
                source: source
            )


            // Add the visual OpenStreetMap layer to the map.
            style.addLayer(layer)
        }


        // MARK: - Marker Appearance


        // MapLibre calls this function when it needs to know
        // what an annotation/marker should look like.
        func mapView(
            _ mapView: MLNMapView,
            viewFor annotation: MLNAnnotation
        ) -> MLNAnnotationView? {

            // A name used to identify reusable marker views.
            let identifier = "marker"


            // Try to reuse a marker that already exists.
            var annotationView =
                mapView.dequeueReusableAnnotationView(
                    withIdentifier: identifier
                )


            // If there is no reusable marker, create a new one.
            if annotationView == nil {

                annotationView = MLNAnnotationView(
                    reuseIdentifier: identifier
                )


                // Give the marker a size of 36 x 36 points.
                annotationView?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: 36,
                    height: 36
                )


                // Create an image using Apple's built-in map pin icon.
                let imageView = UIImageView(
                    image: UIImage(systemName: "mappin.circle.fill")
                )


                // Make the image fill the marker view.
                imageView.frame = annotationView?.bounds ?? .zero


                // Keep the pin image's proportions correct.
                imageView.contentMode = .scaleAspectFit


                // Make the pin red.
                imageView.tintColor = .systemRed


                // Put the pin image inside the annotation view.
                annotationView?.addSubview(imageView)
            }


            // Return the finished marker view to MapLibre.
            return annotationView
        }


        // MARK: - Map Tap


        // This function runs whenever the user taps the map.
        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {

            // Make sure the thing that was tapped is really an MLNMapView.
            // If not, stop the function.
            guard let mapView = gesture.view as? MLNMapView else {
                return
            }


            // Get the screen position where the user tapped.
            let tappedPoint = gesture.location(in: mapView)


            // Convert the screen position into a geographic coordinate.
            let coordinate = mapView.convert(
                tappedPoint,
                toCoordinateFrom: mapView
            )


            // Send the selected latitude back to HomeView.
            parent.latitude = coordinate.latitude


            // Send the selected longitude back to HomeView.
            parent.longitude = coordinate.longitude

            // Tell the interface that it can now display the selected coordinates.
            parent.hasSelectedLocation = true


            // Check whether there is already a marker on the map.
            if let oldAnnotations = mapView.annotations {

                // Remove all existing markers.
                mapView.removeAnnotations(oldAnnotations)
            }


            // Create a new point marker.
            let marker = MLNPointAnnotation()


            // Place the marker at the tapped coordinate.
            marker.coordinate = coordinate


            // Give the marker a title.
            marker.title = "Selected Location"


            // Give the marker a subtitle containing the coordinates.
            marker.subtitle =
                "Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)"


            // Add the new marker to the map.
            mapView.addAnnotation(marker)
        }
    }
}
