//
//  DetectionViewController.swift
//  RealTimeMaskDetection
//
//  Created by Sabuj's Macbook Pro on 04.11.22.
//

import UIKit
import AVFoundation

class DetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var player: AVAudioPlayer = AVAudioPlayer()
    
    let titleLabel: UILabel = UILabel()
    
    let backTitleLabel: UILabel =  UILabel()
    let backButton: UIButton =  UIButton()
    
    let switchTitleLabel: UILabel =  UILabel()
    let switchButton: UISwitch =  UISwitch()
    
    
    
    // Change this to .back to use the back camera:
    let camera: AVCaptureDevice.Position = .front
    
    let maxFaces = 8
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    let sessionQueue = DispatchQueue(label: "capture_session")
    let detectionQueue = DispatchQueue(label: "detection", qos: .userInitiated,
                                       attributes: [], autoreleaseFrequency: .workItem)
    let previewView = PreviewView()
    var boxes: [BoundingBox] = []
    var detector: MaskDetectionVideoHelper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detector = MaskDetectionVideoHelper(maskDetector: MaskDetector(maxResults: maxFaces))
        view.backgroundColor = .white
        
        //---Setup Player---//
        setupPlayer()
        
        
        //--Title Label ---//
        titleLabel.textAlignment = .center
        titleLabel.textColor = .systemOrange
        titleLabel.text = "Real Time Camera Detection"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        
        //--Back Button ---//
        
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        
        backTitleLabel.text = "Close Camera"
        backTitleLabel.textAlignment = .center
        backTitleLabel.textColor = .systemOrange
        
        
        //--- Switch---//
        switchButton.isOn = false
        switchButton.onTintColor = .systemOrange
        switchButton.addTarget(self, action: #selector(switchButtonAction), for: .valueChanged)
        
        switchTitleLabel.text = "Sound Alert"
        switchTitleLabel.textAlignment = .center
        switchTitleLabel.textColor = .systemOrange
        
        
        
        configureCaptureSession()
        configureUI()
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCaptureSession()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput buffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if let results = try? detector.detectInFrame(buffer) {
            DispatchQueue.main.async {
                self.showResults(results)
            }
        }
    }
    
    // MARK: UI
    
    private func configureUI() {
        view.addSubview(previewView)
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(switchButton)
        
        view.addSubview(backTitleLabel)
        view.addSubview(switchTitleLabel)
        
        
        
        titleLabel.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(60)
            make.leading.equalTo((UIScreen.main.bounds.width - 300)/2.0)
            make.top.equalTo(80)
        }
        
        
        backButton.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(UIScreen.main.bounds.width - 40 - 40)
            make.bottom.equalTo(-80)
        }
        
        backTitleLabel.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(20)
            make.leading.equalTo(UIScreen.main.bounds.width - 120 - 10)
            make.bottom.equalTo(-50)
        }
        
        
        switchButton.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(40)
            make.bottom.equalTo(-80)
        }
        
        switchTitleLabel.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(20)
            make.leading.equalTo(10)
            make.bottom.equalTo(-50)
        }
        
        previewView.previewLayer.session = session
        for _ in 0..<maxFaces {
            let box = BoundingBox()
            boxes.append(box)
            box.addToLayer(previewView.previewLayer)
        }
        previewView.snp.makeConstraints { make in
            make.center.leading.trailing.equalToSuperview()
            make.height.equalTo(previewView.snp.width).multipliedBy(4.0 / 3.0)
        }
        
        
    }
    
    private func showResults(_ results: [MaskDetector.Result]) {
        for i in 0..<boxes.count {
            if i < results.count {
                let frame = previewView.toViewCoords(results[i].bound, mirrored: camera == .front)
                let label = results[i].status == .mask ? "Mask" : "No Mask"
                boxes[i].show(frame: frame,
                              label: "\(label) \(String(format: "%.2f", results[i].confidence))",
                              color: results[i].status == .mask ? .systemGreen : .red)
                
                if results[i].status == .mask {
                    player.volume = 0.0
                }else{
                    
                    if switchButton.isOn{
                        player.volume = 1.0
                    }else{
                        player.volume = 0.0
                    }
                }
                
            } else {
                boxes[i].hide()
            }
        }
    }
    
    // MARK: Camera
    
    private func configureCaptureSession() {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: camera) else {
            print("Failed to acquire camera")
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to create AVCaptureDeviceInput")
            return
        }
        output.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        output.connection(with: .video)?.videoOrientation = .portrait
        session.commitConfiguration()
        output.setSampleBufferDelegate(self, queue: detectionQueue)
    }
    
    private func startCaptureSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    private func stopCaptureSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    
    @objc func backButtonAction(){
        self.dismiss(animated: true)
    }
    
    @objc func switchButtonAction(switch: UISwitch){
        
        print(switchButton.isOn)
    }
    
    func setupPlayer(){
        if let bundle = Bundle.main.path(forResource: "alert", ofType: "mp3") {
            let backgroundMusic = NSURL(fileURLWithPath: bundle)
            do {
                player = try AVAudioPlayer(contentsOf:backgroundMusic as URL)
                player.numberOfLoops = -1
                player.prepareToPlay()
                player.play()
                player.volume = 0.0
            } catch {
                print(error)
            }
        }
    }
    
}


