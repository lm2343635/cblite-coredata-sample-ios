/*
     File: RecipesAppDelegate.m 
 Abstract: Application delegate that sets up a tab bar controller with two view controllers -- a navigation controller that in turn loads a table view controller to manage a list of recipes, and a unit converter view controller.
  
  Version: 1.4 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "RecipesAppDelegate.h"
#import "RecipeListTableViewController.h"
#import "UnitConverterTableViewController.h"

#import "CBLIncrementalStore.h"
#import <CouchbaseLite/CouchbaseLite.h>


// The changes from the original sample app are inside #if USE_COUCHBASE blocks
#define USE_COUCHBASE 1

// This is the URL of the remote database to sync with. This value assumes there is a Couchbase
// Sync Gateway running on your development machine with a database named "recipes" that has guest
// access enabled. You'll need to customize this to point to where your actual server is deployed.
#define COUCHBASE_SYNC_URL @"http://127.0.0.1:4984/recipes"


@implementation RecipesAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize recipeListController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    recipeListController.managedObjectContext = self.managedObjectContext;
    //[window addSubview:tabBarController.view];
    [window setRootViewController:tabBarController];
    [window makeKeyAndVisible];
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
        } 
    }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [NSManagedObjectContext new];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
#if USE_COUCHBASE
    CBLIncrementalStore *store = (CBLIncrementalStore*)[coordinator persistentStores][0];
    [store addObservingManagedObjectContext:managedObjectContext];
#endif
    
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];

#if USE_COUCHBASE
    [CBLIncrementalStore updateManagedObjectModel:managedObjectModel];
#endif
    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
#if USE_COUCHBASE
    NSString *databaseName = @"recipes";
	NSURL *storeUrl = [NSURL URLWithString:databaseName];
	
    CBLIncrementalStore *store;
    if (![[CBLManager sharedInstance] existingDatabaseNamed:databaseName error:&error]) {
        NSURL *defaultStoreURL = [[NSBundle mainBundle] URLForResource:@"Recipes" withExtension:@"sqlite"];
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption : @YES,
                                  NSInferMappingModelAutomaticallyOption : @YES
                                  };
        NSPersistentStore *importStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                  configuration:nil
                                                                                            URL:defaultStoreURL
                                                                                        options:options
                                                                                          error:&error];
        
        store = (CBLIncrementalStore*)[persistentStoreCoordinator migratePersistentStore:importStore toURL:storeUrl
                                                                                 options:nil
                                                                                withType:[CBLIncrementalStore type]
                                                                                   error:&error];
    } else {
        store = (CBLIncrementalStore*)[persistentStoreCoordinator addPersistentStoreWithType:[CBLIncrementalStore type]
                                                                               configuration:nil
                                                                                         URL:storeUrl options:nil error:&error];
    }
#else
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Recipes.sqlite"];
	/*
	 Set up the store.
	 For the sake of illustration, provide a pre-populated default store.
	 */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Recipes" ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
    
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
    
    NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];
    
#endif
    if (!store) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }
    
#if USE_COUCHBASE
    NSURL *remoteDbURL = [NSURL URLWithString:COUCHBASE_SYNC_URL];
    [self startReplication:[store.database createPullReplication:remoteDbURL]];
    [self startReplication:[store.database createPushReplication:remoteDbURL]];
#endif
		
    return persistentStoreCoordinator;
}


#if USE_COUCHBASE
/**
 * Utility method to configure, start and observe a replication.
 */
- (void)startReplication:(CBLReplication *)repl {
    repl.continuous = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(replicationProgress:)
                                                 name:kCBLReplicationChangeNotification object:repl];
    [repl start];
}

static BOOL sReplicationAlertShowing;

/**
 Observer method called when the push or pull replication's progress or status changes.
 */
- (void)replicationProgress:(NSNotification *)notification {
    CBLReplication *repl = notification.object;
    NSError* error = repl.lastError;
    NSLog(@"%@ replication: status = %d, progress = %u / %u, err = %@",
          (repl.pull ? @"Pull" : @"Push"), repl.status, repl.changesCount, repl.completedChangesCount,
          error.localizedDescription);

    if (error && !sReplicationAlertShowing) {
        NSString* msg = [NSString stringWithFormat: @"Sync failed with an error: %@", error.localizedDescription];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Sync Error"
                                                        message: msg
                                                       delegate: self
                                              cancelButtonTitle: @"Sorry"
                                              otherButtonTitles: nil];
        sReplicationAlertShowing = YES;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    sReplicationAlertShowing = NO;
}
#endif


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management


@end
