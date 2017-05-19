//
//  AddAvatarPhotoViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/16/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import AVFoundation
import ImagePicker

class AddAvatarPhotoViewController: UIViewController, ImagePickerDelegate {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var sliderView: UIView!
    private var percent:Double = 0.0 {
        didSet {
//            DispatchQueue.main.async {
//                print("\(self.percent)")
//                let size = self.previewImageView.frame.size
//                let dx = size.width - CGFloat((1.0-self.percent))*size.width
//                self.sliderView.frame = self.sliderView.frame.offsetBy(dx: dx, dy: 0)
//            }
        }
    }
    
    private var imageToUpload:UIImage? {
        didSet {
            retakeButton.isHidden = (imageToUpload == nil)
            previewImageView.image = imageToUpload
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retakeButton.layer.borderColor = UIColor.colorWithHex(hex: 0x186f78, alpha: 0.5).cgColor
        retakeButton.layer.cornerRadius = 3.0
        retakeButton.layer.backgroundColor = UIColor.white.cgColor
        retakeButton.layer.borderWidth = 1.5
        retakeButton.isHidden = true
        previewImageView.clipsToBounds = true
        sliderView.isHidden = true
    }
    
    @IBAction func finishButtonDidTouch(_ sender: Any) {
        
        if imageToUpload == nil {
            alert("Please choose your photo")
            return
        }
        
        func onUpdateSuccess() {
            self.performSegue(withIdentifier: "toUserExplorer", sender: self)
        }
        
        showLoading()
        guard let imageData = UIImageJPEGRepresentation(imageToUpload!, 1.0) else { return }
        guard let member_id = AppSession.shared.userInfo?.memberId else { return }
//        sliderView.isHidden = false
//        sliderView.translatesAutoresizingMaskIntoConstraints = true
//        percent = 0.0
        AppSession.shared.avatarImage = imageToUpload
        ApiHelper.updateProfilePicture(params: ["member_id": member_id], imageData: imageData,uploadProgress:{ finishedPercent in
            self.percent = finishedPercent
        }, onsuccess: { (json) in
            self.hideLoading()
            onUpdateSuccess()
        }, onfailure: { errMsg in
            self.hideLoading()
            if let msg = errMsg {
                self.alert(msg)
            }
        })
    }

    @IBAction func captureDidTouch(_ sender: Any) {
        openImagePicker()
    }
    
    @IBAction func retakeDidTouch(_ sender: Any) {
        imageToUpload = nil
        openImagePicker()
    }
    
    private func openImagePicker() {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.configuration.allowMultiplePhotoSelection = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
    }
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard let image = images.first else { return }
        imageToUpload = image
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        
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
