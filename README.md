# ComplexCoreData
A CoreData Handler which consists of all the important CoreData actions such as:

# 1. Initialisation Of Core Data Stack using NSPersistentContainer
a. Load NSPersistentContainer using your own storeURL
b. Option to handle add common XCDataModel container URL for CoreData sharing. 
(This piece of code is commented out for now, you can use this if you are gonna use same CoreData container for multiple applications)
        
```
let groupIdentifier = "group.com.complexCoreData.test1"
let directoryName = "commonDataDirectory"

let container = NSPersistentContainer(name: "CommonContainer", managedObjectModel: self.managedObjectModel)
if let containerDirectory = createCommonContainer() {
   let url = containerDirectory.appendingPathComponent("\(container.name).sqlite")
   let description = self.storeDescription(with: url)
   container.persistentStoreDescriptions = [description]
}

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
```

# 2. Use performBackgroundTask closure
Perform CRUD operations using performBackgroundTask clousure which internally creates a new private managedObjectContext.
This private MOC will perform your task in background thread and finally cascade all the changes to the MainContext            implicitly, no need to worry about merging changes to the mainContext explicitly.

This is how you can access the private NSManagedObjectContext using a closure:

```
public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
   self.persistentContainer.performBackgroundTask(block)
}
```
# 3. Use a new instance of BackgroundContext
You can also perform your CRUD operation on a private thread by creating a new instance of BackgroundContext. Here you have to merge your changes to the MainContext explicitly.

This is how you can easily access a new instance of BackgroundContext:

```
public func newBackgroundContextWithName(_ name: String, mergeType: NSMergePolicyType = .mergeByPropertyObjectTrumpMergePolicyType) -> NSManagedObjectContext {
        
   let backgroundContext = persistentContainer.newBackgroundContext()
   backgroundContext.mergePolicy = mergeType
   backgroundContext.name = name
   backgroundContext.automaticallyMergesChangesFromParent = true
        
   NotificationCenter.default.addObserver(self, selector: #selector(mergeToMainContext(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: backgroundContext)
        return backgroundContext
}
```
As you can see, I have intimated the backgroundContext to be merged on ParentContext by writing this line of code:

```
backgroundContext.automaticallyMergesChangesFromParent = true
```
You can easily observe the changes made to the MainContext by using a observer method like this:
```
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
```
You can easily update your UI once the mainContext is saved.

# 3. Use MainContext
Perform your CRUD operation on MainManagedObjectContext if you want it to be performed on Main Thread.
 
``` 
lazy var mainContext: NSManagedObjectContext = { [unowned self] in
    return self.persistentContainer.viewContext
}() 
```
Access the mainContext from CoreDataHandler and use it to perform your operations either using 
```
perform({
})
```
or
```
performAndWait({
})
```
# 4. Reset Context
This will reset all of your changes and revert your Context back to the initial state.

```
public func reset(context: NSManagedObjectContext?) {
  context?.performAndWait({
    context?.reset()
  })
  mainContext.reset()
}
```
Internally it uses another ```reset()``` method which destroys your current persistantStore and initialises a new store immediately.

```
private func reset() throws {
   var nserror: NSError? = nil
   persistentContainer.persistentStoreCoordinator.performAndWait { [unowned self] in
   if let store = self.persistentContainer.persistentStoreCoordinator.persistentStores.last {
      let storeUrl = self.persistentContainer.persistentStoreCoordinator.url(for: store)
      do {
          try self.destroyPersistentStore(at: storeUrl)
          try self.persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,         configurationName: nil, at: storeUrl, options: nil)
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
private func destroyPersistentStore(at storeURL: URL) throws {
  let psc = persistentContainer.persistentStoreCoordinator
  try psc.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
}
```
# 5. JSON file decoding
I have added a JSON file (Data.json) to inject data into the CoreData. For decoding the value, I have also written one singleton class called JSONHandler which decodes all the values from the JSON file. You just have to call the method like this

```
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

As you can see, you can easily understand whole theory of CoreData and can get started using this simple class in your project.

Cheers!!!
