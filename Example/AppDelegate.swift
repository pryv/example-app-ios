//
//  AppDelegate.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import TAK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let tak = try? TAK(licenseFileName: "license")
        
        if let isRegistered = try? tak?.isRegistered(), !isRegistered {
            do {
                let registrationResponse = try tak!.register(userHash: nil)
                if (registrationResponse.isLicenseAboutToExpire) {
                    print("Warning: TAK license is about to expire.")
                } else {
                    // TODO
                    // It is recommended (but not required) to send the T.A.K ID to your server's backend and bind it to the
                    // current user. It will allow you to use the verification interface of the T.A.K cloud.
                    let takIdentifier = registrationResponse.takIdentifier
                    print("Success: T.A.K register was successful")
                }
            } catch {
                print("Error: T.A.K register failed: \(error.localizedDescription)")
            }
        } else {
            do {
                let checkIntegrityResponse = try tak!.checkIntegrity()
                if (checkIntegrityResponse.isLicenseAboutToExpire) {
                    print("Warning: T.A.K checkIntegrity was successful: TAK license is about to expire.")
                } else if (checkIntegrityResponse.didReregister) {
                    // TODO
                    // When re-registration happens, instance certificates and cryptographic keys are renewed.
                    // This also implies that the T.A.K ID has been updated, so it is recommended to send it to your
                    // backend (same as after the registration operation).
                    let takIdentifier = checkIntegrityResponse.takIdentifier
                    print("Success: T.A.K check integrity was successful: Re-registration happened")
                } else {
                    print("Success: T.A.K check integrity was successful")
                }
            } catch {
                print("Error: Problem occurred when checking integrity of T.A.K: \(error.localizedDescription)")
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
        mainVC.passData(tak: tak)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

