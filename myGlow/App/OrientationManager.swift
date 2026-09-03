//
//  OrientationManager.swift
//  myGlow
//
//  Created by Soraia Freire Batista on 03/09/26.
//

import UIKit

final class OrientationManager {
    static let shared = OrientationManager()
    var currentOrientationMask: UIInterfaceOrientationMask = .landscape
    
    func updateOrientation(to mask: UIInterfaceOrientationMask, forceRotateTo orientation:
        UIInterfaceOrientationMask? = nil) {
        currentOrientationMask = mask
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController
        else { return }
        
        rootViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        
        if let orientation {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                print(error.localizedDescription)
            }
        }
    }
}
