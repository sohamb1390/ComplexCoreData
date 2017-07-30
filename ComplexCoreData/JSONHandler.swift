//
//  JSONHandler.swift
//  ComplexCoreData
//
//  Created by Soham Bhattacharjee on 25/07/17.
//  Copyright © 2017 Soham Bhattacharjee. All rights reserved.
//

import Foundation

class JSONHandler {
    class func readJSON(from fileName: String, with extensionFormat: String) ->(Any?, String?) {
        do {
            if let file = Bundle.main.url(forResource: fileName, withExtension: extensionFormat) {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return (json, nil)
            } else {
                print("no file")
                return (nil, "no file")
            }
        } catch {
            print(error.localizedDescription)
            return (nil, error.localizedDescription)
        }
    }
}
