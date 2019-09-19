//
//  artistProfileVC.swift
//  new_tbx
//
//  Created by SEVENHORNS ADMIN on 8/4/19.
//  Copyright © 2019 TraxBox, INC. All rights reserved.
//

import UIKit
import AWSCore
import AWSMobileClient
import AWSAppSync
import Photos

class artistProfileVC: UITableViewController,  UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
   
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var stageName: UITextField!
    
 
    @IBOutlet weak var genre: UITextField!
    @IBOutlet weak var hometown: UITextField!
    @IBOutlet weak var bio: UITextField!
    
    var imagePicker = UIImagePickerController()
    var userCognitoId = userAPI.getuserId
    var appSyncClient: AWSAppSyncClient?
//    var picker = UIImagePickerController()
    
     var _firstName: String?
    
    fileprivate let s3Service: S3Service = S3Service()
  

    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        _ = userCognitoId
      
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appSyncClient = appDelegate.appSyncClient
        
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(artistProfileVC.imageViewTapped(gesture:)))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = true
    }

    
    @objc func imageViewTapped(gesture: UIGestureRecognizer) {
        //gesture.view as? UIImageView
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancelled picking image")
        picker.dismiss(animated: true) {
            //nothing to do
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.image = chosenImage
        picker.dismiss(animated: true) {
            
        }
    }
    
 
  
    
    
    func runMutation(){
        
        let mutationInput = UpdateArtistProfileInput(id:"\(userCognitoId)", firstName: "\(firstName.text!)", lastName: "\(lastName.text!)", stageName: "\(stageName.text!)", bio:"\(bio.text!)", genre: "\(genre.text!)", hometown:"\(hometown.text!)")
        appSyncClient?.perform(mutation: UpdateArtistProfileMutation(input: mutationInput)) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
            }
            if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }
            print(result.debugDescription)
        }

    
    
    //        dismiss(animated: true, completion: nil)
    

        
}

    @IBAction func saveProfileTapped(_ sender: Any) {
        s3Service.uploadData(data: (profileImageView.image?.pngData()!)!)
        self.runMutation()
    }
   
    }

