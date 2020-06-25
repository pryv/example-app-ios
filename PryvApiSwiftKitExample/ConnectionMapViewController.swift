//
//  ConnectionMapViewController.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import MapKit
import PryvApiSwiftKit

/// Filter for the events timeslot to show on the map
private enum TimeFilter {
    case day
    case week
    case month
}

class ConnectionMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var datePicker: UIDatePicker!
    
    private var duration = TimeFilter.week
    private var selectedDate = Date()
    private let calendar = Calendar.current
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            getEvents(until: selectedDate, during: duration)
        }
    }
    
    override func viewDidLoad() {
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        mapView.delegate = self
    }
    
    // MARK: - Interactions and settings for the events to show on the map
    
    /// Filters the list of events according to the newly set date in the date picker
    /// - Parameter datePicker
    @objc private func dateChanged(_ datePicker: UIDatePicker) {
        selectedDate = datePicker.date
        if calendar.isDateInToday(selectedDate) {
            selectedDate = Date()
        }
        getEvents(until: selectedDate, during: duration)
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
            params["toTime"] = selectedDate.endOfDay.timeIntervalSince1970
        case .week:
            params["fromTime"] = selectedDate.startOfWeek.timeIntervalSince1970
            params["toTime"] = selectedDate.endOfWeek.timeIntervalSince1970
        case .month:
            params["fromTime"] = selectedDate.startOfMonth.timeIntervalSince1970
            params["toTime"] = selectedDate.endOfMonth.timeIntervalSince1970
        }
        
        var events = [Event]()
        connection?.getEventsStreamed(queryParams: params, forEachEvent: { events.append($0) }) { _ in
            self.cleanMapView()
            self.show(events: events.filter{ event in
                (event["type"] as? String)?.contains("position") ?? false
            })
        }
    }
    
    /// Show the events on the map using markers and paths
    /// The last position will have a marker, the others will be drawn using a path between them
    /// # Note
    ///     This path does not follow any route, it is a simple straight line
    /// - Parameter events
    private func show(events: [Event]) {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<events.count {
            let event = events[i]
            if let content = event["content"] as? [String: Any], let latitude = content["latitude"] as? Double, let longitude = content["longitude"] as? Double {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                coordinates.append(coordinate)
                
                if i == 0 {
                    let time = event["time"] as? Double
                    let point = MKPointAnnotation()
                    point.coordinate = coordinate
                    if let _ = time {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        point.title = formatter.string(from: Date(timeIntervalSince1970: time!))
                    }
                    mapView.addAnnotation(point)
                    
                    let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
                    mapView.setRegion(coordinateRegion, animated: true)
                }
            }
        }
        
        if coordinates.count > 0 {
            showRoute(coordinates: coordinates)
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
        polylineRenderer.strokeColor = .systemGreen
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
    
}
