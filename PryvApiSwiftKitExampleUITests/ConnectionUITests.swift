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
    private let defaultServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let endpoint = "https://ckbc28vpd00kz1vd3s7vgiszs@Testuser.pryv.me/"
    
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
               
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
//        TODO ??
//        if (!app.buttons["logoutButton"].exists) {
//            app.buttons["loginButton"].tap()
//            app.alerts.textFields["usernameField"].tap()
//            app.alerts.textFields["usernameField"].typeText("testuser")
//            app.alerts.secureTextFields["passwordField"].tap()
//            app.alerts.secureTextFields["passwordField"].typeText("testuser")
//            app.alerts.buttons["OK"].tap()
//        }
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
        app.alerts.element.buttons["Simple event"].tap() //FIXME
        
        XCTAssert(app.alerts.element.staticTexts["Note: only stream ids in [\"weight\"]) will be accepted."].exists)

        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("90")

        app.alerts.buttons["OK"].tap()
        XCTAssert(app.staticTexts["Pryv Lab - Testuser"].exists)
        
        app.swipeDown()
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, "weight")
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, "mass/kg")
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, "90")
        XCTAssertFalse(cell.staticTexts["attachmentLabel"].exists)
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
    }
    
    func testCreateEventWithFile() {
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.alerts.element.buttons["Event with attachment"].tap() //FIXME
        
        XCTAssert(app.alerts.element.staticTexts["Note: only stream ids in [\"weight\"]) will be accepted."].exists)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("80")

        app.alerts.buttons["OK"].tap()
        app.staticTexts["sample.pdf"].tap() //FIXME
               
        app.swipeDown()
        
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
        app.otherElements["fileBrowser"].staticTexts["sample.pdf"].tap()
        
        cell.pullToRefresh()
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, streamId)
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, type)
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, content)
        XCTAssertEqual(cell.staticTexts["attachmentLabel"].label, "sample.pdf")
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
    }
}

extension XCUIElement {
    func pullToRefresh() {
        let start = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 6))
        start.press(forDuration: 0, thenDragTo: finish)
    }
}
