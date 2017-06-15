//
//  ChatViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/25/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import KeyboardMan
import AudioToolbox
import Xia
import JSQMessagesViewController
import Firebase

final class ChatViewController: JSQMessagesViewController{
    
    // MARK: Properties
    var messages:[JSQMessage] = [] // messages is an array to store the various instances of JSQMessage
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    private lazy var messageRef: DatabaseReference = self.channelRef.child("messages")
    
    private var newMessageRefHandle: DatabaseHandle?
    
    var targetUser: User? {
        didSet{ print("User set:\(String(describing: targetUser?.email))") }
    }
    
    var currentUserId = AppSession.shared.userInfo?.memberId {
        didSet { print("SenderId: \(String(describing: currentUserId))") }
    }
    var senderName = AppSession.shared.userInfo?.firstname
    
    lazy var keyboardMan = {
        return KeyboardMan()
    }()
    
    lazy var isObserveredMessages:Bool = {
        self.observeMessages()
        return true
    }()
    
    lazy var senderAvatar:URL? = {
        if let url =  AppSession.shared.userInfo?.dp {
            return URL(string: url)!
        } else {
            return nil
        }
    }()
    
    lazy var targetAvatar:URL? = {
        if let url = self.targetUser?.avatarUrl {
            return URL(string: url)!
        } else {
            return nil
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = targetUser?.name
        self.setup()
    }

    func setup() {
        self.getUserInfo { [unowned self] in
            _ = self.isObserveredMessages
        }
        senderId = AppSession.shared.userInfo?.memberId ?? ""
        senderDisplayName = AppSession.shared.userInfo?.firstname ?? ""
        setupBubbles()
    }
    
    func getUserInfo(_ done:@escaping ()->()) {
        guard let email = AppSession.shared.userInfo?.email else { return }
        Auth.auth().signIn(withEmail: email, password: "123456", completion: { (user, error) in
            ErrorHelper.apiError(error)
            done()
        })
    }
    
    fileprivate func setupBubbles() {
        // JSQMessagesBubbleImageFactory has methods that create the images for the chat bubbles. There’s even a category provided by JSQMessagesViewController that creates the message bubble colors used in the native Messages app.
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
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
        //collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        //collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        messageRef = channelRef.child("messages")
        let messageQuery = messageRef.queryLimited(toLast:25)
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            guard let messageData:[String:String] = snapshot.value as? [String : String] else { return }
            print("📩 \(messageData)")
            if let id:String = messageData["senderId"],
                let text:String = messageData["text"],
                text.characters.count > 0 {
                if (id == self.targetUser?.id || id == AppSession.shared.userInfo?.memberId) {
                    self.addMessage(id, text: text)
                    self.finishReceivingMessage()
                }
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
            if let url = senderAvatar {
                cell.avatarImageView.af_setImage(withURL: url)
            }
        } else {
            cell.textView?.textColor = UIColor.black
            if let url = senderAvatar {
                cell.avatarImageView.af_setImage(withURL: url)
            }
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
