import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home:MyApp()
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String url ="";
  int? number;
  uploadDataToFirebase() async {
    //Generate random number
    number = Random().nextInt(10);
    //File Picker
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    File pick = File(result!.files.single.path.toString());
    var file = pick.readAsBytesSync();
    String name = DateTime.now().microsecondsSinceEpoch.toString();
    // Uploading File to Firebase
    var pdfFile = FirebaseStorage.instance.ref().child(name).child("/.pdf");
    UploadTask task = pdfFile.putData(file);
    TaskSnapshot snapshot = await task;
    url = await snapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance.collection("file").doc().set({
      'fileUrl' :url,
      'num' :"Book#"+number.toString()
    });


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloud E-Book"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("file").snapshots(),
        builder: (context,AsyncSnapshot<QuerySnapshot>snapshot){
          if(snapshot.hasData){
            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context,i) {
                  QueryDocumentSnapshot x = snapshot.data!.docs[i];
                  return InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>View(url: x['fileUrl'])));
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Text(x["num"]),
                    ),
                  );
                });

          }
          return
            Center(child:  CircularProgressIndicator(),);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadDataToFirebase,child:const Icon(Icons.add)
        ,),
    );
  }
}


class View extends StatelessWidget {
  PdfViewerController? _pdfViewerController;
  final url;
  View ({this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book View"),
      ),
      body: SfPdfViewer.network(url,
      controller: _pdfViewerController,),
    );
  }
}
