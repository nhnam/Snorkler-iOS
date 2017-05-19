//
//  UserProfileViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/12/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import SwiftLocation

class UserProfileViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let userinfo = AppSession.shared.userInfo else { return }
        nameLabel.text = userinfo.firstname + " " + userinfo.lastname
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.locationLabel.text = AppSession.shared.currentLocation ?? "Not found"
        loadLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadLocation() {
        Location.getLocation(accuracy: .city, frequency: .oneShot, success: { (_, location) in
            print("A new update of location is available: \(location)")
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
