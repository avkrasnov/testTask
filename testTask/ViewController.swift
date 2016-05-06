//
//  ViewController.swift
//  testTask
//
//  Created by Краснов Андрей on 06.05.16.
//  Copyright © 2016 Краснов Андрей. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var appsTableView : UITableView!
    
    var page : Int = 1 {
        didSet {
            self.addingDataInProcess = true
            getResultsFromAPI()
        }
    }
    var data: NSMutableData = NSMutableData()
    var tableData = NSMutableArray()
    var imageCache = [String:UIImage]()
    var addingDataInProcess = false

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
                saleOfferKind = ((rowData["saleOffer"] as! NSDictionary)["kind"] as! String) + ", "
                if saleOfferKind == "direct_sell, " {
                    saleOfferKind = "Продажа, "
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        if y > h + 10 {
            if !self.addingDataInProcess {
                self.page += 1
            }
        }
    }
    
    func getResultsFromAPI() {
        print("Страниц: " + String(self.page))
        Alamofire.request(
            .GET,
            "https://api.jqestate.ru/v1/properties/country",
            parameters: ["pagination[offset]": String(self.page * 32)],
            encoding: .URL)
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    print("Error while getting data: \(response.result.error)")
                    self.addingDataInProcess = false
                    return
                }
                
                guard let value = response.result.value as? [String: AnyObject],
                    rows = value["items"] as? NSMutableArray else {
                        print("Data receive fail")
                        self.addingDataInProcess = false
                        return
                }
                self.addData(rows)
                self.addingDataInProcess = false
        }
    }
    
    func addData(data: NSMutableArray) {
        for eachObject in data {
            self.tableData.addObject(eachObject)
        }
        self.appsTableView.reloadData()
    }

}

