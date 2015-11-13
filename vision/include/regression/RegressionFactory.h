
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

#ifndef _REGRESSION_FACTORY_H
#define _REGRESSION_FACTORY_H

#include "regression/RegressionModel.h"
#include "regression/ModelComponent.h"


class RegressionFactory{
public:

    ModelPtr deserializeFromDB(const void* blob, unsigned int len);

    void serializeToDB(ModelPtr model, const void* &blob, unsigned int &len);

    void createNew(std::string modelName, std::string testName);

    void addNewComponent(ModelComponent::ModelType type,
                         float begin, float end,
                         ModelComponent::VariableType var);

    ModelPtr getCreatedModel();
private:
    ModelPtr mTempModel;

    std::string mOutstring;
};

#endif
