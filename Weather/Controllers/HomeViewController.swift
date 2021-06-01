//
//  HomeViewController.swift
//  Weather
//
//  Created by George Kiplagat on 31/05/2021.
//

import UIKit
import Alamofire
import GoogleMaps
import GooglePlaces
import GooglePlacePicker

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, LocationChangeDelegate {
    
    @IBOutlet weak var weatherImageView: UIImageView!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var minimumTemperatureLabel: UILabel!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var maximumTemperatureLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cityButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation!
    
    var location:LocationModel!
    var currentForecast:ForecastModel!
    var futureForeCast:[FutureModel]! = []
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
      
        self.loadingView.layer.cornerRadius = Config.CORNER_RADIUS
        
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            
            guard let currentLocation = self.locationManager.location else {return}
            
            self.reverseGeocodeCoordinate(CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude))
            
        }
        
    }
    
    func passData(selectedLocation: LocationModel, source:String) {
        self.location = selectedLocation
    
        if source == "MAPS" {
            self.reverseGeocodeCoordinate(CLLocationCoordinate2D(latitude: self.location.latitude, longitude: self.location.longitude))
        } else {
            self.loadingView.isHidden = false
            self.loadCurrent()
            self.loadForecast()
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if  self.futureForeCast.count > 0 {
            return 5
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell:ForecastTableViewCell = tableView.dequeueReusableCell(withIdentifier: "forecast_cell", for: indexPath) as! ForecastTableViewCell
          
        cell.dayLabel.text = self.futureForeCast[indexPath.row+1].dt.convertDateToDay()
        cell.temperatureIcon.text = "\(self.futureForeCast[indexPath.row+1].temp.temp)°"
        
        switch self.futureForeCast[indexPath.row+1].weather[0].main {
        case "Clear":
            cell.weatherIcon.image = UIImage(named: "clear")
            break;
        case "Clouds":
            cell.weatherIcon.image = UIImage(named: "partlysunny")
            break;
        default:
            cell.weatherIcon.image = UIImage(named: "rain")
         
        }
        
        return cell;
        
    }
    
    
    func setUpCurrent(){
        self.cityButton.setTitle(self.location.city.uppercased(), for: .normal)
        self.currentTemperatureLabel.text = "\(currentForecast.main.temp)°"
        self.weatherLabel.text = currentForecast.weather[0].description.uppercased()
        self.temperatureLabel.text = "\(currentForecast.main.temp)°"
        self.minimumTemperatureLabel.text = "\(currentForecast.main.tempMin)°"
        self.maximumTemperatureLabel.text = "\(currentForecast.main.tempMax)°"
        
        switch currentForecast.weather[0].main {
        case "Clear":
            self.weatherImageView.image = UIImage(named: "forest_sunny")
            self.view.backgroundColor = ColorUtils.hexStringToUIColor(hex: Config.SUNNY_COLOR)
            break;
        case "Clouds":
            self.weatherImageView.image = UIImage(named: "forest_cloudy")
            self.view.backgroundColor = ColorUtils.hexStringToUIColor(hex: Config.CLOUDY_COLOR)
            break;
        default:
            self.weatherImageView.image = UIImage(named: "forest_rainy")
            self.view.backgroundColor = ColorUtils.hexStringToUIColor(hex: Config.RAINY_COLOR)
         
        }
        
        self.loadingView.isHidden = true
    
    }
    
    func loadCurrent() {
      
        //checks if there is internet conectivity
        
        if Reachability.isConnectedToNetwork() {
            
            AF.request("\(Config.CURRENT_URL)?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(Config.APP_ID)&units=metric")
              .validate()
              .responseDecodable(of: ForecastModel.self) { (response) in
                guard
                    let response = response.value else {return}
                
                if (response.code == Config.SUCCESS_CODE) {
                    self.currentForecast = response;
                    self.setUpCurrent()
                }
            }
        } else {
            let alertController =  UIAlertController(title: "", message: "Could not connect to the interner", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func loadForecast() {
            
        AF.request("\(Config.FORECAST_URL)?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(Config.APP_ID)&units=metric")
          .validate()
          .responseDecodable(of: FutureForecastModel.self) { (response) in
            guard
                let response = response.value else {return}
        
            self.futureForeCast = response.daily
            self.tableView.reloadData()
            self.tableView.isHidden = false
            self.loadingView.isHidden = true
            
          }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.reverseGeocodeCoordinate(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
    }
    
    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        self.loadingView.isHidden = false
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
       
            guard let address = response?.firstResult(), let _ = address.lines else {return}
            
            if let city = address.locality {
                self.location = LocationModel(city: city, country: address.country!, longitude: coordinate.longitude, latitude: coordinate.latitude)
            } else if address.subLocality != nil {
                self.location = LocationModel(city: "\(address.subLocality!)", country: address.country!, longitude: coordinate.longitude, latitude: coordinate.latitude)
            } else {
                self.location = LocationModel(city: "\(address.country!)", country: address.country!, longitude: coordinate.longitude, latitude: coordinate.latitude)
            }
            
            self.loadCurrent()
            self.loadForecast()
           
        }
    }
    
    
    @IBAction func cityButtonAction(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "LocationsViewController") as! LocationsViewController
        newViewController.delegate = self
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
   
    @IBAction func mapButtonAction(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MapsViewController") as! MapsViewController
        newViewController.delegate = self
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
}
