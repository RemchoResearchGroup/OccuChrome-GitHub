
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

#ifndef _DATA_STORE_H_
#define _DATA_STORE_H_

#include <string>
#include <vector>
#include <sqlite3.h>

#include "ModelEntry.h"
#include "ResultEntry.h"

class DataStore {
public:
  /* Open a database file. If it does not exist, it will be created. */
  static DataStore open(std::string db_path);

  /* Create the database schema. If the schema already exists, nothing will be
   * changed. */
  void createTables();

  /* Close the database file. */
  void close();

  std::vector<ModelEntry> findAllModelEntries();
  ModelEntry findModelEntryByName(std::string name);
  std::vector<ResultEntry> findAllResultEntries();
  std::vector<ResultEntry> findResultsForModelName(std::string name);
  ResultEntry findResultForIdWithExportdData(int id);

  void insertModelEntry(ModelEntry entry);
  int insertResultEntry(ResultEntry entry);

  void deleteModelEntry(std::string name);
  void deleteResultEntry(int id);
private:
  DataStore(sqlite3 *db);

  sqlite3_stmt *query(const char *q);

  sqlite3 *db;
};

#endif
