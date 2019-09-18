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
    
    
    /// Takes an `MPMediaItem` and writes its `assetURL` to a temporary file
    ///
    /// - Parameters:
    ///   - mediaItem: The item to export
    ///   - completion: The URL the item was written to, if successful
    func export(_ mediaItem: MPMediaItem, completion: @escaping (URL?) -> ()) {
        guard let assetURL = mediaItem.assetURL else {
            completion(nil)
            return
        }
        let asset = AVURLAsset(url: assetURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return
        }
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(mediaItem.title ?? "Unknown title").appendingPathExtension("m4a")
        exporter.outputURL = fileURL
        exporter.outputFileType = AVFileType.m4a
        exporter.exportAsynchronously {
            if exporter.status == .completed {
                completion(fileURL)
            } else {
                if let error = exporter.error {
                    print(String(describing: error))
                }
                completion(nil)
            }
        }
    }
    
    @IBAction func uploadData(_ sender: UIButton) {
        /** see other properties of an MPMediaItem here: https://developer.apple.com/documentation/mediaplayer/mpmediaitem
        **/
        if let current = avMusicPlayer.nowPlayingItem, let title = current.title {
            self.export(current) { url in
                if let exportedURL = url, let data = try? Data(contentsOf: exportedURL) {
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
                                                   key: "protected/\(userCognitoId)/\(title).mp3",
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
        }
    }
    
 }
 
 
 

