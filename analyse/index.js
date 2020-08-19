const fs = require("fs");
const DATA_DIR = "../mount/tests/";
const siegeParse = require("siege-parser");
const createCsvWriter = require("csv-writer").createObjectCsvWriter;

const jvms = fs.readdirSync(DATA_DIR);

function stripMarkup(val) {
  if (val.replace) {
    return val.replace(/\s|[A-Za-z]|\/|%+/, "");
  } else {
    return val;
  }
}

const report = [];
for (const jvm of jvms) {
  const data = { jvm };
  const siege1 = siegeParse(
    fs
      .readFileSync(`${DATA_DIR}${jvm}/siege1.txt`)
      .toString()
      .split("Lifting the server siege...")[1]
  );
  Object.keys(siege1).forEach((k) => {
    data[`Cold ${k}`] = stripMarkup(siege1[k]);
  });
  const siege2 = siegeParse(
    fs
      .readFileSync(`${DATA_DIR}${jvm}/siege2.txt`)
      .toString()
      .split("Lifting the server siege...")[1]
  );
  Object.keys(siege2).forEach((k) => {
    data[`Warm ${k}`] = stripMarkup(siege2[k]);
  });

  Object.keys(siege2).forEach((k) => {
    data[`Avg ${k}`] = (stripMarkup(siege1[k]) + stripMarkup(siege2[k])) / 2.0;
  });

  const stats = fs
    .readFileSync(`${DATA_DIR}${jvm}/stats.txt`)
    .toString()
    .split(/\n/);
  data["Start Time"] = stats[1].split(",")[1] - stats[0].split(",")[1];
  data["Package Install Time"] =
    stats[3].split(",")[1] - stats[2].split(",")[1];

  const activity = fs
    .readFileSync(`${DATA_DIR}${jvm}/activity.txt`)
    .toString()
    .split(/\n/)
    .slice(1)
    .map((a) => a.split(/\s+/).slice(1));

  console.log(
    (data["Max CPU"] = activity.map((a) => a[2]).map((v) => parseFloat(v)))
  );
  data["Max CPU"] = activity
    .map((a) => a[1])
    .filter((v) => !isNaN(v))
    .map((v) => parseFloat(v))
    .reduce((a, b) => Math.max(a, b));
  data["Avg CPU"] =
    activity
      .map((a) => a[1])
      .filter((v) => !isNaN(v))
      .map((v) => parseFloat(v))
      .reduce((a, b) => a + b, 0) / activity.length;
  data["Max Real Memory"] = activity
    .map((a) => a[2])
    .filter((v) => !isNaN(v))
    .map((v) => parseFloat(v))
    .reduce((a, b) => Math.max(a, b));
  data["Avg Real Memory"] =
    activity
      .map((a) => a[2])
      .filter((v) => !isNaN(v))
      .map((v) => parseFloat(v))
      .reduce((a, b) => a + b, 0) / activity.length;
  data["Max Virtual Memory"] = activity
    .map((a) => a[3])
    .filter((v) => !isNaN(v))
    .map((v) => parseFloat(v))
    .reduce((a, b) => Math.max(a, b));
  data["Avg Virtual Memory"] =
    activity
      .map((a) => a[3])
      .filter((v) => !isNaN(v))
      .map((v) => parseFloat(v))
      .reduce((a, b) => a + b, 0) / activity.length;

  report.push(data);
}

const csvWriter = createCsvWriter({
  path: "data.csv",
  header: [
    { id: "jvm", title: "JVM Vendor" },
    { id: "Cold transactions", title: "Cold transactions" },
    { id: "Cold availability", title: "Cold availability" },
    { id: "Cold elapsedTime", title: "Cold elapsedTime" },
    { id: "Cold dataTransferred", title: "Cold dataTransferred" },
    { id: "Cold responseTime", title: "Cold responseTime" },
    { id: "Cold transactionRate", title: "Cold transactionRate" },
    { id: "Cold throughput", title: "Cold throughput" },
    { id: "Cold concurrency", title: "Cold concurrency" },
    { id: "Cold successfulTransactions", title: "Cold successfulTransactions" },
    { id: "Cold failedTransactions", title: "Cold failedTransactions" },
    { id: "Cold longestTransaction", title: "Cold longestTransaction" },
    { id: "Cold shortestTransaction", title: "Cold shortestTransaction" },
    { id: "Warm transactions", title: "Warm transactions" },
    { id: "Warm availability", title: "Warm availability" },
    { id: "Warm elapsedTime", title: "Warm elapsedTime" },
    { id: "Warm dataTransferred", title: "Warm dataTransferred" },
    { id: "Warm responseTime", title: "Warm responseTime" },
    { id: "Warm transactionRate", title: "Warm transactionRate" },
    { id: "Warm throughput", title: "Warm throughput" },
    { id: "Warm concurrency", title: "Warm concurrency" },
    { id: "Warm successfulTransactions", title: "Warm successfulTransactions" },
    { id: "Warm failedTransactions", title: "Warm failedTransactions" },
    { id: "Warm longestTransaction", title: "Warm longestTransaction" },
    { id: "Warm shortestTransaction", title: "Warm shortestTransaction" },
    { id: "Avg transactions", title: "Avg transactions" },
    { id: "Avg availability", title: "Avg availability" },
    { id: "Avg elapsedTime", title: "Avg elapsedTime" },
    { id: "Avg dataTransferred", title: "Avg dataTransferred" },
    { id: "Avg responseTime", title: "Avg responseTime" },
    { id: "Avg transactionRate", title: "Avg transactionRate" },
    { id: "Avg throughput", title: "Avg throughput" },
    { id: "Avg concurrency", title: "Avg concurrency" },
    { id: "Avg successfulTransactions", title: "Avg successfulTransactions" },
    { id: "Avg failedTransactions", title: "Avg failedTransactions" },
    { id: "Avg longestTransaction", title: "Avg longestTransaction" },
    { id: "Avg shortestTransaction", title: "Avg shortestTransaction" },
    { id: "Start Time", title: "Start Time" },
    { id: "Package Install Time", title: "Package Install Time" },
    { id: "Max CPU", title: "Max CPU" },
    { id: "Avg CPU", title: "Avg CPU" },
    { id: "Max Real Memory", title: "Max Real Memory" },
    { id: "Avg Real Memory", title: "Avg Real Memory" },
    { id: "Max Virtual Memory", title: "Max Virtual Memory" },
    { id: "Avg Virtual Memory", title: "Avg Virtual Memory" },
  ],
});

csvWriter
  .writeRecords(report)
  .then(() => console.log("The CSV file was written successfully"));
