//
//  UIViewController + extension.swift
//  Pizza_Ordering_Web_App
//
//  Created by Mattias Tilert Thunqvist on 2019-02-12.
//  Copyright © 2019 Mattias Tilert Thunqvist. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        guard parent != nil else { return }
        
        DispatchQueue.main.async {
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}