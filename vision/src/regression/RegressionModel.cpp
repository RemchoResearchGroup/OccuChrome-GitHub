
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

#include "regression/RegressionModel.h"
#include "regression/ModelComponent.h"
#include "regression/ModelComponents.h"
#include <iostream>
#include <fstream>

RegressionModel::RegressionModel()
{
    mWasEvaluation = false;
    //blue because that's just how I'm feelin'
    //...not really it just doesn't matter what channel we specify
    mFinalComponent.reset(new LinearRegression(-100000, 100000, ModelComponent::BLUE));
    mFinalPCALinear.reset(new LinearRegression(-100000, 100000, ModelComponent::BLUE));
    mFinalPCAQuad.reset(new QuadraticRegression(-100000, 100000, ModelComponent::BLUE));
    mFinalPCAExponential.reset(new ExponentialRegression(-100000, 100000, ModelComponent::BLUE));
    mHasCircle = false;
    mPCAdone = false;
    mRegressionGraph = PLANAR;
    mFinalRegressionType = PLANAR;
}

//evaluate a test sample, return the estimation
float RegressionModel::evaluate(std::vector<cv::SerializableScalar> colors, cv::Scalar sdev)
{
    mWasEvaluation = true;
    mCalibrationToGraph = -1;
    mRawEvaluationData = colors;
    mEvaluationSDev = sdev;

    runModel(colors);
    cv::Mat weights = getModelWeights();
    cv::Mat weightsPCA = runPCA(weights);

    RegressionType temp = mFinalRegressionType;

    mFinalRegressionType = PCA_LINEAR;
    std::cout << "PCA Linear evaluation: " << evaluateUnknown(weightsPCA) << "\n";
    mFinalRegressionType = PCA_QUADRATIC;
    std::cout << "PCA Quad evaluation  : " << evaluateUnknown(weightsPCA) << "\n";
    mFinalRegressionType = PCA_EXPONENTIAL;
    std::cout << "PCA Exponential eval : " << evaluateUnknown(weightsPCA) << "\n";
    mFinalRegressionType = PLANAR;
    std::cout << "Planar evaluation    : " << evaluateUnknown(weights) << "\n";

    mFinalRegressionType = temp;
    mFinalRegressionType == PLANAR ? evaluateUnknown(weights) : evaluateUnknown(weightsPCA);
    return mLastEvaluation;
}

//add a calibration point to the model
void RegressionModel::calibrate(std::vector<cv::SerializableScalar> colors,
               float calibrationValue, cv::Scalar sdev)
{
    mWasEvaluation = false;
    //push back the color data to be stored in the database
    mRawCalibrationData.push_back(colors);
    mCalibrationSDev.push_back(sdev);
    //run the model components over the new color data
    runModel(colors);

    //grab the weights returned by the components
    cv::Mat weights = getModelWeights();
    //slap in the y value given by the user
    weights.at<float>(0) = calibrationValue;
    //push this back to the set of total calibration data
    mCalibrationData.push_back(weights);

    //do the planar evaluation with the final component
    mFinalComponent->evaluate(mCalibrationData);

    //calculate a new PCA transformation
    createPCATransform();

    //do a linear regression on the PCA'd data
    if(mPCAdone)
    {
        mPCACalibrationData = runPCA(mCalibrationData);

        //std::cout << "calibrating PCA models\n";
        mFinalPCALinear->evaluate(mPCACalibrationData);
        mFinalPCAQuad->evaluate(mPCACalibrationData);
        //std::cout << "moving on to exponential model...\n";
        mFinalPCAExponential->evaluate(mPCACalibrationData);
        //std::cout << "Done calibrating PCA models\n";
    }

    //set the calibration just done as the one to graph
    mCalibrationToGraph = mCalibrationData.size().height - 1;
}

void RegressionModel::dryCalibrate()
{
    mFinalComponent->evaluate(mCalibrationData);
}

void RegressionModel::superSecretCalibrationOverride(cv::Mat newCalibration)
{
    mCalibrationData = newCalibration;
}

void RegressionModel::createPCATransform()
{
    //std::cout << "Creating PCA transform\n";

    mPCAdone = false;

    if(mCalibrationData.size().height >= 2)
    {
        //return one principal components
        //this is easy to graph on the iphone, and won't affect models using only
        //a single component
        cv::Mat dataMinusYVals = stripFirstCol(mCalibrationData);

        //std::cout << "actually doing PCA fn\n";

        mPCA = cv::PCA(dataMinusYVals, cv::Mat(), CV_PCA_DATA_AS_ROW, 1);

        mPCAdone = true;

        mPCACalibrationData = runPCA(mCalibrationData);
    }
}

cv::Mat RegressionModel::runPCA(cv::Mat data)
{
    //std::cout << "running PCA transform\n";

    cv::Mat newData = stripFirstCol(data);
    if(mPCAdone)
    {
        cv::Mat result = mPCA.project(newData);
        //std::cout << "projected!\n";
        cv::Mat result2(result.size().height, result.size().width+1, CV_32F);

        //std::cout << "data height: " << data.size().height << "\n";
        //std::cout << "result height: " << result.size().height << "\n";
        //std::cout << "result width: " << result.size().width << "\n";


        data.col(0).copyTo(result2.col(0));
        //std::cout << "copied first column\n";
        //should only be one more column after pca
        result.col(0).copyTo(result2.col(1));
        return result2;
    }
    return data;
}

cv::Mat RegressionModel::stripFirstCol(cv::Mat data)
{
    //std::cout << "stripping column\n";

    //std::cout << "data width: " << data.size().width << "\n";

    cv::Mat dataMinusYVals(data.size().height, data.size().width - 1, CV_32F);
    
    //std::cout << "dmy width: " << dataMinusYVals.size().width << "\n";

    for(int c = 1; c < data.size().width; c++)
    {
        //std::cout << c << std::endl;
        data.col(c).copyTo(dataMinusYVals.col(c-1));
    }
    //std::cout << "done\n";
    return dataMinusYVals;
}

void RegressionModel::setIndices(int time, int red, int green, int blue)
{
    mTime = time;
    mRed = red;
    mGreen = green;
    mBlue = blue;
}

//number of calibration runs stored
int RegressionModel::getNumCalibrations()
{
    return mCalibrationData.size().height;
}

//return biggest end frame
int RegressionModel::getModelRunTime()
{
    int last = 0;
    for(int c = 0; c < mComponents.size(); c++)
    {
        int temp = mComponents[c]->getEnd();
        if(temp > last)
            last = temp;
    }
    return last;
}

RegressionModel::RegressionType RegressionModel::getCurrentRegressionType()
{
    return mFinalRegressionType;
}

void RegressionModel::setRegressionType(RegressionModel::RegressionType type)
{
    mFinalRegressionType = type;
}

//data grabbing functions to get the raw data from the last run (calibration or evaluation)
float RegressionModel::getRed(int second)
{
    if(mWasEvaluation)
        return getDataPoint(second, mRed, &mRawEvaluationData);
    else
        return getDataPoint(second, mRed, &mRawCalibrationData[mCalibrationToGraph]);
}

float RegressionModel::getGreen(int second)
{
    if(mWasEvaluation)
        return getDataPoint(second, mGreen, &mRawEvaluationData);
    else
        return getDataPoint(second, mGreen, &mRawCalibrationData[mCalibrationToGraph]);
}

float RegressionModel::getBlue(int second)
{
    if(mWasEvaluation)
        return getDataPoint(second, mBlue, &mRawEvaluationData);
    else
        return getDataPoint(second, mBlue, &mRawCalibrationData[mCalibrationToGraph]);
}

float RegressionModel::getRegressionPoint(int component, int second)
{
    if(mComponents.size() > component)
        return mComponents[component]->graphPoint(second);
    return 0;
}

void RegressionModel::getPCASpaceRange(float &left, float &right)
{
    left = right = 0;
    if(mPCACalibrationData.size().height > 0)
    {
        left = right = mPCACalibrationData.row(0).at<float>(1);
        for(int c = 0; c < mPCACalibrationData.size().height; c++)
        {
            float val = mPCACalibrationData.row(c).at<float>(1);
            if(val < left)
                left = val;
            if(val > right)
                right = val;
        }
    }
}

void RegressionModel::getCalibrationPointPostPCA(int index, float &xval, float &yval)
{
    xval = mPCACalibrationData.row(index).at<float>(1);
    yval = mPCACalibrationData.row(index).at<float>(0);
}

void RegressionModel::setRegressionGraphType(RegressionType type)
{
    mRegressionGraph = type;
}

float RegressionModel::getFinalRegressionLine(float PCAindex)
{
    cv::Mat x(1,2,CV_32F,1.f);
    float val = PCAindex;
    x.row(0).at<float>(1) = val;
    switch(mRegressionGraph)
    {
    default:
    case PLANAR:
        return FinalComponentPCAGraph(PCAindex);
    case PCA_LINEAR:
        return mFinalPCALinear->getEstimation(x);
    case PCA_QUADRATIC:
        return mFinalPCAQuad->getEstimation(x);
    case PCA_EXPONENTIAL:
        return mFinalPCAExponential->getEstimation(x);
    }
}

float RegressionModel::FinalComponentPCAGraph(float PCAindex)
{
    //grab the two calibration points that are on either side of the given index,
    //then get y values for those from the planar model, and interpolate linearly

    float leftx = 0, lefty = 0, rightx = 0, righty = 0;
    float distr = 100000000, distl = 100000000;

    for(int c = 0; c < mCalibrationData.size().height; c++)
    {
        float x = mPCACalibrationData.row(c).at<float>(1);

        cv::Mat xr(1,mCalibrationData.size().width,CV_32F,1.f);
        mCalibrationData.row(c).copyTo(xr.row(0));
        xr.row(0).at<float>(0) = 1.f;

        if(x < PCAindex && PCAindex-x < distl)
        {
            float y = mFinalComponent->getEstimation(xr);
            leftx = x;
            lefty = y;
            distl = PCAindex - x;
        }
        if(x > PCAindex && x-PCAindex < distr)
        {
            float y = mFinalComponent->getEstimation(xr);
            rightx = x;
            righty = y;
            distr = x - PCAindex;
        }
    }

    float slope = (righty - lefty) / (rightx - leftx);
    float val = slope * (PCAindex - leftx) + lefty;
    return val;
}

//binary search for value near index on given column of matrix
float RegressionModel::getDataPoint(int index, int column, std::vector<cv::SerializableScalar>* pvec)
{
    int a = 0;
    int b = pvec->size();
    int in = pvec->size() / 2;
    while(fabs(index - (*pvec)[in][mTime]) > .01)//increase this up to .5 to slightly improve performance when graphing if needed
    {
        if((*pvec)[in][mTime] > index)
            b = in;
        else if((*pvec)[in][mTime] <= index)
            a = in;
        in = a + (b-a)/2;
        if(a == in || b == in)
            break;
    }
    //std::cout << (*pvec)[in][mTime] << " " << abs(index - (*pvec)[in][mTime]) << " ";
    return (*pvec)[in][column];
}

int RegressionModel::getGraphedCalibration()
{
    return mCalibrationToGraph;
}

//get the calibration value used for a calibration run (eg mgdL)
float RegressionModel::getCalibrationConcentration(int run)
{
    return mCalibrationData.row(run).at<float>(0);
}

//set the statistical data and graph output to a certain calibration run
void RegressionModel::setStatsForCalibration(int run)
{
    mWasEvaluation = false;
    if(run < mRawCalibrationData.size())
    {
        runModel(mRawCalibrationData[run]);
        mCalibrationToGraph = run;
    }
}


//matrix of raw model output from calibrations
cv::Mat RegressionModel::getRawCalData()
{
    return mCalibrationData;
}

//unique model name
std::string RegressionModel::getModelName()
{
    return mModelName;
}

//name of substance being tested
std::string RegressionModel::getTestName()
{
    return mTestName;
}

std::string RegressionModel::getStatData()
{
    std::string data;
    for(int c = 0; c < mComponents.size(); c++)
    {
        data.append(mComponents[c]->getStatString());
    }

    std::stringstream stream;
    stream << "\n";
    if(mWasEvaluation)
    {
        stream << "Red channel standard deviation  : " << mEvaluationSDev(mRed) << "\n";
        stream << "Green channel standard deviation: " << mEvaluationSDev(mGreen) << "\n";
        stream << "Blue channel standard deviation : " << mEvaluationSDev(mBlue) << "\n";
    }
    else
    {
        stream << "Red channel standard deviation  : " << mCalibrationSDev[mCalibrationToGraph](mRed) << "\n";
        stream << "Green channel standard deviation: " << mCalibrationSDev[mCalibrationToGraph](mGreen) << "\n";
        stream << "Blue channel standard deviation : " << mCalibrationSDev[mCalibrationToGraph](mBlue) << "\n";
    }
    stream << "\n";
    switch(mFinalRegressionType)
    {
    default:
    case PLANAR:
        stream << "Final regression type: Planar regression\n";
        stream << mFinalComponent->getStatString(false);
        break;
    case PCA_LINEAR:
        stream << "Final regression type: PCA Linear regression\n";
        stream << mFinalPCALinear->getStatString(false);
        break;
    case PCA_QUADRATIC:
        stream << "Final regression type: PCA Quadratic regression\n";
        stream << mFinalPCAQuad->getStatString(false);
        break;
    case PCA_EXPONENTIAL:
        stream << "Final regression type: PCA Exponential regression\n";
        stream << mFinalPCAExponential->getStatString(false);
        break;
    }


    data.append(stream.str());
    return data;
}

std::string RegressionModel::getFinalCalStatData()
{
    std::string data;

    data.append("Planar regression method:\n");
    data.append(mFinalComponent->getStatString());
    data.append("\n\nLinear regression in PCA:\n");
    data.append(mFinalPCALinear->getStatString());
    data.append("\n\nQuadratic regression in PCA:\n");
    data.append(mFinalPCAQuad->getStatString());
    data.append("\n\nExponential regression in PCA:\n");
    data.append(mFinalPCAExponential->getStatString());

    return data;
}

void RegressionModel::setCircle(float centerx, float centery, float radius)
{
    if(mHasCircle)
        return;
    mCircleCenterX = centerx;
    mCircleCenterY = centery;
    mCircleRadius = radius;
    mHasCircle = true;
}


float RegressionModel::getCircleCenterX()
{
    if(!mHasCircle)
        return -1;
    return mCircleCenterX;
}

float RegressionModel::getCircleCenterY()
{
    if(!mHasCircle)
        return -1;
    return mCircleCenterY;
}


float RegressionModel::getCircleRadius()
{
    if(!mHasCircle)
        return -1;
    return mCircleRadius;
}

//have at least two calibration runs been done?
bool RegressionModel::isCalibrated()
{
    return mCalibrationData.size().height > 1;
}

int RegressionModel::queryNumComponents()
{
    return mComponents.size();
}

int RegressionModel::queryBegin(int component)
{
    if(component < mComponents.size())
        return mComponents[component]->getBegin();
    return 0;//throw error later
}

int RegressionModel::queryEnd(int component)
{
    if(component < mComponents.size())
        return mComponents[component]->getEnd();
    return 0;//throw error later
}

ModelComponent::VariableType RegressionModel::queryVariable(int component)
{
    if(component < mComponents.size())
        return mComponents[component]->getVarType();
    return ModelComponent::INVALID_VAR;//throw error later
}

ModelComponent::ModelType RegressionModel::queryModelType(int component)
{
    if(component < mComponents.size())
        return mComponents[component]->getModelType();
    return ModelComponent::INVALID_TYPE;//throw error later
}

//private pusher for model components
void RegressionModel::pushComponent(ComponentPtr ptr)
{
    mComponents.push_back(ptr);
}

//private unknown evaluation
float RegressionModel::evaluateUnknown(cv::Mat weights)
{
    //std::cout << mFinalWeights << "\n" << weights << "\n";
    //cv::Mat result = mFinalWeights.t() * weights.t();
    //std::cout << "result: " << mFinalComponent->getEstimation(weights) << "\n";
    switch(mFinalRegressionType)
    {
    default:
    case PLANAR:
        mLastEvaluation = mFinalComponent->getEstimation(weights);
        break;
    case PCA_LINEAR:
        mLastEvaluation = mFinalPCALinear->getEstimation(weights);
        break;
    case PCA_QUADRATIC:
        mLastEvaluation = mFinalPCAQuad->getEstimation(weights);
        break;
    case PCA_EXPONENTIAL:
        mLastEvaluation = mFinalPCAExponential->getEstimation(weights);
        break;
    }
    return mLastEvaluation;
}

void RegressionModel::runModel(std::vector<cv::SerializableScalar> colors)
{
    cv::Mat red, green, blue, hue;
    cv::Mat row(1,2,CV_32F);
    cv::Scalar val;
    for(int c = 0; c < colors.size(); c++)
    {
        val = colors[c];
        row.at<float>(1) = val(mTime);
        if(mBlue >= 0)
        {
            row.at<float>(0) = val(mBlue);
            blue.push_back(row);
        }
        if(mGreen >= 0)
        {
            row.at<float>(0) = val(mGreen);
            green.push_back(row);
        }
        if(mRed >= 0)
        {
            row.at<float>(0) = val(mRed);
            red.push_back(row);
        }
    }

    for(int c = 0; c < mComponents.size(); c++)
    {
        ModelComponent::VariableType var;
        var = mComponents[c]->mVar;
        if(var == ModelComponent::RED)
            mComponents[c]->evaluate(red);
        if(var == ModelComponent::BLUE)
            mComponents[c]->evaluate(blue);
        if(var == ModelComponent::GREEN)
            mComponents[c]->evaluate(green);
        if(var == ModelComponent::HUE)
            mComponents[c]->evaluate(hue);
    }
}

cv::Mat RegressionModel::getModelWeights()
{
    cv::Mat weights(1, mComponents.size() + 1, CV_32F, 1.f);
    for(int c = 0; c < mComponents.size(); c++)
    {
        weights.at<float>(c+1) = mComponents[c]->getWeight();
    }
    return weights;
}

//throw away last calibration run
void RegressionModel::chuckCalibration(int run)
{
    cv::Mat temp(0, mCalibrationData.size().width, CV_32F);
    cv::Mat temp2(0, mPCACalibrationData.size().width, CV_32F);
    for(int c = 0; c < mCalibrationData.size().height; c++)
    {
        if(c != run)
        {
            temp.push_back(mCalibrationData.row(c));
            temp2.push_back(mPCACalibrationData.row(c));
        }
    }
    mCalibrationData = temp;
    mPCACalibrationData = temp2;

    mRawCalibrationData.erase(mRawCalibrationData.begin() + run);
    if(mCalibrationData.size().height > 0)
        dryCalibrate();
    mCalibrationSDev.erase(mCalibrationSDev.begin() + run);
}







