import 'package:flutter/material.dart';
import 'dart:core';

import 'LoginPage.dart';

void main() {
  runApp(MyApp());
}
/* 2020.08.06
 * 화면을 ListView로 하지 않은 상태에서 키보드를 출력할 경우,
 * 다음 라인을 입력하려고 칸을 클릭했을때 화면이 올라오는 기능이 없고
 * 키보드쪽에 오버플로우된다는 경고문이 출력되어서
 * 임시로 ListView로 바꿔서 테스트중이다.
 */

/* 2020.08.08
 * 휴대폰의 크기가 다르더라도 항상 같은 화면이 나오도록 요소들의 위치를
 * 화면크기를 받는 기능을 이용해서 유동적으로 구성해보자.
 * 화면크기 : 1080 * 2088
 * 최대 높이 : 24
 * 
 */
