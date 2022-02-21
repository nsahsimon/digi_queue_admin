import 'dart:math';
import 'package:collection/collection.dart';


class DataAnalysis {
  List<int> timeDataInSeconds; //time intervals in seconds
  double _sd;
  double _mean;
  DataAnalysis({this.timeDataInSeconds});

  /// this method calculates the new time mean in minutes for the timeData dataset
  int trueMeanInMinutes() {
    List<int> newTimeData = []; //without outliers
    double mean = timeDataInSeconds.average;
    int dataLength = timeDataInSeconds.length;
    double sumOfDeviations = 0;
    for (int x in timeDataInSeconds) {
      sumOfDeviations = sumOfDeviations + pow((x - mean), 2);
    }
    double sd = sqrt((sumOfDeviations / dataLength));

    for (int x in timeDataInSeconds) {
      double zScore = (x - mean) / sd;
      if (zScore <= 2.5) {
        newTimeData.add(x);
      }
    }

    double trueMean = newTimeData.average;
    return (trueMean / 60).floor();
  } //Todo: this method is currently not in use, might need to enable it later on.

  ///this method calculates the new time mean in seconds for the timeData dataset
  int trueMeanInSeconds() {
    List<int> newTimeData = [];
    /// first outlier removal maxzScore = 2,
    print('first outlier removal session: ');
    newTimeData = removeOutliers(timeDataInSeconds, 2);
    /// second outlier removal maxzScore = 2.5,
    print('second outlier removal session');
    newTimeData = removeOutliers(newTimeData, 2.5);
    /// third outlier removal maxzScore = 3,
    print('Third outlier removal session');
    newTimeData = removeOutliers(newTimeData, 3);
    double trueMean = newTimeData.average;
    print('----true mean: $trueMean------');
    return trueMean.floor();
  }

  ///This method removes outliers(undesirable data points from a data set)
  ///whose zScore is less than a certain maximum zscore
  List<int> removeOutliers (List<int> data, double maxZScore) {
    List<int> newTimeData = []; //new timeData set without any outliers
    print('----calculating true mean------');
    double mean = data.average;
    int dataLength = data.length;
    double sumOfDeviations = 0;
    for (int x in data) {
      sumOfDeviations = sumOfDeviations + pow((x - mean), 2);
    }
    double sd = sqrt((sumOfDeviations / dataLength));
    print('------mean: $mean------');
    print('------stdDev: $sd------');
    for (int x in data) {
      double zScore = (x - mean) / sd;
      print('------x = $x, zScore= ${zScore.abs()}------, ${(zScore.abs() <= maxZScore) ? 'accepted' : 'rejected'}');
      if (zScore.abs() <= maxZScore) {
        newTimeData.add(x);
      }
    }
    return newTimeData;
  }

}

main() {
  List<int> data = [219, 102, 18, 25, 25, 19, 17, 13, 36];
  DataAnalysis(timeDataInSeconds: data).trueMeanInSeconds();
  print('hello world');
}
