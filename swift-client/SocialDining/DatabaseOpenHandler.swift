var databaseOpenHandler: DatabaseOpenHandler = DatabaseOpenHandler()

import UIKit

class DatabaseOpenHandler: NSObject {
    
    var socialdiningDB: FMDatabase?
    
    func open()->Bool{
        //let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        //let docsDir = dirPaths[0]
        //let databasePath = docsDir.stringByAppendingPathComponent("socialdining.db")
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent("socialdining.db")
        let databasePath = fileURL.path!
        socialdiningDB = FMDatabase(path: databasePath as String)
        return socialdiningDB!.open()
    }
}
