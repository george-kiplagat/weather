//
//  MapsViewController.swift
//  Weather
//
//  Created by George Kiplagat on 31/05/2021.
//

import UIKit
import GoogleMaps
import SugarRecord
import CoreData

class MapsViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    
    lazy var db: CoreDataDefaultStorage = {
            let store = CoreDataStore.named("cd_basic")
            let bundle = Bundle(for: LocationsViewController.classForCoder())
            let model = CoreDataObjectModel.merged([bundle])
            let defaultStorage = try! CoreDataDefaultStorage(store: store, model: model)
            return defaultStorage
        }()
    
    let locationManager = CLLocationManager()
    var delegate: LocationChangeDelegate?
    
    var savedLocations:[LocationModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        mapView.delegate = self

        if CLLocationManager.locationServicesEnabled() {
        
            locationManager.requestLocation()

            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            
            setUpSavedLocations()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    func setUpSavedLocations() {
       
        self.savedLocations = try! db.fetch(FetchRequest<Locations>()).map(LocationModel.init)
        
        for location in self.savedLocations{
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            marker.title = location.city
            marker.snippet = location.country
            marker.map = mapView
            
        }
        
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}


extension MapsViewController: CLLocationManagerDelegate, GMSMapViewDelegate {
      
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        guard status == .authorizedWhenInUse else {
          return
        }

        locationManager.requestLocation()

        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {
          return
        }

        mapView.camera = GMSCameraPosition(
          target: location.coordinate,
          zoom: 10,
          bearing: 0,
          viewingAngle: 0)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.delegate!.passData(selectedLocation: LocationModel(city: "", country: "", longitude: coordinate.longitude, latitude: coordinate.latitude), source: "MAPS")
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.delegate!.passData(selectedLocation: LocationModel(city: marker.title!, country: marker.snippet!, longitude: marker.position.longitude, latitude: marker.position.latitude), source: "MAPS")
        self.navigationController?.popViewController(animated: true)
        return true
    }
}
