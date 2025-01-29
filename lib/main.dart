import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ConnectionScreen(),
    );
  }
}

class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  String _serverAddress = '';

  Future<void> _scanQR() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final image = FirebaseVisionImage.fromFilePath(pickedFile.path);
      final barcodeDetector = FirebaseVision.instance.barcodeDetector();
      final barcodes = await barcodeDetector.detectInImage(image);

      for (var barcode in barcodes) {
        if (barcode.value != null) {
          setState(() {
            _serverAddress = barcode.value;
            _ipController.text = _serverAddress.split(':')[0];
            _portController.text = _serverAddress.split(':')[1];
          });
        }
      }
    }
  }

  void _connect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanScreen(
          serverAddress: 'http://${_ipController.text}:${_portController.text}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conectar al servidor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(labelText: 'IP del servidor'),
            ),
            TextField(
              controller: _portController,
              decoration: InputDecoration(labelText: 'Puerto del servidor'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scanQR,
              child: Text('Escanear QR para IP y Puerto'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              child: Text('Conectar'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanScreen extends StatefulWidget {
  final String serverAddress;

  ScanScreen({required this.serverAddress});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _quantityController = TextEditingController();
  String _scannedData = '';

  Future<void> _scanQR() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final image = FirebaseVisionImage.fromFilePath(pickedFile.path);
      final barcodeDetector = FirebaseVision.instance.barcodeDetector();
      final barcodes = await barcodeDetector.detectInImage(image);

      for (var barcode in barcodes) {
        if (barcode.value != null) {
          setState(() {
            _scannedData = barcode.value;
          });
          _sendData();
        }
      }
    }
  }

  Future<void> _sendData() async {
    final response = await http.post(
      Uri.parse(widget.serverAddress),
      body: {
        'data': _scannedData,
        'quantity': _quantityController.text,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos enviados correctamente')),
      );
      setState(() {
        _quantityController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar los datos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear y Enviar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scanQR,
              child: Text('Escanear Código'),
            ),
          ],
        ),
      ),
    );
  }
}