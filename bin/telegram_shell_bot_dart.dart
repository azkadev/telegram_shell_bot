// ignore_for_file: unnecessary_brace_in_string_interps, non_constant_identifier_names, unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:telegram_client/telegram_client.dart';
import 'package:galaxeus_lib/galaxeus_lib.dart';
import 'package:path/path.dart' as p;
import 'package:telegram_client/scheme/tdlib_scheme.dart' as tdlib_scheme;

String get format_lib {
  if (Platform.isMacOS) {
    return "dylib";
  }
  return "so";
}

void main(List<String> arguments) async {
  Directory current_dir = Directory.current;
  String db_bot_api = p.join(current_dir.path, "bot_api");
  Directory dir_bot_api = Directory(db_bot_api);
  if (!dir_bot_api.existsSync()) {
    dir_bot_api.createSync(recursive: true);
  }
  String token_bot = Platform.environment["token_bot"] ?? ":";
  int owner_user_id = int.parse(Platform.environment["owner_user_id"] ?? "");
  print(token_bot.split(":").first);
  TelegramBotApiServer telegramBotApiServer = TelegramBotApiServer();

  Tdlib tg = Tdlib("./libtdjson.${format_lib}");
  // TelegramBotApi tg = TelegramBotApi(token_bot, clientOption: {
  //   "api": "http://0.0.0.0:9000/",
  // });

  // tg.request("setWebhook", parameters: {"url": "http://${host}:${port}"});
  EventEmitter eventEmitter = EventEmitter();
  Process shell = await Process.start("bash", []);
  late String result = "";
  shell.stdout.listen(
    (event) async {
      result += utf8.decode(event);
      print(utf8.decode(event));
      await tg.request("sendMessage", parameters: {
        "chat_id": owner_user_id,
        "text": result,
      });
    },
    onDone: () async {
      print("done");
      await tg.request("sendMessage", parameters: {
        "chat_id": owner_user_id,
        "text": result,
      });
      result = "";
    },
  );
  shell.stderr.listen(
    (event) async {
      result += utf8.decode(event);
      print(utf8.decode(event));
      await tg.request("sendMessage", parameters: {
        "chat_id": owner_user_id,
        "text": result,
      });
    },
    onDone: () async {
      await tg.request("sendMessage", parameters: {
        "chat_id": owner_user_id,
        "text": result,
      });
      result = "";
    },
  );
  eventEmitter.on("update", null, (ev, context) async {
    if (ev.eventData is Map) {
      Map update = (ev.eventData as Map);

      if (update["message"] is Map) {
        Map msg = (update["message"] as Map);
        Map from = msg["from"];
        int from_id = from["id"];
        Map chat = msg["chat"];
        int chat_id = chat["id"];
        String? text = msg["text"];
        if (text != null) {
          if (RegExp(r"/start", caseSensitive: false).hasMatch(text)) {
            await tg.request("sendMessage", parameters: {
              "chat_id": chat_id,
              "text": "Hai manies lagi apah nich, btw perkenalkan aku robot yah manies, di buat dari cingtah oppah @azkadev",
              "reply_markup": {
                "inline_keyboard": [
                  [
                    {"text": "Github", "url": "https://github.com/azkadev"}
                  ]
                ]
              }
            });
            return;
          }
          // if (from_id != owner_user_id) {
          //   return;
          // }
          result = "";
          shell.stdin.write("${text}\n");
        }
      }
    }
  });

  tg.on(tg.event_update, (UpdateTd update) async {
    // print(json.encode(update.raw));

    /// authorization update
    if (update.raw["@type"] == "updateAuthorizationState") {
      if (update.raw["authorization_state"] is Map) {
        var authStateType = update.raw["authorization_state"]["@type"];

        /// init tdlib parameters
        await tg.initClient(
          update,
          clientId: update.client_id,
          tdlibParameters: update.client_option,
          isVoid: true,
        );

        if (authStateType == "authorizationStateLoggingOut") {}
        if (authStateType == "authorizationStateClosed") {
          print("close: ${update.client_id}");
          tg.exitClient(update.client_id);
        }
        if (authStateType == "authorizationStateWaitPhoneNumber") { 
          /// use this if you wan't login as bot
          await tg.callApi(
            tdlibFunction: tdlib_scheme.TdlibFunction.checkAuthenticationBotToken(
              token: token_bot,
            ),
            clientId: update.client_id, // add this if your project more one client
          );

        }
        if (authStateType == "authorizationStateWaitCode") { 
        }
        if (authStateType == "authorizationStateWaitPassword") {
          
        }

        if (authStateType == "authorizationStateReady") {
          Map get_me = await tg.getMe(clientId: update.client_id);
          print(get_me);
        }
      }
    }

    if (update.raw["@type"] == "updateNewMessage") {
      if (update.raw["message"] is Map) {
        /// tdlib scheme is not full real because i generate file origin to dart with my script but you can still use
        tdlib_scheme.Message message = tdlib_scheme.Message(update.raw["message"]);
        int chat_id = message.chat_id ?? 0;
        if (message.content.special_type == "messageText") {
          if (update.raw["message"]["content"]["text"] is Map && update.raw["message"]["content"]["text"]["text"] is String) {
            String text = (update.raw["message"]["content"]["text"]["text"] as String);

            result = "";
            shell.stdin.write("${text}\n");
          }
        }
      }
    }
  });

  await tg.initIsolate();
  print("succes init isolate");
}
