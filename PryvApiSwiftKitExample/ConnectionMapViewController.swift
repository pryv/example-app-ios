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

class ConnectionMapViewController: UIViewController {
    
    @IBOutlet private weak var mapView: MKMapView!
    
    private var events = [Event]() {
        didSet {
            loadViewIfNeeded()
            for i in 0..<events.count {
                let event = events[i]
                if let content = event["content"] as? [String: Any], let latitude = content["latitude"] as? Double, let longitude = content["longitude"] as? Double {
                    let point = MKPointAnnotation()
                    point.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    mapView.addAnnotation(point)
                    
                    if i == event.count - 1 {
                        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
                        let meters: CLLocationDistance = 2000
                        let coordinateRegion = MKCoordinateRegion(
                          center: initialLocation.coordinate,
                          latitudinalMeters: meters,
                          longitudinalMeters: meters)
                        
                        mapView.setCameraBoundary(
                          MKMapView.CameraBoundary(coordinateRegion: coordinateRegion),
                          animated: true)
                        
                        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 10000)
                        mapView.setCameraZoomRange(zoomRange, animated: true)
                    }
                }
            }
        }
    }
    
    var connection: Connection? {
        didSet {
            getEvents()
        }
    }
    
    func getEvents() {
        var dayComponent = DateComponents()
        dayComponent.day = -7
        let oneWeekAgo = Calendar.current.date(byAdding: dayComponent, to: Date())
        
        let request = [
            [
                "method": "events.get",
                "params": [
                    "fromTime": oneWeekAgo?.timeIntervalSince1970
                ]
            ]
        ]
        if let result = connection!.api(APICalls: request) {
            self.events = result.filter{ event in
                (event["type"] as? String)?.contains("position") ?? false
            }
        }
    }

}
