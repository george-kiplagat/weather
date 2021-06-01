//
//  LocationsViewController.swift
//  Weather
//
//  Created by George Kiplagat on 31/05/2021.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import SugarRecord
import CoreData

protocol LocationChangeDelegate {
    func passData(selectedLocation: LocationModel, source: String)
}

class LocationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GMSAutocompleteViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noRecordLabel: UILabel!
    
    var delegate: LocationChangeDelegate?
    
    var savedLocations:[LocationModel] = []
    
    lazy var db: CoreDataDefaultStorage = {
            let store = CoreDataStore.named("cd_basic")
            let bundle = Bundle(for: LocationsViewController.classForCoder())
            let model = CoreDataObjectModel.merged([bundle])
            let defaultStorage = try! CoreDataDefaultStorage(store: store, model: model)
            return defaultStorage
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.loadData()
        
    }
    
    func loadData() {
        self.savedLocations = try! db.fetch(FetchRequest<Locations>()).map(LocationModel.init)
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        
        if(savedLocations.count == 0) {
            self.noRecordLabel.isHidden = false
            return 0
        } else {
            self.noRecordLabel.isHidden = true
            return savedLocations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        
        let cell:LocationTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LocationTableViewCell", for: indexPath) as! LocationTableViewCell
            
        cell.cityLabel.text = self.savedLocations[indexPath.row].city
        cell.countryLabel.text = self.savedLocations[indexPath.row].country
        
        return cell;
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.delegate!.passData(selectedLocation: self.savedLocations[indexPath.row], source: "LOCATIONS")
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let name = savedLocations[(indexPath as NSIndexPath).row].city
            try! db.operation({ (context, save) -> Void in
                guard let obj = try! context.request(Locations.self).filtered(with: "city", equalTo: name).fetch().first else { return }
                try! context.remove(obj)
                save()
            })
            self.loadData()
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func addLocationAction(_ sender: Any) {
        let gmsController = GMSAutocompleteViewController()
        gmsController.delegate = self
        gmsController.modalPresentationStyle = .fullScreen
        present(gmsController, animated: true, completion: nil)
    
    }

    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        dismiss(animated: true, completion: nil)
        
            
        if place.formattedAddress != nil {
              
                if place.addressComponents != nil {
                    
                    var country = ""
                    var city = ""
                    
                    for component in place.addressComponents! {
                        
                        switch(component.type){
                            case "country":
                                country = component.name
                            case "locality":
                                city = component.name
                        default:
                            print(component.type)
                        }
                    }
                     
                    if self.savedLocations.contains(where: {$0.city == city}) {
                        let alertController =  UIAlertController(title: "", message: "\(city) already exists", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        try! db.operation { (context, save) -> Void in
                            let loc: Locations = try! context.new()
                            loc.city = city
                            loc.country = country
                            loc.latitude = place.coordinate.latitude
                            loc.longitude = place.coordinate.longitude
                            
                            try! context.insert(loc)
                            save()
                        }
                    }
                    
                    self.loadData()
                    
                }
            
            self.tableView.reloadData()
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: \(error)")
        dismiss(animated: true, completion: nil)
    }
    
    // User cancelled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        print("Autocomplete was cancelled.")
        dismiss(animated: true, completion: nil)
    }
}
