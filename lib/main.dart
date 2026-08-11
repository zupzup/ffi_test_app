import 'package:flutter/material.dart';
import 'package:ebill_flutter_ffi/ebill_flutter_ffi.dart';
import 'package:ebill_flutter_ffi/api/general.dart' as general;
import 'package:ebill_flutter_ffi/api/identity.dart' as identity;
import 'package:ebill_flutter_ffi/api/bill.dart' as bill;
import 'package:ebill_flutter_ffi/error.dart' as error;
import 'package:ebill_flutter_ffi/data/lib.dart' as data;
import 'package:ebill_flutter_ffi/data/identity.dart' as identity_data;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Rust init');
  await RustLib.init();

  runApp(const MyApp());
}

Future<String> getDatabaseDir() async {
  final dir = await getApplicationSupportDirectory();
  final dbPath = '${dir.path}/ebill-data_3.db';

  // Ensure folder exists
  await dir.create(recursive: true);

  return dbPath;
}

Future<String> getDatabaseDirFiles() async {
  final dir = await getApplicationSupportDirectory();
  final dbPath = '${dir.path}/ebill-files_3.db';

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
  String _version = "";

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initFfi() async {
    debugPrint('E-Bill init');
    final dbDir = await getDatabaseDir();
    final dbDirFiles = await getDatabaseDirFiles();
    final conf = EbillConfig(
      dbFolderPath: dbDir,
      dbFolderPathFiles: dbDirFiles,
      logLevel: "debug",
      bitcoinNetwork: "testnet",
      esploraBaseUrls: ["https://esplora.minibill.tech"],
      nostrRelays: ["wss://relay.wildcat0.clowder-dev.minibill.tech"],
      blossomServers: ["https://relay.wildcat0.clowder-dev.minibill.tech"],
      nostrOnlyKnownContacts: false,
      jobRunnerInitialDelaySeconds: BigInt.from(5),
      jobRunnerCheckIntervalSeconds: BigInt.from(60),
      transportInitialSubscriptionDelaySeconds: 1,
      defaultMintUrl: "https://mint.wildcat0.clowder-dev.minibill.tech",
      defaultMintNodeId: "bitcrt020e50d48b6b2897743ca257c82684e984509c05c9bf812176c717005698e57023", //wildcat0 clowder-dev
      numConfirmationsForPayment: BigInt.from(1),
      devMode: true,
      mandatoryEmailConfirmations: false,
      defaultCourtUrl: "https://bcr-court-dev.minibill.tech"
    );
    try {
      await initEbillFfi(conf: conf);
      await _getVersion();
    } catch (e, st) {
      debugPrint('Unexpected error on INIT: $e\n$st');
    }
    debugPrint('Init Done - running!');
  }

  Future<void> _getVersion() async {
      try {
          final st = await general.getStatus();
          setState(() {
            _version = st.appVersion;
          });
          debugPrint('APP VERSION: ${st.appVersion}, ${st.bitcoinNetwork}, ${st.connected}');
      } on error.EbillFfiError catch (e) {
          debugPrint('Error, ${e.msg}, ${e.kind}');
      } catch (e, st) {
          debugPrint('Unexpected error: $e\n$st');
      }
  }

  Future<void> _getLinkToPay() async {
      try {
          final pl = data.BtcAddressAndSumPayload(
            billId: "hi",
            address: "hi",
            sum: "15",
          );
          final st = await general.linkToPay(pl: pl);
          debugPrint('Link To Pay: ${st.linkToPay}');
      } on error.EbillFfiError catch (e) {
          debugPrint('Error, ${e.msg}, ${e.kind}');
      } catch (e, st) {
          debugPrint('Unexpected error: $e\n$st');
      }
  }

  Future<void> _createIdentity() async {
      try {
          final pl = identity_data.NewIdentityPayload(
                  t: BigInt.from(1),
                  name: "Minka",
                  email: null,
                  postalAddress: data.CreateOptionalPostalAddressFfi(
                      country: null,
                      city: null,
                      zip: null,
                      address: null,
                      ),
                  dateOfBirth: null,
                  countryOfBirth: null,
                  cityOfBirth: null,
                  identificationNumber: null,
                  profilePictureFileUploadId: null,
                  identityDocumentFileUploadId: null,
                  );
          final identityRes = await identity.create(identity: pl);
          debugPrint('Create: $identityRes');
      } on error.EbillFfiError catch (e) {
          debugPrint('Error, ${e.msg}, ${e.kind}');
      } catch (e, st) {
          debugPrint('Unexpected error: $e\n$st');
      }
  }

  Future<void> _getIdentity() async {
      try {
          final identityRes = await identity.detail();
          debugPrint('Create: ${identityRes.name} ${identityRes.nodeId}');
      } on error.EbillFfiError catch (e) {
          debugPrint('Error, ${e.msg}, ${e.kind}');
      } catch (e, st) {
          debugPrint('Unexpected error: $e\n$st');
      }
  }

  Future<void> _getBills() async {
      try {
          final billRes = await bill.list();

          for (int i = 0; i < billRes.bills.length; i++) {
              var bill = billRes.bills[i];
              debugPrint('Bill: ${bill.id}');
          }
      } on error.EbillFfiError catch (e) {
          debugPrint('Error, ${e.msg}, ${e.kind}');
      } catch (e, st) {
          debugPrint('Unexpected error: $e\n$st');
      }
  }

  @override
  void initState() {
    super.initState();
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
            const SizedBox(height: 16),
            Text('Hello E-Bill $_version!'),
            FloatingActionButton.extended(
              onPressed: _initFfi,
              tooltip: 'INIT',
              label: Text("Init"),
              icon: const Icon(Icons.start),
            ),
            FloatingActionButton.extended(
              onPressed: _getVersion,
              tooltip: 'GETVERSION',
              label: Text('Get Version'),
              icon: const Icon(Icons.list_sharp),
            ),
            FloatingActionButton.extended(
              onPressed: _getLinkToPay,
              tooltip: 'GETLINK',
              label: Text('Get Link To Pay'),
              icon: const Icon(Icons.list_sharp),
            ),
            FloatingActionButton.extended(
              onPressed: _createIdentity,
              tooltip: 'CREATE_IDENTITY',
              label: Text('Create Identity'),
              icon: const Icon(Icons.list_sharp),
            ),
            FloatingActionButton.extended(
              onPressed: _getIdentity,
              tooltip: 'GET',
              label: Text('Get Identity'),
              icon: const Icon(Icons.list_sharp),
            ),
            FloatingActionButton.extended(
              onPressed: _getBills,
              tooltip: 'GET',
              label: Text('Get Bills'),
              icon: const Icon(Icons.list_sharp),
            ),
          ],
        ),
      ),
    );
  }
}
