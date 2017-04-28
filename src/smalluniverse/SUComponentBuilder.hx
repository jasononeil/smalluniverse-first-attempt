package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUComponentBuilder {
	public static function buildUniversalComponent():Array<Field> {
		return ClassBuilder.run([
			hidePlatformSpecificMethods
		]);
	}

	static function hidePlatformSpecificMethods(cb:ClassBuilder):Void {
		for (member in cb) {
			#if server
				// Empty fields with `@:client` metadata.
				switch member.extractMeta(':client') {
					case Success(_): emptyField(member);
					default:
				}
			#elseif client
				// Empty fields with `@:server` metadata.
				switch member.extractMeta(':server') {
					case Success(_): emptyField(member);
					default:
				}
			#end
		}
	}

	static function emptyField(member:Member):Void {
		switch member.kind {
			// Leave the function or variable in place so it exists in case there is a reference to it.
			// But make all types "Any", and make the expression empty, so it won't cause compile time issues.
			case FFun(f):
				for (arg in f.args) {
					arg.type = macro :Any;
				}
				f.ret = macro :Any;
				f.expr = macro return null;
			case FVar(t, e):
				member.kind = FVar(macro :Any, macro null);
			case FProp(get, set, t, e):
				member.kind = FProp(get, set, macro :Any, macro null);
		}
	}
}
