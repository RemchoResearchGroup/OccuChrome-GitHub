
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

#ifndef __DATA_EXPORTER_H
#define __DATA_EXPORTER_H

#include "regression/RegressionModel.h"

class DataExporter{
public:
    DataExporter(ModelPtr model);

    void exportCalibration();
    void exportDiagnosticRun();

    //std::string getCSVFilename();
    //std::string getTextFilename();

    std::string getCSVData();
    std::string getTextData();

private:
    //std::string mPath;
    ModelPtr mModel;

    std::string mCSVData;
    std::string mTextData;

    //bool mCSVFileCurrent;
    //bool mTextFileCurrent;

    //initialize the strings for csv and text files
    void createCSVData();
    void createTextData();

    //create files and return their names
    //std::string createCSVFile();
    //std::string createTextFile();

    void appendtoCSV(int run, float calibrationValue, std::vector<cv::SerializableScalar> data);
    void appendtoText(std::string line);

};


#endif
