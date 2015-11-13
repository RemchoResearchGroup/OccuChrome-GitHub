//
//  JKKResult.m
//  App
//
//  Created by Kevin on 1/26/14.
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

#import "JKKResult.h"

@implementation JKKResult

// hessk: initializer for a result which we will add a value to later
- (id)initNewResultWithName:(NSString*)name subject:(NSString *)subject notes:(NSString *)notes {
    self = [super init];
    
    if (self) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
        
        self.date = [formatter stringFromDate:[NSDate date]];
        self.name = name;
        self.subject = subject;
        self.notes = notes;
        
        self.resultID = -1;
    }
    
    return self;
}

- (id)initResultFromDatabaseWithID:(int)resultID date:(NSString *)date name:(NSString *)name subject:(NSString *)subject notes:(NSString *)notes value:(float)value stats:(NSString *)statsString{
    self = [self initNewResultWithName:name subject:subject notes:notes];
    
    if (self) {
        self.resultID = resultID;
        self.value = value;
        self.date = date;
        self.stats = statsString;
    }
    
    return self;
}

@end
