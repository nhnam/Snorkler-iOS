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
import Fakery
import Firebase

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
            $0?.layer.cornerRadius = ($0?.frame.size.height ?? 50)/2;}
        [subscriberContainer, publisherContainer].forEach {
            $0?.layer.cornerRadius = 5.0;}
        
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
    
    @available(iOS 10.0, *)
    func setupCameraSession() {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return
        #endif
        let captureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) as AVCaptureDevice
        do {

            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
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
        let faker = Faker.init()
        timerLabel.text = "Connecting to a \(20 + faker.number.randomInt() % 10) years old guy from \(faker.address.country())"
    }
    
    func seekNext() {
        count = 3;
        let faker = Faker.init()
        timerLabel.text = faker.lorem.sentence(wordsAmount: 20)
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
        showLoading()
        
        Alamofire.request(video_server + "/session/" + akey).responseJSON { [unowned self] response in
            self.hideLoading()
            print("\(String(describing: response.request))")
            print("Session: \(response.result)")
            if let error = response.error {
                print("Get session fail: \(error.localizedDescription)")
                print("RESPONSE:\n\(response)")
                ready?(false)
                return
            }
            if let JSON = response.result.value {
                print("Session: \(JSON)")
                guard let jsonDict:[String:Any] = JSON as? [String:Any] else { return }
                let token = (jsonDict["token"] as? String) ?? ""
                let sessionId = (jsonDict["sessionId"] as? String) ?? ""
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
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    
}

// MARK: - OTSession delegate callbacks
extension VideoChatViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil && !subscribeToSelf {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension VideoChatViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        if subscriber == nil && subscribeToSelf {
            doSubscribe(stream)
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension VideoChatViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            subsView.frame = subRect
            subscriberContainer.addSubview(subsView)
            cameraSession.stopRunning()
            previewView.isHidden = true
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
