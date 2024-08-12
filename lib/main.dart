import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chart Infinite Scrolling',
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  MyHomePageState();

  GlobalKey<State> _globalKey = GlobalKey<State>();
  ChartSeriesController<ChartData, num>? _seriesController;
  final ScrollController _scrollController = ScrollController();
  late ZoomPanBehavior _zoomPanBehavior;
  late List<ChartData> _chartData;
  bool _isLoadMoreView = false;
  bool _isNeedToUpdateView = false;
  bool _isDataUpdated = true;
  num? _oldAxisVisibleMin;
  num? _oldAxisVisibleMax;

  @override
  void initState() {
    _chartData = <ChartData>[
      ChartData(x: 0, y: 326),
      ChartData(x: 1, y: 416),
      ChartData(x: 2, y: 290),
      ChartData(x: 3, y: 70),
      ChartData(x: 4, y: 500),
      ChartData(x: 5, y: 416),
      ChartData(x: 6, y: 290),
      ChartData(x: 7, y: 120),
      ChartData(x: 8, y: 500),
    ];
    _zoomPanBehavior = ZoomPanBehavior(enablePanning: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildInfiniteScrollingChart(),
      ),
    );
  }

  SfCartesianChart _buildInfiniteScrollingChart() {
    return SfCartesianChart(
      key: GlobalKey<State>(),
      plotAreaBorderWidth: 0,
      title: const ChartTitle(text: 'Flutter Chart Infinite Scrolling'),
      onActualRangeChanged: (ActualRangeChangedArgs args) {
        if (args.orientation == AxisOrientation.horizontal) {
          if (_isLoadMoreView) {
            args.visibleMin = _oldAxisVisibleMin;
            args.visibleMax = _oldAxisVisibleMax;
          }
          _oldAxisVisibleMin = args.visibleMin as num;
          _oldAxisVisibleMax = args.visibleMax as num;
          _isLoadMoreView = false;
        }
      },
      primaryXAxis: NumericAxis(
        interval: 2,
        enableAutoIntervalOnZooming: false,
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        majorGridLines: const MajorGridLines(width: 0),
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          return ChartAxisLabel(details.text.split('.')[0], null);
        },
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(color: Colors.transparent),
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          return ChartAxisLabel(details.text, null);
        },
      ),
      zoomPanBehavior: _zoomPanBehavior,
      series: _buildSeries(),
      loadMoreIndicatorBuilder:
          (BuildContext context, ChartSwipeDirection direction) {
        return _buildloadMoreIndicator(context, direction);
      },
    );
  }

  List<CartesianSeries<ChartData, num>> _buildSeries() {
    const Color color = Color.fromARGB(255, 13, 157, 35);
    return <CartesianSeries<ChartData, num>>[
      SplineAreaSeries<ChartData, num>(
        dataSource: _chartData,
        xValueMapper: (ChartData data, int index) => data.x!,
        yValueMapper: (ChartData data, int index) => data.y!,
        borderColor: color,
        gradient: LinearGradient(
          colors: <Color>[color.withOpacity(0.3), Colors.white],
          stops: const <double>[0.5, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        onRendererCreated: (ChartSeriesController<ChartData, num> controller) {
          _seriesController = controller;
        },
      ),
    ];
  }

  Widget _buildloadMoreIndicator(
      BuildContext context, ChartSwipeDirection direction) {
    if (direction == ChartSwipeDirection.end) {
      _isNeedToUpdateView = true;
      _globalKey = GlobalKey<State>();
      return StatefulBuilder(
          key: _globalKey,
          builder: (BuildContext context, StateSetter stateSetter) {
            Widget widget;
            if (_isNeedToUpdateView) {
              widget = _progressIndicator();
              _updateView();
              _isDataUpdated = true;
            } else {
              widget = Container();
            }
            return widget;
          });
    } else {
      return SizedBox.fromSize(size: Size.zero);
    }
  }

  Widget _progressIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(),
        child: Container(
          width: 50,
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.74)
              ],
              stops: const <double>[0.0, 1],
            ),
          ),
          child: const SizedBox(
            height: 35,
            width: 35,
            child: CircularProgressIndicator(
              backgroundColor: Colors.transparent,
              strokeWidth: 4,
            ),
          ),
        ),
      ),
    );
  }

  void _updateData() {
    for (int i = 0; i < 4; i++) {
      _chartData.add(ChartData(
        x: _chartData[_chartData.length - 1].x! + 1,
        y: _randomInt(0, 600),
      ));
    }
    _isLoadMoreView = true;
    _seriesController?.updateDataSource(
      addedDataIndexes: _indexes(4),
    );
  }

  Future<void> _updateView() async {
    await Future<void>.delayed(const Duration(seconds: 1), () {
      _isNeedToUpdateView = false;
      if (_isDataUpdated) {
        _updateData();
        _isDataUpdated = false;
      }
      if (_globalKey.currentState != null) {
        (_globalKey.currentState as dynamic).setState(() {});
      }
    });
  }

  List<int> _indexes(int length) {
    final List<int> indexes = <int>[];
    final int lastIndex = length - 1;
    for (int i = lastIndex; i >= 0; i--) {
      indexes.add(_chartData.length - 1 - i);
    }
    return indexes;
  }

  int _randomInt(int min, int max) {
    final Random random = Random();
    final int result = min + random.nextInt(max - min);
    return result < 50 ? 95 : result;
  }

  @override
  void dispose() {
    _seriesController = null;
    _scrollController.dispose();
    super.dispose();
  }
}

class ChartData {
  ChartData({this.x, this.y});
  num? x;
  num? y;
}
