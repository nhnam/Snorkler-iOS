//
//  ErrorHelper.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 6/15/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import Foundation

final class ErrorHelper {
    class func apiError(_ error: Error?) {
        if let er = error {
            print(" ‼️ \(er.localizedDescription)")
        }
    }
}
