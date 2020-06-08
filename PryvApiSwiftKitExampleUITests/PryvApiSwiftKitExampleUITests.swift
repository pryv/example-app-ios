//
//  PryvApiSwiftKitExampleUITests.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import XCTest
import Mocker
@testable import PryvApiSwiftKitExample

class PryvApiSwiftKitExampleUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        mockResponses()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testAuthAndBackButton() {
        app.buttons["authButton"].tap()
        XCTAssert(app.webViews["webView"].exists)
        
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssert(app.staticTexts["welcomeLabel"].exists)
    }
    
    func testBadServiceInfoUrl() {
        app.textFields["serviceInfoUrlField"].tap()
        app.textFields["serviceInfoUrlField"].typeText("hello")
        app.buttons["authButton"].tap()
        
        XCTAssertFalse(app.webViews["webView"].exists)
        
        XCTAssertEqual(app.alerts.element.label, "Invalid URL")
    }
    
    private func mockResponses() {
        let mockAccessEndpoint = Mock(url: URL(string: "https://reg.pryv.me/access")!, contentType: .json, statusCode: 200, data: [
            .post: MockedData.authResponse
        ])
        Mocker.register(mockAccessEndpoint)
    }
}
