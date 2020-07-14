//
//  SceneDelegate.swift
//  PryvApiSwiftKitExample
//
//  Created by Sara Alemanno on 05.06.20.
//  Copyright © 2020 Pryv. All rights reserved.
//

import UIKit
import TAK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
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
        let initialViewController = UINavigationController(rootViewController: mainVC)
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
        
//        TODO: uncomment when using on real device ≠ simulator
//        if tak!.isJailbroken() {
//            let alert = UIAlertController(title: "Your device seems jailbroken", message: "For security reasons, you cannot use this application as your device seems to be jailbroken.", preferredStyle: .alert)
//            let activeVC = initialViewController.visibleViewController
//            activeVC?.present(alert, animated: true, completion: nil)
//        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

