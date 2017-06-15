//
//  AppSession.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/13/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import SwiftyJSON

struct UserInfo {
    var firstname:String
    var lastname:String
    var token:String
    var memberId:String
    var email:String
    var dp:String
}

class AppSession: Any {
    class var shared : AppSession {
        struct Static {
            static let instance : AppSession = AppSession()
        }
        return Static.instance
    }
    
    var userInfo:UserInfo?
    var currentLocation:String?
    var avatarImage:UIImage?
    var backgroundImage:UIImage?
    var currentRoom:String?
    static var onlineUsers:[User] = []
    
    class func beginSession() {
        getOnlineUsers()
    }
    class func getOnlineUsers(onDone done:((Bool)->())? = nil) {
        ApiHelper.getOnlineUsers(onsuccess: { (result) in
            if let json:JSON = result {
                if let usersJson = json["users"].array {
                    usersJson.forEach {
                        let user = User(json: $0)
                        if user.id != AppSession.shared.userInfo?.memberId {
                            onlineUsers.append(user)
                        }
                    }
                }
            }
            done?(true)
        }, onfailure: { (err) in
            print("Online Users: \(err ?? "Unknown")")
            done?(false)
        })
    }
    
    class func cache(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    class func getCache(_ key: String) -> String? {
        guard let value =  UserDefaults.standard.object(forKey: key) as? String else {
            print("\(key) doesn't have cache")
            return nil
        }
        return value
    }
    
}
