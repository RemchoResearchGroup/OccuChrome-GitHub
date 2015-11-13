
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

#ifndef _MODEL_COMPONENT_H
#define _MODEL_COMPONENT_H

#include <opencv2/core/core.hpp>
#include <boost/shared_ptr.hpp>
#include "serialization/SerializableMat.h"
#include <vector>
#include <boost/serialization/export.hpp>
#include <boost/serialization/base_object.hpp>
#include <iostream>


//forward declaration of friend
class RegressionModel;

//forward declaring serialization class
namespace boost{
namespace serialization{
class access;
}
}

//abstract interface for a component of a regression model
class ModelComponent
{
public:
    /*
     * Concrete classes must implement some evaluation of a
     * regression between mBegin and mEnd
     *
     * x should have the dependent variable in the first column
     * and the independent variable in the remaining columns
     * eg: [y, x]
     *
     * This will set the weights for the regression over the
     * given data
     */
    virtual void evaluate(cv::Mat x) = 0;

    /*
     *  Concrete classes must also implement an evaluation function
     *  to generate an estimation given a single point
     *
     *  This means that mWeights must be preserved in between evaluation
     *  runs, the user assumes this is based on the last regression
     */
    virtual float getEstimation(cv::Mat x) = 0;

    //concrete classes must implement this-
    //obtain the results of the regression, for now just a float
    virtual float getWeight() = 0;

    //get stat data from last run
    virtual std::string getStatString(bool printBounds = true) = 0;

    //enumerate the types of model components available
    enum ModelType{
        POINT = 0,
        LINEAR,
        EXPONENTIAL,
        QUADRATIC,
        INVALID_TYPE
    };

    //enumerate the variable that this component is testing
    enum VariableType{
        RED = 0,
        BLUE,
        GREEN,
        HUE,
        INVALID_VAR
    };

    //generic constructor, fills in the range and value to test
    ModelComponent(float begin, float end, VariableType variable);
    ~ModelComponent();

    //add a friend to look at our privates, lulz
    friend class RegressionModel;
    //also because lazy...
    friend class QuadraticRegression;
    friend class ExponentialRegression;
protected:
    ModelComponent() {}
    //region of frames to analyze between
    float mBegin;
    float mEnd;

    //weights
    cv::SerializableMat mWeights;

    //r^2 values
    float mR2;

    //mean squared error
    float mMSE;

    //variable to be tested
    VariableType mVar;

    //stick the variable type as a string in a stream
    void insertVar(std::ostringstream *stream);

    //private getters for friends only
    float getBegin();
    float getEnd();
    VariableType getVarType();
    virtual ModelType getModelType() = 0;

    //helper function to strip off matrix entries not within
    //range [mBegin, mEnd]
    cv::Mat cutToSize(cv::Mat x);

    //grab sum( (yi - mean)^2) from mat
    float getSquaredFromMean(cv::Mat x);

    virtual float graphPoint(int second) = 0;

    friend class boost::serialization::access;

    template<typename Archive>
    void serialize(Archive& ar, const unsigned version)
    {
        (void)version;
        ar & mBegin & mEnd & mWeights & mR2 & mVar;
    }
};

//typedef a shared ptr for this class
typedef boost::shared_ptr<ModelComponent> ComponentPtr;




#endif
