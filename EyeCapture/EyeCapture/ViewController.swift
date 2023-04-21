//
//  ViewController.swift
//  EyeCapture
//
//  Created by Noah Nethery on 4/20/23.
//

import UIKit
import ARKit
import WebKit
import CoreData

class ViewController: UIViewController, ARSessionDelegate {
    
    var session: ARSession!
    var webView: WKWebView!
    var managedObjectContext: NSManagedObjectContext!
    var isSessionRunning: Bool = false
    var content: [String] = []
    var contentType: String = ""
    
    private var eyeDataBatch: [EyeData] = []
    private let batchSize = 300
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        content = readStringsFromJSON() ?? []
        
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        view = UIView()
        view.backgroundColor = .white
        
        // Create webView
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // Create toggle ARSession button
        let toggleARSessionButton = UIButton(type: .system)
        toggleARSessionButton.setTitle("Toggle ARSession", for: .normal)
        toggleARSessionButton.addTarget(self, action: #selector(toggleSession), for: .touchUpInside)
        toggleARSessionButton.backgroundColor = .blue
        toggleARSessionButton.setTitleColor(.white, for: .normal)
        toggleARSessionButton.layer.cornerRadius = 8
        toggleARSessionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleARSessionButton)
        
        // Create export button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export Data", for: .normal)
        exportButton.addTarget(self, action: #selector(exportEyeDataToCSV), for: .touchUpInside)
        exportButton.backgroundColor = .green
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 8
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportButton)
        
        // Create dropdown button
        let dropdownButton = UIButton(type: .system)
        dropdownButton.setTitle("Select Content", for: .normal)
        dropdownButton.addTarget(self, action: #selector(showDropdownMenu), for: .touchUpInside)
        dropdownButton.backgroundColor = .gray
        dropdownButton.setTitleColor(.white, for: .normal)
        dropdownButton.layer.cornerRadius = 8
        dropdownButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dropdownButton)
        
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // WebView constraints
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toggleARSessionButton.topAnchor),
            
            // Dropdown button constraints
            dropdownButton.leadingAnchor.constraint(equalTo: toggleARSessionButton.trailingAnchor, constant: 8),
            dropdownButton.trailingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: -8),
            dropdownButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            
            // Toggle ARSession button constraints
            toggleARSessionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            toggleARSessionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            // Export button constraints
            exportButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            // Buttons equal width constraint
            toggleARSessionButton.widthAnchor.constraint(equalTo: exportButton.widthAnchor)
        ])
        
        session = ARSession()
        session.delegate = self
        
        // Enable face tracking configuration
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device")
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the AR session when the view disappears
        session.pause()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let faceAnchor = anchor as? ARFaceAnchor else { continue }
            
            let leftEyePosition = faceAnchor.leftEyeTransform.columns.3
            let rightEyePosition = faceAnchor.rightEyeTransform.columns.3
            
            
            saveEyeData(leftEye: leftEyePosition, rightEye: rightEyePosition, lookAtPoint: faceAnchor.lookAtPoint, timestamp: session.currentFrame?.timestamp ?? 0)
            
            
        }
    }
    
    @objc func showDropdownMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Add actions for each menu item
        let option1Action = UIAlertAction(title: "Text", style: .default) { _ in
            self.contentType = "Text"
            if let url = URL(string: self.content[0]) {
                let request = URLRequest(url: url)
                self.webView.load(request)
            }
        }
        alertController.addAction(option1Action)
        
        let option2Action = UIAlertAction(title: "Video", style: .default) { _ in
            self.contentType = "Video"
            if let url = URL(string: self.content[1]) {
                let request = URLRequest(url: url)
                self.webView.load(request)
            }
        }
        alertController.addAction(option2Action)
        
        let option3Action = UIAlertAction(title: "Game", style: .default) { _ in
            self.contentType = "Game"
            if let url = URL(string: self.content[2]) {
                let request = URLRequest(url: url)
                self.webView.load(request)
            }
        }
        alertController.addAction(option3Action)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // Present the action sheet
        present(alertController, animated: true, completion: nil)
    }
    
    
    @objc func toggleSession() {
        if isSessionRunning {
            session.pause()
            isSessionRunning = false
        } else {
            let configuration = ARFaceTrackingConfiguration()
            session.run(configuration, options: [])
            isSessionRunning = true
        }
    }
    
    func saveEyeData(leftEye: simd_float4, rightEye: simd_float4, lookAtPoint: simd_float3, timestamp: Double) {
        // Create a new EyeData object
        let eyeData = EyeData(context: managedObjectContext)
        
        eyeData.timestamp = timestamp
        eyeData.leftEyeX = Double(leftEye.x)
        eyeData.leftEyeY = Double(leftEye.y)
        eyeData.leftEyeZ = Double(leftEye.z)
        eyeData.rightEyeX = Double(rightEye.x)
        eyeData.rightEyeY = Double(rightEye.y)
        eyeData.rightEyeZ = Double(rightEye.z)
        eyeData.lookAtPointX = Double(lookAtPoint.x)
        eyeData.lookAtPointY = Double(lookAtPoint.y)
        eyeData.lookAtPointZ = Double(lookAtPoint.z)
        
        eyeData.content = contentType
        
        eyeDataBatch.append(eyeData)
        
        if eyeDataBatch.count >= batchSize {
            saveBatchedEyeData()
        }
    }
    
    func saveBatchedEyeData() {
        managedObjectContext.perform {
            do {
                try self.managedObjectContext.save()
                self.eyeDataBatch.removeAll()
            } catch {
                print("Error saving eye data batch: \(error)")
            }
        }
    }
    
    @objc func exportEyeDataToCSV() {
        let fetchRequest: NSFetchRequest<EyeData> = EyeData.fetchRequest()
        
        do {
            let spinner = showLoadingSpinner()
            
            let results = try managedObjectContext.fetch(fetchRequest)
            
            // Create a CSV string from the fetched data
            var csvString = "timestamp,leftEyeX,leftEyeY,leftEyeZ,rightEyeX,rightEyeY,rightEyeZ,lookAtPointX,lookAtPointY,lookAtPointZ,content\n"
            for eyeData in results {
                let rowString = "\(eyeData.timestamp),\(eyeData.leftEyeX),\(eyeData.leftEyeY),\(eyeData.leftEyeZ),\(eyeData.rightEyeX),\(eyeData.rightEyeY),\(eyeData.rightEyeZ),\(eyeData.lookAtPointX),\(eyeData.lookAtPointY),\(eyeData.lookAtPointZ),\(eyeData.content ?? "")\n"
                csvString.append(rowString)
            }
            
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            
            // Configure the dateFormatter
            dateFormatter.dateFormat = "yyyyMMdd-HHmmss" // Customize the format as needed
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            // Create the filename string
            let filename = "eye_data_" + dateFormatter.string(from: currentDate) + ".csv"
            
            // Save CSV string to a file in the app's Documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            self.hideLoadingSpinner(spinner)
            
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                print("Activity view controller dismissed")
                
                self.presentYesNoAlert(
                    from: self,
                    title: "Confirmation",
                    message: "Clear the database?",
                    yesHandler: {
                        self.deleteAllRecords(of: "EyeData", in: self.managedObjectContext)
                    },
                    noHandler: {}
                )
            }
            
            present(activityViewController, animated: true, completion: nil)
            
            print("Eye data exported to: \(fileURL)")
        } catch {
            print("Error fetching and exporting eye data: \(error)")
        }
    }
    
    func presentYesNoAlert(from viewController: UIViewController, title: String, message: String, yesHandler: @escaping () -> Void, noHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            yesHandler()
        }
        alertController.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            noHandler()
        }
        alertController.addAction(noAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func deleteAllRecords(of entityName: String, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            print("All records deleted for entity: \(entityName)")
        } catch {
            print("Error deleting records for entity \(entityName): \(error)")
        }
    }
    
    func showLoadingSpinner() -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .black
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)
        return spinner
    }

    func hideLoadingSpinner(_ spinner: UIActivityIndicatorView) {
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }
    
    func readStringsFromJSON() -> [String]? {
        guard let url = Bundle.main.url(forResource: "URLs", withExtension: "json") else {
            print("JSON file not found")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let strings = try JSONDecoder().decode([String].self, from: data)
            return strings
        } catch {
            print("Error reading JSON file: \(error)")
            return nil
        }
    }
}

