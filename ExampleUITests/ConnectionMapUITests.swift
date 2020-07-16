//
//  ConnectionMapUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import PryvSwiftKit
@testable import Promises

class ConnectionMapUITests: XCTestCase {
    private let defaultServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let endpoint = "https://ckclwj7m504fo1od3fkt6ptqb@Testuser.pryv.me/"
    private var connection: Connection!
    
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
               
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        sleep(1)
        
        if (app.alerts.element.exists) {
            app.alerts.element.buttons["Don’t Allow"].tap()
        }
        
        if (app.buttons["Don’t Allow"].exists) {
            app.buttons["Don’t Allow"].tap()
            app.alerts.element.buttons["OK"].tap()
        }
        
        connection = Connection(apiEndpoint: endpoint)
        
        if (!app.buttons["userButton"].exists) {
            app.buttons["loginButton"].tap()
            app.staticTexts["Username or email"].tap()
            app.typeText("Testuser")
            app.staticTexts["Password"].tap()
            app.typeText("testuser")
            app.buttons["SIGN IN"].tap()
            if app.buttons["ACCEPT"].exists {
                app.buttons["ACCEPT"].tap()
            }
            sleep(2)
        }
        
        app.tabBars["connectionTabBar"].buttons["mapButtonItem"].tap()
        XCTAssert(app.maps.element(boundBy: 0).exists)
        
        changeDate(day: "20", month: "June", year: "2020")
    }
    
    // Assuming that before the 22nd of June 2020 and after the 24th of June 2020, there are no position events.
    
    func testMarkers() {
        changeDate(day: "24")
        sleep(1)
        XCTAssert(app.otherElements["24.06.2020"].exists)
        
        app.segmentedControls["filterController"].buttons["Day"].tap()
        XCTAssert(app.otherElements["24.06.2020"].exists)
        
        app.segmentedControls["filterController"].buttons["Week"].tap()
        XCTAssert(app.otherElements["24.06.2020"].exists)
        
        app.segmentedControls["filterController"].buttons["Month"].tap()
        sleep(1)
        XCTAssert(app.otherElements["29.06.2020"].exists)
    }
    
    func testNoMarkers() {
        app.segmentedControls["filterController"].buttons["Day"].tap()
        sleep(1)
        XCTAssertFalse(app.otherElements["22.06.2020"].exists)
        
        app.segmentedControls["filterController"].buttons["Week"].tap()
        sleep(1)
        XCTAssertFalse(app.otherElements["22.06.2020"].exists)
        
        app.segmentedControls["filterController"].buttons["Month"].tap()
        sleep(1)
        XCTAssert(app.otherElements["29.06.2020"].exists)
        
        changeDate(month: "May")
        XCTAssertFalse(app.otherElements["29.06.2020"].exists)
    }
    
    func testSelectedTime() {
        XCTAssertEqual(app.staticTexts["selectedTimeValue"].label, "20.06.2020")
        
        changeDate(month: "May")
        XCTAssertEqual(app.staticTexts["selectedTimeValue"].label, "20.05.2020")
        
        changeDate(year: "2016")
        XCTAssertEqual(app.staticTexts["selectedTimeValue"].label, "20.05.2016")
        
        changeDate(day: "10", month: "July", year: "2019")
        XCTAssertEqual(app.staticTexts["selectedTimeValue"].label, "10.07.2019")
    }
    
    func testCurrentDayPosition() {
        let params: Json = [
            "streamIds": ["diary"],
            "type": "position/wgs84",
            "content": [
                "latitude": 10.0,
                "longitude": 10.0
            ]
        ]
        
        let apiCall: APICall = [
            "method": "events.create",
            "params": params
        ]
        
        let promise = connection.api(APICalls: [apiCall])
        
        XCTAssert(waitForPromises(timeout: 5.0))
        XCTAssertNil(promise.error)
        XCTAssertNotNil(promise.value)
        
        app.segmentedControls["filterController"].buttons["Day"].tap()
        sleep(1)
        
        changeDate(day: "10", month: "July", year: "2019")
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "dd"
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        
        let today = Date()
        changeDate(day: dayFormatter.string(from: today), month: monthFormatter.string(from: today), year: yearFormatter.string(from: today))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        XCTAssert(app.otherElements[formatter.string(from: today)].exists)
    }
    
    private func changeDate(day: String? = nil, month: String? = nil, year: String? = nil) {
        app.buttons["editDateButton"].tap()
        let datePickers = app.alerts.element.datePickers
        
        if let _ = month {
            datePickers.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: month!)
        }
        
        if let _ = day {
            datePickers.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: day!)
        }
        
        if let _ = year {
            datePickers.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: year!)
        }
        
        app.buttons["Done"].tap()
        sleep(1)
    }

}
