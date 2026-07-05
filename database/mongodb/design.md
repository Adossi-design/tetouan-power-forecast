# MongoDB design for the readings collection

_Task 2 by Shem Ayioka._

## The reasoning behind my design

On the MySQL side I split everything into three tables, but for MongoDB I decided to go the other way on purpose, and my reasoning was simple. Whenever I actually query this data I nearly always want the weather and all three zone values for the same moment at once, so joining separate pieces back together would only make my life harder for no real gain. A document database lets me keep the whole moment as one object, which fits this kind of reading much more naturally than a pile of joined rows would.

So I use a single collection called readings, and each document stands for one timestamp. I keep the weather fields at the top level of the document, and I hold the three zones inside an array where every item carries a zone number and its consumption value. I also worked out the total for that moment ahead of time and stored it in the document, because a lot of my time based queries only care about the total and I did not want them recomputing the sum on every single call.

## What one of my documents looks like

```json
{
  "datetime": ISODate("2017-01-01T00:00:00Z"),
  "temperature": 6.559,
  "humidity": 73.8,
  "wind_speed": 0.083,
  "general_diffuse_flows": 0.051,
  "diffuse_flows": 0.119,
  "zones": [
    { "zone": 1, "consumption": 34055.6962 },
    { "zone": 2, "consumption": 16128.87538 },
    { "zone": 3, "consumption": 20240.96386 }
  ],
  "total_consumption": 70425.53544
}
```

## A second sample document

Here is the very next reading, ten minutes later, so you can see how my documents follow one another through time.

```json
{
  "datetime": ISODate("2017-01-01T00:10:00Z"),
  "temperature": 6.414,
  "humidity": 74.5,
  "wind_speed": 0.083,
  "general_diffuse_flows": 0.070,
  "diffuse_flows": 0.085,
  "zones": [
    { "zone": 1, "consumption": 29814.68354 },
    { "zone": 2, "consumption": 19375.07599 },
    { "zone": 3, "consumption": 20131.08434 }
  ],
  "total_consumption": 69320.84387
}
```

## The index I added

I put a unique index on the datetime field, and it quietly does two jobs for me at once. It stops the same timestamp from being stored twice by accident, and it also keeps my latest and date range queries fast, because Mongo can use the index to jump straight to the right documents instead of scanning the whole collection.

```js
db.readings.createIndex({ datetime: 1 }, { unique: true })
```
