//
//  MapViewController.swift
//  WorkingWithMap
//
//  Created by MacBook Pro on 11.01.2023.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnGroupStack: UIStackView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var allAnnotations = [CustomAnnotation]()
    let locationManager = CLLocationManager()
    var filteredAnnotations = [CustomAnnotation]()
        
    // TODO: fix this
    var serviceCenter: JSONArray = JSONArray(Global.stringArray)!// ?? JSONArray()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        myLocationInit()
        
        //анимация при открытии
        let initialLocation = CLLocation(latitude: 38.5772, longitude: 69.79)
        centerMapOnLocation(location: initialLocation, regionRadius: 500000, animated: false)
        centerMapOnLocation(location: initialLocation, regionRadius: 5000)
    }
    
    
    func myLocationInit() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            checkAuthorization()
            
        } else { // служба гео выкл
            showLocationAlert(title: "У вас выключена служба геолокации",message: "Хотите включить?", url: URL(string: "App-Prefs:root=LOCATION_SERVICES"))
        }
    }
    
    
    func checkAuthorization() {
        switch CLLocationManager.authorizationStatus() {
            
        case .notDetermined: // не определено
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted: // ограниченный (например родительский контроль)
            break
        case .denied: // отклонен
            showLocationAlert(title: "Вы запретили использование местоположение", message: "Хотите включить?", url: URL(string: UIApplication.openSettingsURLString))
            break
        case .authorizedAlways:
            self.mapView.showsUserLocation = true
            break
        case .authorizedWhenInUse:
            self.mapView.showsUserLocation = true
            break
        @unknown default:
            break
        }
        
    }
    
    
    func showLocationAlert(title: String, message: String?, url: URL?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Настройки", style: .default) { alert in
            if let url = url {
                UIApplication.shared.open(url, options:  [:], completionHandler: nil)
            }
        }
        
        alert.addAction(settingsAction)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        present(alert, animated: true)
    }
    
    
    func setupSearchBar() {
        searchBar.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        searchBar.setShowsCancelButton(true, animated: true)
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.setTitle("Отмена", for: .normal) // TODO: lang
        }
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func setup() {
        addAnnotation()
        createButtons()
        
        mapView.delegate = self
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.isHidden = true
        mapView.isHidden = !tableView.isHidden
        
        setupSearchBar()
        
        (btnGroupStack.arrangedSubviews.first as? UIButton)?.sendActions(for: .touchUpInside)
    }
    
    
    func addAnnotation() {
        
        for i in 0..<serviceCenter.count() {
            let job = serviceCenter.getJSONObject(i)
            
            let lat = Double(job?.getString("Lat") ?? "") ??  40.269750
            let lon = Double(job?.getString("Lng") ?? "") ??  69.650454
            
            let type = job?.getString("Type") ?? "-69"
            let typeText = job?.getString("Type_Text") ?? "--"
            
            var locImg =  UIImage(named: "map_office")
            if type == "4" {
                locImg = UIImage(named: "map_atm")
            } else if type == "5" {
                locImg = UIImage(named: "map_pos")
            } else if type == "6" {
                locImg = UIImage(named: "map_qr")
            }
            
            let annotation = CustomAnnotation(
                title: job?.getString("Title") ?? "",
                subTitle: job?.getString("Subtitle") ?? "",
                location: CLLocationCoordinate2DMake(lat, lon),
                localImg: locImg,
                info1: job?.getString("Info1") ?? "",
                info2: job?.getString("Info2") ?? "",
                type: type, typeText: typeText)
            allAnnotations.append(annotation)
        }
        
    }
    
    
    func getGroupsList() -> JSONArray {
        let groups = JSONArray("[]")!
        let vse = JSONObject()
        vse.put(name: "Type_Text", value: "Все") // TODO: lang
        vse.put(name: "Type", value: "0")
        groups.put(job: vse)
                
        for annotation in allAnnotations {
            let jtypes = JSONObject()
            jtypes.put(name: "Type", value: annotation.type)
            jtypes.put(name: "Type_Text", value: annotation.typeText)

            var hasAlready = false
            for i in 0..<groups.count() {
                if groups.getJSONObject(i)?.getString("Type") == annotation.type {
                    hasAlready = true
                    break
                }
            }
            if !hasAlready { groups.put(job: jtypes) }
        }
        return groups
    }
    
    
    func createButtons() {
        btnGroupStack.removeAllArrangedSubviews()
        let groupList = getGroupsList()
        
        for i in 0 ..< groupList.count() {
            
            let btn = UIButton()
            let type = groupList.getJSONObject(i)?.getString("Type") ?? "-69"
            let typeText = groupList.getJSONObject(i)?.getString("Type_Text") ?? "--"
            btn.setTitle(typeText, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            btn.backgroundColor = .white
            btn.cornerRadius = 15
            btn.borderWidth = 2
            btn.borderColor = .hexStringToUIColor(hex: "#ECEFF1")
            
            if #available(iOS 15, *) {
                btn.configuration = .bordered()
                btn.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
                btn.configuration?.baseBackgroundColor = .clear
            } else {
                btn.contentEdgeInsets = UIEdgeInsets(top:0, left:15, bottom:0, right:15)
            }
            
            btn.addAction { _ in
                if btn.state == .selected { return }
                
                self.btnGroupStack.arrangedSubviews.forEach { view in
                    let button = view as! UIButton
                    button.isSelected = button == btn
                    button.backgroundColor = button == btn ? .hexStringToUIColor(hex: "#00B06C") : .white
                    button.borderWidth = button == btn ? 0 : 2
                }
                self.mapView.removeAnnotations(self.allAnnotations)
                self.mapView.addAnnotations(type == "0" ? self.allAnnotations : self.allAnnotations.filter({ $0.type == type }))
                
                // если не видно ни одного маркера, то отдаляем карту
                if !self.checkIfAnyAnnotationShown() {
                    self.centerMapOnLocation(location: CLLocation(latitude: 38.5772, longitude: 69.79), regionRadius: 500000)
                }
            }
            btnGroupStack.addArrangedSubview(btn)
        }
    }
    
    
    func checkIfAnyAnnotationShown() -> Bool {
        for annotation in mapView.annotations {
            if (annotation is MKUserLocation) { continue }
            
            if(mapView.visibleMapRect.contains(MKMapPoint(annotation.coordinate))) {
                return true
            }
        }
        return false
    }


    func centerMapOnLocation(location: CLLocation, regionRadius: CLLocationDistance, animated: Bool = true) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: animated)
    }

    
}








// TableView
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAnnotations.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "location", for: indexPath) as! LocationCell
        
        cell.title.text = filteredAnnotations[indexPath.row].title
        cell.subtitle.text = filteredAnnotations[indexPath.row].subtitle
        
        //cell.typeImage.sd_setImage(with: URL(string: filteredAnnotations[indexPath.row].imageUrl), placeholderImage: UIImage(named: "locate"))
        cell.typeImage.image = UIImage(named: "") // TODO: fix
        
        return cell
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        mapView.removeAnnotations(self.allAnnotations)
        mapView.addAnnotations(self.allAnnotations)
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
        tableView.isHidden = true
        mapView.isHidden = !tableView.isHidden
        
        let coor = filteredAnnotations[indexPath.row].coordinate
        centerMapOnLocation(location: CLLocation(latitude: coor.latitude, longitude: coor.longitude), regionRadius: 5000)
        
        if let button = btnGroupStack.arrangedSubviews.first as? UIButton {
            button.sendActions(for: .touchUpInside)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
    
    
}




extension MapViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
}





// MapView
extension MapViewController: MKMapViewDelegate {
    
    
    // кастомный Callout(pop up) для markerView
    func configure(viewMarker: MKMarkerAnnotationView) {
        
        if let annotation = viewMarker.annotation as? CustomAnnotation {
            let stack = UIStackView(arrangedSubviews: [
                createStack(title: "Адрес", value: annotation.subtitle), // TODO: lang
                createStack(title: "Номер телефона", value: annotation.info1), // TODO: lang
                createStack(title: "График", value: annotation.info2)] // TODO: lang
            )
            stack.axis = .vertical
            stack.spacing = 5
            viewMarker.detailCalloutAccessoryView = stack
        }
    }
    
    
    func createStack(title: String, value: String?) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .init(red: 218/255, green: 218/255, blue: 218/255, alpha: 1)
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = .black
        valueLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.distribution = .equalCentering
        stack.alignment = .fill
        
        return stack
    }

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) { return nil }
        
        var viewMarker: MKMarkerAnnotationView
        
        // сгруппированный маркер
        if let cluster = annotation as? MKClusterAnnotation {
            cluster.title = nil
            cluster.subtitle = nil
            viewMarker = MKMarkerAnnotationView()
            viewMarker.glyphText = String(cluster.memberAnnotations.count)
            viewMarker.markerTintColor = .init(red: 0, green: 176/255, blue: 108/255, alpha: 1)
            viewMarker.canShowCallout = false

            return viewMarker
        }

        guard annotation is CustomAnnotation else { return nil }
        //guard let customPin = annotation as? CustomAnnotation else { return nil }

        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myannotation") as? MKMarkerAnnotationView {
            viewMarker = dequeuedAnnotationView
            viewMarker.annotation = annotation
        } else {
            viewMarker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "myannotation")
            viewMarker.canShowCallout = true
        }
        
        // идентификатор для группировки
        viewMarker.clusteringIdentifier = "CBT"
        configure(viewMarker: viewMarker)
        
        viewMarker.markerTintColor = .init(red: 0, green: 176/255, blue: 108/255, alpha: 1)
        viewMarker.glyphImage = OriginalUIImage(named: "locate")
        
        return viewMarker
    }
    
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // если сгруппированный маркер, то приближаем
        guard let cluster = view.annotation as? MKClusterAnnotation else { return }
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        var distance = getRegionRadius(mapView: mapView) / 4
        distance = distance > 1000 ? distance : 1000
        let location = CLLocation(latitude: cluster.coordinate.latitude, longitude: cluster.coordinate.longitude)
        centerMapOnLocation(location: location, regionRadius: distance)
    }
    

    func getRegionRadius(mapView: MKMapView) -> Double
    {
        let span = mapView.region.span
        let center = mapView.region.center
        
        let loc1 = CLLocation(latitude: center.latitude - span.latitudeDelta * 0.5, longitude: center.longitude)
        let loc2 = CLLocation(latitude: center.latitude + span.latitudeDelta * 0.5, longitude: center.longitude)
        let loc3 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta * 0.5)
        let loc4 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta * 0.5)
        
        let metersInLatitude = loc1.distance(from: loc2)
        let metersInLongitude = loc3.distance(from: loc4)
        
        // среднее значение
        return (metersInLatitude + metersInLongitude) / 2
    }
    
    
}




// SearchBar
extension MapViewController: UISearchBarDelegate {
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        tableView.isHidden = !(searchBar.text != nil && searchBar.text != "")
        mapView.isHidden = !tableView.isHidden
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.endEditing(true)
        tableView.isHidden = true
        mapView.isHidden = !tableView.isHidden
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            tableView.isHidden = true
            mapView.isHidden = !tableView.isHidden
        } else {
            search(searchText: searchText)
        }
    }
    
    
    func search(searchText: String) {
        tableView.isHidden = false
        mapView.isHidden = !tableView.isHidden
        filteredAnnotations = allAnnotations.filter({
            $0.title?.lowercased().contains(searchText.lowercased()) ?? false || $0.subtitle?.lowercased().contains(searchText.lowercased()) ?? false
        })
        tableView.reloadData()
    }
    
    
    
}




class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var localImg:UIImage?
    var info1: String?
    var info2: String?
    var type: String
    var typeText: String
    
    init(title: String, subTitle: String, location: CLLocationCoordinate2D, localImg: UIImage?, info1: String?, info2: String?, type: String, typeText: String) {
        self.title = title
        self.subtitle = subTitle
        self.coordinate = location
        self.localImg = localImg
        self.info1 = info1
        self.info2 = info2
        self.type = type
        self.typeText = typeText
    }
    
}




class OriginalUIImage: UIImage {
    
    convenience init?(named name: String) {
        guard let image = UIImage(named: name),
              nil != image.cgImage else {
                    return nil
        }
        self.init(cgImage: image.cgImage!)
    }

    
    convenience init?(image: UIImage) {
        guard let image = image.cgImage else {
                    return nil
        }
        self.init(cgImage: image)
    }

    override func withRenderingMode(_ renderingMode: UIImage.RenderingMode) -> UIImage {
        // both return statements work:
        return self
        // return super.withRenderingMode(.alwaysOriginal)
    }

}




extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping(_ view: UIView)->()) {
        @objc class ClosureSleeve: NSObject {
            let closure:(_ view: UIView)->()
            let control: UIControl
            init(control: UIControl, _ closure: @escaping(_ view: UIView)->()) {
                self.control = control
                self.closure = closure
                
            }
            @objc func invoke() { closure(control) }
        }
        let sleeve = ClosureSleeve(control: self, closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

