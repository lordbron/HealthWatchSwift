//
//  ViewController.swift
//  HealthWatchSwift
//
//  Created by Melissa Nierle on 8/16/15.
//  Copyright (c) 2015 Melissa Nierle. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    var appHealthStore: HKHealthStore?
    
    var tableViewControllerWithSources = DataTableViewController()
    var tableViewControllerWithHeartRates = DataTableViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        prepareForHealthKit()
        view.addSubview(healthKitStatusLabel)
        view.addSubview(requestHealthKitAccessButton)
        view.addSubview(dataLabel)
        view.addSubview(listAllSources)
        view.addSubview(listHeartRates)
        
        view.backgroundColor = UIColor.whiteColor()
        
        let views = ["statusLabel": healthKitStatusLabel, "requestAccessButton": requestHealthKitAccessButton, "dataLabel": dataLabel, "listAllSources": listAllSources, "listHeartRates": listHeartRates]
        
        let metrics = ["Padding": 8.0, "Margin": 16.0]
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(80.0)-[statusLabel]-(Padding)-[requestAccessButton]-(Margin)-[dataLabel]-(Padding)-[listAllSources]-(Padding)-[listHeartRates]", options: nil, metrics: metrics, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(Margin)-[statusLabel]-(>=Margin)-|", options: nil, metrics: metrics, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(Margin)-[requestAccessButton]-(>=Margin)-|", options: nil, metrics: metrics, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(Margin)-[dataLabel]-(>=Margin)-|", options: nil, metrics: metrics, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(Margin)-[listAllSources]-(>=Margin)-|", options: nil, metrics: metrics, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(Margin)-[listHeartRates]-(>=Margin)-|", options: nil, metrics: metrics, views: views))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //====================================================================
    // MARK: Health Kit
    //====================================================================
    
    func prepareForHealthKit() {
        
        if !HKHealthStore.isHealthDataAvailable() {
            requestHealthKitAccessButton.hidden = true
            healthKitStatusLabel.text = "HealthKit Not available"
            
            return
        }
        appHealthStore = HKHealthStore()
        
        let heartRateIdentifier = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        
        if appHealthStore?.authorizationStatusForType(heartRateIdentifier) == HKAuthorizationStatus.SharingAuthorized {
            healthKitStatusLabel.text = "HealthKit Heart Rate Data Available"
            requestHealthKitAccessButton.hidden = true
        }
    }
    
    func getAllSources() -> [String] {
        
        var sourceNames: [String] = []
        
        let sampleType: HKSampleType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let query = HKSourceQuery(sampleType: sampleType, samplePredicate: nil) { (query, sources, error) -> Void in
            
            if error != nil {
                println("Error Occurred, this needs to be handled.")
                return
            }
            
            for source in sources {
                if let source = source as? HKSource {
                    sourceNames.append(source.name)
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableViewControllerWithSources.tableData = sourceNames
                self.tableViewControllerWithSources.tableView?.reloadData()
            })
    
            println(sourceNames)
        }
        println(sourceNames)
        
        appHealthStore?.executeQuery(query)
        return sourceNames
    }

    func getHeartRates() -> [String] {
        var heartRates: [String] = []
        
        let sampleType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sortDescriptors = [sort]
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 100, sortDescriptors: sortDescriptors) { (query, results, error) -> Void in
            
            if error != nil {
                println("error occurred, this needs to be handled")
                return
            }
            
            for sample in results {
                    var bpm = HKUnit(fromString: "count/min")
                    let quanity = sample.quantity
                
                if let bpmHR = quanity?.doubleValueForUnit(bpm) {
                    heartRates.append(String(stringInterpolationSegment: bpmHR))
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableViewControllerWithHeartRates.tableData = heartRates
                self.tableViewControllerWithHeartRates.tableView?.reloadData()
            })
        }
        
        appHealthStore?.executeQuery(query)
        return heartRates
    }
    
    //====================================================================
    // MARK: Actions
    //====================================================================
    
    func handleRequestHealthKitAccess(sender: UIButton) {
            println("handleRequestHealthKitAccess called")
      
        let healthKitTypesToRead = Set(arrayLiteral:
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
            )
        
        
        let healthKitTypesToWrite = Set(arrayLiteral:
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
            )
        
        appHealthStore?.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead, completion: { (success, error) -> Void in
            if success {
                self.healthKitStatusLabel.text = "Health Kit Heart Rate Data Accessible"
                self.requestHealthKitAccessButton.hidden = true
            } else {
                self.requestHealthKitAccessButton.hidden = false
                self.healthKitStatusLabel.text = "Health Kit Authorization Request Failed"
            }
        })
        
    }
    
    func handleListAllSourcesButton(sender: UIButton) {
        println("push UITableView viewcontroller with healthKit Sources")
        
        navigationController?.pushViewController(tableViewControllerWithSources, animated: true)
        println(getAllSources())
    }

    func handleListHeartRatesButton(sender: UIButton) {
        println("push UITableView viewController with heart rates datasource")
    
        navigationController?.pushViewController(tableViewControllerWithHeartRates, animated: true)
        println(getHeartRates())
    }
    
    //====================================================================
    // MARK: Views
    //====================================================================
    lazy var healthKitStatusLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.text = "Unknown"
        label.font = UIFont.systemFontOfSize(14.0)
        return label
        }()
    
    lazy var dataLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.text = "Health Kit Data:"
        label.font = UIFont.systemFontOfSize(14.0)
        return label
        }()
    
    lazy var listAllSources: UIButton = {
        let button = UIButton(frame: CGRectZero)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setTitle("All Heart Rate Sources", forState: UIControlState.Normal)
        button.addTarget(self, action: "handleListAllSourcesButton:", forControlEvents: UIControlEvents.TouchUpInside)
        button.backgroundColor = UIColor.lightGrayColor()
        
        return button
        }()
    
    lazy var listHeartRates: UIButton = {
        let button = UIButton(frame: CGRectZero)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setTitle("Recent Heart Rate Samples", forState: UIControlState.Normal)
        button.addTarget(self, action: "handleListHeartRatesButton:", forControlEvents: UIControlEvents.TouchUpInside)
        button.backgroundColor = UIColor.lightGrayColor()
        
        return button
        }()
    
    lazy var requestHealthKitAccessButton: UIButton = {
        let button = UIButton(frame: CGRectZero)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setTitle("Request Access from HealthKit", forState: UIControlState.Normal)
        button.addTarget(self, action: "handleRequestHealthKitAccess:", forControlEvents: UIControlEvents.TouchUpInside)
        button.backgroundColor = UIColor.lightGrayColor()
        
        return button
        }()
    
}

