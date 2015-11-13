
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

#include "vision/BiomarkerImageProcessor.h"

#include <iostream>
#include <boost/timer/timer.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

#include "vision/CircularSampleAreaDetector.h"

/* Predefined circle locations to use when circle detection is disabled.
 */
#define DEFAULT_CIRCLE_CENTER_X      317.5
#define DEFAULT_CIRCLE_CENTER_Y      237.5
#define DEFAULT_CIRCLE_RADIUS        30.0

BiomarkerImageProcessor::BiomarkerImageProcessor() :
circleCenterX(DEFAULT_CIRCLE_CENTER_X),
circleCenterY(DEFAULT_CIRCLE_CENTER_Y),
circleRadius(DEFAULT_CIRCLE_RADIUS),
circleDetectionEnabled(true) {
}

void BiomarkerImageProcessor::reset() {
    // Timer starts here
    timer = boost::timer::cpu_timer();
    
    // Clear any samples from previous runs
    samples.clear();
    averageStdDev = cv::Scalar::all(0);
    frameCount = 0;
}

std::vector<cv::SerializableScalar> BiomarkerImageProcessor::process(cv::Mat frame, std::vector<cv::Vec3f> circles) {
    
    
    if(this->samples.size() < circles.size()) {
        this->samples.push_back(std::vector<cv::SerializableScalar>());
    }
    std::vector<cv::SerializableScalar> frameSamples;
    for(size_t i = 0; i < circles.size(); i++) {
        // Sample is a 4-vec of [R, G, B, time]
        cv::Mat mask = cv::Mat::zeros(frame.size(), CV_8UC1);
        cv::circle(mask, cv::Point(circles[i][0], circles[i][1]), circles[i][2], cv::Scalar(255), -1);  // img, centerpoint(x,y), radius, color, -1=filled circle
//        fprintf(stderr, "%s (%f:%f):%f]\n",
//                "Mask(XYR): ",
//                circles[i][0],circles[i][1], circles[i][2]);
        
        cv::Scalar sample = this->sampleSlide(frame, mask);
        
#ifdef DEBUG_MODE
        // Draw the circle to the image
        cv::circle(frame, cv::Point(circles[i][0], circles[i][1]), circles[i][2], sample, 5);
#endif
        
        boost::timer::nanosecond_type const one_second(1 * 1000000000LL);
        sample[3] = (float) timer.elapsed().wall / (float) one_second;
        
        cv::SerializableScalar ser(sample);
        frameSamples.push_back(sample);
        
        this->samples[i].push_back(ser);
    }
    
    return frameSamples;
}

/*
 * Take a color average of a slide, masking out the area we are not interested
 * in.
 */
cv::Scalar BiomarkerImageProcessor::sampleSlide(cv::Mat frame, cv::Mat roi) {
    // Find the average of all pixels within that mask
    cv::Scalar avg;
    cv::Scalar stddev;
//    double min, max;
    
    cv::meanStdDev(frame, avg, stddev, roi);
//    cv::minMaxLoc(frame, &min, &max);
    
/*    fprintf(stderr, "%s [%f:%f:%f]->[%f:%f:%f]\n",
            "RGB: ",
            avg.val[2],avg.val[1],avg.val[0],
            stddev.val[2],stddev.val[1],stddev.val[0]);
 */
    frameCount++;
    averageStdDev += ((stddev - averageStdDev) / frameCount);
    
    return avg;
}


