//
//  ConnectionUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 11.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import KeychainSwift
import Mocker
import PryvApiSwiftKit
@testable import PryvApiSwiftKitExample

class ConnectionUITests: XCTestCase {
    private let keychain = KeychainSwift()
    private let utils = AppUtils()
    private let appId = "app-swift-example"
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
            app.alerts.textFields["usernameField"].tap()
            app.alerts.textFields["usernameField"].typeText("testuser")
            app.alerts.secureTextFields["passwordField"].tap()
            app.alerts.secureTextFields["passwordField"].typeText("testuser")
            app.alerts.buttons["OK"].tap()
        }
    }

    func testWelcomeView() {
        XCTAssert(app.staticTexts["welcomeLabel"].exists)
        
        // Note: cannot check the token as not always the same
        let endpoint = app.staticTexts["endpointLabel"].label
        XCTAssert(endpoint.contains("API endpoint: \nhttps://"))
        XCTAssert(endpoint.contains("testuser.pryv.me/"))
    }
    
    func testCreateAndEditEvent() {
        let streamId = "weight"
        let type = "mass/kg"
        let content = "90"
        
        // Create
        
        app.buttons["createEventsButton"].tap()
        app.buttons["addEventButton"].tap()
        
        XCTAssertTrue(app.alerts.element.staticTexts["Only stream ids [\"weight\"] will be sent to the server"].exists)
        XCTAssertFalse(app.alerts.buttons["OK"].isEnabled)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText(streamId)
        XCTAssertFalse(app.alerts.buttons["OK"].isEnabled)
        
        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText(type)
        XCTAssertFalse(app.alerts.buttons["OK"].isEnabled)
        
        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText(content)
        XCTAssertTrue(app.alerts.buttons["OK"].isEnabled)
        
        app.alerts.buttons["OK"].tap()
        let myTable = app.tables.matching(identifier: "newEventsTable")
        let cell = myTable.cells["newEvent0"]
        XCTAssertEqual(cell.staticTexts["newEventTitleLabel"].label, "Event 1: weight")
        
        // Edit
        
        cell.tap()
        
        XCTAssertEqual(app.textFields["streamIdField"].value as! String, streamId)
        XCTAssertEqual(app.textFields["typeField"].value as! String, type)
        XCTAssertEqual(app.textFields["contentField"].value as! String, content)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].doubleTap()
        app.textFields["streamIdField"].typeText(XCUIKeyboardKey.delete.rawValue)
        app.textFields["streamIdField"].typeText("height")
        
        app.alerts.buttons["OK"].tap()
        XCTAssertEqual(cell.staticTexts["newEventTitleLabel"].label, "Event 1: height")
        
    }
    
    func testCreateEventAndSubmit() {
        app.buttons["createEventsButton"].tap()
        app.buttons["addEventButton"].tap()

        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("90")

        app.alerts.buttons["OK"].tap()

        app.buttons["sendEventsButton"].tap()
        XCTAssert(app.staticTexts["welcomeLabel"].exists)
        
        app.buttons["getEventsButton"].tap()
        
        let myTable = app.tables.matching(identifier: "getEventsTable")
        let cell = myTable.cells["eventCell0"]
        XCTAssertEqual(cell.staticTexts["eventTitleLabel"].label, "weight")
        
        cell.tap()
        let event = app.alerts.element.staticTexts.element.label
        XCTAssert(event.contains("streamId:weight\n"))
        XCTAssert(event.contains("streamIds:(\n\"weight\"\n)\n"))
        XCTAssert(event.contains("type: mass/kg\n"))
        XCTAssert(event.contains("content: 90\n"))
    }
    
    func testCreateEventWithFile() {
        app.buttons["eventWithFileButton"].tap()
        XCTAssertTrue(app.alerts.element.staticTexts["Only stream ids [\"weight\"] will be sent to the server"].exists)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("80")

        app.alerts.buttons["OK"].tap()
        app.staticTexts["sample.pdf"].tap()
        
        let event = app.staticTexts["textLabel"].label
        
        XCTAssert(event.contains("streamId:weight\n"))
        XCTAssert(event.contains("streamIds:(\n\"weight\"\n)\n"))
        XCTAssert(event.contains("type: mass/kg\n"))
        XCTAssert(event.contains("content: 90\n"))
        XCTAssert(event.contains("attachments:(\n"))
        XCTAssert(event.contains("fileName:sample.pdf"))
        XCTAssert(event.contains("type: pdf"))
    }
}
