//
//  UserProfileViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/12/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import SwiftLocation

extension UIImageView{
    func blurImage() {
        if AppSession.shared.backgroundImage != nil {
            let blurImageView = UIImageView(frame: self.frame)
            blurImageView.image = AppSession.shared.backgroundImage
            blurImageView.sizeToFit()
            blurImageView.contentMode = .scaleAspectFit
            blurImageView.center = self.center
            self.addSubview(blurImageView)
            return
        }
        let layer = self.layer
        UIGraphicsBeginImageContext(self.frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        UIGraphicsEndImageContext()
        
        let blurRadius = 5
        let ciimage: CIImage = CIImage(image: self.image!)!
        
        // Added "CIAffineClamp" filter
        let affineClampFilter = CIFilter(name: "CIAffineClamp")!
        affineClampFilter.setDefaults()
        affineClampFilter.setValue(ciimage, forKey: kCIInputImageKey)
        let resultClamp = affineClampFilter.value(forKey: kCIOutputImageKey)
        
        // resultClamp is used as input for "CIGaussianBlur" filter
        let filter: CIFilter = CIFilter(name:"CIGaussianBlur")!
        filter.setDefaults()
        filter.setValue(resultClamp, forKey: kCIInputImageKey)
        filter.setValue(blurRadius, forKey: kCIInputRadiusKey)
        
        
        let ciContext = CIContext(options: nil)
        let result = filter.value(forKey: kCIOutputImageKey) as! CIImage!
        let cgImage = ciContext.createCGImage(result!, from: ciimage.extent) // changed to ciiimage.extend
        
        let finalImage = UIImage(cgImage: cgImage!)
        
        if AppSession.shared.backgroundImage == nil {
           AppSession.shared.backgroundImage = finalImage
        }
        
        let blurImageView = UIImageView(frame: self.frame)
        blurImageView.image = finalImage
        blurImageView.sizeToFit()
        blurImageView.contentMode = .scaleAspectFit
        blurImageView.center = self.center
        
        self.addSubview(blurImageView)
    }
}

class UserProfileViewController: UIViewController {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        guard let userinfo = AppSession.shared.userInfo else { return }
        nameLabel.text = userinfo.firstname + " " + userinfo.lastname
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.locationLabel.text = AppSession.shared.currentLocation ?? "Not found"
        loadLocation()
        guard let image = AppSession.shared.avatarImage else { return }
        avatarImage.image = image
        backgroundImage.image = image
        backgroundImage.blurImage()
    }

    
    private func loadLocation() {
        Location.getLocation(accuracy: .city, frequency: .oneShot, success: { (_, location) in
            Location.getPlacemark(forLocation: location, success: { placemarks in
                if let place = placemarks.first {
                    guard let formatedAdrressArray:[String] = place.addressDictionary?["FormattedAddressLines"] as? [String] else { return }
                    let address = formatedAdrressArray.joined(separator: ", ")
                    print(address)
                    AppSession.shared.currentLocation = address
                    self.locationLabel.text = address
                    self.locationLabel.sizeToFit()
                }
            }) { error in
                print("Cannot retrive placemark due to an error \(error)")
            }
        }) { (request, last, error) in
            request.cancel() // stop continous location monitoring on error
            print("Location monitoring failed due to an error \(error)")
        }
    }
    
    @IBAction func exploreDidTouch(_ sender: Any) {
        let videoViewController = VideoChatViewController(nibName: "VideoChatViewController", bundle: nil)
        self.present(videoViewController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
