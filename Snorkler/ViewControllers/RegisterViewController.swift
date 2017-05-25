//
//  RegisterViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/12/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import SwiftyJSON
import UDatePicker
import SwiftDate

class RegisterViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var cpasswordField: UITextField!
    @IBOutlet weak var firstnameField: UITextField!
    @IBOutlet weak var lastnameField: UITextField!
    @IBOutlet weak var birthdateField: UITextField!
    @IBOutlet weak var genderSegment: UISegmentedControl!
    @IBOutlet weak var finishButton: UIButton!
    
    internal var datePicker:UDatePicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        [emailField, passwordField, cpasswordField, firstnameField, lastnameField, birthdateField].forEach {
            $0?.layer.borderColor = UIColor.white.cgColor
            $0?.layer.cornerRadius = 3.0
            $0?.layer.backgroundColor = UIColor.white.cgColor
            $0?.layer.borderWidth = 1.5
            let leftView = UIView()
            leftView.frame = CGRect(x: 0, y: 0, width: 20, height: 30)
            leftView.backgroundColor = .clear
            $0?.leftView = leftView;
            $0?.leftViewMode = .always
            $0?.delegate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func finishButtonDidTouch(_ sender: Any) {
        let params = ["email":emailField.text ?? "",
                      "password":passwordField.text ?? "",
                      "cpassword":cpasswordField.text ?? "",
                      "firstname":firstnameField.text ?? "",
                      "lastname":lastnameField.text ?? ""]
        showLoading()
        ApiHelper.signup(params:params, onsuccess: { [weak self] (result) in
            self?.hideLoading()
            defer {
                
            }
            guard let json = result as? JSON else { return }
            
            AppSession.shared.userInfo = UserInfo(firstname: json["data"]["firstname"].string ?? "",
                                                  lastname: json["data"]["lastname"].string ?? "",
                                                  token: "",
                                                  memberId: json["data"]["member_id"].string ?? "",
                                                  email: json["data"]["email"].string ?? self?.emailField.text ?? "")
            
            if( AppSession.shared.userInfo?.memberId != nil && AppSession.shared.userInfo?.memberId != "") {
                self?.performSegue(withIdentifier: "toAddInterest", sender: self)
            } else {
                self?.alert(json["message"].stringValue)
            }
            
        }, onfailure: { errMsg in
            self.hideLoading()
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func showDatePicker() {
        if datePicker == nil {
            datePicker = UDatePicker(frame: view.frame, willDisappear: { date in
                guard let birthDate = date else { return }
                print(birthDate.string(custom: "MM/dd/YYYY"))
                self.birthdateField.text = birthDate.string(custom: "MM/dd/YYYY")
            })
        }
        
        datePicker?.picker.date = Date()
        datePicker?.present(self)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == birthdateField {
            showDatePicker()
            return false
        } else {
            return true
        }
    }
}
