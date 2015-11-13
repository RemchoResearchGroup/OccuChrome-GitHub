
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


#ifndef _MODEL_ENTRY_H_
#define _MODEL_ENTRY_H_

#include <string>

class ModelEntry {
public:
  std::string name;
  const void *data;
  int length;
  std::string units;

  ModelEntry(std::string name, const void *data, int length, std::string units) : name(name), data(data), length(length), units(units) { }
};

#endif
