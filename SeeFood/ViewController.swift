//
//  ViewController.swift
//  SeeFood
//
//  Created by Tony Nlemadim on 3/25/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage



class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate { // pickerview needs nav controller
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    

    override func viewDidLoad() {
        super.viewDidLoad()
       
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false // true to enable editing
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {// .edited for cropable pics
            
            imageView.image = userPickedImage
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to ciImage")
            }
            
            detect(image: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
       
        
    }
    
    
    //MARK:- Method for classifying the ML Image
    
    
    func detect(image: CIImage) {
        
//        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
//            fatalError("Loading CoreML model failed")- deprecated!!!!!
//        }
        
        // OR
//
//        guard let seeFoodModel = try? Inceptionv3(configuration: .init()).model,
//              let model = try? VNCoreMLModel(for: seeFoodModel) else {
//            fatalError("Loading CoreML Model failed") - This Works too!!
//        }
        
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: Inceptionv3.urlOfModelInThisBundle)) else {
            fatalError("can't load ML model") // - loads up the model
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")// creates a request to classify data
            }
            
            if let firstResult = results.first {// Actions taken with results based on most confident model rating.
                if firstResult.identifier.contains("hotdog") {
                    self.navigationItem.title = "Hotdog!!"
                } else {
                    self.navigationItem.title = "Not a hotdog!"
                    self.requestInfo(flowerName: firstResult.identifier)
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)// handler comp[letes request.
        
        do {
            
        try handler.perform([request])
        
        }
        
        catch {
            
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize" : "500"
          ]

        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got wiki info")
                print(response)
                
                let flowerJSON : JSON = JSON(response.value!)// store value of request
                
                let pageid = flowerJSON["query"]["pageid"][0].stringValue// store the value of pageid in order to use it to go down the tree to get to extract; for description.
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                print(flowerDescription)
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue // save parameter down the tree for image url
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
//                self.label.text = flowerDescription// to display info on a custom label
            }
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    


}

