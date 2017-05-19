//
//  UIViewController+Ext.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/19/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import IJProgressView

extension UIViewController {
    internal func showLoading() {
        IJProgressView.shared.showProgressView(view)
    }
    
    internal func hideLoading() {
        IJProgressView.shared.hideProgressView()
    }
    
    internal func alert(_ message:String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }
}
