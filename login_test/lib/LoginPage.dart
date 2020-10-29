/* 
 * 로그인 화면에 회원가입을 넣을까 말까 고민중.
 * 어차피 시연할때는 회원가입없이 원래 있는 사람으로 테스트를 할것이기 때문에 그렇게 큰 문제는 안될듯.
 */
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/* To use Internet */
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'Menu.dart';

/*
 * StatelessWidget은 로드될 때 한번만 그려진다.
 * 각 화면들은 기본적으로 StatelessWidget을 상속받은 클래스로 이루어진다.
 */
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      home: _LoginPage(title: 'User or Admin Login Page.'),
    );
  }
}

/*
 * StatefulWidget은 setState를 호출할때마다 화면을 갱신함.
 */
class _LoginPage extends StatefulWidget {
  _LoginPage({Key key, @required this.title}) : super(key: key);

  // BLE 앱에서 호출할때 제목을 호출하기 위해서 이런식으로 선언해주길래 따라해봤음.
  final String title;

  Login createState() => Login();
}

/*
 * 로그인 화면 state
 */
class Login extends State {
  // 원형 progress indicator를 표시할것인지 말것인지 판별하는 변수.
  bool visible = false;

  // 로그인을 시도한 사람의 권한을 판별하기 위한 변수
  bool admin;

  // Text Field Widget으로부터 값들을 받아오게 해주는 변수.
  final idController = TextEditingController();
  final passwordController = TextEditingController();

  Future userLogin() async {
    // 원형 Progress Indicator를 표시한채로 화면을 출력.
    setState(() {
      visible = true;
    });

    // Controller로 부터 값을 얻어옴.
    String id = idController.text.toString();
    String password = passwordController.text.toString();

    // SERVER Login API URL
    final String url = 'Login_flutter.php';

    // Store all data with Param Name.
    var data = {'UserID': id, 'UserPW': password};

    // Starting Web API Call.
    var response = await http.post(url, body: json.encode(data));

    // Getting Server response into variable.
    var message = jsonDecode(response.body);

    // If the Response Message is Matched.
    if (message == 'Login Matched') {
      // Hiding the Circular Progress Indicator.
      setState(() {
        visible = false;
      });

      // 서버에서 관리자임을 판별할 파일이름을 설정.
      final String url = 'IsAdmin.php';

      // 전달할 매개변수 설정.
      var data = {'UserID': id};

      // API 호출 시작.
      var response = await http.post(url, body: json.encode(data));

      // 응답으로 돌아온 값을 저장할 변수 설정
      var message = jsonDecode(response.body);

      // 로그인한 유저가 admin인지 판별
      if (message == 'true')
        admin = true;
      else
        admin = false;

      // Showing Alert Dialog with 로그인 성공 Message.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 0,
            title: new Text("로그인 성공"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: new Text(
                  "확인",
                  style: TextStyle(color: Colors.deepPurple),
                ),
                onPressed: () {
                  // 확인버튼을 누를 시 QR코드 스캔 화면으로 전환.
                  // 뒤로가기 버튼 누를 시 이전 화면으로 돌아가는것을 방지.
                  // 뒤로가기를 두번 누르면 앱을 종료하는 기능을 넣고싶다.
                  /*
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              QRcodePage(userId: id, isAdmin: admin)),
                      (route) => false);
                      */
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => MenuPage(
                              userId: id,
                              isAdmin: admin,
                              userName: ((id == '20161276')
                                  ? ('장주환')
                                  : ((id == '20161255') ? ('김결') : ('한해대'))))),
                      (route) => false);
                },
              ),
            ],
          );
        },
      );
    } else {
      // If Id or Password did not Matched.
      // Hiding the Circluar Progress Indicator.
      // 로그인 성공시에는 다음화면으로 넘어가지만,
      // 로그인 실패시에는 현재화면에 남아있으므로 새로고침을 해줘야함.
      setState(() {
        visible = false;
      });

      // Showing Alert Dialog with 로그인 실패 Message.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 0,
            title: new Text("로그인 실패"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child:
                    new Text("확인", style: TextStyle(color: Colors.deepPurple)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // 화면 UI 설정
  ScrollConfiguration _buildListViewOfLogin() {
    List<Container> containers = new List<Container>();
    List<double> size = new List<double>();
    double height, width;

    size = getWidthNHeight(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    width = size[0];
    height = size[1];

    containers.add(
      Container(
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            SizedBox(
              // 간격 맞추기 위해 사용
              height: 60,
            ),
            SizedBox(
              // 로그인 화면에 표시할 그림
              width: width * 0.26,
              height: width / 7,
              child: Image.asset('assets/Logo.jpg'),
            ),
            SizedBox(
              // 간격 맞추기 위해 사용
              //height: height * 0.05478,
              height: 50,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 0),
                    blurRadius: 5,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 60,
                  ),
                  Row(
                    // 학번 관련
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        // 학번 입력 창.
                        width: width * 0.2407,
                        padding: EdgeInsets.all(10.0),
                        child: Theme(
                          data: ThemeData(
                            cursorColor: Colors.white,
                          ),
                          child: TextField(
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            controller: idController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: '학번',
                              labelStyle: TextStyle(
                                color: Colors.white,
                              ),
                              fillColor: Colors.black,
                              hintStyle: TextStyle(
                                color: Colors.white,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    // 비밀번호 관련
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        // 비밀번호 입력 창.
                        width: width * 0.2407,
                        padding: EdgeInsets.all(10.0),
                        child: Theme(
                          data: ThemeData(
                            cursorColor: Colors.white,
                          ),
                          child: TextField(
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            controller: passwordController,
                            autocorrect: false,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: '비밀번호',
                              labelStyle: TextStyle(
                                color: Colors.white,
                              ),
                              fillColor: Colors.black,
                              hintStyle: TextStyle(
                                color: Colors.white,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    // 간격 맞추기 위해 사용.
                    height: height * 0.015,
                  ),
                  Container(
                    width: 100,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: FlatButton(
                      child: Text('로그인'),
                      textColor: Colors.white,
                      padding: EdgeInsets.zero,
                      onPressed: userLogin,
                    ),
                  ),
                  SizedBox(
                    height: 95.5,
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Made by CSSP',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
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

  // 앱이 실행되는 휴대폰에서 가로와 높이를 알기 위한 메서드
  List<double> getWidthNHeight(double width, double height) {
    return [
      width * MediaQuery.of(context).devicePixelRatio,
      height * MediaQuery.of(context).devicePixelRatio
    ];
  }

  // 화면 그리기
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildListViewOfLogin(),
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
