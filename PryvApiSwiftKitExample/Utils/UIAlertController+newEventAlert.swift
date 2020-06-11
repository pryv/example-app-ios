//
//  UIAlertController+newEventAlert.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 11.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import PryvApiSwiftKit

extension UIAlertController {
    
    func newEventAlert(editing: Bool = false, title: String, message: String?, name: String? = nil, params: Json? = nil, callback: @escaping (String, Json) -> ()) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let submit = UIAlertAction(title: "Save", style: .default, handler: { _ in
            let params: Json = [
                "streamId": alert.textFields![1].text ?? "",
                "type": alert.textFields![2].text ?? "", // Note the new events content can only contain simple types (Int, String, Double, ...)
                "content": alert.textFields![3].text ?? ""
            ]
            callback(alert.textFields![0].text ?? "", params)
        })
        
        submit.isEnabled = editing
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in })
        
        alert.addAction(cancel)
        alert.addAction(submit)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name of your new event"
            textField.text = name
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter stream id"
            textField.text = params?["streamId"] as? String ?? ""
            textField.addTarget(alert, action: #selector(alert.textDidChangeInLoginAlert), for: .editingChanged)
            textField.accessibilityIdentifier = "streamIdField"
        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter type"
            textField.text = params?["type"] as? String ?? ""
            textField.addTarget(alert, action: #selector(alert.textDidChangeInLoginAlert), for: .editingChanged)
            textField.accessibilityIdentifier = "typeField"

        }
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter content"
            textField.text = String(describing: params?["content"] ?? "")
            textField.addTarget(alert, action: #selector(alert.textDidChangeInLoginAlert), for: .editingChanged)
            textField.accessibilityIdentifier = "contentField"
        }
        
        return alert
    }
    
    @objc func textDidChangeInLoginAlert() {
        if let streamId = textFields?[1].text, let type = textFields?[2].text, let content = textFields?[3].text, let action = actions.last {
            action.isEnabled = streamId.count > 0 && type.count > 0 && content.count > 0
        }
    }
}
