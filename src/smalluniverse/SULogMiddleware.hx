package smalluniverse;

import haxe.Json;
import haxe.PosInfos;
import monsoon.Response;
using tink.CoreApi;
using Monsoon;

class SULogMiddleware {

	var logs:Array<Array<String>>;

	public function new() {
		this.logs = [];
		haxe.Log.trace = function(v:Dynamic, ?pos:PosInfos) {
			var arr:Array<Dynamic> = [];
			arr.push('%c${pos.className}.${pos.methodName}():${pos.lineNumber}');
			arr.push("background: #222; color: white");
			arr.push(v);
			if (pos.customParams != null) {
				for (arg in pos.customParams) {
					arr.push(arg);
				}
			}
			var stringArray = arr.map(function (val) return Json.stringify(val));
			logs.push(stringArray);
		};
	}

	public function process(req:Request, res:Response, next) {
		res.after(function(res) {
			var type = res.get('content-type');
			if (type == null || logs.length == 0) {
				return Future.sync(res);
			}

			if (type.indexOf('text/html') > -1) {
				return res.body.all().map(function (b) {
					var body = b.toString();
					var script = '\n<script>';
					for (log in logs) {
						var args = log.map(function (arg) return 'JSON.parse(\'$arg\')').join(", ");
						script += '\nconsole.log($args);';
					}
					script += '\n</script>';
					res.clear();
					res.send(body + script);
					return res;
				});
				return Future.sync(res);
			} else if (type.indexOf('application/json') > -1) {
				return res.body.all().map(function (b) {
					var str = b.toString();
					// Please note we have to use haxe.Json instead of tink.Json.
					// The reason is that tink.Json will ignore any fields it isn't expecting when parsing, and we want to preserve all data.
					var responseData:Dynamic = haxe.Json.parse(str);
					if (!Reflect.hasField(responseData, '__smallUniverse')) {
						Reflect.setField(responseData, '__smallUniverse', {});
					}
					if (!Reflect.hasField(responseData.__smallUniverse, 'messages')) {
						Reflect.setField(responseData.__smallUniverse, 'messages', logs);
					}
					responseData.__smallUniverse.messages = logs;
					res.clear();
					res.json(responseData);
					return res;
				});
			} else {
				return Future.sync(res);
			}
		});
		next();
	}
}
