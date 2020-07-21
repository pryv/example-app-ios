//
//  UIAlertController+newEventAlert.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 11.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvSwiftKit
import TAK

extension UIAlertController {
    
    /// Create a `UIAlertController` that allows the user to create an event from a streamId, type and content
    /// - Parameters:
    ///   - editing: whether the user is editing ≠ creating an object
    ///   - title: title of the `UIAlertController`
    ///   - message: message of the `UIAlertController`
    ///   - name: name of the event (only if editing)
    ///   - callback: function to execute when the button `Save` is hit
    ///   - tak: the TAK object relative to the application and device
    /// - Returns: the `UIAlertController` with a title and a message and four text fields: name, streamId, type and content and a `Save` and `Cancel` button
    func newEventAlert(editing: Bool = false, title: String, message: String?, name: String? = nil, tak: TAK? = nil, callback: @escaping (Json) -> ()) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let submit = UIAlertAction(title: "OK", style: .default, handler: { _ in
            var params: Json = [
                "streamIds": [alert.textFields![0].text ?? ""],
                "type": alert.textFields![1].text ?? "", // Note the new events content can only contain simple types (Int, String, Double, ...)
                "content": alert.textFields![2].text ?? ""
            ]
            
            if let _ = tak {
                let dataToBeSigned = String(describing: params).data(using: String.Encoding.utf8)!
                let signature = try? tak!.generateSignature(input: dataToBeSigned, signatureAlgorithm: .rsa2048)
                params["clientData"] = ["tak-signature": String(describing: signature)]
            }
            
            callback(params)
        })
        
        submit.isEnabled = editing
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in })
        
        alert.addAction(cancel)
        alert.addAction(submit)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Stream id"
            textField.text = "diary"
            textField.addTarget(alert, action: #selector(alert.textDidChangeInEventEditor), for: .editingChanged)
            textField.clearButtonMode = .whileEditing
            textField.accessibilityIdentifier = "streamIdField"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Type"
            textField.text = "note/txt"
            textField.addTarget(alert, action: #selector(alert.textDidChangeInEventEditor), for: .editingChanged)
            textField.clearButtonMode = .whileEditing
            textField.accessibilityIdentifier = "typeField"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Content"
            textField.addTarget(alert, action: #selector(alert.textDidChangeInEventEditor), for: .editingChanged)
            textField.clearButtonMode = .whileEditing
            textField.accessibilityIdentifier = "contentField"
        }
        
        alert.textFields?.forEach {
            $0.superview?.backgroundColor = .clear
            $0.superview?.superview?.subviews[0].removeFromSuperview()
        }
        
        return alert
    }
    
    /// Assert the three fields corresponding to streamId, type and content are not empty to enable the `Save` button
    @objc func textDidChangeInEventEditor() {
        if let streamId = textFields?[0].text, let type = textFields?[1].text, let content = textFields?[2].text, let action = actions.last {
            action.isEnabled = streamId.count > 0 && type.count > 0 && content.count > 0
        }
    }
}
