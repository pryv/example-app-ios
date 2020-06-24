//
//  ConnectionMapUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 22.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest

class ConnectionMapUITests: XCTestCase {
    private let defaultServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let endpoint = "https://ckbc28vpd00kz1vd3s7vgiszs@Testuser.pryv.me/"
    
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
               
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        if (!app.buttons["logoutButton"].exists) {
            app.buttons["loginButton"].tap()
            app.staticTexts["Username or email"].tap()
            app.typeText("Testuser")
            app.staticTexts["Password"].tap()
            app.typeText("testuser")
            app.buttons["SIGN IN"].tap()
            app.buttons["ACCEPT"].tap()
            sleep(2)
        }
        
        app.tabBars["connectionTabBar"].buttons["mapButtonItem"].tap()
        XCTAssert(app.maps.element(boundBy: 0).exists)
        
        let datePickers = XCUIApplication().datePickers
        datePickers.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "June")
        datePickers.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "22")
        datePickers.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "2020")
        
        sleep(2)
    }
    
    // Assuming that before the 22nd of June 2020, there are no position events.
    
    func testMarkers() {
        XCTAssert(app.otherElements["2020-06-22"].exists)
        
        app.segmentedControls["filterController"].buttons["Day"].tap()
        XCTAssert(app.otherElements["2020-06-22"].exists)
        
        app.segmentedControls["filterController"].buttons["Week"].tap()
        XCTAssert(app.otherElements["2020-06-22"].exists)
        
        app.segmentedControls["filterController"].buttons["Month"].tap()
        XCTAssert(app.otherElements["2020-06-22"].exists)
    }
    
    func testNoMarkers() {
        let datePickers = XCUIApplication().datePickers
        datePickers.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "June")
        datePickers.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "21")
        datePickers.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "2020")
        
        sleep(1)
        XCTAssertFalse(app.otherElements["2020-06-22"].exists)
    }

}
