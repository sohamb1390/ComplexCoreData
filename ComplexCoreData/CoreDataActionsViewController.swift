//
//  CoreDataActionsViewController.swift
//  ComplexCoreData
//
//  Created by Soham Bhattacharjee on 27/07/17.
//  Copyright © 2017 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import CoreData

class CoreDataActionsViewController: UIViewController {

    // MARK: Variables
    weak var coreDataHandler: CoreDataHandler?
    var categories: [CategoryStruct] = []
    var carts: [CartStruct] = []
    var selectedAction: CoreDataAction?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let action = selectedAction {
            switch action {
            case .PerformUsingBackgroundContextClosure:
                insertUsingPerformBackgroundTask()
                break
            case .PerformUsingNewBackgroundContext:
                insertUsingNewBackgroundContext()
                break
            default:
                insertUsingMainContext()
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
// MARK: - CoreData Action
extension CoreDataActionsViewController {
    
    // MARK: Insert Objects using performBackgroundTask
    fileprivate func insertUsingPerformBackgroundTask() {
        coreDataHandler?.performBackgroundTask({ [unowned self] (moc) in
            
            let categoryMOBJs = self.getCategories(moc: moc)
            
            // Insert Cart Data
            for cartItem in self.carts {
                if let cart = NSEntityDescription.insertNewObject(forEntityName: Cart.entity().name ?? "Cart", into: moc) as? Cart {
                    
                    cart.cartId = cartItem.id
                    cart.cartName = cartItem.name
                    
                    for inventoryItem in cartItem.inventoryItems {
                        if let inventoryObj = NSEntityDescription.insertNewObject(forEntityName: InventoryItem.entity().name ?? "InventoryItem", into: moc) as? InventoryItem {
                            inventoryObj.inventoryId = inventoryItem.id
                            
                            var filteredCatObjects: [Category] = []
                            for catId in inventoryItem.categoryIds {
                                if let catObj = categoryMOBJs.filter({$0.categoryId == catId}).first {
                                    filteredCatObjects.append(catObj)
                                }
                            }
                            
                            inventoryObj.categories = NSOrderedSet(array: filteredCatObjects)
                            inventoryObj.inv_inventoryItems = cart
                        }
                    }
                }
            }
            
            self.coreDataHandler?.save(context: moc)
            
            self.fetch()
        })
    }
    
    // MARK: Insert objects using newBackgroundContext
    fileprivate func insertUsingNewBackgroundContext() {
        let backgroundContext = coreDataHandler?.newBackgroundContextWithName("workerContext")
        backgroundContext?.perform({ [unowned self] in
            let categoryMOBJs = self.getCategories(moc: backgroundContext!)
            
            // Insert Cart Data
            for cartItem in self.carts {
                if let cart = NSEntityDescription.insertNewObject(forEntityName: Cart.entity().name ?? "Cart", into: backgroundContext!) as? Cart {
                    
                    cart.cartId = cartItem.id
                    cart.cartName = cartItem.name
                    
                    for inventoryItem in cartItem.inventoryItems {
                        if let inventoryObj = NSEntityDescription.insertNewObject(forEntityName: InventoryItem.entity().name ?? "InventoryItem", into: backgroundContext!) as? InventoryItem {
                            inventoryObj.inventoryId = inventoryItem.id
                            
                            var filteredCatObjects: [Category] = []
                            for catId in inventoryItem.categoryIds {
                                if let catObj = categoryMOBJs.filter({$0.categoryId == catId}).first {
                                    filteredCatObjects.append(catObj)
                                }
                            }
                            
                            inventoryObj.categories = NSOrderedSet(array: filteredCatObjects)
                            inventoryObj.inv_inventoryItems = cart
                        }
                    }
                }
            }
            
            self.coreDataHandler?.save(context: backgroundContext!)
            
            self.fetch()
        })
    }
    
    // MARK: Insert objects using mainContext
    fileprivate func insertUsingMainContext() {
        let mainContext = coreDataHandler?.mainContext
        mainContext?.perform({ [unowned self] in
            let categoryMOBJs = self.getCategories(moc: mainContext!)
            
            // Insert Cart Data
            for cartItem in self.carts {
                if let cart = NSEntityDescription.insertNewObject(forEntityName: Cart.entity().name ?? "Cart", into: mainContext!) as? Cart {
                    
                    cart.cartId = cartItem.id
                    cart.cartName = cartItem.name
                    
                    for inventoryItem in cartItem.inventoryItems {
                        if let inventoryObj = NSEntityDescription.insertNewObject(forEntityName: InventoryItem.entity().name ?? "InventoryItem", into: mainContext!) as? InventoryItem {
                            inventoryObj.inventoryId = inventoryItem.id
                            
                            var filteredCatObjects: [Category] = []
                            for catId in inventoryItem.categoryIds {
                                if let catObj = categoryMOBJs.filter({$0.categoryId == catId}).first {
                                    filteredCatObjects.append(catObj)
                                }
                            }
                            
                            inventoryObj.categories = NSOrderedSet(array: filteredCatObjects)
                            inventoryObj.inv_inventoryItems = cart
                        }
                    }
                }
            }
            
            self.coreDataHandler?.save(context: mainContext!)
            
            self.fetch()
        })
    }
    
    // MARK: Insert Categories
    private func getCategories(moc: NSManagedObjectContext) -> [Category] {
        var catMOBJs: [Category] = []
        for categoryStruct in categories {
            if let categoryMOBJ = NSEntityDescription.insertNewObject(forEntityName: Category.entity().name ?? "Category", into: moc) as? Category {
                categoryMOBJ.categoryId = categoryStruct.id
                categoryMOBJ.categoryName = categoryStruct.name
                
                var products: [Product] = []
                
                for productStruct in categoryStruct.products {
                    if let productMOBJ = NSEntityDescription.insertNewObject(forEntityName: Product.entity().name ?? "Product", into: moc) as? Product {
                        productMOBJ.productId = productStruct.id
                        productMOBJ.productName = productStruct.name
                        if let quantity = productStruct.quantity {
                            productMOBJ.quantity = Int64(quantity)
                        }
                        productMOBJ.inv_product_categories = categoryMOBJ
                        products.append(productMOBJ)
                    }
                }
                categoryMOBJ.products = NSOrderedSet(array: products)
                catMOBJs.append(categoryMOBJ)
            }
        }
        self.coreDataHandler?.save(context: moc)
        return catMOBJs
    }
    
    // MARK: - Fetch Objects
    private func fetch() {
        // Here I am fetching all the carts objects, like the same, you can fetch any CoreData objects
        let cartFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Cart.entity().name ?? "Cart")

        // Configure Fetch Request
        // Put your predicate if you want
        
        // FIXME: I didn't do any UI part, please feel free to add UI as per your requirement
        
        // Execute Batch Request
        if let action = selectedAction {
            switch action {
            case .PerformUsingBackgroundContextClosure:
                coreDataHandler?.performBackgroundTask({ (moc) in
                    do {
                        let result = try moc.fetch(cartFetchRequest)
                        if let carts = result as? [Cart] {
                            print("Cart Objects: \(carts)")
                        }
                    } catch let err as NSError {
                        print(err.debugDescription)
                    }
                })
                break
            case .PerformUsingNewBackgroundContext:
                let backgroundContext = coreDataHandler?.newBackgroundContextWithName("workerContext")
                do {
                    let result = try backgroundContext?.fetch(cartFetchRequest)
                    if let carts = result as? [Cart] {
                        print("Cart Objects: \(carts)")
                    }
                } catch let err as NSError {
                    print(err.debugDescription)
                }
                break
            default:
                let mainContext = coreDataHandler?.mainContext
                do {
                    let result = try mainContext?.fetch(cartFetchRequest)
                    if let carts = result as? [Cart] {
                        print("Cart Objects: \(carts)")
                    }
                } catch let err as NSError {
                    print(err.debugDescription)
                }
                break
            }
        }
    }
}
