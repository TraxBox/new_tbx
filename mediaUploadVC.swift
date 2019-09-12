 mediaUploadVC.swift
//  new_tbx
//
//  Created by SEVENHORNS ADMIN on 8/6/19.
//  Copyright © 2019 TraxBox, INC. All rights reserved.
//

import UIKit
import StoreKit
import AWSMobileClient
import AWSCognitoIdentityProvider
import AWSS3
import AWSAppSync
import MediaPlayer
import AVKit
import AVFoundation
import MediaAccessibility
import MediaToolbox

//protocol MPMediaPickerControllerDelegate{}

class mediaUploadVC: UITableViewController, UINavigationControllerDelegate, MPMediaPickerControllerDelegate{

    fileprivate let BUCKETNAME = "newtbxbkt-newtbxeniv"
    

    var avMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    var mpMediapicker: MPMediaPickerController!

    var mediaItems = [MPMediaItem]()
   


    
//    var myMediaPlayer = MPMusicPlayerController.systemMusicPlayer
    
    fileprivate let s3Service: S3Service = S3Service()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

  
 
    @IBAction func pickSongBtn(_ sender: UIView) {

          mpMediapicker  = MPMediaPickerController.self(mediaTypes:MPMediaType.music)
          mpMediapicker .allowsPickingMultipleItems = false
          mpMediapicker .popoverPresentationController?.sourceView = sender as? UIView
          mpMediapicker .delegate = self
 
        self.present(mpMediapicker , animated: true, completion: nil)
        
//         avMusicPlayer.play()

    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        avMusicPlayer.setQueue(with: mediaItemCollection)
        mediaPicker.dismiss(animated: true, completion: nil)
        
        avMusicPlayer.play()
        //        print("you picked: \(MPMediaItemCollection())")
        
    }

        
    @IBAction func uploadData(_ data: UIButton) {
        //        let data: Data = Data() // Data to be uploaded
        let fileURL: URL = URL(fileURLWithPath: "")
        
        if let data = try? Data(contentsOf: fileURL){
//        if (try? Data(contentsOf: fileURL)) != nil {
            // now you have the data
        }
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                
                print("upload in progress")
                // Do something e.g. Update a progress bar.
            })
        }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if let _ = error {
                    print ("There was an error uploading files... \(error.debugDescription)")
                    print ("Let us check response \(String(describing: task.response?.allHeaderFields))")
                    print ("Let us check response \(String(describing: task.response?.debugDescription))")
                } else {
                    print("Completed uploading file...")
                }
            })
        }
        userAPI.getuserId { (userCognitoId) in
            let transferUtility = AWSS3TransferUtility.default()
            
            transferUtility.uploadData(data as! Data,
                                       bucket: self.BUCKETNAME,
                                       key: "protected/\(userCognitoId)/song1.mp3",
                contentType: "audio/mp3",
                expression: expression,
                completionHandler: completionHandler).continueWith {
                    (task) -> AnyObject? in
                    if let error = task.error {
                        print("Error: \(error.localizedDescription)")
                    }
                    
                    if let _ = task.result {
                        // Do something with uploadTask.
                    }
                    return nil;
            }
        }
    }
    
}

    

