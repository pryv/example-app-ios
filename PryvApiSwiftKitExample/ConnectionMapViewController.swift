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
    case day = -1
    case week = -7
    case month = -31
}

class ConnectionMapViewController: UIViewController {
    
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
        params["fromTime"] = calendar.date(byAdding: dateComponent, to: calendar.startOfDay(for: toDate))?.timeIntervalSince1970 ?? 0
        params["toTime"] = toDate.timeIntervalSince1970
        
        let request = [
            [
                "method": "events.get",
                "params": params
            ]
        ]
        if let result = connection!.api(APICalls: request) {
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            show(events: result.filter{ event in
                (event["type"] as? String)?.contains("position") ?? false
            })
        }
    }
    
    private func show(events: [Event]) {
        for i in 0..<events.count {
            let event = events[i]
            if let content = event["content"] as? [String: Any], let latitude = content["latitude"] as? Double, let longitude = content["longitude"] as? Double {
                let point = MKPointAnnotation()
                point.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                mapView.addAnnotation(point)
                
                if i == 0 {
                    let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
                    let meters: CLLocationDistance = 5000
                    let coordinateRegion = MKCoordinateRegion(
                      center: initialLocation.coordinate,
                      latitudinalMeters: meters,
                      longitudinalMeters: meters)
                    
                    mapView.setRegion(coordinateRegion, animated: true)
                }
            }
        }
    }

}
