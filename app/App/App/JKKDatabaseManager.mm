//
//  JKKDatabaseManager.m
//  App
//
//  Created by Kevin on 2/18/14.
/* ========================================================================
 *  Copyright 2014 Kyle Cesare, Kevin Hess, Joe Runde, Chadd Armstrong, Chris Heist
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * ========================================================================
 */

#import "JKKDatabaseManager.h"

@implementation JKKDatabaseManager


- (id)init {
    self = [super init];
    
    if (self) {
        NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.databasePath = [documentsPath stringByAppendingPathComponent:@"/taterbase.sqlite"];
        
        DataStore db = DataStore::open([self.databasePath UTF8String]);
        db.createTables();
        db.close();
    }
    
    return self;
}


+ (JKKDatabaseManager *)sharedInstance {
    static JKKDatabaseManager* instance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        instance = [[JKKDatabaseManager alloc] init];
    });
    
    return instance;
}

- (DataStore)openDatabase {
    DataStore db = DataStore::open([self.databasePath UTF8String]);
    return db;
}

@end
