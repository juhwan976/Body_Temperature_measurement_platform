import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'TemperatureRecords.dart';
import 'CheckTemperatureUser.dart';
import 'CheckTemperatureAdmin.dart';

class MenuPage extends StatelessWidget {
  MenuPage(
      {Key key,
      @required this.userId,
      @required this.isAdmin,
      @required this.userName});

  final String userId;
  final String userName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _MenuPage(userId: userId, userName: userName, isAdmin: isAdmin),
    );
  }
}

class _MenuPage extends StatefulWidget {
  _MenuPage(
      {Key key,
      @required this.userId,
      @required this.isAdmin,
      @required this.userName})
      : super(key: key);

  final String userId;
  final String userName;
  final bool isAdmin;

  Menu createState() =>
      Menu(userId: userId, isAdmin: isAdmin, userName: userName);
}

class Menu extends State {
  Menu(
      {Key key,
      @required this.userId,
      @required this.isAdmin,
      @required this.userName});

  final String userId;
  final String userName;
  final bool isAdmin;

  DateTime today = DateTime.now();

  Column _buildUserPage() {
    return Column(
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).padding.top,
        ),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
          ),
          child: Column(
            children: <Widget>[
              SizedBox(height: 25),
              Container(
                height: 210,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 250,
                        child: ListTile(
                          leading: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: Icon(
                                Icons.face,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                          title: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              '한국해양대학교',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
          color: Colors.deepPurple,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20.0),
                topLeft: Radius.circular(20.0),
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
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 100,
                      width: 310,
                      child: Center(
                        child: ListTile(
                          leading: SizedBox(
                            height: 90,
                            width: 50,
                            child: Image.asset('assets/2.jpg'),
                          ),
                          title: Text(
                            '온도 측정',
                            style: TextStyle(fontSize: 21, color: Colors.black),
                          ),
                          subtitle: Text(
                            '사용자의 온도를 측정합니다.',
                            style: TextStyle(color: Colors.black),
                          ),
                          onTap: () {
                            showMaterialModalBottomSheet(
                              useRootNavigator: true,
                              enableDrag: false,
                              backgroundColor: Colors.black.withOpacity(0),
                              context: context,
                              builder: (context, scrollController) => Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      topLeft: Radius.circular(20),
                                    ),
                                    border: Border.all(color: Colors.black),
                                    color: Colors.white,
                                  ),
                                  height: 600,
                                  width: 200,
                                  child: Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CheckTemperatureUserPage(
                                        isAdmin: isAdmin, userId: userId),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 100,
                      width: 310,
                      child: Center(
                        child: ListTile(
                            leading: SizedBox(
                              height: 50,
                              width: 50,
                              child: Icon(
                                Icons.restore,
                                size: 40,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              '온도 측정 기록',
                              style: TextStyle(
                                fontSize: 21,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '온도를 측정했던 기록을 확인합니다.',
                              style: TextStyle(color: Colors.black),
                            ),
                            onTap: () {
                              showMaterialModalBottomSheet(
                                useRootNavigator: true,
                                enableDrag: false,
                                backgroundColor: Colors.black.withOpacity(0),
                                context: context,
                                builder: (context, scrollController) => Padding(
                                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(20),
                                        topLeft: Radius.circular(20),
                                      ),
                                      border: Border.all(color: Colors.black),
                                      color: Colors.white,
                                    ),
                                    height: 500,
                                    width: 200,
                                    child: Padding(
                                      padding: EdgeInsets.all(6),
                                      child:
                                          TemperatureRecordPage(userId: userId),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        border: Border.all(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 143.4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Column _buildAdminPage() {
    return Column(
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).padding.top,
        ),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
          ),
          child: Column(
            children: <Widget>[
              SizedBox(height: 25),
              Container(
                height: 210,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 250,
                        child: ListTile(
                          leading: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: Icon(
                                Icons.face,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              '한국해양대학교' + '\n관리자',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
          color: Colors.deepPurple,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20.0),
                topLeft: Radius.circular(20.0),
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
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 100,
                      width: 310,
                      child: Center(
                        child: ListTile(
                          leading: SizedBox(
                            height: 90,
                            width: 50,
                            child: Image.asset('assets/2.jpg'),
                          ),
                          title: Text(
                            '온도 측정',
                            style: TextStyle(fontSize: 21, color: Colors.black),
                          ),
                          subtitle: Text(
                            '사용자의 온도를 측정합니다.',
                            style: TextStyle(color: Colors.black),
                          ),
                          onTap: () {
                            showMaterialModalBottomSheet(
                              useRootNavigator: true,
                              enableDrag: false,
                              backgroundColor: Colors.black.withOpacity(0),
                              context: context,
                              builder: (context, scrollController) => Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      topLeft: Radius.circular(20),
                                    ),
                                    border: Border.all(color: Colors.black),
                                    color: Colors.white,
                                  ),
                                  height: 700,
                                  width: 200,
                                  child: Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CheckTemperatureAdminPage(
                                        userId: userId),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 44,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 100,
                      width: 310,
                      child: Text(''),
                      /*Center(
                        child: ListTile(
                            leading: SizedBox(
                              height: 50,
                              width: 50,
                              child: Icon(
                                Icons.restore,
                                size: 40,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              '온도 측정 기록',
                              style: TextStyle(
                                fontSize: 21,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '온도를 측정했던 기록을 확인합니다.',
                              style: TextStyle(color: Colors.black),
                            ),
                            onTap: () {
                              /*
                              showMaterialModalBottomSheet(
                                useRootNavigator: true,
                                backgroundColor: Colors.black.withOpacity(0),
                                context: context,
                                builder: (context, scrollController) => Padding(
                                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(20),
                                        topLeft: Radius.circular(20),
                                      ),
                                      border: Border.all(color: Colors.black),
                                      color: Colors.white,
                                    ),
                                    height: 500,
                                    width: 200,
                                    child: Padding(
                                      padding: EdgeInsets.all(6),
                                      child: TemperatureRecordPage(),
                                    ),
                                  ),
                                ),
                              );
                              */
                            }),
                      ),*/
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 143.4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Column _buildPage() {
    if (isAdmin) {
      return _buildAdminPage();
    } else {
      return _buildUserPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
    );
  }
}
