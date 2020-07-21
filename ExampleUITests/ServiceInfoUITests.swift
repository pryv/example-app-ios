//
//  PryvApiSwiftKitExampleUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest

class ServiceInfoUITests: XCTestCase {
    
    var app: XCUIApplication!
    private var values = [String]()
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        sleep(1)
        
        if (app.navigationBars["connectionNavBar"].buttons["userButton"].exists) {
            app.navigationBars["connectionNavBar"].buttons["userButton"].tap()
            app.sheets.element.buttons["Log out"].tap()
            sleep(1)
            app.alerts.element.buttons["Log out"].tap()
            sleep(1)
        }
    }
    
    func testLogin() {
        app.pickers["serviceInfoPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "https://reg.pryv.me/service/info")
        app.buttons["loginButton"].tap()
        XCTAssert(app.webViews["webView"].exists)
        
        app.staticTexts["Username or email"].tap()
        app.typeText("testuser")
        app.staticTexts["Password"].tap()
        app.typeText("testuser")
        app.buttons["SIGN IN"].tap()
        if app.buttons["ACCEPT"].exists {
            app.buttons["ACCEPT"].tap()
        }
        
        sleep(5)
        XCTAssert(app.staticTexts["Pryv Lab"].exists)
        XCTAssertFalse(app.webViews["webView"].exists)
    }
    
    func testLoginWithoutCertificate() {
        app.pickers["serviceInfoPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "https://reg.pryv.me/service/info")
        app.buttons["loginButton"].tap()
        
        sleep(2)
        XCTAssert(app.webViews["webView"].exists)
        
        app.staticTexts["Username or email"].tap()
        app.typeText("Testuser")
        app.staticTexts["Password"].tap()
        app.typeText("testuser")
        app.buttons["SIGN IN"].tap()
        if app.buttons["ACCEPT"].exists {
            app.buttons["ACCEPT"].tap()
        }
        
        XCTAssertFalse(app.staticTexts["Pryv Lab"].exists)
        XCTAssert(app.alerts.element.staticTexts.element.label.contains("No certificate found for "))
        XCTAssert(app.alerts.element.staticTexts.element.label.contains("Testuser"))
    }
}
