package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUPageBuilder {
	public static function buildUniversalComponent():Array<Field> {
		return ClassBuilder.run([
			processGetMethod,
			processServerActionMethods
		]);
	}

	static function processGetMethod(cb:ClassBuilder):Void {
		for (member in cb) {
			if (member.name == "get") {
				// TODO: change client to make a HTTP call and return a promise of the same type.
				#if client
				#end
				return;
			}
		}
	}

	static function processServerActionMethods(cb:ClassBuilder):Void {
		for (member in cb) {
			switch member.extractMeta(':serverAction') {
				case Success(_):
					// TODO: check that all arguments are typed, and return type is a promise.

					// TODO: transform the client to make a HTTP call and still return a promise of the same type.
					#if client
					#end
				default:
			}
		}
	}
}
