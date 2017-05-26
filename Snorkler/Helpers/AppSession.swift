//
//  AppSession.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/13/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

struct UserInfo {
    var firstname:String
    var lastname:String
    var token:String
    var memberId:String
    var email:String
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
}
