//
//  UIImage+Alpha.swift
//  Pods
//
//  Created by DragonCherry on 8/2/16.
//
//

import UIKit

extension UIImage {
    
    public func setAlpha(_ value: CGFloat) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        
        if let context = UIGraphicsGetCurrentContext(), let CGImage = self.cgImage {
            let area = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0, y: -area.size.height)
            context.setBlendMode(CGBlendMode.multiply)
            context.setAlpha(value)
            context.draw(CGImage, in: area)
            
            return UIGraphicsGetImageFromCurrentImageContext() ?? self
        }
        UIGraphicsEndImageContext()
        return self
    }
}
