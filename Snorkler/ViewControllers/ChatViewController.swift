//
//  ChatViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/25/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import Firebase
import KeyboardMan

// vMv1nC3XrdgyLH6JLe9URpJ5Aja2 hienhien
// 48gT22C0xmYA4iyRU1zTmGVtYgy1 hien1

class ChatViewController: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableMarginBottom: NSLayoutConstraint!
    let defaultBottomConstant: CGFloat = 53.0
    
    var messages:[Message] = []
    var currentUser: User? {
        didSet{
            print("User set:\(String(describing: currentUser?.email))")
        }
    }
    lazy var keyboardMan = {
        return KeyboardMan()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        inputField.delegate = self
        if currentUser != nil {
            fetchData()
        }else {
            let userIdHien1 = "48gT22C0xmYA4iyRU1zTmGVtYgy1"
            User.info(forUserID: userIdHien1, completion: { [weak self] (user:User) in
                self?.currentUser = user
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configKeyboardObserver()
    }
    
    func configKeyboardObserver() {
        keyboardMan.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in
            print("appear \(appearPostIndex), \(keyboardHeight), \(keyboardHeightIncrement)\n")
            self?.tableMarginBottom.constant = keyboardHeight + ( self?.defaultBottomConstant ?? 0.0 )
            self?.view.layoutIfNeeded()
        }
        
        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in
            print("disappear \(keyboardHeight)\n")
            self?.tableMarginBottom.constant = self?.defaultBottomConstant ?? 0.0
            self?.view.layoutIfNeeded()
        }
    }

    func fetchData() {
        guard let userid = self.currentUser?.id else { return }
        Message.downloadAllMessages(forUserID: userid, completion: {[unowned self] (message) in
            self.messages.append(message)
            self.messages.sort{ $0.timestamp < $1.timestamp }
            DispatchQueue.main.async {
                if !self.messages.isEmpty {
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(at: IndexPath.init(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
                }
            }
        })
        
        Message.markMessagesRead(forUserID: self.currentUser!.id)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if inputField.canResignFirstResponder {
            inputField.resignFirstResponder()
        }
    }

    func composeMessage(type: MessageType, content: Any)  {
        guard let userid = self.currentUser?.id else { return }
        let message = Message.init(type: type, content: content, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false)
        Message.send(message: message, toID: userid, completion: { (_) in })
    }
    
    @IBAction func didTouchSend(_ sender: Any) {
        if let text = inputField.text {
            if text.characters.count > 0 {
                self.composeMessage(type: .text, content: text)
                inputField.text = ""
            }
        }
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

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch messages[indexPath.row].owner {
        case .receiver:
            let cell = tableView.dequeueReusableCell(withIdentifier: "receiver_cell", for: indexPath) as! ReceiverCell
            cell.clearCellData()
            switch messages[indexPath.row].type {
            case .text:
                cell.message.text = messages[indexPath.row].content as! String
            case .photo:
                if let image = messages[indexPath.row].image {
                    cell.message.isHidden = true
                } else {
                    messages[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            case .location:
                cell.message.isHidden = true
            }
            return cell
        case .sender:
            let cell = tableView.dequeueReusableCell(withIdentifier: "sender_cell", for: indexPath) as! SenderCell
            cell.clearCellData()
            cell.profilePic.image = self.currentUser?.profilePic
            switch messages[indexPath.row].type {
            case .text:
                cell.message.text = messages[indexPath.row].content as! String
            case .photo:
                if let image = messages[indexPath.row].image {
                    cell.message.isHidden = true
                } else {
                    messages[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            case .location:
                cell.message.isHidden = true
            }
            return cell
        }

    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
