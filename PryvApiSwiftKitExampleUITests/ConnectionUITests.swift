//
//  ConnectionUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 11.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import SwiftKeychainWrapper

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
        
        // TODO: click on plus button
        // TODO: assert OK not clickable
        // TODO: fill streamId
        // TODO: assert OK not clickable
        // TODO: fill type
        // TODO: assert OK not clickable
        // TODO: fill content
        // TODO: assert OK clickable
        // TODO: assert name of cell0 = "Event 1"
    }
    
    func testCreateEventWithoutFile() {
        app.buttons["createEventsButton"].tap()
        
        // TODO: click on plus button
        // TODO: fill the form for a streamId in the mockedData
        // TODO: click on OK
        // TODO: click on submit
        // TODO: assert on welcome view
        // TODO: click on the see events buttons
        // TODO: check that exactly one button in list
        // TODO: clic on the event
        // TODO: check that the text in the alert = the text in the mocked data
    }
    
    func testCreateEventWithFile() {
        // TODO: click on the create event with file button
        // TODO: fill the form for a streamId in the mockedData
        // TODO: clic on OK
        // TODO: select a file from the app
        // TODO: assert on text view
        // TODO: check that the text in the alert = the text in the mocked data with attachment
    }
    
    private func mockResponses() {
        // TODO
    }
}
