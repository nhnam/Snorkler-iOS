//
//  RearMenuViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/20/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

class RearMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tableMenu: UITableView!
    internal let MENUS:[String] = ["Live video", "Chat Conversations"]
    internal let ICONS:[UIImage] = [#imageLiteral(resourceName: "selectCamera"), #imageLiteral(resourceName: "selectMessage")]
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
        tableMenu.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MENUS.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "menu_cell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "menu_cell")
            cell!.backgroundColor = .clear
            cell!.selectionStyle = .none
            cell!.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            cell!.textLabel?.textColor = .white
        }
        cell!.textLabel?.text = MENUS[indexPath.row]
        cell!.imageView?.image = ICONS[indexPath.row]
        return cell!
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let revealController = self.revealViewController() else { return }
        switch indexPath.row {
        case 0:
            break
        case 1:
            guard let navi_conversation = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "navi_conversation") as? UINavigationController else { return }
            revealController.pushFrontViewController(navi_conversation, animated: true)
            break
        default:
            break
        }
    }
    
    @IBAction func signoutDidTouch(_ sender: Any) {
        
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
