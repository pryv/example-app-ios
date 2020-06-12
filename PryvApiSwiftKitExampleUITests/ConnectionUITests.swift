//
//  ConnectionUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 11.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import SwiftKeychainWrapper
import Mocker

class ConnectionUITests: XCTestCase {
    private let appId = "app-swift-example-tests"
    private let endpoint = "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/"
    var app: XCUIApplication!

    override func setUp() {
        mockResponses()
        
        if !KeychainWrapper.standard.set(endpoint, forKey: appId) { print("the endpoint was not saved in the keychain") } // FIXME : mocking does not work so polling url not as expected
        
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
        XCTAssertFalse(!app.staticTexts["Save"].isEnabled)
        
        app.textFields["streamIdField"].typeText("weight")
        XCTAssertFalse(!app.staticTexts["Save"].isEnabled)
        
        app.textFields["typeField"].typeText("mass/kg")
        XCTAssertFalse(!app.staticTexts["Save"].isEnabled)
        
        app.textFields["contentField"].typeText("90")
        XCTAssertFalse(app.staticTexts["Save"].isEnabled)
        
        app.staticTexts["Save"].tap()
        let myTable = app.tables.matching(identifier: "newEventsTable")
        let cell = myTable.cells.element(matching: .cell, identifier: "newEvent0")
        XCTAssert(cell.staticTexts["Event 1"].exists)
    }
    
    func testCreateEventWithoutFile() {
        app.buttons["createEventsButton"].tap()
        app.buttons["addEventButton"].tap()
        
        app.textFields["streamIdField"].typeText("weight")
        app.textFields["typeField"].typeText("mass/kg")
        app.textFields["contentField"].typeText("90")
        app.staticTexts["Save"].tap()
        
        app.buttons["submitEventsButton"].tap()
        XCTAssert(app.staticTexts["welcomeLabel"].exists)
        
        app.buttons["getEventsButton"].tap()
        
        let myTable = app.tables.matching(identifier: "getEventsTable")
        let cell = myTable.cells.element(matching: .cell, identifier: "eventCell0")
        XCTAssert(cell.staticTexts["weight"].exists)
        
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
        let expectedText = (expectedResponse.compactMap({ (key, value) -> String in
            return "\(key):\(value)"
        }) as Array).joined(separator: "\n")
        
        XCTAssert(app.staticTexts[expectedText].exists)
    }
    
    func testCreateEventWithFile() {
        app.buttons["eventWithFileButton"].tap()
        
        app.textFields["streamIdField"].typeText("diary")
        app.textFields["typeField"].typeText("mass/kg")
        app.textFields["contentField"].typeText("80")
        app.staticTexts["Save"].tap()
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
                "content": 90,
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
        let expectedText = (expectedResponse.compactMap({ (key, value) -> String in
            return "\(key):\(value)"
        }) as Array).joined(separator: "\n")
        XCTAssertEqual(app.staticTexts["textLabel"].label, expectedText)
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
