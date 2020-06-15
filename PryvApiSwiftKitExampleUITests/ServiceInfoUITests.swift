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
        super.setUp()
        
        mockResponses()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        if (app.buttons["logoutButton"].exists) {
            app.buttons["logoutButton"].tap()
        }
    }
    
    func testAuthAndBackButton() {
        app.buttons["authButton"].tap()
        XCTAssert(app.webViews["webView"].exists)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssert(app.staticTexts["appName"].exists)
    }
    
    // FIXME : mocking does not work so polling url not as expected
    func testAuthToConnection() {
        app.buttons["authButton"].tap()
        sleep(2)
        XCTAssert(app.staticTexts["welcomeLabel"].exists)

        let expectedApiEndpoint = "https://ckbc28vpd00kz1vd3s7vgiszs@Testuser.pryv.me/"
        XCTAssertEqual(app.staticTexts["endpointLabel"].label, expectedApiEndpoint)
    }
    
    func testBadServiceInfoUrl() {
        app.textFields["serviceInfoUrlField"].tap()
        app.textFields["serviceInfoUrlField"].typeText("hello")
        app.buttons["authButton"].tap()
        
        XCTAssertFalse(app.webViews["webView"].exists)
        
        XCTAssertEqual(app.alerts.element.label, "Invalid URL")
    }
    
    private func mockResponses() {
        let mockServiceInfo = Mock(url: URL(string: "https://reg.pryv.me/service/info")!, dataType: .json, statusCode: 200, data: [
            .get: MockedData.serviceInfoResponse
        ])
        let mockAuthRequest = Mock(url: URL(string: "https://reg.pryv.me/access")!, dataType: .json, statusCode: 200, data: [
            .post: MockedData.needSigninResponse
        ])
        let mockPollRequest = Mock(url: URL(string: "https://access.pryv.me/access/6CInm4R2TLaoqtl4")!, dataType: .json, statusCode: 200, data: [
            .get: MockedData.acceptedResponse
        ])
        
        let mocks = [mockServiceInfo, mockAuthRequest, mockPollRequest]
        mocks.forEach { mock in Mocker.register(mock) }
    }
}
