//
//  ApiHelper.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/11/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

let ApiHost = "http://54.67.89.86/Snorkler"

let apiSignUp = "/api/signup/"
let apiSignIn = "/api/signin/"
let apiGetMemberDetail = "/api/GetMemberDetails/"
let apiUpdateMemberDetail = "/api/updateMemberDetails/"
let apiChangePassword = "/api/changePassword/"
let apiUpdateDP = "/api/updateDPBase64/"

let apiGetTrendingInterests = "/api/interests/"
let apiUpdateInterests = "/api/updateMemberInterests/"
let apiGetSchools = "/api/schools/"
let apiUpdateEducation = "/api/updateMemberEducation/"
let apiGetOnlineUsers = "/api/onlineUsers/"

public enum ApiType {
    case signin
    case signup
    case getMemberDetail
    case updateMemberDetail
    case changePassword
    case updateDP
    case getTrendingInterests
    case updateInterests
    case getSchools
    case updateEducation
    case getOnlineUsers
}

class ApiHelper: Any {
    /*
     1. Validate input params then...
     2. Make request then
     3. Preprocess data by using resultClassify
     */
    
    class func validateParam(_ params:[String: Any], forApiType type:ApiType) -> (Bool, String?){
        let isDataValid = true
        let errMessage:String? = nil
        switch type {
        case .signin:
            break
        default:
            break
        }
        return (isDataValid, errMessage);//valid
    }
    
    class func resultClasssify(with response:DataResponse<Any>, forType type:ApiType, onsuccess success:@escaping (JSON?)->(), onfailure fail:(String?)->() ) {
        func doingOnSuccess(_ json:JSON) {
            success(json)
        }
        func doingOnFail(_ error: Error) {
            print(error)
        }
        switch response.result {
        case .success:
            doingOnSuccess(JSON(data: response.data!, options: JSONSerialization.ReadingOptions.allowFragments, error: nil))
        case .failure(let error):
            doingOnFail(error)
        }
        
        
    }
    
    class func signin(email aEmail:String, password aPassword: String, onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let params = ["email":aEmail, "password":aPassword];
        let (valid, errMsg) = validateParam(params, forApiType: .signin)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiSignIn, method: .post, parameters: params).validate().responseJSON { response in
            resultClasssify(with: response, forType: .signin, onsuccess: success, onfailure: fail)
        }
    }
    
    class func signup(params aParams:[String:Any], onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let (valid, errMsg) = validateParam(aParams, forApiType: .signup)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiSignUp, method: .post, parameters: aParams).responseJSON { response in
            resultClasssify(with: response, forType: .signup, onsuccess: success, onfailure: fail)
        }
    }
    
    class func getMemberDetail(memberId aId:String, onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let params = ["member_id":aId];
        let (valid, errMsg) = validateParam(params, forApiType: .getMemberDetail)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiGetMemberDetail, method: .get, parameters: params).validate().responseJSON { response in
            resultClasssify(with: response, forType: .getMemberDetail, onsuccess: success, onfailure: fail)
        }
    }
    
    class func updateMemberDetail(params aParams:[String:Any], onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let (valid, errMsg) = validateParam(aParams, forApiType: .updateMemberDetail)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiUpdateMemberDetail, method: .post, parameters: aParams).validate().responseJSON { response in
            resultClasssify(with: response, forType: .updateMemberDetail, onsuccess: success, onfailure: fail)
        }
    }
    
    class func changePassword(params aParams:[String:Any], onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let (valid, errMsg) = validateParam(aParams, forApiType: .changePassword)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiUpdateMemberDetail, method: .post, parameters: aParams).validate().responseJSON { response in
            resultClasssify(with: response, forType: .changePassword, onsuccess: success, onfailure: fail)
        }
    }
    
    class func getTrendingInterests(onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        Alamofire.request(ApiHost + apiGetTrendingInterests, method: .get, parameters: nil).validate().responseJSON { response in
            resultClasssify(with: response, forType: .getTrendingInterests, onsuccess: success, onfailure: fail)
        }
    }
    
    class func updateInterests(params aParams:[String:Any], onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let (valid, errMsg) = validateParam(aParams, forApiType: .updateInterests)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiUpdateInterests, method: .post, parameters: aParams).validate().responseJSON { response in
            resultClasssify(with: response, forType: .updateInterests, onsuccess: success, onfailure: fail)
        }
    }

    class func getSchools(onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        Alamofire.request(ApiHost + apiGetSchools, method: .get, parameters: nil).validate().responseJSON { response in
            resultClasssify(with: response, forType: .getSchools, onsuccess: success, onfailure: fail)
        }
    }
    
    class func updateEducation(params aParams:[String:Any], onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        let (valid, errMsg) = validateParam(aParams, forApiType: .updateEducation)
        if !valid {
            fail(errMsg);
            return;
        }
        Alamofire.request(ApiHost + apiUpdateEducation, method: .post, parameters: aParams).validate().responseJSON { response in
            resultClasssify(with: response, forType: .updateEducation, onsuccess: success, onfailure: fail)
        }
    }
    
    class func updateProfilePicture(params aParams:[String:Any],
                                    imageData data:Data,
                                    uploadProgress progress:@escaping (Double)->(),
                                    onsuccess success:@escaping (JSON?)->(),
                                    onfailure fail:@escaping (String?)->()) {
        
        let (valid, errMsg) = validateParam(aParams, forApiType: .updateDP)
        
        if !valid {
            fail(errMsg);
            return;
        }
        
        let url = ApiHost + apiUpdateDP
        
        Alamofire.upload(multipartFormData: { (form) in
            
            if let member_id = aParams["member_id"] as? String {
                form.append(member_id.data(using: .utf8)!, withName: "member_id")
            }
            form.append(data, withName: "dp", fileName: "avatar.jpg", mimeType: "image/jpg")
            
        }, to: url, encodingCompletion: { (result) in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: { (Progress) in
                    progress(Progress.fractionCompleted)
                })
                upload.responseJSON { response in
                    resultClasssify(with: response, forType: .updateDP, onsuccess: success, onfailure: fail)
                }
            case .failure(let encodingError):
                print(encodingError)
                fail(encodingError.localizedDescription)
            }
        })
    }
    
    class func getOnlineUsers(onsuccess success:@escaping (JSON?)->(), onfailure fail:@escaping (String?)->()) {
        Alamofire.request(ApiHost + apiGetOnlineUsers, method: .get, parameters: nil).validate().responseJSON { response in
            resultClasssify(with: response, forType: .getOnlineUsers, onsuccess: success, onfailure: fail)
        }
    }    
}
