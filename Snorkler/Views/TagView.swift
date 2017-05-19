//
//  TagView.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/16/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

@objc public protocol TagViewDelegate {
    @objc optional func onChangedLayoutTag( sender: UIView )
    @objc optional func onDidEndEditingTag( sender: UIView )
    @objc optional func onTapTag( name: String, userData: Any? )
}

class TagView: UIView, UITextFieldDelegate {
    required init( coder aDecoder: NSCoder ) {
        super.init( coder: aDecoder )!
    }
    override init( frame: CGRect ) {
        super.init( frame: frame )
    }
}
