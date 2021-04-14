//
//  ViewController.swift
//  SeyahatKitabim
//
//  Created by ozan aydogdu on 13.04.2021.
//

import UIKit
import MapKit
import CoreLocation
import  CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        
        if selectedTitle != ""{
            
            //coreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults =  false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for results in results as! [NSManagedObject]{
                        if let title = results.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = results.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                            }
                            if let latitude = results.value(forKey: "latitude") as? Double{
                                annotationLatitude = latitude
                            }
                            if let longitude = results.value(forKey: "longitude") as? Double{
                                annotationLongitude = longitude
                                
                                
                                let annotation = MKPointAnnotation()
                                annotation.title = annotationTitle
                                annotation.subtitle = annotationSubtitle
                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                annotation.coordinate =  coordinate
                                
                                
                                mapView.addAnnotation(annotation)
                                nameText.text = annotationTitle
                                commentText.text = annotationSubtitle
                                
                                
                                locationManager.stopUpdatingLocation()
                                
                                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                let region = MKCoordinateRegion(center: coordinate, span: span)
                                mapView.setRegion(region, animated: true)
                                
                            }
                        }
                    }
                }
            }catch{
                print("error")
            }
            
        }else{
            // add new data
        }
        
        
    }
    
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began{
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.self.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
        
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
            
            
            
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }else{
            
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation (requestLocation) { (placemarks, error) in
                
                if let placemark = placemarks{
                    
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemarks![0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeDriving: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
                
                
            }
            
            
        }
    }
    
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let  appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPlaces = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlaces.setValue(nameText.text, forKey: "title")
        newPlaces.setValue(commentText.text, forKey: "subtitle")
        newPlaces.setValue(chosenLatitude, forKey: "latitude")
        newPlaces.setValue(chosenLongitude, forKey: "longitude")
        newPlaces.setValue(UUID(), forKey: "id")
        
        
        do{
            try context.save()
            print("succes")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
        
        
    }
    
    
}

