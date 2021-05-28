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
    private var resultImageBuffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
    @IBOutlet var resultView: NSImageView!
    @IBOutlet var gpuSwitch: NSSwitch!
    @IBOutlet var filterDropdown: NSComboBox!
    
    // Variable to determine if the image processing is performed using the GPU or the CPU
    public var useGpu: Bool {
        get {
            DispatchQueue.main.sync {
                gpuSwitch.state.rawValue != 0
            }
        }
    }
    private var _resultImage = NSImage()
    var resultImage: NSImage {
        _resultImage
    }

    // MARK: Metal Functions Lazy Declarations
    private lazy var metalInverse: MetalSIFunction = {
        return MetalSIFunction(
            functionName: "inverse",
            gridWidth: 1024,
            blockWidth: 1024
        )
    }()
    
    private lazy var metalOrig: MetalSIFunction = {
        return MetalSIFunction(
            functionName: "original",
            gridWidth: 1024,
            blockWidth: 1024
        )
    }()
    
    private lazy var metalRed: MetalSIFunction = {
        return MetalSIFunction(
            functionName: "red_channel",
            gridWidth: 1024,
            blockWidth: 1024
        )
    }()
    
    private lazy var metalGreen: MetalSIFunction = {
        return MetalSIFunction(
            functionName: "green_channel",
            gridWidth: 1024,
            blockWidth: 1024
        )
    }()
    
    private lazy var metalBlue: MetalSIFunction = {
        return MetalSIFunction(
            functionName: "blue_channel",
            gridWidth: 1024,
            blockWidth: 1024
        )
    }()
    
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
        let pxlsz = bytesPerRow/width
        
        // Calculate the total amount of bytes
        let totalBytes = width * height * pxlsz
        
        // Retrieve pointers to pixel buffer
        let pixel_raw_ptr = CVPixelBufferGetBaseAddress(frame)!
        let pixel_buf_ptr = UnsafeMutableRawBufferPointer(start: pixel_raw_ptr, count: totalBytes)
        
        // Create pointer to result buffer
        var res_ptr: UnsafeMutableRawPointer!
        
        var filterType = "Original"
        DispatchQueue.main.sync {
            filterType = filterDropdown.stringValue
        }
        
        if (useGpu) {
            switch filterType {
            case "Inverse":
                res_ptr = metalInverse.run(
                    src_ptr: pixel_buf_ptr.baseAddress!,
                    src_sz: totalBytes,
                    problem_sz: totalBytes
                )!
            case "Red Channel":
                res_ptr = metalRed.run(
                    src_ptr: pixel_buf_ptr.baseAddress!,
                    src_sz: totalBytes,
                    problem_sz: totalBytes
                )!
            case "Green Channel":
                res_ptr = metalGreen.run(
                    src_ptr: pixel_buf_ptr.baseAddress!,
                    src_sz: totalBytes,
                    problem_sz: totalBytes
                )!
            case "Blue Channel":
                res_ptr = metalBlue.run(
                    src_ptr: pixel_buf_ptr.baseAddress!,
                    src_sz: totalBytes,
                    problem_sz: totalBytes
                )!
            default:
                // Apply no filters
                res_ptr = metalOrig.run(
                    src_ptr: pixel_buf_ptr.baseAddress!,
                    src_sz: totalBytes,
                    problem_sz: totalBytes
                )!
            }
        } else {
            // Process pixel buffer
            res_ptr = UnsafeMutableRawPointer.allocate(
                byteCount: totalBytes,
                alignment: MemoryLayout<UInt8>.alignment
            )
            defer { res_ptr.deallocate() }
            switch filterType {
            case "Inverse":
                inverseBGRA(src_ptr: pixel_buf_ptr, dst_ptr: res_ptr)
            case "Red Channel":
                redChannelBGRA(src_ptr: pixel_buf_ptr, dst_ptr: res_ptr)
            case "Green Channel":
                greenChannelBGRA(src_ptr: pixel_buf_ptr, dst_ptr: res_ptr)
            case "Blue Channel":
                blueChannelBGRA(src_ptr: pixel_buf_ptr, dst_ptr: res_ptr)
            default:
                originalBGRA(src_ptr: pixel_buf_ptr, dst_ptr: res_ptr)
            }
            
        }
        
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
                guard let ref = refCon else { return }
                free(UnsafeMutableRawPointer(mutating: ref))
            },
            resultImageBuffer,
            nil,
            resultImageBuffer
        )
        
        // Convert the buffer into a displayable image
        let newFrame = CIImage(cvPixelBuffer: resultImageBuffer.pointee!)
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
        DispatchQueue.main.sync {
//            self.loadResultImg(image: self._resultImage)
            self.resultView.layer!.contents = self._resultImage
        }
        Thread.sleep(forTimeInterval: TimeInterval(1/CAMERA_FPS))
    }
    
   
    
}


