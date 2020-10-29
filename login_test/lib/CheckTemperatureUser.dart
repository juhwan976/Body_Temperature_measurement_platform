import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckTemperatureUserPage extends StatelessWidget {
  CheckTemperatureUserPage(
      {Key key, @required this.userId, @required this.isAdmin})
      : super(key: key);

  final bool isAdmin;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _CheckTemperatureUserPage(userId: userId, isAdmin: isAdmin),
    );
  }
}

class _CheckTemperatureUserPage extends StatefulWidget {
  _CheckTemperatureUserPage(
      {Key key, @required this.userId, @required this.isAdmin})
      : super(key: key);

  final String userId;
  final bool isAdmin;

  CheckTemperatureUser createState() =>
      CheckTemperatureUser(userId: userId, isAdmin: isAdmin);
}

class CheckTemperatureUser extends State with TickerProviderStateMixin {
  CheckTemperatureUser(
      {Key key, @required this.userId, @required this.isAdmin});

  final String userId; // 이전페이지로부터 전달받은 유저 아이디.
  final bool isAdmin; // 이전페이지로부터 전달받은 관라지인지 판단하는 변수. 다듬을 수 있다면 뺼것.

  String date; // qr 코드에 들어갈 데이터값
  int expireCount = 0; // qr 코드가 만료되었는지 유저쪽에서 판별할 변수.
  bool isCertied = false; // 인증되었는지 판단할 변수
  bool showResetBtn = false; // 새로고침 버튼을 표시할지 말지 판단하는 변수.

  /* 온도계 그림을 그리기 위한 변수 */
  final int baseY = 200; // 그림을 그릴 때 베이스 y 값
  double height = 300; // 처음 출력하는 체온계의 높이를 저장한 값. 다른값으로 바뀜.
  double temperature = 37; // 온도 출력 구문에 나올 변수.
  double realTemp;
  //final temperatureController = TextEditingController(); // 온도 입력 받는 필드.

  Animation<double> animation; // 애니메이션 값.
  AnimationController controller; // 애니메이션 컨트롤러

  /*
  Tween<double> _heightTween =
      Tween(begin: 450, end: 300); // 두 값 사이의 리스트를 만들어주는 듯?
  */
  bool isComplete = false; // 애니메이션이 끝났는지 판별하는 변수.
  bool isFirstUserResult =
      true; // UserResult 화면이 처음으로 출력되는지 판별하는 변수. initState 대응.

  // 입력받은 온도값으로부터 그림 기둥의 높이를 계산하는 메서드
  double calculateHeight(double temperature) {
    if (temperature > 39)
      return 185;
    else if (temperature < 35) {
      return 420;
    } else {
      return (450 - ((450 - 200) * (temperature - 34) / (39 - 34))) >= 450
          ? 450
          : (450 - ((450 - 200) * (temperature - 34) / (39 - 34)));
    }
  }

  // 서버로 QR Time을 전송하는 메서드.
  Future sendNCompareQRTime() async {
    final String url = 'QRUpdate.php';

    var data = {'UserID': userId, 'QRTime': whatDateIsItToday()};

    await http.post(url, body: json.encode(data));
  }

  // 현재 시간을 초 단위로 환산해주는 메서드.
  // 앱 구동 기기의 시스템 시간을 받아오기 때문에 시간을 임의로 변경 할 수 있음.
  // 나중에 서버에서 시간을 받아오는 방식으로 변경할 예정.
  // 데이터의 보안을 강화하기 위해서 encode 된 형태의 문자열을 사용할 수도 있을듯.
  String whatDateIsItToday() {
    var today, realToday, realTime;
    StringBuffer str = new StringBuffer();

    today = DateTime.now().toString().split(' ');
    realToday = today[0].split('-');

    for (int i = 0; i < realToday.length; i++) {
      str.write(realToday[i]);
    }

    realTime = today[1].split('.')[0].split(':');

    for (int i = 0; i < realTime.length; i++) {
      str.write(realTime[i]);
    }

    return str.toString();
  }

  // 유저화면, 서버로부터 인식되었는지 읽어들이는 메서드
  Future isCertified(String userId) async {
    final String url = 'IsUserCert.php';

    var data = {'UserID': userId};

    var response = await http.post(url, body: json.encode(data));

    var message = jsonDecode(response.body);

    // 만료를 판별하는데 버그가 있음.
    if (message.toString() == '0') {
      Future.delayed(Duration(milliseconds: 300), () {
        if (++expireCount == 200) {
          setState(() {
            expireCount = 0;
            showResetBtn = true;
          });
        } else {
          isCertified(userId);
        }
      });
    } else if (message.toString() == '1') {
      setState(() {
        isCertied = true;
        print('certification');
      });
    }
  }

  Future readTemperature() async {
    final String url = 'ReadRecord.php';

    var data = {'UserID': userId, 'year': '2020', 'month': '08'};

    var response = await http.post(url, body: json.encode(data));

    var message = jsonDecode(response.body);

    temperature = double.parse(message[message.length - 1].toString());
    realTemp = temperature;
  }

  // QR 출력 페이지 설정
  ScrollConfiguration _buildUserQR() {
    List<Container> containers = new List<Container>();

    if (!showResetBtn) {
      // QR Time을 전송하는 구문.
      sendNCompareQRTime();

      // 인식되었는지 확인하는 구문.
      isCertified(userId);

      date = whatDateIsItToday() + userId;
    }

    // 간격을 맞추기 위해서는 SizedBox가 더 효율적일지도 모르겠다는 생각이 들었다.
    containers.add(
      Container(
        child: Column(
          children: <Widget>[
            SizedBox(height: 100),
            SizedBox(
              // QR 코드 출력
              height: 250,
              width: 250,
              child: QrImage(
                data: date,
                version: QrVersions.auto,
                size: 250,
                gapless: true,
              ),
            ),
            SizedBox(height: 30),
            Padding(
              // 시간 안내 구문.
              padding: EdgeInsets.all(8.0),
              // 유효시간을 얼마로 할지 정확하게 정해지지는 않았지만, 일단은 1분으로 한다.
              child: Text('1분 이내에 인식해 주세요.', style: TextStyle(fontSize: 12)),
            ),
            SizedBox(height: 30),
            Visibility(
              visible: true /*showResetBtn*/,
              child: FlatButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.deepPurple,
                textColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('새로고침'),
                ),
                onPressed: null,
              ),
            ),
            SizedBox(height: 30),
            /*
            FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.deepPurple,
              textColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text('다음으로'),
              ),
              onPressed: () {
                setState(() {
                  isCertied = true;
                });
              },
            ),
            */
          ],
        ),
      ),
    );

    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          ...containers,
        ],
      ),
    );
  }

  // 유저 인증이 완료되었을 경우 출력화면
  ScrollConfiguration _buildUserResult() {
    List<Container> containers = new List<Container>();
    double resultHeight;

    // initState와 같은 역할을 한다.
    if (isFirstUserResult) {
      readTemperature();
      resultHeight = calculateHeight(realTemp);
      height = resultHeight;
      Tween<double> _heightTween = Tween(begin: 450, end: resultHeight);

      controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000),
      );

      animation = _heightTween.animate(controller)
        ..addListener(() {
          setState(() {});
        })
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            isComplete = true;
          } else if (status == AnimationStatus.dismissed) {
            controller.forward();
          }
        });

      isFirstUserResult = false;
      controller.forward();
    }

    containers.add(
      Container(
        child: Column(
          children: <Widget>[
            CustomPaint(
              painter:
                  MyPainter(value: animation.value, isComplete: isComplete),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 400,
            ),
            Padding(
              padding: EdgeInsets.zero,
              child: Text(
                '당신의 체온은',
                style: TextStyle(fontSize: 22),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                temperature.toString() + ' ℃',
                style: TextStyle(fontSize: 31),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                (temperature >= 37.5)
                    ? ((temperature >= 38)
                        ? Text(
                            '고열',
                            style: TextStyle(
                              fontSize: 31,
                              color: Colors.red[200],
                            ),
                          )
                        : Text('미열',
                            style: TextStyle(
                              fontSize: 31,
                              color: Colors.red[200],
                            )))
                    : ((temperature < 36)
                        ? Text(
                            '저체온',
                            style: TextStyle(
                              fontSize: 31,
                              color: Colors.red[200],
                            ),
                          )
                        : Text(
                            '정상',
                            style: TextStyle(
                              fontSize: 31,
                              color: Colors.green[200],
                            ),
                          )),
                Text(
                  ' 입니다.',
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            /*
            Text(
              '자신의 체온 입력.',
              style: TextStyle(fontSize: 10),
            ),
            SizedBox(width: 50),
            Row(
              children: <Widget>[
                SizedBox(width: 50),
                Expanded(
                  child: Container(
                    width: 200,
                    padding: EdgeInsets.all(0.0),
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: temperatureController,
                      autocorrect: false,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                ),
                ButtonTheme(
                  minWidth: 50,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(0.0),
                    child: RaisedButton(
                      child: Text('적용'),
                      textColor: Colors.white,
                      padding: EdgeInsets.all(0.0),
                      onPressed: isComplete ? updatePage : null,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                ),
              ],
            ),
            SizedBox(
              height: 100,
            ),
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    '온도 측정에 대한 정보',
                    style: TextStyle(fontSize: 21),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 100,
            ),*/
          ],
        ),
      ),
    );

    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          ...containers,
        ],
      ),
    );
  }

  // 어떤 화면을 출력할지 변수에 따라 다르게 나오게 해주는 메서드
  ScrollConfiguration _buildView() {
    if (!isCertied) {
      return _buildUserQR();
    } else {
      return _buildUserResult();
    }
  }

  // 화면 그리기
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildView(),
    );
  }
}

/* ListView를 사용할 시 화면에 나오는 애니매이션을 없애기 위해서 사용 */
class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

/* 온도계를 표시하기 위한 클래스 */
class MyPainter extends CustomPainter {
  MyPainter({Key key, @required this.value, @required this.isComplete});

  final double value;
  final bool isComplete;

  final double baseX = 0;
  final double baseY = 200;

  @override
  void paint(Canvas canvas, Size size) {
    var myPaint = Paint();

    myPaint.color = Colors.blue[100];
    canvas.drawRect(
        Rect.fromCenter(center: Offset(0, baseY), height: 300, width: 40),
        myPaint);

    canvas.drawCircle(Offset(0, 150 + baseY), 50, myPaint);
    canvas.drawCircle(Offset(0, -150 + baseY), 20, myPaint);

    myPaint.color = Colors.red[300];

    // 기둥 높이 정하기
    var height = value - 140;
    canvas.drawRect(Rect.fromLTRB(-10, height, 10, (150 + baseY)), myPaint);

    canvas.drawCircle(Offset(0, 150 + baseY), 40, myPaint);

    // 온도 표시하기
    if (isComplete) {
      myPaint.color = Colors.black;
      canvas.drawRect(
          Rect.fromLTRB(0, height - 1.5, 80, height + 1.5), myPaint);
      canvas.drawCircle(Offset(0, height), 8, myPaint);
      myPaint.color = Colors.white;
      canvas.drawCircle(Offset(0, height), 5, myPaint);
    }
    myPaint.color = Colors.black;

    for (int i = 0; i < 5; i++) {
      TextSpan span = new TextSpan(
        style: new TextStyle(color: Colors.black),
        text: (35 + i).toString(),
      );
      TextPainter tp = new TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, new Offset(100, 102.5 + baseY - (50 * (i + 1))));
    }

    double i = (110 + baseY - 50);

    while (i > -125 + baseY) {
      // 오른쪽 라인 그리기
      canvas.drawRect(
          Rect.fromPoints(Offset(50, i - 1), Offset(80, i)), myPaint);

      for (int j = 1; j < 5; j++)
        canvas.drawLine(Offset(50, i - j * 5), Offset(65, i - j * 5), myPaint);

      i -= 25;
    }
    canvas.drawRect(Rect.fromPoints(Offset(50, i - 1), Offset(80, i)), myPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
