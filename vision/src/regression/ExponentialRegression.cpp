
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

#include "regression/ExponentialRegression.h"
#include "regression/LinearRegression.h"
#include "serialization/SerializableScalar.h"
#include <math.h>
#include <iostream>

//BOOST_CLASS_EXPORT_IMPLEMENT(ExponentialRegression);

ExponentialRegression::ExponentialRegression(float begin, float end, ModelComponent::VariableType variable) :
    ModelComponent(begin, end, variable),
    mLinearComponent(new LinearRegression(begin, end, variable))
{
    //no construction
}

void ExponentialRegression::evaluate(cv::Mat x)
{
    x = cutToSize(x);
    //float sem = getSquaredFromMean(x);
    cv::Mat y;

    //for now dont use a displacement to account for y=ln(x)+c,
    //just model y=ln(x)
    //this is crap but eh......
    y = logMat(x, .0);

    mLinearComponent->evaluate(y);
    mWeight = mLinearComponent->getWeight();

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
    mR2 = mLinearComponent->mR2;
}

float ExponentialRegression::getEstimation(cv::Mat x)
{
    //assuming x will be [1, x]...
    float val = mLinearComponent->getEstimation(x);
    return exp(val) + mDisp;
}


//not taking noise into account, just find minimum y value and drop all the values by
// percent of the minimum value
cv::Mat ExponentialRegression::logMat(cv::Mat x, float percent)
{
    float minimum = x.col(0).at<float>(0);
    int height = x.size().height;

    for(int c = 0; c < height; c++)
    {
        float val = x.col(0).at<float>(c);
        if(val < minimum)
            minimum = val;
    }

    if(minimum > 0)
    {
        mDisp = minimum * percent;
    }
    else
    {
        //flip percent over 100% so that we end up shifting
        //all values to be above zero
        mDisp = minimum * (2.f - percent);
    }

    cv::Mat out(0,2,CV_32F);

    for(int c = 0; c < height; c++)
    {
        float val = x.col(0).at<float>(c) - mDisp;
        if(val > 0)
        {
            out.push_back(x.row(c));
            out.col(0).at<float>(c) = log(val);
        }
    }

    return out;

}

std::string ExponentialRegression::getStatString(bool printBounds)
{
    std::ostringstream data;
    data << "Exponential Regression Component\n";
    if(printBounds)
    {
        insertVar(&data);
        data << "channel from " << mBegin << "s to " << mEnd << "s\n";
    }
    data << "y = exp(" << mLinearComponent->mWeights.row(0).at<float>(1) << "t + " << mLinearComponent->mWeights.row(0).at<float>(0)
         << ") + " << mDisp << "\n";
    data << "R^2 (linear) = " << mR2 << "\n";
    data << "MSE          = " << mMSE << "\n";
    return data.str();
}

float ExponentialRegression::getWeight()
{
    return mWeight;
}

float ExponentialRegression::graphPoint(int second)
{
    float val = mLinearComponent->graphPoint(second);
    return exp(val) + mDisp;
}

ModelComponent::ModelType ExponentialRegression::getModelType()
{
    return ModelComponent::EXPONENTIAL;
}
