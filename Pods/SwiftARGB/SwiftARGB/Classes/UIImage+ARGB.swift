//
//  UIImage+RGB.swift
//  Pods
//
//  Created by DragonCherry on 6/30/16.
//
//

import UIKit

extension UIImage {
    
    public class func imageWithColor(_ color: UIColor) -> UIImage? {
        return imageWithColor(color, size: CGSize(width: 1, height: 1))
    }
    
    public class func imageWithColor(_ color: UIColor, size: CGSize) -> UIImage? {
        
        let area: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(area.size)
        
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(area)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    public class func imageWithHex(_ rgb: Int, alpha: Float) -> UIImage? {
        return imageWithColor(UIColor(rgbHex: rgb, alpha: alpha))
    }
    
    public class func imageWithHex(_ rgb: Int, alpha: Float, size: CGSize) -> UIImage? {
        return imageWithColor(UIColor(rgbHex: rgb, alpha: alpha), size: size)
    }
}
