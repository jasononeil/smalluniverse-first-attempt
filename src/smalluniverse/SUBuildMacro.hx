package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUBuildMacro {
	public static function buildUniversalComponent():Array<Field> {
		return ClassBuilder.run([
			#if server
				removePlatformSpecificMethods.bind(':client')
			#elseif client
				removePlatformSpecificMethods.bind(':server')
			#end
		]);
	}

	public static function buildUniversalPage():Array<Field> {
		return ClassBuilder.run([
			addCustomSerializeMethods
		]);
	}

	public static function buildBackendApi():Array<Field> {
		return ClassBuilder.run([
			#if client
				emptyAllMethodsExcept(['get', 'processAction']),
				emptyMethodBodies
			#end
		]);
	}

	static function emptyAllMethodsExcept(methodsToKeep:Array<String>):ClassBuilder->Void {
		return function (cb:ClassBuilder) {
			for (member in cb) {
				if (methodsToKeep.indexOf(member.name) == -1) {
					cb.removeMember(member);
				}
			}
		};
	}

	static function emptyMethodBodies(cb:ClassBuilder):Void {
		for (member in cb) {
			emptyField(member, false);
		}
	}

	static function removePlatformSpecificMethods(metaName:String, cb:ClassBuilder):Void {
		for (member in cb) {
			// Empty fields with `@:client` metadata.
			switch member.extractMeta(metaName) {
				case Success(_): emptyField(member, true);
				default:
			}
		}
	}

	static function emptyField(member:Member, changeSignature:Bool):Void {
		switch member.kind {
			// Leave the function or variable in place so it exists in case there is a reference to it.
			// But make all types "Any", and make the expression empty, so it won't cause compile time issues.
			case FFun(f):
				if (changeSignature) {
					for (arg in f.args) {
						arg.type = macro :Any;
					}
					f.ret = macro :Any;
				}
				f.expr = macro return null;
			case FVar(t, e):
				if (changeSignature) {
					member.kind = FVar(macro :Any, macro null);
				} else {
					member.kind = FVar(t, macro null);
				}
			case FProp(get, set, t, e):
				if (changeSignature) {
					member.kind = FProp(get, set, macro :Any, macro null);
				} else {
					member.kind = FProp(get, set, t, macro null);
				}
		}
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
			override public function $serializeName(value:$targetType):String @:pos(cb.target.pos) {
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
			override public function $deserializeName(json:String):$targetType @:pos(cb.target.pos) {
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
