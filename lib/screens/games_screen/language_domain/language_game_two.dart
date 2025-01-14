import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../constants/base_url.dart';
import '../../../constants/color.dart';
import '../../../constants/enum.dart';
import '../../../utils/custom_dialog.dart';
import '../../../utils/toast.dart';
import '../../../widget/clock.dart';

class LanguageGameTwo extends StatefulWidget {
  const LanguageGameTwo({Key? key}) : super(key: key);

  @override
  State<LanguageGameTwo> createState() => _LanguageGameTwoState();
}

class _LanguageGameTwoState extends State<LanguageGameTwo> {
  final int answerDurationInSeconds = 300;
  final int pointPerCorrectAnswer = 200;
  String languageGamePath = "lib/constants/language_2.json";
  Duration answerDuration = const Duration();
  Timer? countdownTimer;
  late Toast toast;
  late CustomDialog dialog;

  TextEditingController controller = TextEditingController();
  late Future<String> firstCharacter;
  final List<String> _answer = [];
  List<String> correctAnswers = [];
  int _point = 0;
  late int numOfWord;
  int numOfGame = 0;
  GameStatus _status = GameStatus.playing;

  // Timer Handler
  void startTimer() {
    answerDuration = Duration(seconds: answerDurationInSeconds);

    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setCountDown());
  }

  void setCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = answerDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        setCancelTimer();
        changeStatus(GameStatus.end);
      } else {
        answerDuration = Duration(seconds: seconds);
      }
    });
  }

  void setCancelTimer() {
    countdownTimer!.cancel();
  }

  // Fetch Data
  Future<String> fetchRandomCharacter() async {
    final response = await http.get(dictionaryUrl);
    final data = response.body;
    List<String> dataList = data.toLowerCase().split('\n');

    if (dataList.isNotEmpty) {
      String firstCharacter =
          dataList[Random().nextInt(dataList.length)].split(' ')[0];
      _answer.add(firstCharacter);
      return firstCharacter;
    }

    throw Exception('Failed to load random character in the dictionary');
  }

  Future<String> readJson() async {
    final String response = await rootBundle.loadString(languageGamePath);
    final data = await json.decode(response);
    final dataRes = data['words'];
    final wordObj = dataRes[Random().nextInt(dataRes.length)];
    setState(() {
      _answer.add(wordObj[0]);
      // firstCharacter = wordObj[0];
      numOfWord = wordObj[1];
    });
    return wordObj[0];
  }

  Future<bool> checkValidWord(String word) async {
    Map<String, String> headers = {'Content-type': 'application/json'};
    final response = await http.post(Uri.parse('$baseUrlLanguage/check'),
        headers: headers, body: jsonEncode({'text': word}));
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  // Logic Handler
  void handleClickCheck() async {
    String userAnswer = controller.text;
    String firstChar = _answer.last;
    String checkingWord = '$firstChar $userAnswer';
    bool existed = correctAnswers.contains(userAnswer);
    bool isValidWord = await checkValidWord(checkingWord);
    if (isValidWord && !existed) {
      toast.show('Chính xác', Colors.green);
      // _answer.add(userAnswer);
      setState(() {
        _point += pointPerCorrectAnswer;
        numOfGame++;
        correctAnswers.add(userAnswer);
        // Restart timer
        answerDuration = Duration(seconds: answerDurationInSeconds);
      });
    } else {
      toast.show('Không hợp lệ, hoặc đã từng nhập', Colors.red);
    }

    controller.text = '';
    if (numOfGame == numOfWord) {
      changeStatus(GameStatus.end);
      setCancelTimer();
    }
  }

  void changeStatus(GameStatus status) {
    handleStatusChange(status);

    setState(() {
      _status = status;
    });
  }

  void handleStatusChange(GameStatus status) {
    if (status == GameStatus.end) {
      dialog.show(Text('Kết thúc'), Text('Tổng điểm: $_point'), [
        TextButton(
          child: const Text('Xác nhận'),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ]);
    }
  }

  @override
  void initState() {
    super.initState();
    firstCharacter = readJson();
    toast = Toast(context: context);
    dialog = CustomDialog(context: context);
    // firstCharacter = fetchRandomCharacter();
    startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    setCancelTimer();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = answerDuration.inSeconds;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Tìm cụm từ có nghĩa'),
        backgroundColor: primaryOrange,
      ),
      body: SingleChildScrollView(
          child: FutureBuilder<String>(
        future: firstCharacter,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Clock(seconds: seconds),
                  ],
                ),
              ),
              Text("Điểm: $_point",
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: brownColor,
                      fontSize: 30)),
              const SizedBox(
                height: 30,
              ),
              const Text('Hãy điền tiếng tiếp theo để tạo nên một từ có nghĩa',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 25)),
              const SizedBox(
                height: 60,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Container(
                    color: primaryOrange,
                    width: 180,
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(_answer.last,
                        style: const TextStyle(
                            fontSize: 30, color: Colors.white))),
                Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2)),
                    width: 180,
                    height: 120,
                    alignment: Alignment.center,
                    child: TextField(
                      enabled: _status == GameStatus.playing,
                      controller: controller,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        border: InputBorder.none,
                        hintText: 'Nhập từ',
                      ),
                    ))
              ]),
              const SizedBox(
                height: 120,
              ),
              ElevatedButton(
                onPressed:
                    controller.text.isNotEmpty && _status == GameStatus.playing
                        ? () => handleClickCheck()
                        : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    textStyle: const TextStyle(fontSize: 24)),
                child: const Text('Kiểm tra'),
              )
            ]);
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          // By default, show a loading spinner.
          return const Center(
              heightFactor: 22.0, child: CircularProgressIndicator());
        },
      )),
    );
  }
}
