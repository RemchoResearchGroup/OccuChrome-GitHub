
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

#include <vector>
#include <opencv2/highgui/highgui.hpp>

#include "vision/CircularSampleAreaDetector.h"

std::vector<cv::Vec3f> CircularSampleAreaDetector::detect(cv::Mat frame) {
  // Convert the image to grayscale
  cv::Mat frame_gray(frame);
  cv::cvtColor(frame, frame_gray, CV_BGR2GRAY);

  // cv::cvtColor(frame, frame_gray, CV_BGR2HSV);
  // std::vector<cv::Mat> channels;
  // cv::split(frame_gray, channels);
  // frame_gray = channels[2];

  // Blur to remove extraneous detail before edge detection
  // cv::medianBlur(frame_gray, frame_gray, 9);
  // cv::blur(frame_gray, frame_gray, cv::Size(3, 3));
  cv::GaussianBlur(frame_gray, frame_gray, cv::Size(9, 9), 2, 2);

  // cv::imshow("blur_win", frame_gray);

  // Edge detection
  // cv::adaptiveThreshold(frame_gray, frame_gray, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 11, 1);
  cv::Mat frame_canny;

  // int erosion_size = 2;
  // cv::Mat element = getStructuringElement(cv::MORPH_ELLIPSE,
  //     cv::Size( 2*erosion_size + 1, 2*erosion_size+1),
  //     cv::Point( erosion_size, erosion_size ));
  // cv::dilate(frame_gray, frame_gray, element );
  // cv::erode(frame_gray, frame_gray, element );

  // cv::Canny(frame_gray, frame_canny, 5, 50);
  // cv::imshow("canny_win", frame_canny);

  // Extract circle features
  std::vector<cv::Vec3f> circles;
  // HoughCircles(frame_gray, circles, CV_HOUGH_GRADIENT, 1, 50, 50, 40, 0, 0);
  HoughCircles(frame_gray, circles, CV_HOUGH_GRADIENT,
      2,   // inverse resolution ratio
      50,  // min dist between circle centers
      50,  // canny upper threshold
      150,  // center detection threshold
      0,   // min radius
      0    // max radius
    );
  // HoughCircles(frame_gray, circles, CV_HOUGH_GRADIENT,
  //     1,   // inverse resolution ratio
  //     50,  // min dist between circle centers
  //     50,  // canny upper threshold
  //     50,  // center detection threshold
  //     0,   // min radius
  //     0    // max radius
  //   );

  // Of the circles found, pick the one closest to the center of the frame
  // TODO: This is not the best way to do this. Research probabilistic methods?
  cv::Point frame_center(frame_gray.cols / 2, frame_gray.rows / 2);

  std::vector<cv::Vec3f> good_circles;
  for(size_t i = 0; i < circles.size(); i++) {
    cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
    int radius = circles[i][2];

    // Ensure circle is entirely in screen
    if(center.x - radius < 0 || center.x + radius > frame_gray.cols
        || center.y - radius < 0 || center.y + radius > frame_gray.rows) {
      continue;
    }

    good_circles.push_back(cv::Vec3f(circles[i][0], circles[i][1], circles[i][2] * CIRCLE_SHRINK_FACTOR));
  }

  return good_circles;
}
