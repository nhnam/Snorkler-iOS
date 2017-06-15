//
//  ConversationsViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/25/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit

class ConversationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var email:String = {
        return AppSession.shared.userInfo?.email ?? ""
    }()
    
    internal var selectedUser: User?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    
    lazy var listUsers:[User] = {
        return AppSession.onlineUsers
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuBarButton.target = self.revealViewController()
            menuBarButton.action = #selector(SWRevealViewController.revealToggle(_:))
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        if !email.isEmpty {
            
            User.loginUser(withEmail: email, password: "123456", completion: { status in
                
            })
        }
    }
    
    @IBAction func didTouchOpenChat(_ sender: Any) {
        
    }

    //MARK: Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.listUsers.count == 0 {
            return 1
        } else {
            return self.listUsers.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.listUsers.count == 0 {
            return self.view.bounds.height - self.navigationController!.navigationBar.bounds.height
        } else {
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.listUsers.count {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "empty_cell")!
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "friend_cell", for: indexPath) as! FriendCell
            let user = self.listUsers[indexPath.row]
            cell.user = user
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.listUsers.count > 0 {
            self.selectedUser = self.listUsers[indexPath.row]
            self.performSegue(withIdentifier: "toChatVC", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ChatViewController {
            let vc:ChatViewController = segue.destination as! ChatViewController
            vc.targetUser = self.selectedUser
        }
    }

}
