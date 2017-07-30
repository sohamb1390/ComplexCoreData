//
//  CoreDataHandler.swift
//  ComplexCoreData
//
//  Created by Soham Bhattacharjee on 25/07/17.
//  Copyright © 2017 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

// MARK: For CoreData sharing
 let groupIdentifier = "group.com.complexCoreData.test1"
 let directoryName = "commonDataDirectory"

// MARK: - CoreDataHandler Interface
public class CoreDataHandler: NSObject {
    //**************************************************
    // MARK: - Properties
    //**************************************************
    
    private var persistentContainer: NSPersistentContainer
    
    /// A name that indicates the name of the container
    var containerName: String!
    
    // An URL that indicates the location of the Model
    var modelURL: URL!
    
    // A name that indicates Model Name
    var modelName: String!
    
    /// A flag that indicates whether this store is read-only. Set this value
    /// to YES before loading the persistent store if you want a read-only
    /// store (for example if loading from the application bundle).
    /// Default is false.
    public var isReadOnly = false
    
    /// A flag that indicates whether the store is added asynchronously.
    /// Set this value before loading the persistent store.
    /// Default is true.
    public var shouldAddStoreAsynchronously = true
    
    /// A flag that indicates whether the store should be migrated
    /// automatically if the store model version does not match the
    /// coordinators model version.
    /// Set this value before loading the persistent store.
    /// Default is true.
    public var shouldMigrateStoreAutomatically = true
    
    /// A flag that indicates whether a mapping model should be inferred
    /// when migrating a store.
    /// Set this value before loading the persistent store.
    /// Default is true.
    public var shouldInferMappingModelAutomatically = true


    /// The `URL` of the persistent store for this Core Data Stack. If there
    /// is more than one store this property returns the first store it finds.
    /// The store may not yet exist. It will be created at this URL by default
    /// when first loaded.
    ///
    /// This is a readonly property to create a persistent store in a different
    /// location use `loadStoreAtURL:withCompletionHandler`. To move an existing
    ///  persistent store use
    /// `replacePersistentStoreAtURL:withPersistentStoreFromURL:`.
    public var storeURL: URL? {
        var url: URL?
        let descriptions = persistentContainer.persistentStoreDescriptions
        if let firstDescription = descriptions.first {
            url = firstDescription.url
        }
        return url
    }
    
    // Access the container's Main ManagedObjectContext
    lazy var mainContext: NSManagedObjectContext = { [unowned self] in
        return self.persistentContainer.viewContext
    }()

    // Setup ManagedObjectModel
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        return NSManagedObjectModel(contentsOf: self.modelURL)!
    }()
    
    /// Creates and returns a `CoreDataController` object. This is the designated
    /// initializer for the class. It creates the managed object model,
    /// persistent store coordinator and main managed object context but does
    /// not load the persistent store.
    ///
    /// The managed object model should be in the same bundle as this class.
    ///
    /// - Parameter name: The name of the persistent store.
    ///
    /// - Returns: A `CoreDataController` object or nil if the model
    ///   could not be loaded.
    
    // MARK: - Core Data stack

    // Setup PersistentContainer
    private func loadStore(completionHandler: @escaping (Error?) -> Void) {
        loadStore(storeURL: storeURL, completionHandler: completionHandler)
    }
    
    private func loadStore(storeURL: URL?, completionHandler: @escaping (Error?) -> Void) {
        
        // MARK: For CoreData Sharing
        /*
             let container = NSPersistentContainer(name: "CommonContainer", managedObjectModel: self.managedObjectModel)
             if let containerDirectory = createCommonContainer() {
             let url = containerDirectory.appendingPathComponent("\(container.name).sqlite")
             let description = self.storeDescription(with: url)
             container.persistentStoreDescriptions = [description]
             }
         */
        
        if let storeURL = storeURL ?? self.storeURL {
            let description = storeDescription(with: storeURL)
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    private func storeDescription(with url: URL) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically
        description.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically
        description.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
        description.isReadOnly = isReadOnly
        return description
    }
    
    /// Destroy a persistent store.
    ///
    /// - Parameter storeURL: An `NSURL` for the persistent store to be
    ///   destroyed.
    /// - Returns: A flag indicating if the operation was successful.
    /// - Throws: If the store cannot be destroyed.
    private func destroyPersistentStore(at storeURL: URL) throws {
        let psc = persistentContainer.persistentStoreCoordinator
        try psc.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
    }
    
    /// Reset NSManagedObjectContext
    private func reset() throws {
        var nserror: NSError? = nil
        persistentContainer.persistentStoreCoordinator.performAndWait { [unowned self] in
            if let store = self.persistentContainer.persistentStoreCoordinator.persistentStores.last {
                let storeUrl = self.persistentContainer.persistentStoreCoordinator.url(for: store)
                do {
                    try self.destroyPersistentStore(at: storeUrl)
                    try self.persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: nil)
                    
                } catch let error {
                    print(error.localizedDescription)
                    nserror = error as NSError
                }
            }
        }
        if nserror != nil {
            throw nserror!
        }
    }
    
    //**************************************************
    // MARK: Constructors
    //**************************************************
    /// Creates and returns a `CoreDataController` object. This is the designated
    /// initializer for the class. It creates the managed object model,
    /// persistent store coordinator and main managed object context but does
    /// not load the persistent store.
    ///
    /// The managed object model should be in the same bundle as this class.
    ///
    /// - Parameter name: The name of the persistent store.
    ///
    /// - Returns: A `CoreDataController` object or nil if the model
    ///   could not be loaded.
    init?(containerName: String, modelURL: URL) {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            print("Model not found")
            return nil
        }
        persistentContainer = NSPersistentContainer(name: containerName, managedObjectModel: mom)
        super.init()
        loadStore { (error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    //**************************************************
    // MARK: Destructors
    //**************************************************
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    //**************************************************
    // MARK: Pubic Methods
    //**************************************************
    public func defaultDirectoryURL() -> URL {
        return NSPersistentContainer.defaultDirectoryURL()
    }
    
    public func managedObjectID(forURIRepresentation storeURL: URL) -> NSManagedObjectID? {
        let psc = persistentContainer.persistentStoreCoordinator
        return psc.managedObjectID(forURIRepresentation: storeURL)
    }
    
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.persistentContainer.performBackgroundTask(block)
    }
        
    public func newBackgroundContextWithName(_ name: String, mergeType: NSMergePolicyType = .mergeByPropertyObjectTrumpMergePolicyType) -> NSManagedObjectContext {
        
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = mergeType
        backgroundContext.name = name
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(mergeToMainContext(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: backgroundContext)
        return backgroundContext
    }
    
    public func save(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    public func reset(context: NSManagedObjectContext?) {
        context?.performAndWait({
            context?.reset()
        })
        mainContext.reset()
    }
    
    //**************************************************
    // MARK: Merge to Main (Observer Method)
    //**************************************************
    dynamic func mergeToMainContext(notification: Notification) {
        mainContext.perform({ [unowned self] in
            self.mainContext.mergeChanges(fromContextDidSave: notification)
            do {
                try self.mainContext.save()
                print("\(self.mainContext.name ?? "MainContext") saved...")
            } catch let err {
                print(err)
            }
        })
    }
}

// MARK: - For Core Data Sharing
/// Core Data Sharing is possible only when you are implementing apps within the same group.
/// Multiple applications will access the same CoreDataModel folder
/// The Model you will create will be resided inside the app-group folder.
/// Most important Pont: ***** The applications which will have CoreData sharing feature, must be conformed to same XCDataModel *****
/// You have combine all the apps in the same group container.
extension CoreDataHandler {
    // MARK: Create common container directory
    private func createCommonContainer() -> URL? {
        let fileManager = FileManager.default
        if let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
            let newDirectory = container.appendingPathComponent(directoryName)
            print("New Directory at \(newDirectory)")
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: newDirectory.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    // file exists and is a directory
                } else {
                    // file exists and is not a directory
                }
            } else {
                try? fileManager.createDirectory(at: newDirectory, withIntermediateDirectories: false, attributes: nil)
            }
            return newDirectory
        }
        return nil
    }
}
