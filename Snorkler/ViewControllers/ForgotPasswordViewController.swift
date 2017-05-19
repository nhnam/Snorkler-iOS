//
//  ForgotPasswordViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/19/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        [emailField].forEach {
            $0?.layer.borderColor = UIColor.white.cgColor
            $0?.layer.cornerRadius = 3.0
            $0?.layer.backgroundColor = UIColor.white.cgColor
            $0?.layer.borderWidth = 1.5
            let leftView = UIView()
            leftView.frame = CGRect(x: 0, y: 0, width: 20, height: 30)
            leftView.backgroundColor = .clear
            $0?.leftView = leftView;
            $0?.leftViewMode = .always
        }
    }

    @IBAction func didTouchConfirm(_ sender: Any) {
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
