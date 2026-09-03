import SwiftUI
import MapKit

struct DraggableLocationMap: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .includingAll
        map.showsCompass = true
        let annotation = MKPointAnnotation()
        annotation.title = "拖动调整位置"
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        map.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500), animated: false)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard let annotation = map.annotations.first(where: { !($0 is MKUserLocation) }) as? MKPointAnnotation else { return }
        if abs(annotation.coordinate.latitude - coordinate.latitude) > 0.000001 || abs(annotation.coordinate.longitude - coordinate.longitude) > 0.000001 {
            annotation.coordinate = coordinate
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: DraggableLocationMap
        init(parent: DraggableLocationMap) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = "draggable-pin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView) ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.isDraggable = true
            view.markerTintColor = .systemTeal
            view.glyphImage = UIImage(systemName: "mappin")
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
            guard newState == .ending, let value = view.annotation?.coordinate else { return }
            parent.coordinate = value
        }
    }
}
