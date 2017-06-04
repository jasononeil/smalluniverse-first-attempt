package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUPageBuilder {
	public static function buildUniversalPage():Array<Field> {
		return ClassBuilder.run([
			addCustomSerializeMethods
		]);
	}

	static function addCustomSerializeMethods(cb:ClassBuilder) {
		// Note: we are assuming we are extending UniversalPage<TAction, TParams, TProps, TState, TRef>. Which may not be the case.
		var propsCT = cb.target.superClass.params[2].toComplex();
		var actionsCT = cb.target.superClass.params[0].toComplex();
		addSerializeMethods(cb, 'Props', propsCT);
		addSerializeMethods(cb, 'Action', actionsCT);
	}

	static function addSerializeMethods(cb:ClassBuilder, name:String, targetType:ComplexType) {
		var serializeName = 'serialize' + name;
		var deserializeName = 'deserialize' + name;
		var newMethods = (macro class Tmp {
			override public function $serializeName(value:$targetType):String {
				return try {
					tink.Json.stringify(value);
				} catch (e:Dynamic) {
					trace('Error stringifying JSON: '+e);
					#if client
					js.Lib.rethrow();
					#else
					throw e;
					#end
					null;
				}
			}
			override public function $deserializeName(json:String):$targetType {
				return try {
					tink.Json.parse(json);
				} catch (e:Dynamic) {
					trace('Error parsing JSON: '+e);
					#if client
					js.Lib.rethrow();
					#else
					throw e;
					#end
					null;
				}
			}
		}).fields;
		cb.addMember(newMethods[0]);
		cb.addMember(newMethods[1]);
	}
}
