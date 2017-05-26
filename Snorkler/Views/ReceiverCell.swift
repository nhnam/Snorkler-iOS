//
//  ReceiverCell.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/25/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

final class ReceiverCell: UITableViewCell {
    
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var name: UILabel!
    
    func clearCellData()  {
        self.message.text = nil
        self.message.isHidden = false
        self.name.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}
