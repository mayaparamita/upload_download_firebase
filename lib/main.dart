import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uploaddownloadfirebase/services/authentication.dart';
import 'package:uploaddownloadfirebase/pages/root_page.dart';


void main() => runApp(MyApp());
//void main() {
//  WidgetsFlutterBinding.ensureInitialized();
//  runApp(MaterialApp(
//    //home: Login(),
//    debugShowCheckedModeBanner: false,
//    home:  new RootPage(auth: new Auth()),
//    //debugShowCheckedModeBanner: false,
//  ));
//}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Firebase Storage Demo",
      debugShowCheckedModeBanner: false,
      //home: MyHomePage(),
      home:  new RootPage(auth: new Auth()),
      //home: TabBarDemo(),
    ); // MaterialApp
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  File _imageFile;
  bool _uploaded=false;
  String _downloadUrl;
  StorageReference _reference = FirebaseStorage.instance.ref().child('myimage.jpg');

  Future getImage(bool isCamera) async {
    File image;
    if (isCamera) {
      image= await ImagePicker.pickImage(source: ImageSource.camera);
    } else
    {
      image= await ImagePicker.pickImage(source:ImageSource.gallery);
    }
    setState(() {
      _imageFile = image;
    });
  }

  Future uploadImage() async {
    StorageUploadTask uploadTask = _reference.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;// so when the upload task is complete we can have a snapshot [Maya note]
    setState(() {
      _uploaded = true;
    });
  }

  Future downloadImage() async {
    final String downloadAddress=await _reference.getDownloadURL();
    final http.Response downloadData = await http.get(downloadAddress);
    final Directory systemTempDir = Directory.systemTemp;
    final File tempFile = File('${systemTempDir.path}/tmp.jpg');
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
    await tempFile.create();
    final StorageFileDownloadTask task = _reference.writeToFile(tempFile);
    final int byteCount = (await task.future).totalByteCount;
    var bodyBytes = downloadData.bodyBytes;
    final String name = await _reference.getName();
    final String path = await _reference.getPath();

    var streamProfile = await tempFile.readAsBytes();
    var lengthProfile = await tempFile.length();
    print ('Success downloaded: $name \nUrl: $downloadAddress\nPath: $path\nBytes Count: $byteCount');


    setState(() {
      _downloadUrl=downloadAddress;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("Firebase Demo"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children:<Widget> [
              _imageFile == null? Container(): Image.file(_imageFile, height: 300.0, width: 300.0),
              RaisedButton(
                child:Text('Camera'),
                onPressed: () {
                  getImage(true);
                },
              ),
              SizedBox(height:10.0),
              RaisedButton(
                child:Text('Gallery'),
                onPressed: () {
                  getImage(false);
                },
              ),
              _imageFile == null? Container() : RaisedButton(
                  child:Text("Upload to Storage"),
                  onPressed: () {
                    uploadImage();
                  }
              ),
              _uploaded== false? Container (): RaisedButton(
                  child: Text('Download Image'),
                  onPressed: () {
                    downloadImage();
                  }),
              _downloadUrl==null? Container():Image.network(_downloadUrl),

            ],
          ),
        ),
      ),
    );
  }
}