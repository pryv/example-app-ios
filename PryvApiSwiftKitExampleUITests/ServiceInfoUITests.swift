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
    private let appId = "app-swift-example"//-tests" // FIXME: UITest should use another key to avoid interfering with the add, but if does not use the same key in keychain as the app => will not work
    private let keychain = KeychainSwift()
    private var values = [String]()
    
    override func setUp() {
        super.setUp()
        
        if !keychain.delete(appId) { print("endpoint not deleted") }
        mockResponses()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
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

        let expectedApiEndpoint = "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/"
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
        
        mockServiceInfo.register()
        mockAuthRequest.register()
        mockPollRequest.register()
    }
}
