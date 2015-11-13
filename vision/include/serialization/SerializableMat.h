
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

#ifndef _SER_MAT_H
#define _SER_MAT_H

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <vector>
#include <iostream>


//forward declaring serialization class
namespace boost{
namespace serialization{
class access;
}
}

namespace cv{

    // extension of a cv::Mat that can be serialized into a boost archive
    class SerializableMat : public cv::Mat
    {
    public:
        //default constructor, simply calls default cv::Mat constructor
        SerializableMat();

        //constructor taking a cv::Mat so we can have an implicit conversion
        //from cv::Mat -> cv::SerializableMat. Allows us to send cv::Mats
        //into template functions of type cv::SerializableMat.
        //Calls putMatrix to fill in the data.
        SerializableMat(cv::Mat mat);

        //copies the data from a given cv::Mat into this object
        void putMatrix(cv::Mat mat);

        friend class boost::serialization::access;

    private:
        //underlying representation for boost-friendly serialization
        std::vector< std::vector< float> > mMat;

        template<typename Archive>
        void serialize(Archive& ar, const unsigned version)
        {
            (void)version;

            //serialization code, packs contents of this object into the
            //vector-of-vectors, mMat

            std::vector<float> blankRow;
            int height, width;
            height = size().height;
            width = size().width;
            for(int c = 0; c < height; c++)
            {
                //push a blank row...
                mMat.push_back(blankRow);
                for(int i = 0; i < width; i++)
                {
                    //...then push in each column's values
                    mMat[c].push_back(row(c).at<float>(i));
                }
            }

            //push/pull data to/from archive
            ar & mMat;


            //deserialization code, unpacks contents of the vector-of-vectors
            //into this object

            height = mMat.size();
            width = 0;
            if(height > 0)
                width = mMat[0].size();

            cv::Mat rowMat(1, width, CV_32F);

            //make sure we're starting with a blank matrix
            release();
            for(int c = 0; c < height; c++)
            {
                //then push back a blank row...
                push_back(rowMat);
                for(int i = 0; i < width; i++)
                {
                    //...and fill in each column's value
                    row(c).at<float>(i) = mMat[c][i];
                }
            }

            //release the contents of our vector-of-vectors so that we don't
            //double the memory footprint of every cv::Mat
            mMat.clear();
        }
    };

}

#endif
