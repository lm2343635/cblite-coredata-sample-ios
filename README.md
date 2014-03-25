# Couchbase Lite Core Data Sample App

This project demonstrates how to adapt existing Core Data-based code to use [Couchbase Lite][CBL] as its backing store and add data synchronization to a remote server.

It's based on Apple's "[iPhoneCoreDataRecipes][IPCDR]" sample application that's provided as part of the iOS SDK. Actually, "based on" may be an exaggeration; it _is_ that sample, except with a handful of changes to use Couchbase Lite.

The changes are all in the source file RecipesAppDelegate.m and are delimited inside `#if USE_COUCHBASE` ... `#endif` blocks to make them easy to find. They relate to:

* Creating the NSManagedObjectModel
* Creating the NSPersistentStoreCoordinator
* Starting replication/synchronization

## Setup

Requirements: Xcode 4.6 or later. Devices must be running iOS 6 or later.

1. [Download][CBLDL] Couchbase Lite for iOS.
2. Copy `CouchbaseLite.framework` into the `Extras` directory of this project folder.
3. Also copy `CBLIncrementalStore.h` and `CBLIncrementalStore.m` from the downloaded "Extras" subfolder into the `Extras` directory of this project folder. (**NOTE:** In Couchbase Lite beta 3 these files were accidentally omitted. You can [download them from Github][EXTRASb3]. Sorry!)
4. Open Recipes.xcodeproj
5. Build and run!

## License

Apple's sample code license, which is reproduced at the top of every source file.


[IPCDR]: https://developer.apple.com/library/ios/samplecode/iPhoneCoreDataRecipes/Introduction/Intro.html
[CBL]: http://www.couchbase.com/mobile
[CBLDL]: http://www.couchbase.com/download#cb-mobile
[EXTRASb3]: https://github.com/couchbase/couchbase-lite-ios/tree/1.0-beta3/Source/API/Extras