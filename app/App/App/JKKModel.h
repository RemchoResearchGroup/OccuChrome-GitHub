//
//  JKKModel.h
//  App
//
//  Created by Kevin on 1/30/14.
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

/*
 Objective-C adapter class for C++ RegressionModel objects
*/

#import <Foundation/Foundation.h>
#import "RegressionModel.h"

@interface JKKModel : NSObject

@property ModelPtr model;
@property NSString *units;

- (id)initWithModel: (ModelPtr)model units:(NSString *)units;

- (NSString *)getModelName;
- (NSString *)getTestName;

@end
