import 'package:flutter/material.dart';
import 'package:wallet_ffi/wallet_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbDir = await getDatabaseDir();
  final conf = WalletFfiConfig(dbFolderPath: dbDir);
  await RustLib.init();

  await initWalletFfi(conf: conf);
  await initValueChannel();
  runApp(const MyApp());
}

Future<String> getDatabaseDir() async {
  final dir = await getApplicationSupportDirectory();
  final dbPath = '${dir.path}/wallet-data.redb';

  // Ensure folder exists
  await dir.create(recursive: true);

  return dbPath;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  int _counter = 0;
  String _greeting = '..waiting for Rust..';
  double? _random;
  String _resp = 'no resp yet';
  String _db = 'no db yet';
  StreamSubscription<int>? _sub;
  StreamSubscription<Event>? _subEvent;
  Event? _latestEvent;
  int _lastValue = 0;
  String _canFailVal = 'no value yet';

  void _startStream() {
    _sub?.cancel();
    _sub = startNumberStream().listen(
      (value) {
        setState(() {
          _lastValue = value;
        });
      },
      onError: (err, stack) {
        debugPrint('Stream error: $err');
      },
      onDone: () {
        debugPrint('Stream done');
      },
    );
  }

  void _startEvents() {
    _subEvent?.cancel();
    _subEvent = subscribeValueChannel().listen(
      (value) {
        setState(() {
          _latestEvent = value;
        });
      },
      onError: (err, stack) {
        debugPrint('Stream error: $err');
      },
      onDone: () {
        debugPrint('Stream done');
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subEvent?.cancel();
    super.dispose();
  }

  Future<void> _testCallback() async {
    await callMeBaby(
      cb: (msg) {
        debugPrint('Rust callback called with: $msg');
        // You can also setState here if you like
        return 'ok';
      },
    );
    return;
  }

  Future<void> _testCanFail() async {
    try {
      final text = _controller.text.trim();

      if (text.isEmpty) {
        return;
      }

      final num = int.tryParse(text);
      if (num == null) {
        return;
      }
      final req = CanFailRequest(num: num);
      final resp = await canFail(req: req);
      debugPrint('Success: ${resp.res}');
      setState(() {
        _canFailVal = resp.res;
      });
    } on WalletError catch (e) {
      switch (e.kind) {
        case WalletErrorKind.notFound:
          debugPrint('Not found, ${e.msg}');
          break;
        case WalletErrorKind.io:
          debugPrint('IO error: ${e.msg}');
          break;
        case WalletErrorKind.network:
          debugPrint('Network error: ${e.msg}');
          break;
        case WalletErrorKind.other:
          debugPrint('Other error: ${e.msg}');
          break;
      }
    } catch (e, st) {
      debugPrint('Unexpected error: $e\n$st');
    }
  }

  Future<void> _loadRandom() async {
    final value = await randomNumber();
    final resp = await doReq();
    final db = await doDbQuery();

    setState(() {
      _random = value;
      _counter++;
      _greeting = greet(name: 'Rusted $_counter');
      _resp = resp;
      _db = db;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGreeting();
  }

  void _loadGreeting() {
    final result = greet(name: 'Mario');
    setState(() {
      _greeting = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter a number',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testCanFail,
              child: const Text("Call can_fail"),
            ),
            Text(_random?.toString() ?? 'Press the button for a random number'),
            Text(_greeting),
            Text(_resp),
            Text(_db),
            Text('Last value from stream: $_lastValue'),
            Text(
              'Latest Event from stream - kind: ${_latestEvent?.kind.toString()}, msg: ${_latestEvent?.msg}',
            ),
            Text('Result from canFail: $_canFailVal'),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _testCallback,
              tooltip: 'CALLBACK',
              child: const Icon(Icons.timer),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _startStream,
              tooltip: 'STREAM',
              child: const Icon(Icons.play_arrow),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _startEvents,
              tooltip: 'STREAM EVENTS',
              child: const Icon(Icons.cookie),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRandom,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
