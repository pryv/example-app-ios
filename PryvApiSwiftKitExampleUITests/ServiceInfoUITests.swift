//
//  PryvApiSwiftKitExampleUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import Mocker
import KeychainSwift

class ServiceInfoUITests: XCTestCase {
    
    var app: XCUIApplication!
    private let keychain = KeychainSwift()
    private var values = [String]()
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        if (app.navigationBars["connectionNavBar"].buttons["userButton"].exists) {
            app.navigationBars["connectionNavBar"].buttons["userButton"].tap()
            app.sheets.element.buttons["Log out"].tap()
            sleep(1)
            app.alerts.element.buttons["Log out"].tap()
        }
    }
    
    func testBadServiceInfoUrl() {
        app.textFields["serviceInfoUrlField"].tap()
        app.textFields["serviceInfoUrlField"].doubleTap()
        app.textFields["serviceInfoUrlField"].typeText(XCUIKeyboardKey.delete.rawValue)
        app.textFields["serviceInfoUrlField"].typeText("hello")
        app.buttons["loginButton"].tap()
        
        XCTAssertEqual(app.alerts.element.staticTexts.element.label, "Please, type a valid service info URL")
        XCTAssertFalse(app.webViews["webView"].exists)
    }
    
    func testLogin() {
        app.buttons["loginButton"].tap()
        XCTAssert(app.webViews["webView"].exists)
    }
}
