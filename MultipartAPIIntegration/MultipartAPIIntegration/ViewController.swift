//
//  ViewController.swift
//  MultipartAPIIntegration
//
//  Created by Swayam Patel on 06/01/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //API Reference
        //https://dummy.restapiexample.com/
        
        //GET - This type of API is used to send media to the server(image, video, audio)
        //Example - Upload API
        var multipartAPI = "https://v2.convertapi.com/upload"
        
        self.multipartAPICallwithJSONSerialization(apiName: multipartAPI)
        
        // Do any additional setup after loading the view.
    }
    
    //MARK: - MULTIPART API Call
    func multipartAPICallwithJSONSerialization(apiName: String){
        if let url = URL(string: apiName){
            // Generate boundary string using a unique per-app string
            let boundary = UUID().uuidString
            
            // Create a URLSession
            let session = URLSession.shared
            
            // Set the URLRequest to POST and to the specified URL
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            
            // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
            // And the boundary is also set here
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            // Declare Data to pass
            var parameterName = "file"
            var fileName = "swift_upload.png"
            var image = UIImage(named: "test")
            
            // Add the image data to the raw http request data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(parameterName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            data.append(image!.pngData()!)
            
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            // Send a POST request to the URL, with the data we created earlier
            var task = session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
                if error == nil {
                    let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                    if let json = jsonData as? [String: Any] {
                        print(json)
                    }
                }
            })
            
            //Resumes the datatask if it is suspended i.e. it is the API Call
            task.resume()
            
        } else {
            print("Invalid API URL")
        }
    }
}
