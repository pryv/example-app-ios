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
import PryvSwiftKit

class ConnectionListUITests: XCTestCase {
    private let defaultServiceInfoUrl = "https://reg.pryv.me/service/info"
    private let endpoint = "https://ckbc28vpd00kz1vd3s7vgiszs@Testuser.pryv.me/"
    private let existsPredicate = NSPredicate(format: "exists == TRUE")
    private let doesNotExistPredicate = NSPredicate(format: "exists == FALSE")
    
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
               
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        if (app.alerts.element.exists) {
            app.alerts.element.buttons["Don’t Allow"].tap()
        }
        
        if (app.buttons["Don’t Allow"].exists) {
            app.buttons["Don’t Allow"].tap()
            app.alerts.element.buttons["OK"].tap()
        }
        
        if (app.buttons["loginButton"].exists) {
            app.buttons["loginButton"].tap()
            
            let usernameTextfield = app.staticTexts["Username or email"]
            self.expectation(for: existsPredicate, evaluatedWith: usernameTextfield, handler: nil)
            self.waitForExpectations(timeout: 10.0, handler: nil)
            
            usernameTextfield.tap()
            app.typeText("Testuser")
            app.staticTexts["Password"].tap()
            app.typeText("testuser")
            app.buttons["SIGN IN"].tap()
            if app.buttons["ACCEPT"].exists {
                app.buttons["ACCEPT"].tap()
            }
            
            self.expectation(for: existsPredicate, evaluatedWith: app.tabBars["connectionTabBar"], handler: nil)
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
        
    }

    func testConnectionViewBasicUI() {
        XCTAssert(app.staticTexts["Pryv Lab"].exists)
        XCTAssert(app.navigationBars["connectionNavBar"].exists)
        XCTAssert(app.navigationBars["connectionNavBar"].buttons["userButton"].isHittable)
        XCTAssert(app.navigationBars["connectionNavBar"].buttons["addEventButton"].isHittable)
        XCTAssert(app.tables["eventsTableView"].exists)
    }
    
    func testCreateAndDeleteSimpleEvent() {
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Simple event"].tap()

        let streamIdTextfield = app.textFields["streamIdField"]
        self.expectation(for: existsPredicate, evaluatedWith: streamIdTextfield, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)

        streamIdTextfield.tap()
        app.textFields["streamIdField"].buttons["Clear text"].tap()
        app.textFields["streamIdField"].typeText("measurements")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].buttons["Clear text"].tap()
        app.textFields["typeField"].typeText("length/cm")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("180")

        app.alerts.buttons["OK"].tap()
        XCTAssert(app.staticTexts["Pryv Lab"].exists)
        
        let addButton = app.navigationBars["connectionNavBar"].buttons["addEventButton"]
        self.expectation(for: existsPredicate, evaluatedWith: addButton, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        addButton.tap()
        app.sheets.element.buttons["Simple event"].tap()
        
        self.expectation(for: existsPredicate, evaluatedWith: streamIdTextfield, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)

        streamIdTextfield.tap()
        app.textFields["streamIdField"].buttons["Clear text"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].buttons["Clear text"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("90")

        app.alerts.buttons["OK"].tap()
        XCTAssert(app.staticTexts["Pryv Lab"].exists)
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        var streamIdLabel = cell.staticTexts["streamIdLabel"]
        let weightPredicate = NSPredicate(format: "label == %@", "weight")
        self.expectation(for: weightPredicate, evaluatedWith: streamIdLabel, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertEqual(streamIdLabel.label, "weight")
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, "mass/kg")
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, "90")
        XCTAssertFalse(cell.staticTexts["attachmentLabel"].exists)
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
        
        cell.swipeLeft()
        cell.buttons["Delete"].tap()
        
        streamIdLabel = cell.staticTexts["streamIdLabel"]
        let measurementsPredicate = NSPredicate(format: "label == %@", "measurements")
        self.expectation(for: measurementsPredicate, evaluatedWith: streamIdLabel, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertNotEqual(cell.staticTexts["streamIdLabel"].label, "weight")
        XCTAssertNotEqual(cell.staticTexts["typeLabel"].label, "mass/kg")
        XCTAssertNotEqual(cell.staticTexts["contentLabel"].label, "90")
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, "measurements")
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, "length/cm")
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, "180")
    }
    
    func testCreateBadEvent() {
        let wrongField = "-----------"
        
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Simple event"].tap()

        let streamIdTextfield = app.textFields["streamIdField"]
        self.expectation(for: existsPredicate, evaluatedWith: streamIdTextfield, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)

        streamIdTextfield.tap()
        app.textFields["streamIdField"].buttons["Clear text"].tap()
        app.textFields["streamIdField"].typeText(wrongField)

        app.textFields["typeField"].tap()
        app.textFields["typeField"].buttons["Clear text"].tap()
        app.textFields["typeField"].typeText(wrongField)

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText(wrongField)

        app.alerts.buttons["OK"].tap()
        
        let errorAlert = app.alerts.element.staticTexts["The parameters' format is invalid."]
        self.expectation(for: existsPredicate, evaluatedWith: errorAlert, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssert(errorAlert.exists)
        
        app.alerts.buttons["OK"].tap()
        self.expectation(for: existsPredicate, evaluatedWith: app.staticTexts["Pryv Lab"], handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        let streamIdLabel = cell.staticTexts["streamIdLabel"]
        let notWrongPredicate = NSPredicate(format: "label != %@", wrongField)
        self.expectation(for: notWrongPredicate, evaluatedWith: streamIdLabel, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertNotEqual(streamIdLabel.label, wrongField)
        XCTAssertNotEqual(cell.staticTexts["typeLabel"].label, wrongField)
        XCTAssertNotEqual(cell.staticTexts["contentLabel"].label, wrongField)
    }
    
    func testCreateEventWithFile() {
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Event with attachment"].tap()

        let momentsElement = app.otherElements.tables.cells["Moments"]
        self.expectation(for: existsPredicate, evaluatedWith: momentsElement, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        momentsElement.tap()
        
        let collectionView = app.otherElements.collectionViews.element.cells.element(boundBy: 1)
        self.expectation(for: existsPredicate, evaluatedWith: collectionView, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        collectionView.tap()
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        let typeLabel = cell.staticTexts["typeLabel"]
        self.expectation(for: doesNotExistPredicate, evaluatedWith: typeLabel, handler: nil)
        self.waitForExpectations(timeout: 10.0, handler: nil)
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, "diary")
        XCTAssertFalse(typeLabel.exists)
        XCTAssertFalse(cell.staticTexts["contentLabel"].exists)
        XCTAssertFalse(cell.staticTexts["attachmentLabel"].exists)
    }
    
    func testAddFileToEvent() {
        app.navigationBars["connectionNavBar"].buttons["addEventButton"].tap()
        app.sheets.element.buttons["Simple event"].tap()

        let streamIdTextfield = app.textFields["streamIdField"]
        self.expectation(for: existsPredicate, evaluatedWith: streamIdTextfield, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)

        streamIdTextfield.tap()
        app.textFields["streamIdField"].buttons["Clear text"].tap()
        app.textFields["streamIdField"].typeText("measurements")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].buttons["Clear text"].tap()
        app.textFields["typeField"].typeText("length/cm")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("180")

        app.alerts.buttons["OK"].tap()
        self.expectation(for: existsPredicate, evaluatedWith: app.staticTexts["Pryv Lab"], handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        let myTable = app.tables.matching(identifier: "eventsTableView")
        let cell = myTable.cells["eventCell0"]
        
        let streamId = cell.staticTexts["streamIdLabel"].label
        let type = cell.staticTexts["typeLabel"].label
        let content = cell.staticTexts["contentLabel"].label
        
        cell.buttons["addAttachmentButton"].tap()
        
        let momentsElement = app.otherElements.tables.cells["Moments"]
        self.expectation(for: existsPredicate, evaluatedWith: momentsElement, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        momentsElement.tap()
        
        let collectionView = app.otherElements.collectionViews.element.cells.element(boundBy: 1)
        self.expectation(for: existsPredicate, evaluatedWith: collectionView, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        collectionView.tap()
        sleep(8)
        
        let attachmentLabel = cell.staticTexts["attachmentLabel"]
        self.expectation(for: existsPredicate, evaluatedWith: attachmentLabel, handler: nil)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertEqual(cell.staticTexts["streamIdLabel"].label, streamId)
        XCTAssertEqual(cell.staticTexts["typeLabel"].label, type)
        XCTAssertEqual(cell.staticTexts["contentLabel"].label, content)
        XCTAssertEqual(attachmentLabel.label, "image.png")
        XCTAssertFalse(cell.images["attachmentImageView"].exists)
    }
}
