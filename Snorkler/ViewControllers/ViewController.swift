//
//  ViewController.swift
//  CustomCalloutView
//
//  Created by Malek T. on 3/9/16.
//  Copyright © 2016 Medigarage Studios LTD. All rights reserved.
//
import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    var coordinates: [[Double]]!
    var names:[String]!
    var addresses:[String]!
    var phones:[String]!
    let locationManager = CLLocationManager() // location permission
    
    @IBOutlet var menuButton:UIBarButtonItem!
    
    func callPhoneNumber(sender: UIButton)
    {
        let v = sender.superview as! CustomCalloutView
        if let url = URL(string: "telprompt://\(v.snorklerUserPhone.text!)"), UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.openURL(url)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if revealViewController() != nil {
            menuButton.target = revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        locationManager.delegate = self// location permission
        locationManager.requestAlwaysAuthorization()// location permission
        
        
        // 1
        coordinates = [[48.85672,2.35501],[48.85196,2.33944],[48.85376,2.33953]]// Latitude,Longitude
        names = ["James\nSmith","Cho\nChang","Alicia\nJones"]
        addresses = ["170 followers\n200 following","170 followers\n200 following","987 followers\n1002 following"]
        phones = ["+33144789478","+33146345268","+33146340672"]
        self.mapView.delegate = self
        // 2
        for i in 0...2 {
            let coordinate = coordinates[i]
            let point = snorklerUserAnnotation(coordinate: CLLocationCoordinate2D(latitude: coordinate[0] , longitude: coordinate[1] ))
            point.image = UIImage(named: "snorklerUser-\(i+1).jpg")
            point.name = names[i]
            point.address = addresses[i]
            point.phone = phones[i]
            self.mapView.addAnnotation(point)
        }
        // 3
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.856614, longitude: 2.3522219000000177), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        self.mapView.setRegion(region, animated: true)
    }
    
    //MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
        
        if annotationView == nil{
            annotationView = AnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            annotationView?.canShowCallout = false
        }else{
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "contact-icon")
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 1
        if view.annotation is MKUserLocation {
            // Don't proceed with custom callout
            return
        }
        // 2
        let snorklerUserAnnotation = view.annotation as! snorklerUserAnnotation
        let views = Bundle.main.loadNibNamed("CustomCalloutView", owner: nil, options: nil)
        let calloutView = views?[0] as! CustomCalloutView
        calloutView.snorklerUserName.text = snorklerUserAnnotation.name
        calloutView.snorklerUserAddress.text = snorklerUserAnnotation.address
        calloutView.snorklerUserPhone.text = snorklerUserAnnotation.phone
        
        //
        let button = UIButton(frame: calloutView.snorklerUserPhone.frame)
        button.addTarget(self, action: #selector(ViewController.callPhoneNumber(sender:)), for: .touchUpInside)
        calloutView.addSubview(button)
        calloutView.snorklerUserImage.image = snorklerUserAnnotation.image
        // 3
        calloutView.center = CGPoint(x: view.bounds.size.width / 2, y: -calloutView.bounds.size.height*0.52)
        view.addSubview(calloutView)
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.isKind(of: AnnotationView.self) {
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

