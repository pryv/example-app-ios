//
//  PryvApiSwiftKitExampleUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import KeychainSwift

class ServiceInfoUITests: XCTestCase {
    
    var app: XCUIApplication!
    private let keychain = KeychainSwift()
    private var values = [String]()
    private let existsPredicate = NSPredicate(format: "exists == TRUE")
    
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
            self.waitForExpectations(timeout: 5.0, handler: nil)
            
            logout.tap()
            
            self.expectation(for: existsPredicate, evaluatedWith: app.buttons["loginButton"], handler: nil)
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
    }
    
    func testBadServiceInfoUrl() {
        app.textFields["serviceInfoUrlField"].tap()
        app.textFields["serviceInfoUrlField"].buttons["Clear text"].tap()
        app.textFields["serviceInfoUrlField"].typeText("hello")
        app.buttons["loginButton"].tap()
        
        XCTAssert(app.alerts.element.staticTexts["unsupported URL"].exists)
        XCTAssertEqual(app.alerts.element.label, "Service info request failed")
        XCTAssertFalse(app.webViews["webView"].exists)
    }
    
    func testLogin() {
        app.buttons["loginButton"].tap()
        
        let webView = app.webViews["webView"]
        self.expectation(for: existsPredicate, evaluatedWith: webView, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssert(webView.exists)
    }
}
