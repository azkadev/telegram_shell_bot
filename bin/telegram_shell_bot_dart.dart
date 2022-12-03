// ignore_for_file: unnecessary_brace_in_string_interps, non_constant_identifier_names, unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:telegram_client/telegram_client.dart';
import 'package:alfred/alfred.dart';
import 'package:galaxeus_lib/galaxeus_lib.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  Directory current_dir = Directory.current;
  String db_bot_api = p.join(current_dir.path, "bot_api");
  Directory dir_bot_api = Directory(db_bot_api);
  if (!dir_bot_api.existsSync()) {
    dir_bot_api.createSync(recursive: true);
  }
  int port = int.parse(Platform.environment["PORT"] ?? "8970");
  String host = Platform.environment["HOST"] ?? "0.0.0.0";
  String token_bot = Platform.environment["token_bot"] ?? ":";
  int owner_user_id = int.parse(Platform.environment["owner_user_id"] ?? "");
  print(token_bot.split(":").first);
  TelegramBotApiServer telegramBotApiServer = TelegramBotApiServer();
  telegramBotApiServer.run(
    executable: "./telegram-bot-api",
    arguments: telegramBotApiServer.optionsParameters(
      api_id: Platform.environment["api_id"] ?? "",
      api_hash: Platform.environment["api_hash"] ?? '',
      http_port: "9000",
      dir: dir_bot_api.path,
    ),
  );
  TelegramBotApi tg = TelegramBotApi(token_bot, clientOption: {
    "api": "http://0.0.0.0:9000/",
  });

  tg.request("setWebhook", parameters: {"url": "http://${host}:${port}"});
  Alfred app = Alfred(logLevel: LogType.error);
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

  app.all("/", (req, res) async {
    if (req.method.toLowerCase() != "post") {
      return res.json({"@type": "ok", "message": "server run normal"});
    } else {
      Map body = await req.bodyAsJsonMap;
      eventEmitter.emit("update", null, body);
      return res.json({"@type": "ok", "message": "server run normal"});
    }
  });

  await app.listen(port, host);

  print("Server run on ${app.server!.address.address}}");
}
