# Body_Temperature_measurement_platform
### nRF52DK를 이용한 비접촉식 적외선 온도계 및 체온측정 플랫폼
#
# 설명
- __서버에서 데이터를 주고 받게 하는 PHP파일은 넣지 않았습니다.__
- nRF52DK(52832)를 이용한 비접촉식 적외선 체온계
- 스마트폰 앱을 이용한 체온 측정
- 사용가능한 기능
  - 관리자
    1. 로그인
    
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1599426491.png" width="200" />
    
    2. QR코드 스캔
    
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1599426687.png" width="200" />
        
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/KakaoTalk_20201030_030030520.png" width="200" />
        
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/KakaoTalk_20201030_030030520_01.png" width="200" />
        
    3. BLE기기 스캔
    
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1599427621.png" width="200" />
        
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/KakaoTalk_20200907_063704368.jpg" width="200" />
    
    4. 온도 측정
    
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/KakaoTalk_20200907_073822837.jpg" width="200" />
    
    5. 결과 확인
    
        <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/KakaoTalk_20200907_073822837_01.jpg" width="200" />
    
  - 사용자
    - 온도 측정
      1. 로그인
      
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1599426491.png" width="200" />
          
      2. QR코드 스캔
        
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1604001101.png" width="200" />
        
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1603999015.png" width="200" />
      
      3. 온도 측정
      
          - nRF52DK로 온도 측정
        
      4. 결과 확인
      
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/KakaoTalk_20200907_073822837_01.jpg" width="200" /> 
      
    - 기록 확인
      1. 로그인
      
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1599426491.png" width="200" />
      
      2. 결과 확인
        
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1604001101.png" width="200" />
        
          <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1603994379.png" width="200" />
        
        - 날짜별 내용
        
            <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1603994388.png" width="200" />
        
            <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1603994392.png" width="200" />
        
            <img src="https://github.com/juhwan976/Body_Temperature_measurement_platform/blob/main/%EC%95%B1%EC%82%AC%EC%A7%84/Screenshot_1603994398.png" width="200" />
      
  - 시연 영상
  
    https://youtu.be/AzfZ85ExSL0
    
#
# 개발환경 및 사용언어
- 개발환경
  - SEGGER Embedded Studio for ARM v4.52c
  - VSCode(Flutter)
- 사용언어
  - C
  - Dart

#
# 설치 및 실행
- __SEGGER Embedded Studio for ARM 필요__
- __nRF SDK 16버전 이상 필요__
- __Flutter가 설치된 VSCode 필요__
#
- nRF52DK 설치
  1. 파일 전체를 받는다
  2. nRF폴더 전체를 SDK\examples\ble_peripheral\ 로 이동
  3. pca100400\s132\ses\ble_app_uart_pca10040_s132.emProject 실행
  4. 온도센서의 SCL을 P0.27, SDA를 P0.26, VCC를 5V, GND를 GND에 각각 연결
  5. nRF52DK의 전원을 킨다.
  6. F5를 누른다.
- 앱 설치
  1. 파일 전체를 받는다
  2. VSCode를 이용해 폴더를 login_test 폴더를 연다
  3. 실행한다.
#
## 기타 부가 설명
- 메뉴화면
  - 관리자는 온도 측정 기능만 사용가능
  - 사용자는 온도 측정 및 온도 측정 기록 열람 가능
- QR 코드 스캔 및 생성
  - QR코드는 기본적으로 사용자의 ID(학번)과 '년월일시분초'를 합쳐서 생성
  - QR코드의 유효기간은 1분으로 설정했으나, 만료를 판단하는 알고리즘에 문제가 있음
  - QR코드를 생성한 사용자의 경우 1분이 지나면 새로고침이 가능하도록 구상했으나 실현하는데 문제가 있음
  - QR코드 스캔은 라이브러리를 약간 수정해서 사용
- Bluetooth 연결
  - 일반 Bluetooth 연결이 아닌 BLE를 지원하는 기기에서만 스캔 가능
  - 온도의 측정이라서 온도 측정 서비스를 이용할 수도 있었으나, Nordic UART Service를 써보고 싶어서 NUS를 사용
- 온도 결과
  - 측정한 온도에 따라서 사용자와 관리자 모두에게 출력되도록 설정
  - 애니메이션을 적용하였으며, 애니메이션은 온도계의 최하단부터 자신의 체온까지 1초동안 실행
  - 사용자의 온도 결과 화면은 아직 버그가 있음
- 온도 측정 기록
  - 사용자만 사용할 수 있는 기능
  - 달력을 구현하였으며, 새로고침 버튼을 누를 경우 오늘이 속한 달의 달력으로 바로 이동
  - 선택한 날의 기록 중 하나라도 고온이 있을 경우 '빨강'으로 출력
  - 선택한 날의 기록 중 하나라도 저체온 또는 미열이 있을 경우 '노랑'으로 출력
  - 선택한 날의 기록이 모두 정상일 경우 '초록'으로 출력
#
## 버그
  - BLE 설정, 연결해제 관련 버그가 있음
  - 사용자의 온도 결과 화면에서 버그가 있음
  - 밑에서 위로 올라오는 페이지에 렉이 너무 심함
