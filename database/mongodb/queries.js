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


// Query 3 finds the newest reading.
// It sorts by time from new to old and takes one document.
db.readings.find(
  {},
  { _id: 0, datetime: 1, total_consumption: 1, zones: 1 }
).sort({ datetime: -1 }).limit(1)



// Query 4 is a bonus that finds the average consumption per zone.
// It unwinds the zones array and groups by zone number.
db.readings.aggregate([
  { $unwind: "$zones" },
  { $group: { _id: "$zones.zone", avg_consumption: { $avg: "$zones.consumption" } } },
  { $sort: { _id: 1 } }
])

