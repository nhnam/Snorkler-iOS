//
//  FriendCell.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 6/13/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import AlamofireImage

class FriendCell: UITableViewCell {
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    
    var user:User? {
        didSet{
            if let newUser = user {
                nameLabel.text = newUser.name
                if let url = newUser.avatarUrl {
                    profilePic.af_setImage(withURL: URL(string:url)!)
                }
                locationLabel.text = newUser.email
            }
        }
    }
    
    func clearCellData()  {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.profilePic.layer.borderWidth = 2
        self.profilePic.layer.borderColor = GlobalVariables.purple.cgColor
        self.nameLabel.font = UIFont(name:"AvenirNext-Regular", size: 18.0)
        self.locationLabel.font = UIFont(name:"AvenirNext-Regular", size: 13.0)
        self.statusView.layer.cornerRadius = self.statusView.layer.frame.size.height/2
        self.statusView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
