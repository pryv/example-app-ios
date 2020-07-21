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
            sleep(1)
            app.alerts.element.buttons["Log out"].tap()
            sleep(3)
        }
    }
    
    func testBadServiceInfoUrl() {
        app.textFields["serviceInfoUrlField"].tap()
        app.textFields["serviceInfoUrlField"].buttons["Clear text"].tap()
        app.textFields["serviceInfoUrlField"].typeText("hello")
        app.buttons["loginButton"].tap()
        
        XCTAssertEqual(app.alerts.element.staticTexts.element.label, "Please, type a valid service info URL")
        XCTAssertFalse(app.webViews["webView"].exists)
    }
    
    func testLogin() {
        app.buttons["loginButton"].tap()
        sleep(2)
        XCTAssert(app.webViews["webView"].exists)
    }
}
