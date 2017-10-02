//
//  Client.swift
//  ImmoApp
//
//  Created by etudiant on 2/10/17.
//  Copyright © 2017 etudiant. All rights reserved.
//


import UIKit
import RealmSwift

class Client: Object {
    dynamic var scanId = ""
    dynamic var status = ""
    dynamic var textScanResult:String?
    dynamic var classificationResult:String?
    dynamic var faceDetectionResult:String?
    dynamic var imageData: Data?
}
