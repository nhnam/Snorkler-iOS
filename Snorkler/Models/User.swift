//
//  User.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/25/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import Foundation
import SwiftyJSON
import Firebase

class User: NSObject {
    
    //MARK: Properties
    let name: String
    let email: String
    let id: String
    var profilePic: UIImage?
    var avatarUrl:String?
    var address: String?
    //MARK: Methods
    class func registerUser(withName: String, email: String, password: String, profilePic: UIImage, completion: @escaping (Bool) -> ()) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
                user?.sendEmailVerification(completion: nil)
                let storageRef = Storage.storage().reference().child("usersProfilePics").child(user!.uid)
                let imageData = UIImageJPEGRepresentation(profilePic, 0.1)
                storageRef.putData(imageData!, metadata: nil, completion: { (metadata, err) in
                    if err == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        let values = ["name": withName, "email": email, "profilePicLink": path!]
                        Database.database().reference().child("users").child((user?.uid)!).child("credentials").updateChildValues(values, withCompletionBlock: { (errr, _) in
                            if errr == nil {
                                let userInfo = ["email" : email, "password" : password]
                                UserDefaults.standard.set(userInfo, forKey: "userInformation")
                                completion(true)
                            }
                        })
                    }
                })
            }
            else {
                completion(false)
            }
        })
    }
    
    class func loginUser(withEmail: String, password: String, completion: @escaping (Bool) -> ()) {
        Auth.auth().signIn(withEmail: withEmail, password: password, completion: { (user, error) in
            if let u = user {
                if(u.isEmailVerified) {
                    u.sendEmailVerification(completion: { (error:Error?) in
                        print("Email Verification sent !")
                    })
                }
            }
            if error == nil {
                let userInfo = ["email": withEmail, "password": password]
                UserDefaults.standard.set(userInfo, forKey: "userInformation")
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    class func logOutUser(completion: @escaping (Bool) -> ()) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "userInformation")
            completion(true)
        } catch _ {
            completion(false)
        }
    }
    
    class func info(forUserID: String, completion: @escaping (User) -> ()) {
        Database.database().reference()
            .child("users")
            .child(forUserID)
            .child("credentials")
            .observeSingleEvent(of: .value, with: { snapshot in
            if let data = snapshot.value as? [String: String] {
                let name = data["name"]!
                let email = data["email"]!
                let link = URL.init(string: data["profilePicLink"]!)
                URLSession.shared.dataTask(with: link!, completionHandler: { (data, response, error) in
                    if error == nil {
                        let profilePic = UIImage.init(data: data!)
                        let user = User.init(name: name, email: email, id: forUserID, profilePic: profilePic!)
                        completion(user)
                    }
                }).resume()
            }
        })
    }
    
    class func downloadAllUsers(exceptID: String, completion: @escaping (User) -> ()) {
        Database.database().reference()
            .child("users")
            .observe(.value, with: { snapshot in
            if snapshot.exists() {
                let id = snapshot.key
                guard let data = snapshot.value as? [String: Any] else { return }
                if let credentials = data["credentials"] as? [String: String] {
                    if id != exceptID {
                        let name = credentials["name"]!
                        let email = credentials["email"]!
                        let link = URL.init(string: credentials["profilePicLink"]!)
                        URLSession.shared.dataTask(with: link!, completionHandler: { (data, response, error) in
                            if error == nil {
                                let profilePic = UIImage.init(data: data!)
                                let user = User.init(name: name, email: email, id: id, profilePic: profilePic!)
                                completion(user)
                            }
                        }).resume()
                    }
                }
            }
        })
    }
    
    class func checkUserVerification(completion: @escaping (Bool) -> ()) {
        Auth.auth().currentUser?.reload(completion: { (_) in
            let status = (Auth.auth().currentUser?.isEmailVerified)!
            completion(status)
        })
    }
    
    
    //MARK: Inits
    init(name: String, email: String, id: String, profilePic: UIImage) {
        self.name = name
        self.email = email
        self.id = id
        self.profilePic = profilePic
    }
    init(json:JSON) {
        self.name = "\(json["firstname"].stringValue)  \(json["lastname"].stringValue)"
        self.email = json["member_email"].stringValue
        self.id = json["member_id"].stringValue
        self.profilePic = nil
        self.avatarUrl = json["dp"].stringValue
    }
}

