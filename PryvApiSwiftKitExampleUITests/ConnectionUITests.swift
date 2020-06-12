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
@testable import PryvApiSwiftKitExample

class ConnectionUITests: XCTestCase {
    private let keychain = KeychainSwift()
    private let utils = AppUtils()
    private let appId = "app-swift-example"//-tests" // FIXME: UITest should use another key to avoid interfering with the add, but if does not use the same key in keychain as the app => will not work-tests"
    private let endpoint = "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/"
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        
        if !keychain.set(endpoint, forKey: appId) { print("endpoint not set") } // FIXME: cannot set
        mockResponses()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testWelcomeView() {
        XCTAssert(app.staticTexts["welcomeLabel"].exists)

        let expectedApiEndpoint = "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/"
        XCTAssertEqual(app.staticTexts["endpointLabel"].label, expectedApiEndpoint)
    }
    
    func testCreateEventWithoutParams() {
        app.buttons["createEventsButton"].tap()
        app.buttons["addEventButton"].tap()
        
        XCTAssertTrue(app.alerts.element.staticTexts["Only stream ids [\"weight\"] will be sent to the server"].exists)
        XCTAssertFalse(app.alerts.buttons["Save"].isEnabled)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")
        XCTAssertFalse(app.alerts.buttons["Save"].isEnabled)
        
        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")
        XCTAssertFalse(app.alerts.buttons["Save"].isEnabled)
        
        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("90")
        XCTAssertTrue(app.alerts.buttons["Save"].isEnabled)
        
        app.alerts.buttons["Save"].tap()
        let myTable = app.tables.matching(identifier: "newEventsTable")
        let cell = myTable.cells["newEvent0"]
        XCTAssertEqual(cell.staticTexts["newEventTitleLabel"].label, "Event 1: weight")
    }
    
    func testCreateEventWithoutFile() {
        app.buttons["createEventsButton"].tap()
        app.buttons["addEventButton"].tap()

        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("90")

        app.alerts.buttons["Save"].tap()

        app.buttons["sendEventsButton"].tap()
        XCTAssert(app.staticTexts["welcomeLabel"].exists)
        
        app.buttons["getEventsButton"].tap()
        
        let myTable = app.tables.matching(identifier: "getEventsTable")
        let cell = myTable.cells["eventCell0"]
        XCTAssertEqual(cell.staticTexts["eventTitleLabel"].label, "weight")
        
        cell.tap()
        let expectedResponse = [
            "event": [
                "id": "eventId",
                "time": 1591274234.916,
                "streamIds": [
                  "weight"
                ],
                "streamId": "weight",
                "tags": [],
                "type": "mass/kg",
                "content": 90,
                "created": 1591274234.916,
                "createdBy": "ckb0rldr90001q6pv8zymgvpr",
                "modified": 1591274234.916,
                "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
            ]
        ]
        let expectedText = utils.eventToString(expectedResponse)
        
        let predicate = NSPredicate(format: "label LIKE %@", expectedText)
        let element = app.alerts.element.staticTexts.element(matching: predicate)
        XCTAssert(element.exists)
    }
    
    func testCreateEventWithFile() {
        app.buttons["eventWithFileButton"].tap()
        XCTAssertTrue(app.alerts.element.staticTexts["Only stream ids [weight] will be sent to the server"].exists)
        
        app.textFields["streamIdField"].tap()
        app.textFields["streamIdField"].typeText("weight")

        app.textFields["typeField"].tap()
        app.textFields["typeField"].typeText("mass/kg")

        app.textFields["contentField"].tap()
        app.textFields["contentField"].typeText("80")

        app.alerts.buttons["Save"].tap()
        app.staticTexts["sample.pdf"].tap()
        
        let expectedResponse = [
            "event": [
                "id": "eventId",
                "time": 1591274234.916,
                "streamIds": [
                  "weight"
                ],
                "streamId": "weight",
                "tags": [],
                "type": "mass/kg",
                "content": 80,
                "attachments": [
                  [
                    "id": "ckb97kwrp000radpv90rkvh76",
                    "fileName": "sample.pdf",
                    "type": "pdf",
                    "size": 1111,
                    "readToken": "ckb97kwrp000sadpv485eu3eg-e21g0DgCivlKKvmysxVKtGq3vhM"
                  ]
                ],
                "created": 1591274234.916,
                "createdBy": "ckb0rldr90001q6pv8zymgvpr",
                "modified": 1591274234.916,
                "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
            ]
        ]
        let expectedText = utils.eventToString(expectedResponse)
        
        XCTAssertEqual(app.staticTexts["textLabel"].label, expectedText) // FIXME: order in json file 
    }
    
    private func mockResponses() {
        let mockCallBatch = Mock(url: URL(string: "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.callBatchResponse
        ])
        let mockCreation = Mock(url: URL(string: "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/events")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.callBatchResponse
        ])
        let mockAttachment = Mock(url: URL(string: "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/events/eventId")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.addAttachmentResponse
        ])
        
        mockCallBatch.register()
        mockCreation.register()
        mockAttachment.register()
    }
}
