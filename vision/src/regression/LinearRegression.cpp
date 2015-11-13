
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
#include <math.h>
#include <iostream>
#include "serialization/SerializableScalar.h"

//BOOST_CLASS_EXPORT_IMPLEMENT(LinearRegression);

LinearRegression::LinearRegression(float begin, float end, ModelComponent::VariableType variable) :
    ModelComponent(begin, end, variable)
{
    //no construction;
}

//support for multiple features as well, for use with the final regression
void LinearRegression::evaluate(cv::Mat x)
{
    x = cutToSize(x);

    float sem = getSquaredFromMean(x);

    cv::Mat weights(1, x.size().width, CV_32F);
    cv::Mat dependent(x.size().height, 1, CV_32F);
    cv::Mat independent(x.size().height, x.size().width, CV_32F, 1.f);

    x.col(0).copyTo(dependent.col(0));
    for(int c = 1; c < x.size().width; c++)
    {
        x.col(c).copyTo(independent.col(c));
    }

    //Use the SVD Decomposition here for matrix inverting
    //during computation the matrix (independent.t() * independent) becomes very non-normalized
    //and the default .inv() method will sometimes calculate zero for the determinant, and return all zeroes.
    //According to the documentation, SVD Decomposition uses a "pseudo inverse" in this case,
    //which seems to work well for our purposes
    weights = (independent.t() * independent).inv(cv::DECOMP_SVD) * independent.t() * dependent;
    mWeights = weights;

    float se = 0;
    float val;
    for(int c = 0; c < x.size().height; c++)
    {
        val = getEstimation(independent.row(c));
        se += pow(val - dependent.row(c).at<float>(0), 2.f);
    }
    mR2 = (1-se/sem);
    mMSE = se / ((float)x.size().height);
}

float LinearRegression::getEstimation(cv::Mat x)
{
    return cv::Mat(mWeights.t() * x.t()).at<float>(0);
}

float LinearRegression::getWeight()
{
    if(mWeights.size().height > 0)
        return mWeights.row(1).at<float>(0);
    else
        return 0; //should throw some error here, get around to that later
}

std::string LinearRegression::getStatString(bool printBounds)
{
    std::ostringstream data;
    data << "Linear Regression Component\n";
    if(printBounds)
    {
        insertVar(&data);
        data << "channel from " << mBegin << "s to " << mEnd << "s\n";
    }
    data << "y = ";

    for(int c = 1; c < mWeights.size().height; c++)
        data << mWeights.row(c).at<float>(0) << "t" << c << " + ";

    data << mWeights.row(0).at<float>(0) << "\n";
    data << "R^2 = " << mR2 << "\n";
    data << "MSE = " << mMSE << "\n";

    return data.str();
}

float LinearRegression::graphPoint(int second)
{
    if(second < mBegin || second > mEnd)
        return 0;
    return mWeights.row(0).at<float>(0) + mWeights.row(1).at<float>(0) * second;
}

ModelComponent::ModelType LinearRegression::getModelType()
{
    return ModelComponent::LINEAR;
}
