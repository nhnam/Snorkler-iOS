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
    internal var items = [Conversation]()
    internal var selectedUser: User?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private var channelRefHandle: DatabaseHandle?
    lazy var isObserveredChannel:Bool = {
        self.observeChannels()
        return true
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuBarButton.target = self.revealViewController()
            menuBarButton.action = #selector(SWRevealViewController.revealToggle(_:))
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        if !email.isEmpty {
            print("Login with email: \(email)")
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
            print("New channel:\(channelData)")
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
//        
//        Conversation.showConversations { (conversations) in
//            self.items = conversations
//            self.items.sort{ $0.lastMessage.timestamp > $1.lastMessage.timestamp }
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//                for conversation in self.items {
//                    if conversation.lastMessage.isRead == false {
//                        break
//                    }
//                }
//            }
//        }
    }

    //MARK: Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.items.count == 0 {
            return 1
        } else {
            return self.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.items.count == 0 {
            return self.view.bounds.height - self.navigationController!.navigationBar.bounds.height
        } else {
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.items.count {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "empty_cell")!
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "conversation_cell", for: indexPath) as! ConversationsTBCell
            cell.clearCellData()
            cell.profilePic.image = self.items[indexPath.row].user.profilePic
            cell.nameLabel.text = self.items[indexPath.row].user.name
            switch self.items[indexPath.row].lastMessage.type {
            case .text:
                let message = self.items[indexPath.row].lastMessage.content as! String
                cell.messageLabel.text = message
            case .location:
                cell.messageLabel.text = "Location"
            default:
                cell.messageLabel.text = "Media"
            }
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval(self.items[indexPath.row].lastMessage.timestamp))
            let dataformatter = DateFormatter.init()
            dataformatter.timeStyle = .short
            let date = dataformatter.string(from: messageDate)
            cell.timeLabel.text = date
            if self.items[indexPath.row].lastMessage.owner == .sender && self.items[indexPath.row].lastMessage.isRead == false {
                cell.profilePic.layer.borderColor = GlobalVariables.blue.cgColor
                cell.messageLabel.textColor = GlobalVariables.purple
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.items.count > 0 {
            self.selectedUser = self.items[indexPath.row].user
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
