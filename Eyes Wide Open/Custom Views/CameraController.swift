//
//  Camera.swift
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/18/21.
//

import AVFoundation
import Cocoa

class CameraController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: Class Parameters & Constants
    private let ANIM_KEY = "contents"
    private let CAMERA_FPS = 60;
    
    private var frame_counter = 0
    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoFormat = kCVPixelFormatType_32BGRA
    @IBOutlet var resultView: NSImageView!
    
    // Variable to determine if the image processing is performed using the GPU or the CPU
    private var _useGpu = false
    public var useGpu: Bool {
        get {
            _useGpu
        }
        set {
            _useGpu = newValue
        }
    }
    private var _resultImage = NSImage()
    var resultImage: NSImage {
        _resultImage
    }

    
    // MARK: Setup Methods
    private func setupCamera() {
        let device = AVCaptureDevice.default(for: .video)!
        let cameraInput = try!AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func setupVideoOutput() {
        self.videoOutput.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: videoFormat)
        ] as [String: Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ewo.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }
    
    private func setupResultView() {
        let layer = CALayer()
        layer.frame = self.resultView.bounds
        layer.contentsGravity = .center
        self.resultView.layer = layer
        self.resultView.wantsLayer = true
    }
    
    // MARK: View Lifecycle Methods
    override func viewWillLayout() {
        super.viewWillLayout()
        self.previewLayer.frame = self.view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.plugCamera()
        self.addPreviewLayer()
        self.setupVideoOutput()
        self.setupResultView()
        self.captureSession.startRunning()
    }
    override func viewWillDisappear() {
        self.turnOff()
    }
    
    // MARK: Camera Management Methods
    public func plugCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.setupCamera()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setupCamera()
                    }
                }
            default:
                return
        }
    }
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    
    private func addPreviewLayer() {
        self.view.layer = CALayer()
        self.view.wantsLayer = true
        self.view.layer!.addSublayer(self.previewLayer)
    }
    public func turnOff () {
        self.captureSession.stopRunning()
    }
    
    // MARK: Video Capture Methods
    private func loadResultImg(image: NSImage){
        let animation = CABasicAnimation(keyPath: self.ANIM_KEY)
        animation.duration = 0.25
        animation.fromValue = self.resultView.layer!.contents
        animation.toValue = image
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        self.resultView.layer!.add(animation, forKey: self.ANIM_KEY)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            debugPrint("Couldn't retrieve buffer image")
            return
        }
        self.handleFrame(frame: frame)
    }
    
    private func handleFrame(frame: CVImageBuffer) {
        // Lock the memory address for the buffer
        CVPixelBufferLockBaseAddress(frame, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(frame, CVPixelBufferLockFlags(rawValue: 0)) }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(frame)
        
        // Retrieve the buffer dimension
        let width = CVPixelBufferGetWidth(frame)
        let height = CVPixelBufferGetHeight(frame)
        
        // Get the pixel size in bytes
        let pxlsz = bytesPerRow/width;
        
        // Retrieve pointers to pixel buffer
        let pixel_raw_ptr = CVPixelBufferGetBaseAddress(frame)!
        let pixel_buf_ptr = UnsafeRawBufferPointer(start: pixel_raw_ptr, count: width * height * pxlsz)
        
        // Create pointer to result buffer
        let res_ptr = UnsafeMutableRawPointer.allocate(
            byteCount: width * height * pxlsz,
            alignment: MemoryLayout<UInt8>.alignment
        )
        defer { res_ptr.deallocate() }
        
        // Process pixel buffer
        inverseBGRA(src_ptr: pixel_buf_ptr, dst_ptr: res_ptr)
        
        // Create pointer for the modified pixel buffer
        let transformed_buff_ptr = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
        defer { transformed_buff_ptr.deallocate() }
        
        // Create modified pixel buffer from bytes
        CVPixelBufferCreateWithBytes(
            nil,
            width,
            height,
            videoFormat,
            res_ptr,
            bytesPerRow,
            { baseAddr, refCon  in
                guard let baseAddress = baseAddr else { return }
                free(UnsafeMutableRawPointer(mutating: baseAddress))
            },
            nil,
            nil,
            transformed_buff_ptr
        )
        
        // Convert the buffer into a displayable image
        let newFrame = CIImage(cvPixelBuffer: transformed_buff_ptr.pointee!)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(
            newFrame,
            from: CGRect(x: 0, y: 0, width: width, height: height)
        )!
        
        // Store the resulting new image
        self._resultImage = NSImage(
            cgImage: cgImage,
            size: CGSize(width: width, height: height)
        )
        DispatchQueue.main.async {
            self.loadResultImg(image: self._resultImage)
        }
        
    }
    
   
    
}


