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
@testable import PryvApiSwiftKitExample

class ServiceInfoUITests: XCTestCase {
    
    var app: XCUIApplication!
    private let keychain = KeychainSwift()
    private var values = [String]()
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        if (app.buttons["logoutButton"].exists) {
            app.buttons["logoutButton"].tap()
        }
    }
    
    func testLogin() {
        app.buttons["loginButton"].tap()
        
        app.alerts.textFields["usernameField"].tap()
        app.alerts.textFields["usernameField"].typeText("testuser")
        XCTAssertFalse(app.alerts.buttons["OK"].isEnabled)
        
        app.alerts.secureTextFields["passwordField"].tap()
        app.alerts.secureTextFields["passwordField"].typeText("testuser")
        XCTAssertTrue(app.alerts.buttons["OK"].isEnabled)
        
        app.alerts.buttons["OK"].tap()
        XCTAssert(app.staticTexts["welcomeLabel"].exists)
    }
    
    func testBadLogin() {
        app.buttons["loginButton"].tap()
        
        app.alerts.textFields["usernameField"].tap()
        app.alerts.textFields["usernameField"].typeText("testuser")
        XCTAssertFalse(app.alerts.buttons["OK"].isEnabled)
        
        app.alerts.secureTextFields["passwordField"].tap()
        app.alerts.secureTextFields["passwordField"].typeText("random_wrong_pwd")
        XCTAssertTrue(app.alerts.buttons["OK"].isEnabled)
        
        app.alerts.buttons["OK"].tap()
        XCTAssertFalse(app.staticTexts["welcomeLabel"].exists)
    }
    
    func testAuthAndBackButton() {
        app.buttons["authButton"].tap()
        XCTAssert(app.webViews["webView"].exists)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssert(app.staticTexts["appName"].exists)
    }
    
    func testBadServiceInfoUrl() {
        app.textFields["serviceInfoUrlField"].tap()
        app.textFields["serviceInfoUrlField"].typeText("hello")
        app.buttons["authButton"].tap()
        
        XCTAssertFalse(app.webViews["webView"].exists)
        
        XCTAssertEqual(app.alerts.element.label, "Invalid URL")
    }
}
