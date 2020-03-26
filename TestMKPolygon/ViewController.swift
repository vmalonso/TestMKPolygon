//
//  ViewController.swift
//  TestMKPolygon
//
//  Created by Victor Alonso on 26/03/2020.
//  Copyright © 2020 Blue Blink One. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var arrayPolygons = [MKPolygon]()
    var data: Data!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        readFile()
        loadPolygons(xmlData: data)
    }
    
    func drawPolygons() {
        for polygon in arrayPolygons {
            mapView.addOverlay(polygon)
        }
        centerMap()
    }
    
    func centerMap() {
        var frame = mapView.frame
        frame.origin.x += 20
        frame.size.width -= 40
        frame.origin.y += 44
        frame.size.height -= 96
        centerMap(frame: frame)
    }
    
    func centerMap(frame: CGRect) {
      /*  if (![SettingsModel canChangeRegionSafely]) {
            [self performSelector:@selector(centerMap) withObject:nil afterDelay:1.0];
            return;
        } */
        var region = MKCoordinateRegion()
        var maxLat: CLLocationDegrees = -90
        var maxLon: CLLocationDegrees = -180
        var minLat: CLLocationDegrees = 90
        var minLon: CLLocationDegrees = 180

        for polygon in arrayPolygons {

            for coordinate in polygon.coordinates {
                if coordinate.latitude > maxLat  { maxLat = coordinate.latitude }
                if coordinate.latitude < minLat  { minLat = coordinate.latitude }
                if coordinate.longitude > maxLon  { maxLon = coordinate.longitude }
                if coordinate.longitude < minLon  { minLon = coordinate.longitude }
            }
        }

        region.center.latitude     = (maxLat + minLat) / 2
        region.center.longitude    = (maxLon + minLon) / 2
        region.span.latitudeDelta  = (maxLat - minLat)
        region.span.longitudeDelta = (maxLon - minLon)
        
        let mapViewTemp = MKMapView(frame: frame)
        region = mapViewTemp.regionThatFits(region)
        
        if region.span.longitudeDelta < 0.0003 {
            region.span.longitudeDelta = 0.0003
        }
        if region.span.latitudeDelta < 0.0003 {
            region.span.latitudeDelta = 0.0003
        }
         
        safeSetRegion(region, animated: true)
        
    }
    
    func safeSetRegion(_ region: MKCoordinateRegion, animated: Bool) {
        let myRegion = mapView.regionThatFits(region)
        if !(myRegion.span.latitudeDelta.isNaN || myRegion.span.longitudeDelta.isNaN) {
            mapView.setRegion(myRegion, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(overlay: overlay)
        renderer.fillColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5)
        return renderer
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawPolygons()
    }
    
    func readFile() {
        
        if let path = Bundle.main.path(forResource: "example", ofType: "mmp") {
            // use path
            print(path)
            
            let file: FileHandle? = FileHandle(forReadingAtPath: path)

            if file != nil {
                // Read all the data
                data = file?.readDataToEndOfFile()

                // Close the file
                file?.closeFile()

                // Convert our data to string
                let str = String(data: data!, encoding: .utf8)
                print(str!)
            }
            else {
                print("Ooops! Something went wrong!")
            }
        } else {
            print ("file not found")
        }

        

    }


    final func loadPolygons(xmlData: Data) {
        let xml: XML
        do {
            xml = try XML(string: String(data: xmlData, encoding: String.Encoding.utf8)!)
        } catch {
            
            print("Error reading XML.")
            print(String(data: xmlData, encoding: .utf8) ?? "No text")
            return
        }

        var currentPolygon = xml["POLYGON"][0].xml
 
        var counterOfPolygons = 1
        
        var currentPoint: XML?
        
        while currentPolygon != nil {
                
            var nodoPoints: XML? = nil
            nodoPoints = currentPolygon?["POINTS"].xml
            var pointsCounter = 0
            if nodoPoints != nil {
                currentPoint = nodoPoints!["POINT"][0].xml
            } else {
                currentPoint = nil
            }
            var coordinates = [CLLocationCoordinate2D]()
            while currentPoint != nil {
   
                var coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                if let pointLat = currentPoint!["LAT"].double {
                    coord.latitude = pointLat
                } else {
                    coord.latitude = 0.0
                }
                if let pointLong = currentPoint!["LONG"].double {
                    coord.longitude = pointLong
                } else {
                    coord.longitude = 0.0
                }

                coordinates.append(coord)
                
                pointsCounter += 1

                currentPoint = nodoPoints!["POINT"][pointsCounter].xml
                
            }

            currentPolygon = xml["POLYGON"][counterOfPolygons].xml
            counterOfPolygons += 1
            
            let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
            arrayPolygons.append(polygon)
        }
    
    }
}

extension MKPolygon {
  var coordinates: [CLLocationCoordinate2D] {
    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
    getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
    return coords
  }
}

