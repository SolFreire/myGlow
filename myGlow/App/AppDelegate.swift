//
//  AppDelegate.swift
//  myGlow
//
//  Created by Soraia Freire Batista on 03/09/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationlock: UIInterfaceOrientationMask = .landscape
    
    func application(_ application: UIApplication, supportedInterfaceOrientationFor window: UIWindow?)
        -> UIInterfaceOrientationMask{
        OrientationManager.shared.currentOrientationMask
    }
}
