//
//  LoginViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/11/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import SwiftyJSON
import SwiftLocation

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registeButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        emailField.attributedPlaceholder = NSAttributedString(string: "email@domain.com", attributes: [NSForegroundColorAttributeName : UIColor.white.withAlphaComponent(0.7)])
        passwordField.attributedPlaceholder = NSAttributedString(string: "******", attributes: [NSForegroundColorAttributeName : UIColor.white.withAlphaComponent(0.7)])
        loadLocation()
    }
    
    private func loadLocation() {
        Location.getLocation(accuracy: .city, frequency: .oneShot, success: { (_, location) in
            Location.getPlacemark(forLocation: location, success: { placemarks in
                if let place = placemarks.first {
                    guard let formatedAdrressArray:[String] = place.addressDictionary?["FormattedAddressLines"] as? [String] else { return }
                    let address = formatedAdrressArray.joined(separator: ", ")
                    print(address)
                    AppSession.shared.currentLocation = address
                }
            }) { error in
                print("Cannot retrive placemark due to an error \(error)")
            }
        }) { (request, last, error) in
            request.cancel() // stop continous location monitoring on error
            print("Location monitoring failed due to an error \(error)")
        }
    }

    @IBAction func registerDidTouch(_ sender: Any) {
    }
    
    @IBAction func loginFacebookDidTouch(_ sender: Any) {
    }

    @IBAction func forgotPasswordDidTouch(_ sender: Any) {
    
    }
    
    @IBAction func loginButtonDidTouch(_ sender: Any) {
        
        func onLogInSuccess() {
            //toAddInterests
            //toUserExplorer
            self.performSegue(withIdentifier: "toUserExplorer", sender: self)
        }
        
        showLoading()
        ApiHelper.signin(email:emailField.text ?? "", password:passwordField.text ?? "", onsuccess: { [weak self] (result) in
            self?.hideLoading()
            guard let json = result as? JSON else { return }
            
            AppSession.shared.userInfo = UserInfo(firstname: json["data"]["firstname"].string ?? "",
                                                  lastname: json["data"]["lastname"].string ?? "",
                                                  token: "",
                                                  memberId: json["data"]["member_id"].string ?? "",
                                                  email: json["data"]["email"].string ?? self?.emailField.text ?? "")
            
            if( AppSession.shared.userInfo?.memberId != nil && AppSession.shared.userInfo?.memberId != "") {
                onLogInSuccess()
            } else {
                let alert = UIAlertController(title: "Login fail", message: "User is invalid", preferredStyle: UIAlertControllerStyle.alert)
                let defaultAction = UIAlertAction(title: "Try again", style: .default, handler: nil)
                alert.addAction(defaultAction)
                self?.present(alert, animated: true, completion: nil)
            }
            
            }, onfailure: { errMsg in
                self.hideLoading()
        })
    }
}
