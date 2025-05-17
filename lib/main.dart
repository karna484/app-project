import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'TimesNewRoman'),
          bodyMedium: TextStyle(fontFamily: 'TimesNewRoman'),
          bodySmall: TextStyle(fontFamily: 'TimesNewRoman'),
          headlineLarge: TextStyle(fontFamily: 'TimesNewRoman'),
        ),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController passwordController = TextEditingController();
  String defaultPassword = "1234";
  String? savedPassword;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  // Load the saved password from SharedPreferences
  void _loadPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedPassword = prefs.getString('password');
    if (savedPassword == null) {
      await prefs.setString('password', defaultPassword);
    }
  }

  // Handle login action
  void _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPassword = prefs.getString('password');
    if (passwordController.text == savedPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DiaryPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wrong password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Enter Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: Text('Login')),
            ],
          ),
        ),
      ),
    );
  }
}

class DiaryPage extends StatefulWidget {
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  TextEditingController diaryController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  String? savedPassword;
  String? diaryPath;
  String? otp;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  // Load the saved password from SharedPreferences
  void _loadPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedPassword = prefs.getString('password');
    otp = prefs.getString('otp'); // Load OTP if exists
  }

  // Get the directory path for the diary file based on the topic
  Future<void> _getDiaryPath(String topic) async {
    Directory directory = await getApplicationDocumentsDirectory();
    diaryPath = '${directory.path}/diary_$topic.txt';
    _loadDiary();
  }

  // Load diary content from the file for the given topic
  Future<void> _loadDiary() async {
    if (diaryPath == null) return;
    File file = File(diaryPath!);
    if (await file.exists()) {
      diaryController.text = await file.readAsString();
    }
  }

  // Save diary content to the file for the given topic
  Future<void> _saveDiary(String topic) async {
    if (topic.isEmpty) return;
    File file = File(diaryPath!);
    await file.writeAsString(diaryController.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diary Saved under $topic!')));
  }

  // View all diary entries (list of topics)
  void _viewAllData() async {
    if (otp == null) {
      // If OTP is not set, prompt to create OTP
      _setOtp();
    } else {
      // If OTP is already set, ask for OTP to view data
      _verifyOtp();
    }
  }

  // Set OTP to secure "View All Data" feature
  void _setOtp() async {
    TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create One-Time Password'),
          content: TextField(
            controller: otpController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Enter OTP'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (otpController.text.isNotEmpty) {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('otp', otpController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP created successfully!')));
                  otp = otpController.text;  // Store OTP for future verification
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Verify OTP to view data
  void _verifyOtp() {
    TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter OTP to View Data'),
          content: TextField(
            controller: otpController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Enter OTP'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (otpController.text == otp) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DataViewerPage()),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect OTP')));
                }
              },
              child: Text('Verify'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Logout the user
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Diary'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Enter Topic',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: diaryController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write your thoughts...'
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    String topic = topicController.text;
                    if (topic.isNotEmpty) {
                      _getDiaryPath(topic);
                      _saveDiary(topic);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a topic')));
                    }
                  },
                  child: Text('Save'),
                ),
                ElevatedButton(onPressed: _viewAllData, child: Text('View All Data')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Popup menu with options like change password and logout
  void _showMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 100.0, 0.0, 0.0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            onTap: () {
              Navigator.pop(context); // Close the menu
              _changePassword();  // Open change password dialog
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context); // Close the menu
              _logout();  // Perform logout
            },
          ),
        ),
      ],
    );
  }

  // Change the password
  void _changePassword() async {
    TextEditingController newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Enter New Password'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newPasswordController.text.isNotEmpty) {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('password', newPasswordController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password changed successfully!')));
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class DataViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Diary Entries')),
      body: FutureBuilder<List<String>>(
        future: _getAllDiaryFiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<String> diaryFiles = snapshot.data!;
          return ListView.builder(
            itemCount: diaryFiles.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(diaryFiles[index]),
                onTap: () {
                  _openDiaryFile(context, diaryFiles[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Fetch all diary files by topic name
  Future<List<String>> _getAllDiaryFiles() async {
    Directory directory = await getApplicationDocumentsDirectory();
    var files = directory.listSync();
    List<String> diaryFiles = files
        .where((file) => file.path.endsWith('.txt'))
        .map((file) => file.uri.pathSegments.last)
        .toList();
    return diaryFiles;
  }

  // Open the selected diary file
  void _openDiaryFile(BuildContext context, String fileName) async {
    Directory directory = await getApplicationDocumentsDirectory();
    File file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      String content = await file.readAsString();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(fileName),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }
}
