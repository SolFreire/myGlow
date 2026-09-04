//
//  AppDelegate.swift
//  myGlow
//
//  Created by Soraia Freire Batista on 03/09/26.
//

import UIKit

final class AppDelegate : NSObject, UIApplicationDelegate {
    static var orientationlock: UIInterfaceOrientationMask = .all
    
    
   func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
       OrientationManager.shared.currentOrientationMask
   }
    
}
