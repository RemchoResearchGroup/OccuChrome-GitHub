
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

#include "regression/LinearRegression.h"
#include "regression/QuadraticRegression.h"
#include <math.h>
#include <iostream>
#include "serialization/SerializableScalar.h"

QuadraticRegression::QuadraticRegression(float begin, float end, ModelComponent::VariableType variable) :
    ModelComponent(begin, end, variable),
    mLinearComponent(new LinearRegression(begin, end, variable))
{
   //no construction
}

void QuadraticRegression::evaluate(cv::Mat x)
{
    x = cutToSize(x);
    //sqrt values before sending to linear component
    x = squareRoot(x);
    mLinearComponent->evaluate(x);

    float se = 0;
    float val;
    for(int c = 0; c < x.size().height; c++)
    {
        cv::Mat xr(1,2,CV_32F,1.f);
        xr.row(0).at<float>(1) = x.row(c).at<float>(1);
        val = getEstimation(xr);
        se += pow(val - x.row(c).at<float>(0), 2.f);
    }
    mMSE = se / ((float)x.size().height);

    //update r2 and weights from the linear component
    mR2 = mLinearComponent->mR2;
    mWeights = mLinearComponent->mWeights; //mWeights not really used for anything though....
}

//assume mats in form [y, x], taking sqrt(y)
cv::Mat QuadraticRegression::squareRoot(cv::Mat x)
{
    int rows = x.size().height;
    for(int c = 0; c < rows; c++)
    {
        float val = x.col(0).at<float>(c);
        x.col(0).at<float>(c) = sqrt(val);
    }
    return x;
}

float QuadraticRegression::getEstimation(cv::Mat x)
{
    float val = mLinearComponent->getEstimation(x);
    return val * val;
}

float QuadraticRegression::getWeight()
{
    return mLinearComponent->getWeight();
}

std::string QuadraticRegression::getStatString(bool printBounds)
{
    std::ostringstream data;
    data << "Quadratic Regression Component\n";
    if(printBounds)
    {
        insertVar(&data);
        data << "channel from " << mBegin << "s to " << mEnd << "s\n";
    }
    data << "y = (" << mWeights.row(0).at<float>(1) << "t + " << mWeights.row(0).at<float>(0) << ")^2 \n";
    data << "R^2 (linear) = " << mR2 << "\n";
    data << "MSE          = " << mMSE << "\n";

    return data.str();
}

float QuadraticRegression::graphPoint(int second)
{
    float val = mLinearComponent->graphPoint(second);
    return val * val;
}

ModelComponent::ModelType QuadraticRegression::getModelType()
{
    return ModelComponent::QUADRATIC;
}
