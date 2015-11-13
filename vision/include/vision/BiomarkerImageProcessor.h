
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

#ifndef __BIOMARKER_IMAGE_PROCESOR_H
#define __BIOMARKER_IMAGE_PROCESOR_H

#include <boost/timer/timer.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include "serialization/SerializableScalar.h"

class BiomarkerImageProcessor {
public:
  BiomarkerImageProcessor();

  /* Reset the internal timer to prepare for a new test run. */
  void reset();

  /* Process a single input frame and store the result. */
  std::vector<cv::SerializableScalar> process(cv::Mat frame, std::vector<cv::Vec3f> regions);

  /* Return the list of samples for the current test. */
  std::vector<std::vector<cv::SerializableScalar>> getSamples() { return samples; }

  /* Options */
  bool isCircleDetectionEnabled() { return this->circleDetectionEnabled; }
  void setCircleDetectionEnabled(bool c) { this->circleDetectionEnabled = c; }
  float getCircleCenterX() { return this->circleCenterX; }
  float getCircleCenterY() { return this->circleCenterY; }
  float getCircleRadius() { return this->circleRadius; }
  void setCircleCenterX(float x) { this->circleCenterX = x; }
  void setCircleCenterY(float y) { this->circleCenterY = y; }
  void setCircleRadius(float r) { this->circleRadius = r; }
  cv::Scalar getAverageStdDev() { return this->averageStdDev; }

private:
  boost::timer::cpu_timer timer;
  std::vector<std::vector<cv::SerializableScalar>> samples;
  float circleCenterX, circleCenterY;
  float circleRadius;
  bool circleDetectionEnabled;

  cv::Scalar averageStdDev;
  int frameCount = 0;

  cv::Scalar sampleSlide(cv::Mat frame, cv::Mat roi);
};

#endif
