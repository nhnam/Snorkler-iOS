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
import AudioToolbox
import Xia

class ChatViewController: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableMarginBottom: NSLayoutConstraint!
    let defaultBottomConstant: CGFloat = 53.0
    
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private lazy var messageRef: DatabaseReference = self.channelRef.child("messages")
    private var newMessageRefHandle: DatabaseHandle?
    
    var messages:[Message] = []
    var currentUser: User? {
        didSet{ print("User set:\(String(describing: currentUser?.email))") }
    }
    var senderId = Auth.auth().currentUser?.uid {
        didSet { print("SenderId: \(String(describing: senderId))") }
    }
    var senderName = AppSession.shared.userInfo?.firstname
    
    lazy var keyboardMan = {
        return KeyboardMan()
    }()
    
    lazy var isObserveredMessages:Bool = {
        self.observeMessages()
        return true
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 50
        self.tableView.separatorStyle = .none
        self.inputField.delegate = self
        self.inputField.layer.borderWidth = 2
        self.inputField.layer.borderColor = GlobalVariables.purple.cgColor
        self.inputField.layer.cornerRadius = 3.0
        self.inputField.clipsToBounds =  true
        let view = UIView(frame: CGRect(x:0,y:0,width:30,height:30))
        self.inputField.leftViewMode = .always
        self.inputField.leftView = view
        
        self.title = AppSession.shared.currentRoom
        
        if currentUser != nil {
            fetchData()
        } else {
            guard let email = AppSession.shared.userInfo?.email else { return }
            Auth.auth().signIn(withEmail: email, password: "123456", completion: { (user, error) in
                if let er = error {
                    print("Signin Error: \(er.localizedDescription)")
                    return
                }
                print ("Signed in chat as \(email)")
                self.senderId = Auth.auth().currentUser?.uid
            })
        }
        _ = isObserveredMessages
    }
    
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configKeyboardObserver()
    }
    
    func configKeyboardObserver() {
        keyboardMan.animateWhenKeyboardAppear = { [weak self] appearPostIndex, keyboardHeight, keyboardHeightIncrement in
            self?.tableMarginBottom.constant = keyboardHeight + ( self?.defaultBottomConstant ?? 0.0 )
            self?.view.layoutIfNeeded()
        }
        
        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in
            self?.tableMarginBottom.constant = self?.defaultBottomConstant ?? 0.0
            self?.view.layoutIfNeeded()
        }
    }
    

    func fetchData() {
        guard let userid = self.currentUser?.id else { return }
//        Message.downloadAllMessages(forUserID: userid, completion: {[unowned self] (message) in
//            // self.messages.append(message)
//            self.finishReceivingMessage()
//        })
        Message.markMessagesRead(forUserID: userid)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if inputField.canResignFirstResponder {
            inputField.resignFirstResponder()
        }
    }

    func composeMessage(type: MessageType, content: String)  {
        
        guard let userid = senderId else { return }
        
        let message = Message.init(type: type, content: content, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false, name: senderName)
        
        Message.send(message: message, toID: userid, completion: { (_) in })
        
        let itemRef = messageRef.childByAutoId()
        let messageItem:[String:String] = [
            "senderId": senderId!,
            "senderName": senderName!,
            "text": content]
        
        itemRef.setValue(messageItem) // 3
    }
    
    @IBAction func didTouchSend(_ sender: Any) {
        if let text = inputField.text {
            if text.characters.count > 0 {
                self.composeMessage(type: .text, content: text)
                inputField.text = ""
            }
        }
    }
    
    func observeMessages() {
        messageRef = channelRef.child("messages")
        let messageQuery = messageRef.queryLimited(toLast:25)
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            guard let messageData:[String:String] = snapshot.value as? [String : String] else { return }
            if let id:String = messageData["senderId"],
                let name:String = messageData["senderName"],
                let text:String = messageData["text"],
                text.characters.count > 0 {
                self.addMessage(withId: id, name: name, text: text)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
                Xia.showWarning("Can't decode message.\n\(messageData)")
            }
        })
    }
    
    private func addMessage(withId userId:String, name senderName:String, text content: String) {
        let message = Message.init(type: .text, content: content, owner: (userId == senderId) ? .sender : .receiver, timestamp: Int(Date().timeIntervalSince1970), isRead: false, name: senderName)
        messages.append(message)
    }
    
    private func finishReceivingMessage() {
        self.messages.sort{ $0.timestamp < $1.timestamp }
        DispatchQueue.main.async {
            if !self.messages.isEmpty {
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: IndexPath.init(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
            }
        }
        self.playSound()
    }
    
    func playSound()  {
        var soundURL: NSURL?
        var soundID:SystemSoundID = 0
        let filePath = Bundle.main.path(forResource: "newMessage", ofType: "wav")
        soundURL = NSURL(fileURLWithPath: filePath!)
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        AudioServicesPlaySystemSound(soundID)
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
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch messages[indexPath.row].owner {
        case .receiver:
            let cell = tableView.dequeueReusableCell(withIdentifier: "receiver_cell", for: indexPath) as! ReceiverCell
            cell.clearCellData()
            cell.profilePic.image = #imageLiteral(resourceName: "profile pic")
            cell.message.text = messages[indexPath.row].content as? String
            cell.name.text = messages[indexPath.row].name
            return cell
        case .sender:
            let cell = tableView.dequeueReusableCell(withIdentifier: "sender_cell", for: indexPath) as! SenderCell
            cell.clearCellData()
            cell.profilePic.image = #imageLiteral(resourceName: "contact-icon")
            cell.message.text = messages[indexPath.row].content as? String
            cell.name.text = messages[indexPath.row].name
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
