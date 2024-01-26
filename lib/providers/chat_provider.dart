import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:minimal/constants/constants.dart';
import 'package:minimal/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatProvider {

  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider({required this.firebaseFirestore, required this.prefs, required this.firebaseStorage});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(docPath).update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentSnapshot> getChatBot(String id) async{
    return await firebaseFirestore
        .collection(FirestoreConstants.pathBotCollection).doc(id).get();
  }

  void sendMessage(String content, int type, String groupChatId, String currentUserId, Arguments arg) {
    send(content, groupChatId, currentUserId, arg.peerId, type);
  }

  void getResponse(String content, String groupChatId, String currentUserId, Arguments arg, int type){
    getAIResponse(content, arg).then((String result){
      send(result, groupChatId, arg.peerId, currentUserId, type);
    });
  }

  void send(String message, String groupChatId, String from, String to, int type){
    DocumentReference documentReference2 = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    MessageChat messageChat2 = MessageChat(
      idFrom: from,
      idTo: to,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      type: type,
    );

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference2,
        messageChat2.toJson(),
      );
    });
  }

  Future<String> getAIResponse(String message, Arguments arg) async {
    try {
      Map<String, dynamic> body =  arg.azureRequest(message);
      var encode = json.encode(arg.peerIsSearchIndex?RequestIndexer.fromJson(body):Request.fromJson(body));
      final response = await http.post(
        Uri.parse(arg.peerEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: encode
      );

      if (response.statusCode == 200) {
        var decode = json.decode(response.body);
        if(arg.peerIsSearchIndex){
          var message = decode["choices"].first["messages"];
          var citation = jsonDecode(message.first["content"])["citations"];
          if(citation.isEmpty){
            return "Mohon maaf kami tidak mengerti pertanyaan anda!";
          }else{
            var content = citation.first["content"];
            return "$content";
          }
        }else{
          var message = decode["choices"].first["message"];
          return "${message["content"]}";
        }
      } else {
        return "Mohon maaf ada kesalahan pada sistem kami!";
      }
    } catch  (e) {
        return "Mohon maaf ada kesalahan pada sistem kami!";
    }
  }
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}

class Request {
  final List<Map<String, String>> messages;
  final double temperature;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final int maxTokens;
  final List<String>? stop;

  Request(this.messages, 
       this.temperature,
       this.topP,
       this.frequencyPenalty,
       this.presencePenalty,
       this.maxTokens,
       this.stop
      ); 

  Request.fromJson(Map<String, dynamic> json)
      : messages = json['messages'] as List<Map<String, String>>,
        temperature = json['temperature'] as double,
        topP = json['top_p'] as double,
        frequencyPenalty = json['frequency_penalty'] as double,
        presencePenalty = json['presence_penalty'] as double,
        maxTokens = json['max_tokens'] as int,
        stop = json['stop'] as List<String>?;
        
  Map<String, dynamic> toJson() => {
        'messages': messages,
        'temperature': temperature,
        'top_p': topP,
        'frequency_penalty': frequencyPenalty,
        'presence_penalty': presencePenalty,
        'max_tokens': maxTokens,
        'stop': stop?.isEmpty ?? true ?null:stop,
      };
}

class RequestIndexer {
  final List<Map<String, String>> messages;
  final double temperature;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final int maxTokens;
  final List<String>? stop;
  final ListDataSource dataSources;

  RequestIndexer(this.messages, 
       this.temperature,
       this.topP,
       this.frequencyPenalty,
       this.presencePenalty,
       this.maxTokens,
       this.stop,
       this.dataSources
      ); 

  RequestIndexer.fromJson(Map<String, dynamic> json)
      : messages = json['messages'] as List<Map<String, String>>,
        temperature = json['temperature'] as double,
        topP = json['top_p'] as double,
        frequencyPenalty = json['frequency_penalty'] as double,
        presencePenalty = json['presence_penalty'] as double,
        maxTokens = json['max_tokens'] as int,
        stop = json['stop'] as List<String>?,
        dataSources = ListDataSource.fromJson(json['dataSources']);
        
  Map<String, dynamic> toJson() => {
        'messages': messages,
        'temperature': temperature,
        'top_p': topP,
        'frequency_penalty': frequencyPenalty,
        'presence_penalty': presencePenalty,
        'max_tokens': maxTokens,
        'stop': stop?.isEmpty ?? true ?null:stop,
        // 'dataSources': 
        'dataSources': dataSources.list.map((e) => {
          'type': e.type,
          'parameters': {
            'endpoint': e.param.endpoint,
            'key': e.param.key,
            'indexName': e.param.indexName
          }
        }).toList()
      };
}

class ListDataSource{
  late List<IndexerDataSources> list;

  ListDataSource({required this.list});

  ListDataSource.fromJson(List<Map<String, dynamic>> json){
    list = <IndexerDataSources>[];
    json.forEach((element) {
      list.add(IndexerDataSources.fromJson(element));
    });
  }
}

class IndexerDataSources{
  final String type;
  final DataSourcesParam param;

  // IndexerDataSources({required type, required param});

  IndexerDataSources.fromJson(Map<String, dynamic> json):
    type = json['type'] as String,
    param = DataSourcesParam.fromJson(json['parameters']);
}

class DataSourcesParam{
  final String endpoint;
  final String key;
  final String indexName;

  DataSourcesParam.fromJson(Map<String, dynamic> json):
    endpoint= json['endpoint'] as String,
    key = json['key'] as String,
    indexName = json['indexName'] as String;
}