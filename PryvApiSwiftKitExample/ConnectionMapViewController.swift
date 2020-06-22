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

enum TimeFilter: Int {
    case day = 1
    case week = -7
    case month = -31
}

class ConnectionMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var datePicker: UIDatePicker!
    
    private var duration = TimeFilter.week
    private var currentDate = Date()
    private let calendar = Calendar.current
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            getEvents(toDate: currentDate, duration)
        }
    }
    
    override func viewDidLoad() {
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        mapView.delegate = self;
    }
    
    @objc private func dateChanged(sender: UIDatePicker) {
        currentDate = sender.date
        if calendar.isDateInToday(currentDate) {
            currentDate = Date()
        }
        getEvents(toDate: currentDate, duration)
    }
    
    @IBAction private func switchFilter(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            duration = .day
        case 1:
            duration = .week
        case 2:
            duration = .month
        default:
            return
        }
        getEvents(toDate: currentDate, duration)
    }
    
    private func getEvents(toDate: Date, _ duration: TimeFilter) {
        var dateComponent = DateComponents()
        dateComponent.day = duration.rawValue
        
        var params = Json()
        switch duration {
        case .day:
            params["fromTime"] = calendar.startOfDay(for: toDate).timeIntervalSince1970
            params["toTime"] = calendar.date(byAdding: dateComponent, to: calendar.startOfDay(for: toDate))?.timeIntervalSince1970
        case .week, .month:
            var dayComp = DateComponents()
            dayComp.day = 1
            let endOfDay = calendar.date(byAdding: dayComp, to: calendar.startOfDay(for: toDate))!
            params["fromTime"] = calendar.date(byAdding: dateComponent, to: endOfDay)?.timeIntervalSince1970
            params["toTime"] = endOfDay.timeIntervalSince1970
        }
        
        let request = [
            [
                "method": "events.get",
                "params": params
            ]
        ]
        if let result = connection!.api(APICalls: request) {
            cleanMapView()
            show(events: result.filter{ event in
                (event["type"] as? String)?.contains("position") ?? false
            })
        }
    }
    
    private func show(events: [Event]) {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<events.count {
            let event = events[i]
            if let content = event["content"] as? [String: Any], let latitude = content["latitude"] as? Double, let longitude = content["longitude"] as? Double {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                coordinates.append(coordinate)
                
                if i == 0 {
                    let point = MKPointAnnotation()
                    point.coordinate = coordinate
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
    
    private func showRoute(coordinates: [CLLocationCoordinate2D]) {
        let geodesic = MKGeodesicPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(geodesic)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = .systemGreen
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
    
    private func cleanMapView() {
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
        
        let allOverlays = mapView.overlays
        mapView.removeOverlays(allOverlays)
    }
    
}
