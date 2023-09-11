import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var scannedQRCodeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            videoInput = try AVCaptureDeviceInput(device: captureDevice)
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Set the input device on the capture session.
        captureSession.addInput(videoInput)
        
        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        
        // Set self as the delegate for metadata output and use the default dispatch queue to execute the callback
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [.qr]
        
        // Initialize the video preview layer and add it as a sublayer to the view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Create a label to display the scanned QR code value
        scannedQRCodeLabel = UILabel(frame: CGRect(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100))
        scannedQRCodeLabel.textAlignment = .center
        scannedQRCodeLabel.textColor = UIColor.white
        scannedQRCodeLabel.font = UIFont.systemFont(ofSize: 18)
        scannedQRCodeLabel.numberOfLines = 0
        view.addSubview(scannedQRCodeLabel)
        
        // Create a view to represent the border around the QR code
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView!)
        
        // Start video capture.
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    // AVCaptureMetadataOutputObjectsDelegate method to handle detected metadata (QR codes)
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            if let qrCodeValue = metadataObject.stringValue {
                // Display the scanned QR code value in the label
                scannedQRCodeLabel.text = qrCodeValue
                
                // Highlight the QR code with a green border
                if let objectRect = videoPreviewLayer?.transformedMetadataObject(for: metadataObject)?.bounds {
                    qrCodeFrameView?.frame = objectRect
                }
                
                // Check if the scanned value is a valid URL
                if let url = URL(string: qrCodeValue), UIApplication.shared.canOpenURL(url) {
                    // It's a valid URL, show a popup to open it
                    let alertController = UIAlertController(title: "Open URL", message: "Do you want to open this URL?", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    let openAction = UIAlertAction(title: "Open", style: .default) { (_) in
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                    
                    alertController.addAction(cancelAction)
                    alertController.addAction(openAction)
                    
                    present(alertController, animated: true, completion: nil)
                }
                
                // You can perform further actions with the QR code value here if needed
            }
        }
    }
}
