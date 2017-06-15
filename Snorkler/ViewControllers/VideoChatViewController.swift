//
//  VideoChatViewController.swift
//  Snorkler
//
//  Created by ナム Nam Nguyen on 5/12/17.
//  Copyright © 2017 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import OpenTok
import Alamofire
import AVFoundation
import GPUImage
import Firebase
import SwiftyJSON

let video_server = "https://face2faceserver.herokuapp.com"
//let video_server = "http://localhost:8000"

let subscribeToSelf = false

struct Session {
    var sessionId:String
    var token:String
    var key:String
}

class VideoChatViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var subscriberContainer: UIView!
    @IBOutlet weak var publisherContainer: UIView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var subscriberLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var publisherLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var controlsBottomConstraint: NSLayoutConstraint!
    
    internal var pubRect = CGRect.zero
    internal var subRect = CGRect.zero
    
    internal var session : OTSession?
    internal var publisher : OTPublisher?
    internal var subscriber : OTSubscriber?
    
    internal let ApiKey = "45839832"
    internal var mySession:Session = Session(sessionId: "", token: "", key: AppSession.shared.userInfo?.email ?? "unknown") {
        didSet{
            if (mySession.sessionId.characters.count > 0) {
                session = OTSession(apiKey: ApiKey, sessionId: mySession.sessionId, delegate: self)
            }
        }
    }
    // current session = mysession
    internal var currentSession:Session = Session(sessionId: "", token: "", key: AppSession.shared.userInfo?.email ?? "unknown")
    internal var listSessions:[Session] = []
    lazy internal var listUsers:[User] = {
        return AppSession.onlineUsers
    }()
    internal var userIndex:Int = 0
    
    var stillImageOutput: AVCaptureStillImageOutput?
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetPhoto
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview!.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        return preview!
    }()
    
    internal var timer:Timer?
    internal var count = 3;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [startButton, endButton].forEach {
            $0?.layer.borderColor = $0?.titleLabel?.textColor.cgColor
            $0?.layer.borderWidth = 1.5;
            $0?.layer.cornerRadius = ($0?.frame.size.height ?? 50)/2;
        }
        
        [subscriberContainer, publisherContainer].forEach {
            $0?.layer.cornerRadius = 5.0;
        }
        
        if #available(iOS 10.0, *) {
            setupCameraSession()
        }
        
        seekNext()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pubRect = publisherContainer.bounds
        subRect = subscriberContainer.bounds
        subscriberLoadingIndicator.isHidden = true
        publisherLoadingIndicator.isHidden = true
        
        // Connect to my own session
        getSessionCredentials(username: mySession.key)
        
        let listKey = AppSession.onlineUsers.map { return $0.email }
        listKey.forEach { (key) in
            getSessionCredentials(username: key)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.previewView.layer.addSublayer(previewLayer)
        previewLayer.frame = self.previewView.bounds
        cameraSession.startRunning()
    }
    
    func setupCameraSession() {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return
        #endif
        
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else { return }
        
        for device in devices {
            if device.position == .front {
                initWithCamera(device)
            }
        }
    }
    
    func initWithCamera(_ camera:AVCaptureDevice) {
        
        do {
            
            let deviceInput = try AVCaptureDeviceInput(device: camera)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            cameraSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.partnerpeople.snorkler.videopreviews")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }

    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    func stop() {
        if(count > 0) {
            count = count - 1
        } else {
            timer?.invalidate();
            askForConnect()
        }
    }
    
    func askForConnect() {
        if userIndex < listUsers.count {
            let user = listUsers[userIndex]
            if let address = user.address {
                timerLabel.text = "Connecting to \(user.name) guy from \(address)"
            } else {
                timerLabel.text = "Connecting to \(user.name)"
            }
        }
    }
    
    func seekNext() {
        count = 3;
        timerLabel.numberOfLines = 0
        timerLabel.lineBreakMode = .byWordWrapping
        startTimer()
    }
    
    func subLoading(_ isLoading: Bool) {
        if(isLoading) {
            subscriberLoadingIndicator.isHidden = false
            subscriberLoadingIndicator.startAnimating()
        } else {
            subscriberLoadingIndicator.stopAnimating()
            subscriberLoadingIndicator.isHidden = true
        }
    }
    func pubLoading(_ isLoading: Bool) {
        if(isLoading) {
            publisherLoadingIndicator.isHidden = false
            publisherLoadingIndicator.startAnimating()
        } else {
            publisherLoadingIndicator.stopAnimating()
            publisherLoadingIndicator.isHidden = true
        }
    }
    
    func connectTo(key username:String) {
        pubLoading(false)
        subLoading(false)
        doDisconnect(escape: false)
        getSessionCredentials(username: username, onReady: { [weak self] ready in
            if ready {
                self?.pubLoading(true)
                self?.subLoading(true)
                self?.doConnect()
            }
        })
    }
    
    @IBAction func startButtonDidTouch(_ sender: Any) {
        pubLoading(true)
        subLoading(true)
        self.doConnect()
    }
    
    @IBAction func endButtonDidTouch(_ sender: Any) {
        DispatchQueue(label: "EndStreaming").async {  [weak self] in
            DispatchQueue.main.async {
                self?.pubLoading(false)
                self?.subLoading(false)
                self?.doDisconnect(escape: false)
                self?.previewView.isHidden = false
                self?.seekNext()
            }
        }
    }
    
    @IBAction func closeDidTouch(_ sender: Any) {
        DispatchQueue(label: "CloseStreaming").async { [weak self] in
            DispatchQueue.main.async {
                if (self?.cameraSession.isRunning ?? false){
                    self?.cameraSession.stopRunning()
                }
                self?.previewView.isHidden = true
                self?.pubLoading(false)
                self?.subLoading(false)
                self?.doDisconnect(escape: true)
            }
        }
    }
    
    
    private func getSessionCredentials(username akey:String, onReady ready: ((Bool)->())? = nil) {
        
        Alamofire.request(video_server + "/session/" + akey).responseJSON { [unowned self] response in

            if let request = response.request, let code = response.response?.statusCode {
                print("-------------------------------------------------------")
                print("\(request). \(code)")
            }
            
            if let error = response.error {
                print("Get session fail: \(error.localizedDescription). Content:")
                print("\n\(response)")
                ready?(false)
                return
            }
            if let data = response.data {
                let json = JSON(data)
                print("\(json)")
                let token = json["token"].stringValue
                let sessionId = json["sessionId"].stringValue
                if akey == self.mySession.key {
                    self.mySession = Session(sessionId: sessionId, token: token, key: akey)
                } else {
                    self.listSessions.append(Session(sessionId: sessionId, token: token, key: akey))
                }
                ready?(true)
            }
        }
    }
    
    func doConnect() {
        print("Do Connect to session: \(currentSession.sessionId)")
        if let session = self.session {
            var maybeError : OTError?
            session.connect(withToken: mySession.token, error: &maybeError)
            if let error = maybeError {
                showAlert(message: error.localizedDescription)
            }
        }
    }
    
    func doDisconnect(escape willEscape:Bool) {
        print("Do Disconnect")
        if let session = self.session {
            var maybeError : OTError?
            session.disconnect(&maybeError)
            cleanupSubscriber()
            if let error = maybeError {
                showAlert(message: error.localizedDescription)
            }
        }
        if(willEscape) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func doPublish() {
        publisher = OTPublisher(delegate: self)
        
        var maybeError : OTError?
        session?.publish(publisher!, error: &maybeError)
        
        if let error = maybeError {
            showAlert(message: error.localizedDescription)
        }
        
        publisherContainer.addSubview(publisher!.view!)
        publisher!.view?.frame = pubRect
        pubLoading(false);
    }
    
    func doSubscribe( _ stream : OTStream) {
        if let session = self.session {
            subscriber = OTSubscriber(stream: stream, delegate: self)
            
            var maybeError : OTError?
            session.subscribe(subscriber!, error: &maybeError)
            if let error = maybeError {
                showAlert(message: error.localizedDescription)
            }
        }
    }
    
    func doUnsubscribe() {
        if let subscriber = self.subscriber {
            var maybeError : OTError?
            session?.unsubscribe(subscriber, error: &maybeError)
            
            self.cleanupSubscriber()
            
            if let error = maybeError {
                showAlert(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Helpers
    func showAlert(message: String) {
        print("❗️ \(message)")
    }
    
    func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    
}

