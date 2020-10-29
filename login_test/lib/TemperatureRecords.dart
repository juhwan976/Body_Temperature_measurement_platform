import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class TemperatureRecordPage extends StatelessWidget {
  TemperatureRecordPage({Key key, @required this.userId}) : super(key: key);

  final String userId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temerature Record Page',
      home: _TemperatureRecordPage(userId: userId),
    );
  }
}

class _TemperatureRecordPage extends StatefulWidget {
  _TemperatureRecordPage({Key key, @required this.userId}) : super(key: key);

  final String userId;

  TemperatureRecord createState() => TemperatureRecord(userId: userId);
}

class TemperatureRecord extends State {
  TemperatureRecord({Key key, @required this.userId});

  final String userId;
  List<String> record = new List<String>();
  bool isDisplaying = false;

  DateTime today = DateTime.now();

  // 유저 아이디를 바탕으로 고유 번호를 알아내고, 그 값으로 데이터 베이스에서 값을 찾아온다.
  Future readRecord() async {
    if (!isDisplaying) {
      isDisplaying = true;
      record.clear();

      final String url = 'ReadRecord.php';

      // 일별로가 아닌 월별로 데이터를 받아야 달력에 자신이 온도를 젠 날을 표시할 수 있다.
      var data = {'UserID': userId, 'year': today.year, 'month': today.month};

      var response = await http.post(url, body: json.encode(data));

      var message = jsonDecode(response.body);

      for (int i = 0; i < message.length; i++) {
        record.add(message[i]);
      }
      print(record);
    }
  }

  BoxDecoration decorationTile(int year, int month, int date) {
    DateTime destinationDay = DateTime(year, month, date);
    int rCount = 0, yCount = 0;
    Color color;
    bool isWork = false;

    for (int i = 0; i < record.length; i += 4) {
      if (record[i + 1].split(' ')[0] ==
          destinationDay.toString().split(' ')[0]) {
        isWork = true;
        if (double.parse(record[i + 3]) >= 38) {
          rCount++;
        } else if (double.parse(record[i + 3]) >= 37.5) {
          yCount++;
        } else if (double.parse(record[i + 3]) > 36) {
          /* do nothing */
        } else {
          yCount++;
        }
      }
    }

    if (rCount != 0 && isWork) {
      color = Colors.red[300];
    } else if (yCount != 0 && isWork) {
      color = Colors.yellow[300];
    } else if (rCount == 0 && yCount == 0 && isWork) {
      color = Colors.green[300];
    } else {
      color = null;
    }

    return BoxDecoration(color: color);
  }

  ListView makeTile(int year, int month, int date) {
    List<ListTile> listTiles = new List<ListTile>();
    DateTime destinationDay = DateTime(year, month, date);

    if (record != null) {
      for (int i = 0; i < record.length; i += 4) {
        if (record[i + 1].split(' ')[0] ==
            destinationDay.toString().split(' ')[0]) {
          listTiles.add(
            ListTile(
              leading: SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 5,
                    ),
                    Text(record[i + 2]),
                    Text(
                      record[i + 1].split(' ')[1].substring(0, 5),
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(record[i + 3] + ' ℃'),
            ),
          );
        }
      }
    }

    return ListView(
      children: <Widget>[
        ...listTiles,
      ],
    );
  }

  Column _buildTempPage() {
    readRecord();

    return Column(
      children: [
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(),
            ),
            ButtonTheme(
              minWidth: 20,
              child: FlatButton(
                child: Icon(Icons.autorenew),
                onPressed: () {
                  setState(() {
                    today = DateTime.now();
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  ' ' +
                      today.year.toString() +
                      '년 ' +
                      today.month.toString() +
                      '월 ',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 60,
            ),
            ButtonTheme(
              minWidth: 20,
              child: FlatButton(
                child: Icon(Icons.arrow_drop_up),
                onPressed: () {
                  setState(() {
                    today = DateTime(today.year, today.month + 1);
                  });
                },
              ),
            ),
            ButtonTheme(
              minWidth: 20,
              child: FlatButton(
                child: Icon(Icons.arrow_drop_down),
                onPressed: () {
                  setState(() {
                    today = DateTime(today.year, today.month - 1);
                  });
                },
              ),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          physics: ScrollPhysics(),
          shrinkWrap: true,
          children: <Widget>[
            Center(
              child: Text(
                'SUN',
                style: TextStyle(
                  color: Colors.red[300],
                ),
              ),
            ),
            Center(
              child: Text('MON'),
            ),
            Center(
              child: Text('TUE'),
            ),
            Center(
              child: Text('WED'),
            ),
            Center(
              child: Text('THU'),
            ),
            Center(
              child: Text('FRI'),
            ),
            Center(
              child: Text(
                'SAT',
                style: TextStyle(
                  color: Colors.blue[300],
                ),
              ),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          physics: ScrollPhysics(),
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          children: List.generate(
            DateTime(today.year, today.month + 1, 0).day +
                DateTime(today.year, today.month, 1).weekday,
            (index) {
              if (index + 1 <
                  DateTime(today.year, today.month, 1).weekday + 1) {
                return Center(
                  child: Text(' '),
                );
              } else {
                return Container(
                  padding: EdgeInsets.zero,
                  decoration: decorationTile(
                      today.year,
                      today.month,
                      (index -
                          DateTime(today.year, today.month, 1).weekday +
                          1)),
                  child: FlatButton(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            (index -
                                    DateTime(today.year, today.month, 1)
                                        .weekday +
                                    1)
                                .toString(),
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          (today.year == DateTime.now().year &&
                                  today.month == DateTime.now().month &&
                                  index -
                                          DateTime(today.year, today.month, 1)
                                              .weekday +
                                          1 ==
                                      DateTime.now().day)
                              ? Container(
                                  height: 2,
                                  width: 15,
                                  color: Colors.black,
                                )
                              : Container(
                                  height: 2,
                                ),
                        ],
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              title: Text(today.month.toString() +
                                  '월 ' +
                                  (index -
                                          DateTime(today.year, today.month, 1)
                                              .weekday +
                                          1)
                                      .toString() +
                                  '일'),
                              content: Container(
                                height: 300,
                                width: 300,
                                child:
                                    /*ListView(
                                    children: */
                                    makeTile(
                                        today.year,
                                        today.month,
                                        index -
                                            DateTime(today.year, today.month, 1)
                                                .weekday +
                                            1),
                                /*<Widget>[

                                    
                                    ListTile(
                                      leading: SizedBox(
                                        width: 150,
                                        child: Text('어울림관'),
                                      ),
                                      title: Text('37.5도'),
                                      subtitle: Text('미열'),
                                    ),
                                    ListTile(
                                      leading: SizedBox(
                                        width: 150,
                                        child: Text('국제대학'),
                                      ),
                                      title: Text('37.5도'),
                                      subtitle: Text('미열'),
                                    ),
                                    ListTile(
                                      leading: SizedBox(
                                        width: 150,
                                        child: Text('해양과학기술대학'),
                                      ),
                                      title: Text('37.5도'),
                                      subtitle: Text('미열'),
                                    ),
                                    ListTile(
                                      leading: SizedBox(
                                        width: 150,
                                        child: Text('해사대학'),
                                      ),
                                      title: Text('37.5도'),
                                      subtitle: Text('미열'),
                                    ),
                                  ],*/
                                /*    ),*/
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text('확인'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTempPage(),
    );
  }
}
