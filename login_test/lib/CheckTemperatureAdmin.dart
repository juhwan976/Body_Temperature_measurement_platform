import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:qrscan/qrscan.dart' as scanner;

import 'package:flutter_blue/flutter_blue.dart';

class CheckTemperatureAdminPage extends StatelessWidget {
  CheckTemperatureAdminPage({Key key, @required this.userId}) : super(key: key);

  final String userId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _CheckTemperatureAdminPage(userId: userId),
    );
  }
}

class _CheckTemperatureAdminPage extends StatefulWidget {
  _CheckTemperatureAdminPage({Key key, @required this.userId});

  final String userId;

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<ScanResult> devicesList = new List<ScanResult>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  CheckTemperatureAdmin createState() =>
      CheckTemperatureAdmin(/*userId: userId*/);
}

class CheckTemperatureAdmin extends State<_CheckTemperatureAdminPage>
    with TickerProviderStateMixin {
  //CheckTemperatureAdmin({Key key, @required this.userId});

  //final String userId; // 이전 페이지로부터 전달받은 유저 아이디.
  var readData; // qr scan으로 얻은 문자열을 저장할 변수.
  bool isScan = false; // qr scan으로 입력받았는지 여부를 판별하는 변수.
  bool isCheck = false; // qr 코드 값이 유효한지 서버에서 받은 응답.

  String temp;

  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;
  bool _isReceiving = false, _isConnecting = false, _isScanning = false;
  List<ScanResult> scanResult = new List<ScanResult>();
  bool isFirst = true;
  bool isTempComplete = false;
  double bleResult;

  StringBuffer str = new StringBuffer();

  /* 온도계 그림을 그리기 위한 변수 */
  final int baseY = 200; // 그림을 그릴 때 베이스 y 값
  double height = 300; // 처음 출력하는 체온계의 높이를 저장한 값. 다른값으로 바뀜.
  double temperature = 37; // 온도 출력 구문에 나올 변수.
  final temperatureController = TextEditingController(); // 온도 입력 받는 필드.
  String userId;

  Animation<double> animation; // 애니메이션 값.
  AnimationController controller; // 애니메이션 컨트롤러

  Tween<double> _heightTween =
      Tween(begin: 450, end: 300); // 두 값 사이의 리스트를 만들어주는 듯?
  bool isComplete = false; // 애니메이션이 끝났는지 판별하는 변수.
  bool isFirstUserResult =
      true; // UserResult 화면이 처음으로 출력되는지 판별하는 변수. initState 대응.

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

  // 서버에 기록된 시간을 읽어들이는 메서드.
  String whatDateIsItYesterday(String dateTime) {
    var today, realToday, realTime;
    StringBuffer str = new StringBuffer();

    today = dateTime.split(' ');
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

  // QR코드를 스캔하는 메서드.
  Future startScan() async {
    readData = await scanner.scan();

    // 스캔한 코드의 유효성을 판별하는 구문이 들어가야한다.
    // 우선 스캔한 코드가 의도한 값인지를 판별.
    // 값의 유효함은 문자열 비교를 통해서 한다.
    // 나중에는 서버에서 받아온 시간으로 하면 좋을듯.

    // null이 아닐 경우 문자도 포함되어있다.
    if (int.tryParse(readData.toString()) == null) {
      // 년(4) 월(2) 일(2) 시(2) 분(2) 초(2) 학번(8) = 22
      if (readData.toString().length == 22) {
        // QR코드의 값이 현재의 값보다 클 경우 유효하지 않다고 출력.
        // 인식할 시간 기준으로는 당연히 과거에 생성된 코드이므로.
        if (int.parse(readData.toString().substring(0, 14)) >
            int.parse(whatDateIsItToday())) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: new Text('유효하지 않은 QR코드 입니다.'),
                actions: <Widget>[
                  FlatButton(
                    child: new Text('확인'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          isScan = false;
        } else {
          // userId를 QR코드로부터 얻어온다.
          userId = readData.toString().substring(14);

          // 기다리지 않을 경우, temp가 null이 되어 오류가 발생한다.
          // userId를 서버로 보내서 서버에서 코드가 생성된 시간을 받아온다.
          await checkQrCode(userId, readData.toString().substring(0, 14));

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(userId + ' 님'),
                    Text('인증되었습니다. '),
                    //Text(isCheck.toString()),
                  ],
                ),
                actions: <Widget>[
                  FlatButton(
                    child: new Text('확인'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );

          // 다음화면으로 넘기고 싶으면 true로 변경.
          // 지금은 테스트 할겸 화면 넘어가지 않게 설정.
          isScan = true;
        }
      } else {
        // 바코드값의 길이가 지정한것과 맞지 않는 경우.
        isScan = false;
      }
    } else {
      // 바코드값에 문자열도 포함되어 있는 경우.
      isScan = false;
    }
    setState(() {});
  }

  // 학번과 QR코드를 서버로 보내서 유효한 값인지를 판별하는 메서드.
  Future checkQrCode(String userId, String qrTime) async {
    final String url = 'CheckQRCode.php';

    var data = {'UserID': userId, 'QRTime': qrTime};

    var response = await http.post(url, body: json.encode(data));

    var message = jsonDecode(response.body);

    temp = message.toString();

    if ((whatDateIsItYesterday(temp) == qrTime) &&
        ((int.parse(whatDateIsItToday()) - int.parse(qrTime)) <= 100)) {
      isCheck = true;
    } else {
      isCheck = false;
    }
  }

  // 사용자가 인증되었음을 전송하는 메서드.
  Future sendUserCert(String userId) async {
    final String url = 'UpdateUserCert.php';

    var data = {'UserID': userId};

    var response = await http.post(url, body: json.encode(data));

    var message = jsonDecode(response.body);

    print(message.toString());
  }

  // 측정한 온도값을 전송하는 메서드
  Future sendTemperature(String userId, double temperature) async {
    final String url = 'UpdateUserTemperature.php';

    var data = {'UserID': userId, 'temperature': temperature.toString()};

    var response = await http.post(url, body: json.encode(data));

    var message = jsonDecode(response.body);
  }

  // QR코드 스캔 화면 설정
  ScrollConfiguration _buildAdminQR() {
    List<Container> containers = new List<Container>();

    containers.add(
      Container(
        child: Column(
          children: <Widget>[
            Padding(
              // 간격 맞추기 위해 사용.
              padding: EdgeInsets.all(8.0),
              child: Text(' '),
            ),
            SizedBox(
              height: 200,
            ),
            FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.deepPurple,
              textColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text('스캔시작'),
              ),
              onPressed: () {
                startScan();
              },
            ),
            SizedBox(height: 100),
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
                  isScan = true;
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

  // BLE Scan
  ScrollConfiguration _buildScanBLE() {
    List<Container> containers = new List<Container>();

    if (isFirst) {
      // 위 구문을 다음과 같이 바꿈
      widget.flutterBlue.connectedDevices
          .asStream()
          .listen((List<BluetoothDevice> devices) {
        for (BluetoothDevice device in devices) {
          ScanResult temp = new ScanResult(device: device);
          _addDeviceTolist(temp);
        }
      });

      // 스캔 결과 리스너 설정.
      widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          _addDeviceTolist(result);
          print("${result.device}, ${result.rssi}");
        }
      });
      isFirst = false;
    }

    for (ScanResult result in widget.devicesList) {
      containers.add(
        Container(
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: ListTile(
                title: Text(result.device.name == ''
                    ? 'Unknown Device'
                    : result.device.name),
                subtitle: Row(children: <Widget>[
                  Expanded(
                    child: Text(result.device.id.toString()),
                  ),
                  Text(result.rssi.toString() + ' dbm'),
                ]),
                onTap: () async {
                  if (!_isConnecting) {
                    await widget.flutterBlue.stopScan();
                    setState(() {
                      _isConnecting = true;
                    });

                    try {
                      await result.device.connect();
                    } catch (e) {
                      if (e.code != 'already_connected') {
                        throw e;
                      }
                    } finally {
                      _services = await result.device.discoverServices();
                    }

                    setState(() {
                      _isScanning = false;
                      _connectedDevice = result.device;
                    });
                  }
                },
              ),
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: Column(
        children: <Widget>[
          Container(
            height: 60,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    ' 장치 검색',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(),
                ),
                (_isScanning)
                    ? ButtonTheme(
                        minWidth: 50,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.deepPurple,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(' '),
                ButtonTheme(
                  minWidth: 100,
                  child: FlatButton(
                    child: Text(
                      _isScanning ? 'Stop Scan' : 'Start Scan',
                    ),
                    onPressed: () async {
                      if (_isScanning) {
                        _isScanning = false;
                        await widget.flutterBlue.stopScan();
                      } else {
                        _isScanning = true;

                        scanResult.clear();
                        widget.devicesList.clear();
                        await widget.flutterBlue.startScan();
                      }

                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              height: 616,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
              child: ListView(
                padding: EdgeInsets.all(10),
                children: <Widget>[
                  ...containers,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ScrollConfiguration _buildReceiveBLE() {
    var value, btn;
    List<Widget> gui = new List<Widget>();

    str.clear();

    // 정해진 Characteristic 으로부터 보내진 값을 저장.
    for (BluetoothService service in _services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() ==
            '6e400003-b5a3-f393-e0a9-e50e24dcca9e') {
          btn = characteristic;
          value = widget.readValues[characteristic.uuid];

          if (value != null) {
            for (var i = 0; i < value.length; i++) {
              str.write(String.fromCharCode(value[i]));
            }
          } else {
            str.write('--');
          }
        }
      }
    }

    gui.add(
      Row(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text('Connected'),
          ),
          Expanded(child: SizedBox()),
          ButtonTheme(
            minWidth: 100,
            child: FlatButton(
              child: Text(
                'Disconnect',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                await _connectedDevice.disconnect();
                _connectedDevice = null;

                setState(() {});
              },
            ),
          )
        ],
      ),
    );

    // 제목 및 버튼 출력
    gui.add(
      Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Temperature', style: TextStyle(fontSize: 21)),
            ),
          ),
          FlatButton(
              color: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  _isReceiving ? '값 수신 중' : '값 수신 시작',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              onPressed: () async {
                if (!_isReceiving) {
                  btn.value.listen((value) {
                    setState(() {
                      widget.readValues[btn.uuid] = value;
                      _isReceiving = true;
                    });
                  });
                  await btn.setNotifyValue(true);
                }
              }),
        ],
      ),
    );

    // 온도 값 출력
    gui.add(
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(str.toString() + ' °C', style: TextStyle(fontSize: 21)),
      ),
    );

    gui.add(
      FlatButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        color: Colors.deepPurple,
        child: Text(
          '온도 결정',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        onPressed: () async {
          bleResult = double.parse(str.toString());
          btn.setNotifyValue(false);
          isTempComplete = true;
          sendTemperature(userId, double.parse(str.toString()));
          // 서버로 인증되었음을 전송하는 구문.
          sendUserCert(userId);

          setState(() {});
        },
      ),
    );

    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          ...gui,
        ],
      ),
    );
  }

  void _addDeviceTolist(final ScanResult result) {
    // 디바이스를 추가 또는 업데이트
    if (widget.devicesList
            .indexWhere((element) => element.device == result.device) ==
        -1) {
      /*setState(() {*/
      widget.devicesList.add(result);
      /*});*/
    } else /*if (widget.devicesList
            .indexWhere((element) => element.device == result.device) !=
        -1)*/
    {
      /*setState(() {*/
      widget.devicesList[widget.devicesList
          .indexWhere((element) => element.device == result.device)] = result;
      /*});*/
    }

    setState(() {});
  }

  ScrollConfiguration _buildShowTemp() {
    List<Container> containers = new List<Container>();
    double resultHeight;
    double temp = bleResult;

    // initState와 같은 역할을 한다.
    if (isFirstUserResult) {
      resultHeight = calculateHeight(temp);
      temperature = temp;

      _heightTween = Tween(begin: 450, end: resultHeight);
      height = resultHeight;

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
          ],
        ),
      ),
    );

    return ScrollConfiguration(
      behavior: MyBehavior(),
      child: ListView(
        children: <Widget>[
          ...containers,
        ],
      ),
    );
  }

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

  ScrollConfiguration _buildView() {
    if (!isScan) {
      return _buildAdminQR();
    } else {
      if (_connectedDevice != null) {
        if (!isTempComplete)
          return _buildReceiveBLE();
        else
          return _buildShowTemp();
      }
      return _buildScanBLE();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildView(),
    );
  }
}

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
