
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

#include "persistence/DataStore.h"

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <stdexcept>

DataStore::DataStore(sqlite3 *db) : db(db) {}

DataStore DataStore::open(std::string db_path) {
  sqlite3 *db;
  if(sqlite3_open(db_path.c_str(), &db) != SQLITE_OK) {
    std::cout << "Error opening SQLite database" << std::endl;
  }

  return DataStore(db);
}

void DataStore::createTables() {
  const char *q =
    "CREATE TABLE IF NOT EXISTS model ("
       "name CHAR(50) PRIMARY KEY,"
       "data BLOB,"
       "units TEXT"
     ");";
  sqlite3_stmt *stmt = query(q);
  sqlite3_step(stmt);

  sqlite3_finalize(stmt);

  const char *q2 =
     "CREATE TABLE IF NOT EXISTS result ("
       "id INTEGER PRIMARY KEY AUTOINCREMENT,"
       "model_name CHAR(50),"
       "subject_name CHAR(50),"
       "notes TEXT,"
       "date TEXT,"
       "value REAL,"
       "exported_data TEXT,"
       "exported_message TEXT,"
       "statistics TEXT,"
       "FOREIGN KEY(model_name) REFERENCES model(name)"
     ");";

  sqlite3_stmt *stmt2 = query(q2);
  sqlite3_step(stmt2);

  sqlite3_finalize(stmt2);
}

void DataStore::close() {
  sqlite3_close(db);
}

std::vector<ModelEntry> DataStore::findAllModelEntries() {
  std::vector<ModelEntry> entries;

  const char *q = "select name, data, units from model order by name desc";
  sqlite3_stmt *stmt = query(q);

  int rc;
  while((rc = sqlite3_step(stmt)) != SQLITE_DONE) {
    switch(rc) {
      case SQLITE_ROW:
        std::string name(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 0)));
        int len = sqlite3_column_bytes(stmt, 1);
        void *data = std::malloc(len);
        std::memcpy(data, sqlite3_column_blob(stmt, 1), len);
        std::string units(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 2)));
        entries.push_back(ModelEntry(name, data, len, units));
        break;
    }
  }

  sqlite3_finalize(stmt);

  return entries;
}

ModelEntry DataStore::findModelEntryByName(std::string name) {
  const char *q = sqlite3_mprintf("select name, data, units from model where name = '%q'", name.c_str());
  sqlite3_stmt *stmt = query(q);

  int rc;
  while((rc = sqlite3_step(stmt)) != SQLITE_DONE) {
    switch(rc) {
      case SQLITE_ROW:
        std::string name(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 0)));
        int len = sqlite3_column_bytes(stmt, 1);
        void *data = std::malloc(len);
        std::memcpy(data, sqlite3_column_blob(stmt, 1), len);
        std::string units(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 2)));

        ModelEntry entry(name, data, len, units);

        sqlite3_free((void *) q);
        sqlite3_finalize(stmt);

        return entry;
    }
  }

  throw std::runtime_error("No model for given id");
}

std::vector<ResultEntry> DataStore::findAllResultEntries() {
  std::vector<ResultEntry> entries;

  const char *q = "select id, model_name, subject_name, notes, date, value, statistics from result order by date desc";
  sqlite3_stmt *stmt = query(q);

  int rc;
  while((rc = sqlite3_step(stmt)) != SQLITE_DONE) {
    switch(rc) {
      case SQLITE_ROW:
        int id = sqlite3_column_int(stmt, 0);
        std::string modelName(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 1)));
        std::string subjectName(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 2)));
        std::string notes(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 3)));
        std::string date(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 4)));
        double value = sqlite3_column_double(stmt, 5);
        std::string statistics(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 6)));

        entries.push_back(ResultEntry(id, modelName, subjectName, notes, date, value, "", "", statistics));
        break;
    }
  }

  sqlite3_finalize(stmt);

  return entries;
}

std::vector<ResultEntry> DataStore::findResultsForModelName(std::string modelName) {
  std::vector<ResultEntry> entries;

  const char *q = sqlite3_mprintf("select id, model_name, subject_name, notes, date, value, statistics from result where model_name = '%q'", modelName.c_str());
  sqlite3_stmt *stmt = query(q);

  int rc;
  while((rc = sqlite3_step(stmt)) != SQLITE_DONE) {
    switch(rc) {
      case SQLITE_ROW:
        int id = sqlite3_column_int(stmt, 0);
        std::string modelName(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 1)));
        std::string subjectName(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 2)));
        std::string notes(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 3)));
        std::string date(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 4)));
        double value = sqlite3_column_double(stmt, 5);
        std::string statistics(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 6)));

        entries.push_back(ResultEntry(id, modelName, subjectName, notes, date, value, "", "", statistics));
        break;
    }
  }

  sqlite3_free((void *) q);
  sqlite3_finalize(stmt);

  return entries;
}

ResultEntry DataStore::findResultForIdWithExportdData(int id) {
  const char *q = sqlite3_mprintf("select id, model_name, subject_name, notes, date, value, exported_data, exported_message, statistics from result where id = '%d'", id);
  sqlite3_stmt *stmt = query(q);

  int rc;
  while((rc = sqlite3_step(stmt)) != SQLITE_DONE) {
    switch(rc) {
      case SQLITE_ROW:
        int id = sqlite3_column_int(stmt, 0);
        std::string modelName(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 1)));
        std::string subjectName(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 2)));
        std::string notes(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 3)));
        std::string date(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 4)));
        double value = sqlite3_column_double(stmt, 5);
        std::string exportedData(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 6)));
        std::string exportedMessage(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 7)));
        std::string statistics(reinterpret_cast<char const*>(sqlite3_column_text(stmt, 8)));

        ResultEntry entry = ResultEntry(id, modelName, subjectName, notes, date, value, exportedData, exportedMessage, statistics);

        sqlite3_free((void *) q);
        sqlite3_finalize(stmt);

        return entry;
    }
  }

  throw std::runtime_error("No result for given id");
}

void DataStore::insertModelEntry(ModelEntry entry) {
  const char *q = "insert into model (name, data, units) values (?, ?, ?)";

  sqlite3_stmt *stmt = query(q);
  int rc = sqlite3_prepare_v2(db, q, -1, &stmt, 0);
  sqlite3_bind_text(stmt, 1, entry.name.c_str(), -1, NULL);
  sqlite3_bind_blob(stmt, 2, entry.data, entry.length, NULL);
  sqlite3_bind_text(stmt, 3, entry.units.c_str(), -1, NULL);

  sqlite3_step(stmt);

  if(rc != SQLITE_OK) {
    std::cerr << "SQL Error: " << sqlite3_errmsg(db) << std::endl;
  }

  sqlite3_finalize(stmt);
}

int DataStore::insertResultEntry(ResultEntry entry) {
  const char *q = sqlite3_mprintf("insert into result "
      "(model_name, subject_name, notes, date, value, exported_data, exported_message, statistics) "
      "values ('%q', '%q', '%q', '%q', %f, '%q', '%q', '%q')",
      entry.modelName.c_str(), entry.subjectName.c_str(), entry.notes.c_str(), entry.date.c_str(), entry.value, entry.exportedData.c_str(), entry.exportedMessage.c_str(), entry.statistics.c_str());

  sqlite3_stmt *stmt = query(q);
  sqlite3_step(stmt);

  sqlite3_free((void *) q);
  sqlite3_finalize(stmt);

  return sqlite3_last_insert_rowid(db);
}

void DataStore::deleteModelEntry(std::string name) {
  const char *q = sqlite3_mprintf("delete from model where name = '%q'", name.c_str());

  sqlite3_stmt *stmt = query(q);
  sqlite3_step(stmt);

  sqlite3_free((void *) q);
  sqlite3_finalize(stmt);
}

void DataStore::deleteResultEntry(int id) {
  const char *q = sqlite3_mprintf("delete from result where id = %d", id);

  sqlite3_stmt *stmt = query(q);
  sqlite3_step(stmt);

  sqlite3_free((void *) q);
  sqlite3_finalize(stmt);
}

sqlite3_stmt *DataStore::query(const char *q) {
  sqlite3_stmt *stmt;
  int rc = sqlite3_prepare_v2(db, q, -1, &stmt, 0);
  if(rc != SQLITE_OK) {
    std::cerr << "SQL Error: " << sqlite3_errmsg(db) << std::endl;
    return NULL;
  }

  return stmt;
}

