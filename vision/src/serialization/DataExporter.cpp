
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

#include "serialization/DataExporter.h"


DataExporter::DataExporter(ModelPtr model):
    mModel(model)
{
}

void DataExporter::exportCalibration()
{
    //initialize strings
    createCSVData();
    createTextData();

    for(int c = 0; c < mModel->getNumCalibrations(); c++)
    {
        appendtoCSV(c, mModel->getCalibrationConcentration(c), mModel->mRawCalibrationData[c]);
        mModel->setStatsForCalibration(c);

        std::ostringstream stream;
        if(c != 0)
            stream << "\n\n";
        stream << "Calibration #" << c << "\n";
        stream << "Value: " << mModel->getCalibrationConcentration(c) << "\n\n";
        appendtoText(stream.str());
        appendtoText(mModel->getStatData());
    }

    appendtoText("\n\nModel data: \n");
    appendtoText(mModel->getFinalCalStatData());
    appendtoText("\n\nFirst layer regression weights, in form [y, x1, x2...]\n\n");

    std::ostringstream stream;
    stream << mModel->mCalibrationData << "\n\n" << mModel->mPCACalibrationData;

    appendtoText(stream.str());
}

void DataExporter::exportDiagnosticRun()
{
    createCSVData();
    createTextData();

    appendtoCSV(-1, -1, mModel->mRawEvaluationData);
    appendtoText("Diagnostic run:\n\n");
    appendtoText(mModel->getStatData());

    std::ostringstream stream;
    stream << "Final evaluation: " << mModel->mLastEvaluation;
    appendtoText(stream.str());
}

std::string DataExporter::getCSVData()
{
    return mCSVData;
}

std::string DataExporter::getTextData()
{
    return mTextData;
}

void DataExporter::createCSVData()
{
    mCSVData.clear();
    std::ostringstream stream;
    stream << "Run #, calibration value, ";
    int red, green, blue, time;
    red = mModel->mRed;
    green = mModel->mGreen;
    blue = mModel->mBlue;
    time = mModel->mTime;

    for(int c = 0; c < 4; c++)
    {
        if(red == c)
            stream << "Red";
        else if(green == c)
            stream << "Green";
        else if(blue == c)
            stream << "Blue";
        else if(time == c)
            stream << "Time";
        else
            stream << "?";

        if(c < 3)
            stream << ", ";
    }
    
    stream << "\n";

    mCSVData.append(stream.str());
    //mCSVFileCurrent = false;
}

void DataExporter::createTextData()
{
    mTextData.clear();
    //mTextFileCurrent = false;
}

void DataExporter::appendtoCSV(int run, float calibrationValue, std::vector<cv::SerializableScalar> data)
{
    //mCSVFileCurrent = false;
    std::ostringstream stream;
    for(int c = 0; c < data.size(); c++)
    {
        stream << run << "," << calibrationValue << "," << data[c][0] << "," << data[c][1]
               << "," << data[c][2] << "," << data[c][3] << "\n";
    }
    mCSVData.append(stream.str());
}

void DataExporter::appendtoText(std::string line)
{
    //mTextFileCurrent = false;
    mTextData.append(line);
}
