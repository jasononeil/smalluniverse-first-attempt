package smalluniverse;

import haxe.PosInfos;

/**
	A singleton that intercepts `trace()` calls and gives them to you on demand.
**/
class SULogger {
	/** A singleton! **/
	public static var instance(get, null):SULogger;

	static function get_instance() {
		if (instance == null) {
			instance = new SULogger();
		}
		return instance;
	}

	var logs:Array<Array<String>> = [];

	function new() {}

	public function captureTraces() {
		haxe.Log.trace = log;
	}

	public function log(v:Dynamic, ?pos:PosInfos) {
		var arr:Array<Dynamic> = [];
		arr.push('%c${pos.className}.${pos.methodName}():${pos.lineNumber}');
		arr.push("background: #222; color: white");
		arr.push(v);
		if (pos.customParams != null) {
			for (arg in pos.customParams) {
				arr.push(arg);
			}
		}
		var stringArray = arr.map(function(val) return haxe.Json.stringify(val));
		#if hxnodejs
		// Also log to the server console.
		var className = pos.className.substr(pos.className.lastIndexOf('.') + 1), params = [v], resetColor = "\x1b[0m", dimColor = "\x1b[2m";
		if (pos.customParams != null) {
			for (p in pos.customParams)
				params.push(p);
		}
		js.Node.console.log('${dimColor}${className}.${pos.methodName}():${pos.lineNumber}:${resetColor} ${params.join(" ")}');
		#end
		logs.push(stringArray);
	}

	/**
		Get an array of all logs (each log containing an array of strings).
		If there are no logs this will return null.
		This will empty the queue of logs, so logs can only be retrieved once.
	**/
	public function getMessages():Null<Array<Array<String>>> {
		if (logs.length > 0) {
			var toReturn = logs;
			logs = [];
			return toReturn;
		}
		return null;
	}
}
