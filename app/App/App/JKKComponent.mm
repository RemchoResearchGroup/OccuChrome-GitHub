//
//  JKKComponent.m
//  App
//
//  Created by Kevin on 2/8/14.
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

#import "JKKComponent.h"

@implementation JKKComponent

- (id)initWithVarType:(ModelComponent::VariableType)varType withModelType:(ModelComponent::ModelType)modelType withStartTime:(float)startTime withEndTime:(float)endTime {
    self = [super init];
    
    if (self) {
        self.varType = varType;
        self.modelType = modelType;
        self.startTime = startTime;
        self.endTime = endTime;
    }
    
    return self;
}

- (NSString *)getVarTypeString {
    NSString* returnString;
    
    switch (self.varType) {
        case ModelComponent::RED:
            returnString = @"R";
            break;
        case ModelComponent::GREEN:
            returnString = @"G";
            break;
        case ModelComponent::BLUE:
            returnString = @"B";
            break;
        case ModelComponent::HUE:
            returnString = @"H";
            break;
        case ModelComponent::INVALID_VAR:
        default:
            returnString = @"INVALID_VAR_TYPE";
            NSLog(@"Error getting variable type string; invalid variable type found");
            break;
    }
    
    return returnString;
}

- (NSString *)getModelTypeString {
    NSString* returnString;
    
    switch (self.modelType) {
        case ModelComponent::LINEAR:
            returnString = @"Linear";
            break;
        case ModelComponent::EXPONENTIAL:
            returnString = @"Exponential";
            break;
        case ModelComponent::POINT:
            returnString = @"Point";
            break;
        case ModelComponent::INVALID_TYPE:
        default:
            returnString = @"INVALID_MODEL_TYPE";
            NSLog(@"Error getting model type string; invalid model type found");
            break;
    }
    
    return returnString;
}

@end
