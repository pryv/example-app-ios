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

class ConnectionListUITests: XCTestCase {
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
            if app.buttons["ACCEPT"].exists {
                app.buttons["ACCEPT"].tap()
            }
            sleep(2)
        }
    }

    func testConnectionViewBasicUI() {
        XCTAssert(app.staticTexts["Pryv Lab - Testuser"].exists)
        XCTAssert(app.navigationBars["connectionNavBar"].exists)
        XCTAssert(app.navigationBars["connectionNavBar"].buttons["logoutButton"].isHittable)
        XCTAssert(app.navigationBars["connectionNavBar"].buttons["addEventButton"].isHittable)
        XCTAssert(app.tables["eventsTableView"].exists)
    }
    
    func testCreateSimpleEvent() {
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Simple event"].tap()
        sleep(1)

        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("90")

        app.alerts.buttons["OK"].tap()
        XCTAssert(app.staticTexts["Pryv Lab - Testuser"].exists)
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, "weight")
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, "mass/kg")
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, "90")
        XCTAssertFalse(cell.staticTexts["attachmentLabel"].exists)
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
    }
    
    func testCreateBadEvent() {
        let wrongField = "-----------"
        
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Simple event"].tap()
        sleep(1)

        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText(wrongField)

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText(wrongField)

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText(wrongField)

        app.alerts.buttons["OK"].tap()
        sleep(1)
        XCTAssert(app.alerts.element.staticTexts["The parameters' format is invalid."].exists)
        
        app.alerts.buttons["OK"].tap()
        XCTAssert(app.staticTexts["Pryv Lab - Testuser"].exists)
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        XCTAssertNotEqual(cell.staticTexts["streamIdLabel"].label, wrongField)
        XCTAssertNotEqual(cell.staticTexts["typeLabel"].label, wrongField)
        XCTAssertNotEqual(cell.staticTexts["contentLabel"].label, wrongField)
    }
    
    func testCreateEventWithFile() {
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Event with attachment"].tap()
        sleep(1)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("80")

        app.alerts.buttons["OK"].tap()
        sleep(1)
        app.otherElements["fileBrowserCreate"].staticTexts["sample.pdf"].tap()
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, "weight")
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, "mass/kg")
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, "80")
        XCTAssertEqual(cell.staticTexts["attachmentLabel"].label, "sample.pdf")
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
    }
    
    func testAddFileToEvent() {
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        let streamId = cell.staticTexts["streamIdLabel"].label
        let type = cell.staticTexts["typeLabel"].label
        let content = cell.staticTexts["contentLabel"].label
        
        cell.buttons["addAttachmentButton"].tap()
        sleep(1)
        app.otherElements["fileBrowserAdd"].staticTexts["sample.pdf"].tap()
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, streamId)
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, type)
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, content)
        XCTAssertEqual(cell.staticTexts["attachmentLabel"].label, "sample.pdf")
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
    }
}
