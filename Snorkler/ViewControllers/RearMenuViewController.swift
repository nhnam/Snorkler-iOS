//
//  RearMenuViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/20/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

class RearMenuViewController: UIViewController {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
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
        guard let image = AppSession.shared.avatarImage else { return }
        avatarImage.image = image
        backgroundImage.image = image
        backgroundImage.blurImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
