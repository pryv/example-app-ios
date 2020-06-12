//
//  MockedData.swift
//  PryvApiSwiftKitExampleUITests
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import Foundation

public final class MockedData {
    public static let serviceInfoResponse: Data = """
        {
          "register": "https://reg.pryv.me/",
          "access": "https://access.pryv.me/access",
          "api": "https://{username}.pryv.me/",
          "name": "Pryv Lab",
          "home": "https://www.pryv.com",
          "support": "https://pryv.com/helpdesk",
          "terms": "https://pryv.com/pryv-lab-terms-of-use/",
          "eventTypes": "https://api.pryv.com/event-types/flat.json"
        }
    """.data(using: .utf8)!
    
    public static let needSigninResponse: Data = """
        {
          "status": "NEED_SIGNIN",
          "url": "https://sw.pryv.me/access/access.html?lang=fr&key=6CInm4R2TLaoqtl4&requestingAppId=test-app-id&domain=pryv.me®isterURL=https%3A%2F%2Freg.pryv.me&poll=https%3A%2F%2Freg.pryv.me%2Faccess%2F6CInm4R2TLaoqtl4",
          "authUrl": "https://sw.pryv.me/access/access.html?poll=https://access.pryv.me/access/6CInm4R2TLaoqtl4",
          "key": "6CInm4R2TLaoqtl4",
          "poll": "https://access.pryv.me/access/6CInm4R2TLaoqtl4",
          "poll_rate_ms": 1000,
          "requestingAppId": "test-app-id",
          "requestedPermissions": [
            {
              "streamId": "diary",
              "level": "contribute",
              "defaultName": "Journal"
            },
            {
              "streamId": "weight",
              "level": "read",
              "defaultName": "Weight"
            },
            {
              "streamId": "weight",
              "level": "contribute",
              "defaultName": "Weight"
            }
          ],
          "lang": "fr",
          "serviceInfo": {}
        }
    """.data(using: .utf8)!
    
    public static let acceptedResponse: Data = """
        {
            "status": "ACCEPTED",
            "pryvAPIEndpoint": "https://ckb97kwpg0003adpv4cee5rw5@chuangzi.pryv.me/",
            "serviceInfo": {
                "register": "https://reg.pryv.me",
                "access": "https://access.pryv2.me/access",
                "api": "https://{username}.pryv.me/",
                "name": "Pryv Lab",
                "home": "https://www.pryv.com",
                "support": "https://pryv.com/helpdesk",
                "terms": "https://pryv.com/pryv-lab-terms-of-use/",
                "eventTypes": "https://api.pryv.com/event-types/flat.json"
            }
        }
    """.data(using: .utf8)!
    
    public static let callBatchResponse = """
        {
          "event": {
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
          }
        }
    """.data(using: .utf8)!
    
    public static let addAttachmentResponse = """
        {
          "event": {
          "id": "eventId",
            "time": 1591274234.916,
            "streamIds": [
              "weight"
            ],
            "streamId": "weight",
            "tags": [],
            "type": "mass/kg",
            "content": 80,
            "attachments": "attachments": [
              {
                "id": "ckb97kwrp000radpv90rkvh76",
                "fileName": "sample.pdf",
                "type": "pdf",
                "size": 1111,
                "readToken": "ckb97kwrp000sadpv485eu3eg-e21g0DgCivlKKvmysxVKtGq3vhM"
              }
            ],
            "created": 1591274234.916,
            "createdBy": "ckb0rldr90001q6pv8zymgvpr",
            "modified": 1591274234.916,
            "modifiedBy": "ckb0rldr90001q6pv8zymgvpr"
          }
        }
    """.data(using: .utf8)!
    
}
