#define DEBUG_MODE

#include <iostream>
#include <opencv2/highgui/highgui.hpp>

#include "vision/BiomarkerImageProcessor.h"
#include "vision/CircularSampleAreaDetector.h"
#include "persistence/DataStore.h"
#include "regression/RegressionFactory.h"
#include "regression/RegressionModel.h"

#define FRAME_SKIP 0

/*
 * Skip n frames returning the n+1 frame. Returns NULL if no frames are
 * available.
 */
bool skipNFrames(cv::VideoCapture capture, int n, cv::Mat *image) {
  for(int i = 0; i < n + 1; i++) {
    if(!capture.read(*image)) {
      return false;
    }
  }

  return true;
}

int main(int argc, char **argv) {
  if(argc < 2) {
    std::cerr << "Usage: " << argv[0] << " [file_name]" << std::endl;
    return 0;
  }

  BiomarkerImageProcessor processor;

  cv::namedWindow("blur_win", CV_WINDOW_AUTOSIZE);
  cv::namedWindow("canny_win", CV_WINDOW_AUTOSIZE);
  cv::namedWindow("img_win", CV_WINDOW_AUTOSIZE);
  cv::VideoCapture cap(argv[1]);

  DataStore p = DataStore::open("jkk_store.sqlite3");
  p.createTables();

  ResultEntry entry(-1, "My Model", "Bob", "Some notes", "now", 66.6, "", "", "some stats");
  p.insertResultEntry(entry);

  // char *str = "SOMEDATA";
  // void *ptr = str;
  // ModelEntry mod("My Model", ptr, 7);
  // p.insertModelEntry(mod);

  // RegressionFactory factory;
  // factory.createNew("mymodel_ser", "mytest_ser");
  // factory.addNewComponent(ModelComponent::LINEAR, 0, 10, ModelComponent::RED);

  // ModelPtr myModel = factory.getCreatedModel();

  // const void *blob;
  // unsigned int len;
  // factory.serializeToDB(myModel, blob, len);

  // ModelEntry mod(myModel->getModelName(), blob, len);
  // p.insertModelEntry(mod);

  // std::vector<ModelEntry> entries = p.findAllModelEntries();
  // for(int i = 0; i < entries.size(); i++) {
  //   std::cout << entries[i].name << " (" << entries[i].length << " bytes)" << std::endl;
  //   std::vector<ResultEntry> results = p.findResultsForModelName(entries[i].name);
  //   ModelPtr deserModel = factory.deserializeFromDB(entries[i].data, entries[i].length);
  //   std::cout << "Deserialized -- name: " << deserModel->getModelName() << std::endl;
  //   std::cout << "  Entries: ";
  //   for(int j = 0; j < results.size(); j++) {
  //     std::cout << results[i].subjectName << ", ";
  //   }
  //   std::cout << std::endl;
  // }
  // p.close();

  cv::Mat frame;
  // skipNFrames(cap, 8730, &frame);

  std::vector<cv::Vec3f> circles;
  while(true) {
    bool got_frame = skipNFrames(cap, FRAME_SKIP, &frame);

    if(got_frame) {
      CircularSampleAreaDetector detector;
      circles = detector.detect(frame);

      // Just to draw the circle...
      processor.process(frame, circles);

      cv::imshow("img_win", frame);
    } else {
      break;
    }

    char key = cvWaitKey(0);
    if(key == 'y') {
      break;
    }
  }

  processor.reset();

  while(true) {
    bool got_frame = skipNFrames(cap, FRAME_SKIP, &frame);

    if(got_frame) {
      std::vector<cv::SerializableScalar> samples = processor.process(frame, circles);
      if(samples.size() > 0) {
        cv::SerializableScalar sample = samples[0];
        std::cout << sample[0] << "," << sample[1] << "," << sample[2] << "," << sample[3] << "," << processor.getAverageStdDev()[0] << std::endl;
      }

      cv::imshow("img_win", frame);
    } else {
      break;
    }

    char key = cvWaitKey(1);
    if(key == 27) {
      break;
    }
  }

  return 0;
}
