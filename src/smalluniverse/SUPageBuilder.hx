package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUPageBuilder {
	public static function buildUniversalPage():Array<Field> {
		return ClassBuilder.run([
			processGetMethod,
			processServerActionMethods
		]);
	}

	static function processGetMethod(cb:ClassBuilder):Void {
		for (member in cb) {
			if (member.name == "get") {
				#if client
					var fn = member.getFunction().sure();
					fn.expr = macro {
						// TODO: make a HTTP call to return a promise of the same type.
						return tink.core.Future.sync(Success(null));
					}
				#end
				return;
			}
		}
	}

	static function processServerActionMethods(cb:ClassBuilder):Void {
		for (member in cb) {
			switch member.extractMeta(':serverAction') {
				case Success(_):
					// Check that all arguments are typed, and return type is a promise.
					var fn = member.getFunction().sure();
					checkReturnTypeIsPromise(fn.ret, member.pos);
					checkArgumentsAreExplicitlyTyped(fn.args, member.pos);

					#if client
					// Transform the client to make a HTTP call and still return a promise of the same type.
					var argExprs = [for (arg in fn.args) macro $i{arg.name}];
					fn.expr = macro {
						// TODO: make a HTTP call to return a promise of the same type.
						var argsString = $a{argExprs};
						var args = haxe.Serializer.run(argsString);
						return this.callServerApi($v{member.name}, args);
					}
					#end
				default:
			}
		}
	}

	static function checkReturnTypeIsPromise(ret:ComplexType, pos:Position) {
		var type = ret.toType(pos).sure();
		switch Context.follow(type) {
			case TAbstract(_.toString() => "tink.core.Promise", params):
			case _:
				Context.error('Function should return a tink.core.Promise', pos);
		}
	}

	static function checkArgumentsAreExplicitlyTyped(args:Array<FunctionArg>, pos:Position) {
		for (arg in args) {
			if (arg.type == null) {
				Context.warning('Argument ${arg.name} should have explicit type', pos);
			}
		}
	}
}
