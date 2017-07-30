//
//  ViewController.swift
//  ComplexCoreData
//
//  Created by Soham Bhattacharjee on 25/07/17.
//  Copyright © 2017 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import CoreData

let segueConstant = "CoreDataActionSegue"

enum CoreDataAction {
    case PerformUsingBackgroundContextClosure
    case PerformUsingNewBackgroundContext
    case PerformUsingMainContext
}

// MARK: JSON Object Structures
struct CartStruct {
    var id: String
    var name: String
    var inventoryItems: [InventoryItemStruct] = []
    
    mutating func insert(invItem: InventoryItemStruct) {
        inventoryItems.append(invItem)
    }
}

struct InventoryItemStruct {
    var id: String
    var categoryIds: [String]
}

struct CategoryStruct {
    var id: String
    var name: String
    var products: [ProductStruct] = []
    
    mutating func insert(productItem: ProductStruct) {
        products.append(productItem)
    }
}

struct ProductStruct {
    var id: String
    var name: String
    var quantity: NSNumber?
}

// MARK: - ViewController Interface
class ViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    // MARK: Variables
    var coreDataHandler: CoreDataHandler?
    var categories: [CategoryStruct] = []
    var carts: [CartStruct] = []
    var selectedAction: CoreDataAction?

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setup CoreData
        setupCoreData()

        print("DB Url: --------------- \(coreDataHandler?.defaultDirectoryURL().path ?? "")")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueConstant, let destination = segue.destination as? CoreDataActionsViewController {
            destination.selectedAction = selectedAction
            destination.categories = categories
            destination.carts = carts
            destination.coreDataHandler = coreDataHandler
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Read JSON
    fileprivate func readJSON() {
        let responseTupple =  JSONHandler.readJSON(from: "Data", with: "json")
        if let error = responseTupple.1 {
            showAlert(with: "Error", message: error)
            return
        }
        
        if let dict = responseTupple.0 as? NSDictionary {
            print(dict)
            
            // Extract Dictionary
            extract(responseDict: dict)
        }
    }
    
    func showAlert(with title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Extract JSON
    func extract(responseDict: NSDictionary) {
        
        // Reset the arrays
        categories.removeAll()
        carts.removeAll()
        
        // Extract all the 'Cart', 'InventoryItems', 'Category', 'Product' informations
        // Extract Product & category items from response dictionary
        if let categoryResponse = responseDict["Categories"] as? [[String: Any]] {
            for categoryDict in categoryResponse {
                let categoryId = categoryDict["id"] as? String ?? ""
                let categoryName = categoryDict["name"] as? String ?? ""
                
                // Creating a Category Struct object
                var categoryStructObj = CategoryStruct(id: categoryId, name: categoryName, products: [])
                
                // Insert all the product items to the categoryStructObj
                if let products = categoryDict["products"] as? [[String: Any]] {
                    for productItem in products {
                        let productId = productItem["id"] as? String ?? ""
                        let productName = productItem["name"] as? String ?? ""
                        let quantity = productItem["quantity"] as? NSNumber
                        
                        // Create instance of a productStruct Item
                        let productStructObj = ProductStruct(id: productId, name: productName, quantity: quantity)
                        
                        // Insert the productStruct into the categoryStructObj
                        categoryStructObj.insert(productItem: productStructObj)
                    }
                }
                
                // Finally append the category object into categories array
                categories.append(categoryStructObj)
            }
        }
        
        // Extract Cart & Inventory items from the response dictionary
        if let cartResponse = responseDict["cart"] as? [[String: Any]] {
            for cartDict in cartResponse {
                let cartId = cartDict["id"] as? String ?? ""
                let cartName = cartDict["name"] as? String ?? ""
                
                // Creating a Cart Struct object
                var cartStructObj = CartStruct(id: cartId, name: cartName, inventoryItems: [])
                
                // Here I have added only one inventory item in each cart
                // You can have multiple inventories for a single cart item
                // This is why I made this as an array of inventory items
                if let inventoryItems = cartDict["inventoryItems"] as? [[String: Any]] {
                    for inventoryItem in inventoryItems {
                        let inventoryItemId = inventoryItem["id"] as? String ?? ""
                        var categoryIds: [String] = []
                        
                        // Iterate through all the category ids dict array and append all the category ids into the local array
                        if let categories = inventoryItem["categoryIds"] as? [[String: Any]] {
                            categoryIds = categories.map({ (catDict) in
                                return catDict["catId"] as? String ?? ""
                            })
                        }
                        // Creating an inventoryItem Struct object
                        let inventoryStructObj = InventoryItemStruct(id: inventoryItemId, categoryIds: categoryIds)
                        
                        // Assigning inventoryStructObj into cartStructObj
                        cartStructObj.insert(invItem: inventoryStructObj)
                    }
                }
                
                // Finally append the cart object into carts array
                carts.append(cartStructObj)
            }
        }
    }
    
    // MARK: - Setup CoreData Handler
    func setupCoreData() {
        guard let modelURL = Bundle.main.url(forResource: "ComplexCoreData", withExtension: "momd") else {
            return
        }
        coreDataHandler = CoreDataHandler(containerName: "ComplexCoreDataContainer", modelURL: modelURL)
    }
    
    // MARK: - CoreData Actions
    fileprivate func deleteAll() {
        // Create Fetch Request
        let cartFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Cart.entity().name ?? "Cart")
        let inventoryFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: InventoryItem.entity().name ?? "InventoryItem")
        let categoryFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Category.entity().name ?? "Category")
        let productFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Product.entity().name ?? "Product")

        // Configure Fetch Request
        // Put your predicate if you want
        
        // Initialize Batch Delete Request
        let batchDeleteRequestForCart = NSBatchDeleteRequest(fetchRequest: cartFetchRequest)
        let batchDeleteRequestForInventory = NSBatchDeleteRequest(fetchRequest: inventoryFetchRequest)
        let batchDeleteRequestForCategory = NSBatchDeleteRequest(fetchRequest: categoryFetchRequest)
        let batchDeleteRequestForProduct = NSBatchDeleteRequest(fetchRequest: productFetchRequest)
        
        // Configure Batch Update Request
        batchDeleteRequestForCart.resultType = .resultTypeCount
        batchDeleteRequestForInventory.resultType = .resultTypeCount
        batchDeleteRequestForCategory.resultType = .resultTypeCount
        batchDeleteRequestForProduct.resultType = .resultTypeCount
        
        // Execute Batch Request
        coreDataHandler?.performBackgroundTask({ (moc) in
            do {
                if let batchDeleteResult = try moc.execute(batchDeleteRequestForCart) as? NSBatchDeleteResult {
                    print("The batch delete request has deleted \(batchDeleteResult.result!) cart records.")
                }
                
                if let batchDeleteResult = try moc.execute(batchDeleteRequestForInventory) as? NSBatchDeleteResult {
                    print("The batch delete request has deleted \(batchDeleteResult.result!) inventory records.")
                }

                if let batchDeleteResult = try moc.execute(batchDeleteRequestForCategory) as? NSBatchDeleteResult {
                    print("The batch delete request has deleted \(batchDeleteResult.result!) category records.")
                }

                if let batchDeleteResult = try moc.execute(batchDeleteRequestForProduct) as? NSBatchDeleteResult {
                    print("The batch delete request has deleted \(batchDeleteResult.result!) product records.")
                }

                // Reset Managed Object Context
                self.coreDataHandler?.reset(context: moc)
                
                // Save Context
                self.coreDataHandler?.save(context: moc)
                
            } catch {
                let updateError = error as NSError
                print("\(updateError), \(updateError.userInfo)")
            }
        })
    }
}
// MARK: - UITableView Delegates & DataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CoredataOptionsCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "PerformBackgroundContext Closure"
            break
        case 1:
            cell.textLabel?.text = "New BackgroundContext"
            break
        case 2:
            cell.textLabel?.text = "Perform on MainContext"
            break
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Flush the existing data before performing an action
        deleteAll()
        
        // Fetch fresh data from local JSON file
        readJSON()
        
        switch indexPath.row {
        case 0:
            selectedAction = .PerformUsingBackgroundContextClosure
            break
        case 1:
            selectedAction = .PerformUsingNewBackgroundContext
            break
        case 2:
            selectedAction = .PerformUsingMainContext
            break
        default:
            break
        }
        
        performSegue(withIdentifier: segueConstant, sender: self)
    }
}
