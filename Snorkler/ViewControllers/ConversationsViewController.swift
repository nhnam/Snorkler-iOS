//
//  ConversationsViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/25/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import Firebase


class ConversationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var email:String = {
        return AppSession.shared.userInfo?.email ?? ""
    }()
    
    internal var selectedUser: User?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private var channelRefHandle: DatabaseHandle?
    lazy var isObserveredChannel:Bool = {
        self.observeChannels()
        return true
    }()
    
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
                if let id = Auth.auth().currentUser?.uid {
                    User.info(forUserID: id, completion: { (user) in
                        print("UserID: \(user.id)")
                    })
                }
                self.fetchData()
            })
        }
        _ = isObserveredChannel
    }
    
    func observeChannels() {
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> () in
            guard let channelData = snapshot.value as? Dictionary<String, AnyObject> else { return }
            self.hideLoading()
            if let name = channelData["name"] as! String!, name.characters.count > 0 {
                if name == AppSession.shared.currentRoom {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toChatVC", sender: name)
                    }
                }
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    @IBAction func didTouchOpenChat(_ sender: Any) {
        let askingChannel = UIAlertController(title: "Group name", message: "Please enter group name", preferredStyle: .alert)
        askingChannel.addTextField { (textfield) in
            textfield.placeholder = "Channel name"
        }
        askingChannel.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action) in
            let newChannelRef = self.channelRef.childByAutoId()
            let channelItem = [
                "name": askingChannel.textFields?.first?.text ?? "Default Room"
            ]
            newChannelRef.setValue(channelItem)
            AppSession.shared.currentRoom = askingChannel.textFields?.first?.text ?? "Default Room"
            DispatchQueue.main.async {
                self.showLoading()
            }
        }))
        self.present(askingChannel, animated: true, completion: nil)
    }
    
    func fetchData() {

        if let id = Auth.auth().currentUser?.uid {
            User.downloadAllUsers(exceptID: id, completion: { (user:User) in
                print("Downloaded all users")
            })
        }
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
            vc.currentUser = self.selectedUser
        }
        
    }

}
