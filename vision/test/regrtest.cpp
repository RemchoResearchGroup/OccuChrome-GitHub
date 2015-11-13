#include "regression/RegressionFactory.h"
#include "regression/RegressionModel.h"
#include "serialization/DataExporter.h"
//#include "../include/BiomarkerImageProcessor.h"

#include <iostream>
#include <string>
#include <fstream>
#include <sstream>

#include "regression/ModelComponents.h"

//read a csv file and return it in a vector of scalars
std::vector<cv::SerializableScalar> readcsv(std::string fname)
{
    //Open up that file bor
    std::ifstream in;
    in.open(fname.c_str(), std::ifstream::in);
    //make sure it exists and hardcore crash if it doesn't
    if(!in.good())
        exit(-1);

    //We need to figure out the number of elements per row
    int cols = 0;
    std::string temp;

    //so read it in and count the commas
    getline(in, temp);
    //assume no comma at the end of line
    cols = std::count(temp.begin(), temp.end(), ',') + 1;

    //vector to fill
    std::vector<cv::SerializableScalar> M;
    //temp scalar to hold each row as we read the file
    cv::Scalar Y(0.f, 0.f, 0.f, 0.f);

    //ghetto re-seek to top of the file
    in.close();
    in.open(fname.c_str(), std::ifstream::in);

    char delim;
    float tmp;

    while(!in.eof())
    {
        for(int i = 0; i < cols; i++)
        {
            in >> tmp;
            Y[i] = tmp;
            if(i == cols-1)
                Y[i] /= 30.f;
            if(i < cols-1)
                in >> delim;
        }
        if(!in.eof()) //push the new row if we didn't run into the end of file during reading
            M.push_back(Y);
    }
    return M;
}

int main(int argc, char** argv)
{
    std::cout << "Jollies!\n";

    ModelPtr model;

    RegressionFactory factory;

    factory.createNew("Joe's test", "Glucose");

    //sample model ideas
    //factory.addNewComponent(ModelComponent::LINEAR, 0, 1000, ModelComponent::GREEN);


    //factory.addNewComponent(ModelComponent::LINEAR, 0, 9789/30.f, ModelComponent::RED);
    //factory.addNewComponent(ModelComponent::EXPONENTIAL, 0, 80, ModelComponent::GREEN);
    //factory.addNewComponent(ModelComponent::EXPONENTIAL, 0, 80, ModelComponent::BLUE);

    factory.addNewComponent(ModelComponent::LINEAR, 10, 30, ModelComponent::BLUE);
    factory.addNewComponent(ModelComponent::LINEAR, 10, 30, ModelComponent::GREEN);

    //factory.addNewComponent(ModelComponent::POINT, 8500/30.f, 9790/30.f, ModelComponent::RED);
    //factory.addNewComponent(ModelComponent::POINT, 8500/30.f, 9790/30.f, ModelComponent::BLUE);
    //factory.addNewComponent(ModelComponent::POINT, 8500/30.f, 9790/30.f, ModelComponent::GREEN);



    //factory.addNewComponent(ModelComponent::POINT, 0, 9790, ModelComponent::RED);
    //factory.addNewComponent(ModelComponent::EXPONENTIAL, 0, 9790, ModelComponent::BLUE);
    //factory.addNewComponent(ModelComponent::EXPONENTIAL, 1, 400, ModelComponent::HUE);

    model = factory.getCreatedModel();

    model->setIndices(3,2,1,0);

    std::vector<cv::SerializableScalar> colors;
    std::vector<cv::SerializableScalar> colors1;
    std::vector<cv::SerializableScalar> colors2;
    std::vector<cv::SerializableScalar> colors3;
    std::vector<cv::SerializableScalar> colors4;
    std::vector<cv::SerializableScalar> colors5;

    std::cout << "Lollies!\n";

    colors = readcsv("test/40mg.csv");

    std::cout << "Polly?\n";

    model->calibrate(colors, 40);

    std::cout << "Kollies!\n";

    colors1 = readcsv("test/100mg.csv");
    model->calibrate(colors1, 100);
    colors2 = readcsv("test/200mg.csv");
    model->calibrate(colors2, 200);
    colors3 = readcsv("test/300mg.csv");
    model->calibrate(colors3, 300);
    colors4 = readcsv("test/400mg.csv");
    float laterresult = model->evaluate(colors4);
    model->calibrate(colors4, 400);

    DataExporter exp(model);
    exp.exportCalibration();
    //std::cout << exp.getCSVData();
    //std::cout << exp.getTextData();

    colors5 = readcsv("test/unknown.csv");

    float result = model->evaluate(colors);
    std::cout << "\n---------------------\n  40 Result: " << result << "\n" << model->getStatData()
              << "\n---------------------\n";
    result = model->evaluate(colors1);
    std::cout << "\n---------------------\n 100 Result: " << result << "\n" << model->getStatData()
              << "\n---------------------\n";
    result = model->evaluate(colors2);
    std::cout << "\n---------------------\n 200 Result: " << result << "\n" << model->getStatData()
              << "\n---------------------\n";
    result = model->evaluate(colors3);
    std::cout << "\n---------------------\n 300 Result: " << result << "\n" << model->getStatData()
              << "\n---------------------\n";
    result = model->evaluate(colors4);
    std::cout << "\n---------------------\n 400 Result: " << result << "\n" << model->getStatData()
              << "\n---------------------\n";
    result = model->evaluate(colors5);
    std::cout << "\n---------------------\n  70 Result: " << result << "\n" << model->getStatData()
              << "\n---------------------\n";

    //model->setRegressionType(RegressionModel::PCA_EXPONENTIAL);
    //result = model->evaluate(colors5);
    //std::cout << "\n---------------------\n  70 Result: " << result << "\n" << model->getStatData()
    //          << "\n---------------------\n";

    cv::Mat shit = model->getRawCalData();
    std::cout << shit << "\n\n";

    const void* blob;
    unsigned int len;

    factory.serializeToDB(model, blob, len);
    ModelPtr mod3;
    mod3 = factory.deserializeFromDB(blob, len);
    factory.serializeToDB(mod3, blob, len);
    ModelPtr mod4 = factory.deserializeFromDB(blob, len);
    factory.serializeToDB(mod4, blob, len);
    ModelPtr mod2 = factory.deserializeFromDB(blob, len);

    std::cout << "\nPost archive test";
    result = mod2->evaluate(colors);
    std::cout << "\n---------------------\n 40 Result: " << result
              << "\n---------------------\n";

    std::cout << "\nChucking and recalibrating test";
    model->chuckCalibration(model->getNumCalibrations() - 1);
    result = model->evaluate(colors4);
    std::cout << "\n---------------------\n 400 Result: " << result << "~~" << laterresult
              << "\n---------------------\n";
    model->calibrate(colors4, 400);
    result = model->evaluate(colors4);
    std::cout << "\n---------------------\n 400 Result: " << result
              << "\n---------------------\n";

    std::cout << "\nPlotting test, 400mg eval\n";
    for(int c = 60; c < 80; c++)
    {
        std::cout << c << " " << model->getRed(c) << " " << colors4[c*30][2] << " " << model->getRegressionPoint(0,c) << "\n";
    }

    model->evaluate(colors5);
    //exp.exportDiagnosticRun();
    //std::cout << "\n\n\n\n" << exp.getCSVData() << exp.getTextData() << "\n\n";

    std::cout << "\n\n\n" << model->getRawCalData() << "\n\n";
    //std::cout << model->getFinalCalStatData() << "\n";

    std::cout << exp.getTextData() << "\n";

    //model->setRegressionGraphType(RegressionModel::PCA_EXPONENTIAL);
    float left, right;
    model->getPCASpaceRange(left, right);


    for(float c = left; c < right; c += (right-left)/100)
    {
        std::cout << c << " " << model->getFinalRegressionLine(c) << "\n";
    }


}
