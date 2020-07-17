//
//  ConnectionMapViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import MapKit
import PryvSwiftKit
import RLBAlertsPickers
import TAK

/// Filter for the events timeslot to show on the map
private enum TimeFilter {
    case day
    case week
    case month
}

class ConnectionMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet private weak var currentDateLabel: UILabel!
    @IBOutlet private weak var mapView: MKMapView!
    
    private var duration = TimeFilter.week
    private var selectedDate = Date()
    private let calendar = Calendar.current
    private let formatter = DateFormatter()
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            getEvents(until: selectedDate, during: duration)
        }
    }
    
    override func viewDidLoad() {
        formatter.dateFormat = "dd.MM.yyyy"
        currentDateLabel.text = formatter.string(from: selectedDate)
        mapView.delegate = self
    }
    
    // MARK: - Interactions and settings for the events to show on the map
    
    /// Filters the list of events according to the newly set date in the date picker
    /// - Parameter sender: the button to tap to open the date picker alert
    @IBAction func openDatePicker(_ sender: Any) {
        var pickedDate: Date?
        let minDate = calendar.date(byAdding: .year, value: -5, to: Date()) // max 5 years ago
        
        let alert = UIAlertController(style: .alert, title: nil)
        alert.addDatePicker(mode: .date, date: selectedDate, minimumDate: minDate, maximumDate: Date()) { pickedDate = $0 }
        alert.addAction(title: "Done", style: .default, handler: { _ in
            if let _ = pickedDate {
                self.selectedDate = pickedDate!
                self.currentDateLabel.text = self.formatter.string(from: self.selectedDate)
                self.getEvents(until: self.selectedDate, during: self.duration)
            }
        })
        
        alert.show()
    }
    
    /// Filters the list of events according to the newly set duration in the segmented control
    /// - Parameter segControl: the segmented control with day, week or month duration filter
    @IBAction private func switchFilter(_ segControl: UISegmentedControl) {
        switch segControl.selectedSegmentIndex {
        case 0:
            duration = .day
        case 1:
            duration = .week
        case 2:
            duration = .month
        default:
            return
        }
        getEvents(until: selectedDate, during: duration)
    }
    
    /// Loads the events from the Pryv backend using `events.get` method, filters them by time/duration and shows them on the map
    /// - Parameters:
    ///   - until: the date corresponding to the `toTime` in the `events.get` method
    ///   - during: the duration of the timeslot to show
    private func getEvents(until: Date, during: TimeFilter) {
        var params = Json()
        switch during {
        case .day:
            params["fromTime"] = selectedDate.startOfDay.timeIntervalSince1970
            params["toTime"] = selectedDate.isInToday ? Date().timeIntervalSince1970 : selectedDate.endOfDay.timeIntervalSince1970
        case .week:
            params["fromTime"] = selectedDate.startOfWeek.timeIntervalSince1970
            params["toTime"] = selectedDate.endOfWeek.timeIntervalSince1970
        case .month:
            params["fromTime"] = selectedDate.startOfMonth.timeIntervalSince1970
            params["toTime"] = selectedDate.endOfMonth.timeIntervalSince1970
        }
        
        var events = [Event]()
        connection?.getEventsStreamed(queryParams: params, forEachEvent: { events.append($0) }).then { _ in
            self.cleanMapView()
            var coordinates = [Double: CLLocationCoordinate2D]()
            events.forEach { event in
                if let position = (event["type"] as? String)?.contains("position"), position,
                    let content = event["content"] as? [String: Any],
                    let latitude = content["latitude"] as? Double,
                    let longitude = content["longitude"] as? Double, let time = event["time"] as? Double {
                    coordinates[time] = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
            }
            
            self.show(coordinates: coordinates)
        }
    }
    
    /// Show the events on the map using markers and paths
    /// The last position will have a marker, the others will be drawn using a path between them
    /// # Note
    ///     This path does not follow any route, it is a simple straight line
    /// - Parameter time of the events mapped to their 2D location
    private func show(coordinates: [Double: CLLocationCoordinate2D]) {
        if let mostRecentTime = coordinates.keys.max(), let mostRecentCoord = coordinates[mostRecentTime] {
            let point = MKPointAnnotation()
            point.coordinate = mostRecentCoord
            point.title = formatter.string(from: Date(timeIntervalSince1970: mostRecentTime))
            mapView.addAnnotation(point)
            
            let coordinateRegion = MKCoordinateRegion(center: mostRecentCoord, latitudinalMeters: 5000, longitudinalMeters: 5000)
            mapView.setRegion(coordinateRegion, animated: true)
        }
        
        if coordinates.count > 0 {
            showRoute(coordinates: coordinates.sorted(by: { $0.key < $1.key }).map({ $0.value }))
        }
    }
    
    /// Draw the path between the coordinates on the map
    /// # Note
    ///     This path does not follow any route, it is a simple straight line
    /// - Parameter coordinates
    private func showRoute(coordinates: [CLLocationCoordinate2D]) {
        let geodesic = MKGeodesicPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(geodesic)
    }
    
    /// Clean the map view by remove all the paths and markers
    private func cleanMapView() {
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
        
        let allOverlays = mapView.overlays
        mapView.removeOverlays(allOverlays)
    }
    
    // MARK:- map view delegate functions
    
    /// Render the mapView details such as the paths
    /// - Parameters:
    ///   - mapView
    ///   - overlay: the paths overlay
    /// - Returns: a renderer for the paths
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = .systemBlue
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
    
}
