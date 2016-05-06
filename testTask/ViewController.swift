//
//  ViewController.swift
//  testTask
//
//  Created by Краснов Андрей on 06.05.16.
//  Copyright © 2016 Краснов Андрей. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    @IBOutlet var appsTableView : UITableView!
    
    var data: NSMutableData = NSMutableData()
    var tableData = NSMutableArray()
    var imageCache = [String:UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        appsTableView.rowHeight = 100
        getResultsFromAPI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func resizedImage(image: UIImage) -> UIImage {
        let itemSize = CGSize(width: 96, height: 64)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, 0)
        let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
        image.drawInRect(imageRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "MyTestCell")
        cell.detailTextLabel?.numberOfLines = 3
        let rowData: NSDictionary = self.tableData[indexPath.row] as! NSDictionary
        var countryName : String = ""
        if ((rowData["location"] as! NSDictionary)["countryName"] as? String) != nil {
            countryName = ((rowData["location"] as! NSDictionary)["countryName"] as! String) + ", "
        }
        var regionName : String = ""
        if ((rowData["location"] as! NSDictionary)["regionName"] as? String) != nil {
            regionName = ((rowData["location"] as! NSDictionary)["regionName"] as! String) + ", "
        }
        var districtName : String = ""
        if ((rowData["location"] as! NSDictionary)["districtName"] as? String) != nil {
            districtName = ((rowData["location"] as! NSDictionary)["districtName"] as! String)
        }
        cell.textLabel!.text = countryName + regionName + districtName
        cell.textLabel!.font = cell.textLabel!.font.fontWithSize(11)
        
        var id : String = ""
        if (rowData["id"] as? NSNumber) != nil {
            id = "id: " + String(rowData["id"] as! NSNumber) + "\n"
        }
        var saleOfferKind : String = ""
        var saleOfferPrice : String = ""
        if (rowData["saleOffer"] as? NSDictionary) != nil {
            if ((rowData["saleOffer"] as! NSDictionary)["kind"] as? String) != nil {
                saleOfferKind = ((rowData["saleOffer"] as! NSDictionary)["kind"] as! String) + ",   "
                if saleOfferKind == "direct_sell,   " {
                    saleOfferKind = "Продажа,   "
                }
            }
            if ((rowData["saleOffer"] as! NSDictionary)["price"] as? NSNumber) != nil {
                saleOfferPrice = "цена: " + String((rowData["saleOffer"] as! NSDictionary)["price"] as! NSNumber)
            }
        }
        cell.detailTextLabel?.text = id + saleOfferKind + saleOfferPrice
        var urlString = NSString()
        let imagesArray = rowData["images"] as! NSArray
        if imagesArray.count == 0 {
            urlString = ""
        } else {
            urlString = (((imagesArray[0] as! NSDictionary)["url"] as! NSString) as String) + (NSString(string: "-128") as String)
        }
        let imgURL: NSURL = NSURL(string: urlString as String)!
        
        cell.imageView?.image = resizedImage(UIImage(named: "Blank52")!)
        if let img = imageCache[urlString as String] {
            cell.imageView?.image = img
        }
        else if urlString == "" {
            cell.imageView?.image = resizedImage(UIImage(named: "Blank52")!)
        } else {
            let request: NSURLRequest = NSURLRequest(URL: imgURL)
            let mainQueue = NSOperationQueue.mainQueue()
            NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                if error == nil {
                    let image = self.resizedImage(UIImage(data: data!)!)
                    self.imageCache[urlString as String] = image
                    dispatch_async(dispatch_get_main_queue(), {
                        if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) {
                            cellToUpdate.imageView?.image = image
                        }
                    })
                }
                else {
                    print("Error: \(error!.localizedDescription)")
                }
            })
        }
        
        return cell
    }
    
    func getResultsFromAPI() {
        let urlPath = "https://api.jqestate.ru/v1/properties/country?pagination[offset]=32"
        let url: NSURL = NSURL(string: urlPath)!
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            print("Task completed")
            if((error) != nil) {
                print(error!.localizedDescription)
            }
            var jsonResult : NSDictionary!
            do {
            jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            }
            catch {
                print(error)
            }
            let results = jsonResult["items"] as! NSMutableArray
            dispatch_async(dispatch_get_main_queue(), {
                self.tableData = results
                self.appsTableView.reloadData()
            })
        })
        task.resume()
    }

    func connection(didReceiveResponse: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.data.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        var jsonResult : NSDictionary!
        do {
        jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        }
        catch {
            print(error)
        }
        
        if jsonResult.count>0 && jsonResult["items"]!.count>0 {
            let results: NSMutableArray = jsonResult["items"] as! NSMutableArray
            self.tableData = results
            self.appsTableView.reloadData()
        }
    }

}

