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
    private let existsPredicate = NSPredicate(format: "exists == TRUE")
    private let timeout = 10.0
    
    override func setUp() {
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
        
        if (app.navigationBars["connectionNavBar"].buttons["userButton"].exists) {
            app.navigationBars["connectionNavBar"].buttons["userButton"].tap()
            app.sheets.element.buttons["Log out"].tap()
            let logout = app.alerts.element.buttons["Log out"]
            self.expectation(for: existsPredicate, evaluatedWith: logout, handler: nil)
            self.waitForExpectations(timeout: timeout, handler: nil)
            
            logout.tap()
        }
        
        self.expectation(for: existsPredicate, evaluatedWith: app.textFields["serviceInfoUrlField"], handler: nil)
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testLogin() {
        app.pickers["serviceInfoPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "https://reg.pryv.me/service/info")
        app.buttons["loginButton"].tap()
        sleep(3)
        XCTAssert(app.webViews["webView"].exists)
        
        app.staticTexts["Username or email"].tap()
        app.typeText("testuser")
        app.staticTexts["Password"].tap()
        app.typeText("testuser")
        app.buttons["SIGN IN"].tap()
        if app.buttons["ACCEPT"].exists {
            app.buttons["ACCEPT"].tap()
        }
        
        XCTAssert(app.alerts.element.staticTexts["unsupported URL"].exists)
        XCTAssertEqual(app.alerts.element.label, "Service info request failed")
        XCTAssertFalse(app.webViews["webView"].exists)
    }
    
    func testLoginWithoutCertificate() {
        app.pickers["serviceInfoPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "https://reg.pryv.me/service/info")
        app.buttons["loginButton"].tap()
        
        let webView = app.webViews["webView"]
        self.expectation(for: existsPredicate, evaluatedWith: webView, handler: nil)
        self.waitForExpectations(timeout: timeout, handler: nil)
        XCTAssert(webView.exists)
        
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
