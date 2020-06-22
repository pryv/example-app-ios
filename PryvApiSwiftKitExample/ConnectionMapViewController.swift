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
    @IBOutlet private weak var filterControl: UISegmentedControl! // TODO: deal with it
    
    override func viewDidLoad() {
        filterControl.backgroundColor = .lightGray
    }
    
    var connection: Connection? {
        didSet {
            loadViewIfNeeded()
            getEvents(.week)
        }
    }
    
    @IBAction func switchFilter(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            getEvents(.day)
        case 1:
            getEvents(.week)
        case 2:
            getEvents(.month)
        default:
            return
        }
    }
    
    private func getEvents(_ filter: TimeFilter) { // 1: day, 7: week, 31: month
        var dayComponent = DateComponents()
        dayComponent.day = filter.rawValue
        let fromTime = Calendar.current.date(byAdding: dayComponent, to: Date())
        
        let request = [
            [
                "method": "events.get",
                "params": [
                    "fromTime": fromTime?.timeIntervalSince1970
                ]
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
