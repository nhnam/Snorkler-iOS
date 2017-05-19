//
//  CustomGradientView.swift
//  ViewSonicTradeshowConnect
//
//  Created by James Jing Jing na krub on 3/1/17.
//  Copyright © 2017 PartnerPeople. All rights reserved.
//

import UIKit

//class CustomGradientView: UIView {
//
//    /*
//    // Only override draw() if you perform custom drawing.
//    // An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//        // Drawing code
//    }
//    */
//
//}
@IBDesignable final class CustomGradientView: UIView {
    
    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear
    
    override func draw(_ rect: CGRect) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: CGFloat(0),
                                y: CGFloat(0),
                                width: superview!.frame.size.width,
                                height: superview!.frame.size.height)
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        layer.addSublayer(gradient)
    }
    
}
