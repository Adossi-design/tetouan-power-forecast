// Task 2 by Shem Ayioka.
// This file has MongoDB queries with their expected results.
// You can run it with: mongosh tetouan_power database/mongodb/queries.js

use("tetouan_power")

// Query 1 finds all readings on 1 January 2017.
// It returns the time and the total demand in time order.
db.readings.find(
  {
    datetime: {
      $gte: ISODate("2017-01-01T00:00:00Z"),
      $lt:  ISODate("2017-01-02T00:00:00Z")
    }
  },
  { _id: 0, datetime: 1, total_consumption: 1 }
).sort({ datetime: 1 }).limit(3)

// Expected result is the first three of the day:
// { datetime: 2017-01-01T00:00:00Z, total_consumption: 70425.53 }
// { datetime: 2017-01-01T00:10:00Z, total_consumption: 69320.84 }
// { datetime: 2017-01-01T00:20:00Z, total_consumption: 67803.22 }


// Query 2 finds the average total demand for each hour of day.
// It uses a group stage and confirms the evening peak.
db.readings.aggregate([
  {
    $group: {
      _id: { $hour: "$datetime" },
      avg_total: { $avg: "$total_consumption" }
    }
  },
  { $sort: { avg_total: -1 } },
  { $limit: 3 }
])

// Expected result top three hours:
// { _id: 20, avg_total: about 98037 }
// { _id: 19, avg_total: about 95645 }
// { _id: 21, avg_total: about 94632 }


// Query 3 finds the newest reading.
// It sorts by time from new to old and takes one document.
db.readings.find(
  {},
  { _id: 0, datetime: 1, total_consumption: 1, zones: 1 }
).sort({ datetime: -1 }).limit(1)

// Expected result is the last timestamp in the data:
// { datetime: 2017-12-30T23:50:00Z, zones: [ ... ], total_consumption: about 65750 }


// Query 4 is a bonus that finds the average consumption per zone.
// It unwinds the zones array and groups by zone number.
db.readings.aggregate([
  { $unwind: "$zones" },
  { $group: { _id: "$zones.zone", avg_consumption: { $avg: "$zones.consumption" } } },
  { $sort: { _id: 1 } }
])

// Expected result is about:
// { _id: 1, avg_consumption: 32344.97 }
// { _id: 2, avg_consumption: 21042.51 }
// { _id: 3, avg_consumption: 17835.41 }
