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
import JSQMessagesViewController

final class ChatViewController: JSQMessagesViewController{
    
    // MARK: Properties
    var messages:[JSQMessage] = [] // messages is an array to store the various instances of JSQMessage
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private lazy var messageRef: DatabaseReference = self.channelRef.child("messages")
    
    private var newMessageRefHandle: DatabaseHandle?
    
    var currentUser: User? {
        didSet{ print("User set:\(String(describing: currentUser?.email))") }
    }
    var currentUserId = Auth.auth().currentUser?.uid {
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
        self.title = AppSession.shared.currentRoom
        self.getUserInfo { [unowned self] in
            _ = self.isObserveredMessages
        }
    }
    
    func getUserInfo(_ done:@escaping ()->()) {
        guard let email = AppSession.shared.userInfo?.email else { return }
        Auth.auth().signIn(withEmail: email, password: "123456", completion: { (user, error) in
            ErrorHelper.apiError(error)
            self.senderId = Auth.auth().currentUser?.uid
            done()
        })
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
            self?.view.layoutIfNeeded()
        }
        
        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in
            self?.view.layoutIfNeeded()
        }
    }

    func composeMessage(type: MessageType, content: String)  {
        
        guard let userid = currentUserId else { return }
        guard let name = senderName else { return }
        
        let itemRef = messageRef.childByAutoId()
        let messageItem:[String:String] = [
            "senderId": userid,
            "senderName": name,
            "text": content]
        
        itemRef.setValue(messageItem) // 3
    }
    
    func observeMessages() {
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        messageRef = channelRef.child("messages")
        let messageQuery = messageRef.queryLimited(toLast:25)
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            guard let messageData:[String:String] = snapshot.value as? [String : String] else { return }
            print("📩 \(messageData)")
            if let id:String = messageData["senderId"],
                let text:String = messageData["text"],
                text.characters.count > 0 {
                self.addMessage(id, text: text)
                // Inform JSQMessagesViewController that a message has been received.
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
                Xia.showWarning("Can't decode message.\n\(messageData)")
            }
        })
    }
    
    // MARK: - Create Message
    // This helper method creates a new JSQMessage with a blank displayName and adds it to the data source.
    func addMessage(_ id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message!)
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        // Using childByAutoId(), you create a child reference with a unique key.
        let itemRef = messageRef.childByAutoId()
        // Create a dictionary to represent the message. A [String: AnyObject] works as a JSON-like object
        let messageItem = ["text": text as String, "senderId": senderId as String]
        
        itemRef.setValue(messageItem) // Save the value at the new child location.
        
        // Play the canonical “message sent” sound.
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        // Complete the “send” action and reset the input toolbar to empty.
        finishSendingMessage()
    }
}

extension ChatViewController {
    // MARK: JSQMessagesCollectionView Datasource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item] // retrieve the message based on the NSIndexPath item.
        if message.senderId == senderId { // Check if the message was sent by the local user. If so, return the outgoing image view.
            return outgoingBubbleImageView
        } else {  // If the message was not sent by the local user, return the incoming image view.
            return incomingBubbleImageView
        }
    }
    
    // set text color based on who is sending the messages
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[(indexPath as NSIndexPath).item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        
        return cell
    }
    
    
    
    // remove avatar support and close the gap where the avatars would normally get displayed.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
}


extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
