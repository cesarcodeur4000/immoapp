//
//  ScanViewController.swift
//  ImmoApp
//
//  Created by etudiant on 2/10/17.
//  Copyright © 2017 etudiant. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController, UIImagePickerControllerDelegate {

    
    //MARK:= UI Elements
    let userImage           = UIImageView()
    let resultsTextView     = UITextView()
    let statusTextLabel     = UILabel()
    let scanButton          = UIButton()
    let resetButton         = UIButton()
    
    var imageLoaded = false
    let backgroundImage = UIImage(named: "TakePhotoButton@3x")
    //MARK:=Realm variables
    var realm: Realm?
    var currentScan: Scan?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewAndConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: View Setup and management
    func setupViewAndConstraints() {
        let allViews: [String : Any] = ["userImage": userImage, "resultsTextView": resultsTextView, "statusTextLabel": statusTextLabel, "scanButton": scanButton, "resetButton": resetButton]
        var allConstraints = [NSLayoutConstraint]()
        let metrics = ["imageHeight": self.view.bounds.width, "borderWidth": 10.0]
        
        // all of our views are created by hand when the controller loads;
        // make sure they are subviews of this ViewController, else they won't show up,
        allViews.forEach { (k,v) in
            self.view.addSubview(v as! UIView)
        }
        
        // an ImageView that will hold an image from the camers or photo library
        userImage.translatesAutoresizingMaskIntoConstraints = false
        userImage.contentMode = .scaleAspectFit
        userImage.isHidden = false
        userImage.isUserInteractionEnabled = false
        userImage.backgroundColor = .lightGray
        // a label to hold text (if any) found by the OCR service
        resultsTextView.translatesAutoresizingMaskIntoConstraints = false
        resultsTextView.isHidden = false
        resultsTextView.alpha = 0.75
        resultsTextView.isScrollEnabled = true
        resultsTextView.showsVerticalScrollIndicator = true
        resultsTextView.showsHorizontalScrollIndicator = true
        resultsTextView.textColor = .black
        resultsTextView.text = ""
        resultsTextView.textAlignment  = .left
        resultsTextView.layer.borderWidth = 0.5
        resultsTextView.layer.borderColor = UIColor.lightGray.cgColor
        // the status label showing the state of the backend ROS Event service or OCR API status
        statusTextLabel.translatesAutoresizingMaskIntoConstraints = false
        statusTextLabel.backgroundColor = .clear
        statusTextLabel.isEnabled = true
        statusTextLabel.textAlignment = .center
        statusTextLabel.text = ""
        // Button that starts the scan
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.backgroundColor = .darkGray
        scanButton.isEnabled = true
        scanButton.setTitle(NSLocalizedString("Tap to select an image...", comment: "select img"), for: .normal)
        
        scanButton.addTarget(self, action:  #selector(selectImagePressed(sender:)), for: .touchUpInside)
        // Button to reset and pick a new image
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.backgroundColor = .purple
        resetButton.isEnabled = true
        resetButton.setTitle(NSLocalizedString("Reset", comment: "reset"), for: .normal)
        resetButton.addTarget(self, action:  #selector(resetButtonPressed(sender:)), for: .touchUpInside)
        
        // Set up all the placement & constraints for the elements in this view
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let verticalConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-[userImage(imageHeight)]-[resultsTextView(>=100)]-[statusTextLabel(21)]-[scanButton(50)]-[resetButton(50)]-(borderWidth)-|",
            options: [], metrics: metrics, views: allViews)
        allConstraints += verticalConstraints
        
        let userImageHConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[userImage]|",
            options: [],
            metrics: metrics,
            views: allViews)
        allConstraints += userImageHConstraint
        
        let resultsTextViewHConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-[resultsTextView]-|", options: [],
            metrics: metrics, views: allViews)
        allConstraints += resultsTextViewHConstraint
        
        let statusTextlabelHConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-[statusTextLabel]-|",
            options: [],
            metrics: metrics,
            views: allViews)
        allConstraints += statusTextlabelHConstraint
        
        let scanButtonHConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-[scanButton]-|",
            options: [],
            metrics: metrics,
            views: allViews)
        allConstraints += scanButtonHConstraint
        
        let resetButtonHConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-[resetButton]-|",
            options: [],
            metrics: metrics,
            views: allViews)
        allConstraints += resetButtonHConstraint
        
        
        self.view.addConstraints(allConstraints)
    }
    
    
    func updateImage(_ image: UIImage?) {
        DispatchQueue.main.async( execute: {
            self.userImage.image = image
            self.imageLoaded = true
        })
    }
    
    func updateUI(shouldReset: Bool = false){
        DispatchQueue.main.async( execute: {
            if (shouldReset == true && self.imageLoaded == true) || self.imageLoaded == false {
                // here if just launched or the user has reset the app
                self.userImage.image = self.backgroundImage
                self.imageLoaded = false
            } else {
                // just update the UI with whatever we've got from the back end for the last scan
                self.statusTextLabel.text = self.currentScan?.status
                // NB: there's a chance that the currentScan has been nil'd out by a user reset;
                // in this case just srt the text label to empty, otherwise we'll crash on a nil dereferrence
                self.resultsTextView.text = [self.currentScan?.classificationResult, self.currentScan?.faceDetectionResult, self.currentScan?.textScanResult]
                    .flatMap({$0}).joined(separator:"\n\n")
            }
        })
    }
    
    
    //MARK:- Realm Interactions
    func submitImageToRealm() {
        SyncUser.logIn(with: .usernamePassword(username: "ds@realm.io", password: "cinnabar21"), server: URL(string: "http://\(kRealmObjectServerHost)")!, onCompletion: {
            user, error in
            DispatchQueue.main.async {
                guard let user = user else {
                    let alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: error?.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: "Try Again"), style: .default, handler: { (action) in
                        self.submitImageToRealm()
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
                    
                    self.updateUI(shouldReset: true)
                    
                    self.present(alertController, animated: true)
                    return
                }
                
                // Open Realm
                let configuration =  Realm.Configuration(
                    syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://\(kRealmObjectServerHost)/~/scanner")!))
                self.realm = try! Realm(configuration: configuration)
                
                // Prepare the scan object
                self.prepareToScan()
                self.currentScan?.imageData = self.userImage.image!.data()
                self.saveScan()
            }
        })
    }
    
    func beginImageLookup() {
        updateResetButton()
        submitImageToRealm()
    }
    
    func prepareToScan() {
        if let realm = currentScan?.realm {
            try! realm.write {
                realm.delete(currentScan!)
            }
        }
        
        currentScan = Scan()
    }
    
    
    
    func saveScan() {
        guard currentScan?.realm == nil else {
            return
        }
        
        statusTextLabel.text = "Saving..."
        
        try! realm?.write {
            realm?.add(currentScan!)
            currentScan?.status = Status.Uploading.rawValue
        }
        
        statusTextLabel.text = "Uploading..."
        
        self.currentScan?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "status" && change?[NSKeyValueChangeKey.newKey] != nil else {
            return
        }
        
        let currentStatus = Status(rawValue: change?[NSKeyValueChangeKey.newKey] as! String)!
        switch currentStatus {
        case .ClassificationResultReady, .TextScanResultReady, .FaceDetectionResultReady:
            self.updateUI()
            self.updateResetButton()
            
            try! self.currentScan?.realm?.write {
                self.currentScan?.status = Status.Completed.rawValue
            }
            
        case .Failed:
            self.updateUI()
            
            try! self.currentScan?.realm?.write {
                realm?.delete(self.currentScan!)
            }
            self.currentScan = nil
            
        case .Processing, .Completed:
            self.updateUI()
            
        default: return
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
