//
//  HomeViewController.swift
//  RealTimeMaskDetection
//
//  Created by Sabuj's Macbook Pro on 04.11.22.
//

import UIKit
import AVFoundation


class HomeViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        configureUI()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func configureUI(){
        
        imageView.layer.borderWidth = 0.1
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.clipsToBounds = true
        
        
        //--Camera Button ---//
        cameraButton.layer.masksToBounds = false
        cameraButton.layer.cornerRadius = 8.0
        cameraButton.clipsToBounds = true
        
    }
    
    @IBAction func cameraButtonAction(){
        
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                DispatchQueue.main.async {
                    let detectionVC = DetectionViewController()
                    detectionVC.modalPresentationStyle = .fullScreen
                    self.present(detectionVC, animated: true)
                }
            } else {
              
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "Camera Permission Denied!", message: "Camera access is absolutely necessary to use this app", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }))
                   
                    self.present(alert, animated: true)
                }
                
               
            }
        }
        
    }
    
}


