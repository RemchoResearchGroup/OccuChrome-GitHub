
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

#ifndef _REGRESSION_MODEL_H
#define _REGRESSION_MODEL_H

#include "regression/ModelComponent.h" //will need this later
                                         //for smart pointers
#include "serialization/SerializableScalar.h"
#include "serialization/SerializableMat.h"

#include <opencv2/core/core.hpp>
#include <vector>
#include <string>
#include <boost/shared_ptr.hpp>

//forward declaring serialization class
namespace boost{
namespace serialization{
class access;
}
}

//forward declare a friend
class RegressionFactory;

//forward declare the damn class to typedef a pointer for it
class RegressionModel;
//typedef a shared ptr for this class
typedef boost::shared_ptr<RegressionModel> ModelPtr;

class RegressionModel{
public:
    friend class RegressionFactory;

    /*
     *  These are the main three interface functions for a Regression Model,
     *  the evaluation of an unknown or the addition of a calibration point.
     *  Additionally, setIndices() is used to tell the model what order the
     *  red, green, blue, and time values will be in for the inputs to
     *  evaluate() and calibrate()
     */

    //evaluate a test sample, return the estimation
    float evaluate(std::vector<cv::SerializableScalar> colors, cv::Scalar sdev = (0,0,0,0));

    //add a calibration point to the model
    void calibrate(std::vector<cv::SerializableScalar> colors,
                   float calibrationValue, cv::Scalar sdev = (0,0,0,0));

    //announce the indices of incoming matrices. Use -1 for not present
    void setIndices(int time, int red, int green, int blue);

    /*
     *  These next two functions are for manually putting calibration data
     *  into the model. This is mostly for testing purposes, and wouldn't
     *  normally be used.
     *  Usage: stick custom calibration data in with superSecretCalibrationOverride(),
     *  then call dryCalibrate() to apply this new data to the model
     */

    //super secret function, don't touch!
    void superSecretCalibrationOverride(cv::Mat newCalibration);

    //re-run the calibration without any new data
    void dryCalibrate();

    /*
     *  The RegressionModel is two-layered, a first pass over the RGB data yields weights
     *  from the results of regressions over the color channels (Described by the ModelComponents
     *  added to the RegressionModel in the RegressionFactory). Weights from many of these
     *  first passes are then run through four second pass regression models, listed here in
     *  the enum RegressionType. The regression type set for the model will be the one used to
     *  calculate the value returned by a call to evaluate().
     */

    enum RegressionType{
        PLANAR = 0,         //n-dimensional planar regression
        PCA_LINEAR,         //linear regression over the data in PCA(1) space
        PCA_QUADRATIC,      //quadratic regression over the data in PCA(1) space
        PCA_EXPONENTIAL,    //exponential regression over the data in PCA(1) space
        INVALID_TYPE
    };

    //get and set the regression type
    RegressionType getCurrentRegressionType();
    void setRegressionType(RegressionType type);

    /*
     *  This next section covers grabbing data for graphical output
     */

    /*
     *  Grab lines for the RGB graphs of each calibration/evaluation run. These functions will return
     *  data from either the calibration run set in setStatsForCalibration(), or from the call to
     *  evaluate(), whichever happened most recently
     */

    //grab the last frame we need to look at. Useful for both setting the upper bound for the range
    //of a graph, and also for reporting to a camera controller how long to watch the test runs for
    int getModelRunTime();

    //RGB data returned indexed by second (if actual data has subsecond accuracy,
    //not all data will be returned)
    float getRed(int second);
    float getGreen(int second);
    float getBlue(int second);

    //get a point to graph for the regression result of the given component
    float getRegressionPoint(int component, int second);

    //get currently graphed calibration run
    int getGraphedCalibration();

    //get string with statistical data about the test run
    std::string getStatData();

    //set the statistical data and graph output to a certain calibration run
    void setStatsForCalibration(int run);

    /*
     *  Grab points for final regression graphs. These are all done in PCA space.
     *  Possible graphs are:
     *      Planar regression
     *      PCA Linear regression
     *      PCA Exponential regression
     *      PCA Quadratic regression
     *  The graph output will be set by setRegressionGraphType()
     */

    //get the x range of the PCA space
    void getPCASpaceRange(float &left, float &right);
    //here are the points for the calibration values that we're performing regression on
    void getCalibrationPointPostPCA(int index, float &xval, float &yval);
    //get a point to graph for the regression type mFinalRegressionType in PCA space
    float getFinalRegressionLine(float PCAindex);

    //get statistical output for the final regression models
    std::string getFinalCalStatData();

    //set regression type for graph output
    void setRegressionGraphType(RegressionType type);

    //get the calibration value used for a calibration run (eg mgdL)
    float getCalibrationConcentration(int run);


    /*
     *  The model stores a circular area of interest to look at in a video.
     *  This isn't data used by the model, but rather stored along with the model
     *  to be reported back to a camera controller, so that the same pixels are
     *  watched for each test run
     */

    //set the circle center and size
    void setCircle(float centerx, float centery, float radius);

    //get the circle center and size
    float getCircleCenterX();
    float getCircleCenterY();
    float getCircleRadius();

    /* Finally the rest of random necessary things to interface with */

    //matrix of raw model output from calibrations
    cv::Mat getRawCalData();

    //unique model name
    std::string getModelName();

    //name of substance being tested
    std::string getTestName();

    //delete an unwanted calibration run
    void chuckCalibration(int run);

    //have at least two calibration runs been done?
    bool isCalibrated();

    //number of calibration runs stored
    int getNumCalibrations();

    //query the important UI things about each model component
    int queryNumComponents();
    int queryBegin(int component);
    int queryEnd(int component);
    ModelComponent::VariableType queryVariable(int component);
    ModelComponent::ModelType queryModelType(int component);

private:
    //private constructor, cannot build outside the factory
    RegressionModel();

    //private pusher for model components
    void pushComponent(ComponentPtr ptr);

    //private unknown evaluation
    //runs weights through the regression given by
    //mFinalRegressionType
    float evaluateUnknown(cv::Mat weights);

    //run the model
    void runModel(std::vector<cv::SerializableScalar> colors);

    //get a row vector of run results
    cv::Mat getModelWeights();

    //binary search for value near index on given column of matrix
    float getDataPoint(int index, int column, std::vector<cv::SerializableScalar>* pvec);

    //create the PCA transformation
    void createPCATransform();

    //run the PCA transformation
    cv::Mat runPCA(cv::Mat data);

    //strip the first column off a matrix
    cv::Mat stripFirstCol(cv::Mat data);

    //graph of planar regression in PCA space
    float FinalComponentPCAGraph(float PCAindex);

    //positions of variables in input matrices
    int mRed, mGreen, mBlue, mTime;

    //list of the components that make up the model
    std::vector<ComponentPtr> mComponents;

    /*
     *  Regression Components for the final model
     */
    //n-planar regression
    ComponentPtr mFinalComponent;
    //PCA linear fit
    ComponentPtr mFinalPCALinear;
    //PCA quadratic fit
    ComponentPtr mFinalPCAQuad;
    //PCA LM fit
    ComponentPtr mFinalPCAExponential;

    //which component will be used for the final regression?
    RegressionType mFinalRegressionType;

    //which regression type will we be graphing?
    RegressionType mRegressionGraph;

    //PCA object for the transformation to PCA space
    cv::PCA mPCA;
    //has the PCA transform been built?
    bool mPCAdone;

    //calibration test outcomes, in matrix format
    //rows of form [y, w1, w2, w3...]
    //where wi is the regression output from the ith model component
    cv::SerializableMat mCalibrationData;
    //calibration test outcomes in PCA space
    //rows of [y, x]
    cv::SerializableMat mPCACalibrationData;


    //!!!!!!!! note laziness because the expo is near, don't remove/add elements in
    //one of these vectors without modifying the other one too :D

    //raw color data of calibration tests, so shit can be graphed later on yo
    std::vector<std::vector<cv::SerializableScalar> > mRawCalibrationData;
    //standard deviation value of RGB channels in calibration runs
    std::vector<cv::SerializableScalar> mCalibrationSDev;

    //was the last run a calibration or an evaluation?
    bool mWasEvaluation;
    //if calibration, which one are we graphing?
    int mCalibrationToGraph;

    //raw rgb data for last evaluation
    std::vector<cv::SerializableScalar> mRawEvaluationData;
    //standard deviation for rgb channels of last evaluation
    cv::SerializableScalar mEvaluationSDev;

    //name of the model, eg. "Chad's Baller Glucose Model"
    std::string mModelName;

    //name of test being performed, eg. "Glucose"
    std::string mTestName;

    //center of circle of interest
    float mCircleCenterX;
    float mCircleCenterY;

    //radius of circle of interest
    float mCircleRadius;

    //is the circle set?
    float mHasCircle;

    //last result from evaluation
    float mLastEvaluation;

    //allow serialization
    friend class boost::serialization::access;
    //allow data exporting
    friend class DataExporter;

    template<typename Archive>
    void serialize(Archive& ar, const unsigned version)
    {
        (void)version;
        //archive all the member variables
        //everything is serializable with boost archives
        ar & mRed & mGreen & mBlue & mTime & mComponents & mFinalComponent & mFinalPCALinear
                & mFinalPCAQuad & mFinalPCAExponential & mCalibrationData & mRawCalibrationData & mWasEvaluation
                & mCalibrationToGraph & mRawEvaluationData & mModelName & mFinalRegressionType & mRegressionGraph
                & mTestName & mCircleCenterX & mCircleCenterY & mCircleRadius & mHasCircle & mLastEvaluation
                & mEvaluationSDev & mCalibrationSDev & mPCACalibrationData;
        //PCA data cannot be serialized without some wrapper, so screw it we'll just recalculate it here.
        //This will restore mPCAdone, as well as recreating the PCA calibration data
        createPCATransform();
    }

};

#endif


