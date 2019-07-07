package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.ds.Option;

using tink.MacroApi;

class SUBuildMacro {
	public static function buildUniversalComponent():Array<Field> {
		return ClassBuilder.run([
			#if server removePlatformSpecificMethods.bind(':client') #elseif client removePlatformSpecificMethods.bind(':server')
			#end
		]);
	}

	public static function buildUniversalPage():Array<Field> {
		return ClassBuilder.run([addCustomSerializeMethods]);
	}

	public static function buildBackendApi():Array<Field> {
		return ClassBuilder.run([
			#if client emptyAllMethodsExcept(['get', 'processAction']), emptyMethodBodies, emptyConstructor,
			#end
		]);
	}

	/**
		Build a SmallUniverseRoute appropriate for the UniversalPage type.

		The main thing here is the "POST" method needs to use tink_web macro magic to parse the JSON of the expected action.
		This build method extends
	**/
	public static function buildSmallUniverseRoute():ComplexType {
		return buildRoute(Context.getLocalType());
	}

	static function emptyAllMethodsExcept(methodsToKeep:Array<String>):ClassBuilder->Void {
		return function(cb:ClassBuilder) {
			for (member in cb) {
				if (methodsToKeep.indexOf(member.name) == -1) {
					cb.removeMember(member);
				}
			}
		};
	}

	static function emptyMethodBodies(cb:ClassBuilder):Void {
		for (member in cb) {
			emptyField(cb, member, false);
		}
	}

	static function removePlatformSpecificMethods(metaName:String, cb:ClassBuilder):Void {
		for (member in cb) {
			// Empty fields with `@:client` metadata.
			switch member.extractMeta(metaName) {
				case Success(_):
					emptyField(cb, member, true);
				default:
			}
		}
	}

	static function emptyField(cb:ClassBuilder, member:Member, changeSignature:Bool):Void {
		// If the member overrides a parent, it is safe to just remove it entirely.
		if (member.overrides) {
			cb.removeMember(member);
			return;
		}
		switch member.kind {
			// Leave the function or variable in place so it exists in case there is a reference to it.
			// But make all types "Any", and make the expression empty, so it won't cause compile time issues.
			case FFun(f):
				if (changeSignature) {
					for (arg in f.args) {
						arg.type = macro:Any;
					}
					f.ret = macro:Any;
				}
				f.expr = macro return null;
			case FVar(t, e):
				if (changeSignature) {
					member.kind = FVar(macro:Any, macro null);
				} else {
					member.kind = FVar(t, macro null);
				}
			case FProp(get, set, t, e):
				if (changeSignature) {
					member.kind = FProp(get, set, macro:Any, macro null);
				} else {
					member.kind = FProp(get, set, t, macro null);
				}
		}
	}

	static function emptyConstructor(cb:ClassBuilder):Void {
		if (cb.hasConstructor()) {
			var constructor = cb.getConstructor();
			constructor.onGenerate(function(fn) {
				fn.args = [
					for (a in fn.args)
						{
							name: '_',
							opt: true,
							type: null,
							value: null
						}
				];
				fn.params = null;
				fn.expr = if (cb.target.superClass != null) macro super() else macro {};
			});
		}
	}

	static function addCustomSerializeMethods(cb:ClassBuilder) {
		if (cb.target.superClass.t.toString() != "smalluniverse.UniversalPage") {
			// Only add these methods on classes that extend UniversalPage directly, not on their subclasses.
			return;
		}
		// Note: we are assuming we are extending UniversalPage<TAction, TProps, TRef>. Which may not be the case.
		var actionsCT = cb.target.superClass.params[0].toComplex();
		var propsCT = cb.target.superClass.params[1].toComplex();
		addSerializeMethods(cb, 'Props', propsCT);
		addSerializeMethods(cb, 'Action', macro:smalluniverse.SURequestBody<$actionsCT>);
	}

	static function addSerializeMethods(cb:ClassBuilder, name:String, targetType:ComplexType) {
		var serializeName = 'serialize' + name;
		var deserializeName = 'deserialize' + name;
		var newMethods = (macro class Tmp {
			override public function $serializeName(value : $targetType):String@:pos(cb.target.pos) {
				return try {
					tink.Json.stringify(value);
				} catch (e:Dynamic) {
					#if client
					js.Lib.rethrow();
					#else
					throw e;
					#end
					null;
				}
			}

			override public function $deserializeName(json : String):$targetType@:pos(cb.target.pos) {
				return try {
					tink.Json.parse(json);
				} catch (e:Dynamic) {
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

	//
	// SmallUniverseRoute builder
	//
	static function buildRoute(localType:Type):ComplexType {
		switch (Context.getLocalType()) {
			case TInst(classRef, [pageType]) if (classRef.toString() == "smalluniverse.SmallUniverseRoute"):
				switch getActionType(pageType) {
					case Some(actionType):
						return getOrDefineClass(pageType, actionType);
					case None:
				}
			case TInst(classRef, typeParams) if (classRef.toString() == "smalluniverse.SmallUniverseRoute"):
				Context.error('You must specify a type parameter: eg `new SmallUniverseRoute<MyUniversalPage>(new MyUniversalPage())`', Context.currentPos());
			case t:
				Context.error('buildSmallUniverseRoute() should only be used on SmallUniverseRoute, but was used on $t', Context.currentPos());
		}
		return null;
	}

	static function getActionType(pageType:Type):Option<ComplexType> {
		return switch pageType {
			case TInst(pageRef, params):
				var pageClassType = pageRef.get();
				if (pageClassType.superClass == null) {
					Context.error('Expected page type to be a subclass of UniversalPage, but ${pageRef.toString()} does not extend anything',
						Context.currentPos());
					return None;
				}
				// TODO: make this recursive, so we can subclass UniversalPages and it will climb the tree until we find UniversalPage.
				var superClassName = pageClassType.superClass.t.toString();
				if (superClassName != "smalluniverse.UniversalPage") {
					Context.error('Expected page type to be a subclass of UniversalPage, but ${pageRef.toString()} extends $superClassName instead',
						Context.currentPos());
					return None;
				}
				var pageParams = pageClassType.superClass.params;
				var actionType = pageParams[0];
				return Some(actionType.toComplex());
			case other:
				Context.error('Expected pageType to be a class (TInst), but was $other', Context.currentPos());
				return None;
		}
	}

	static function getOrDefineClass(pageType:Type, actionType:ComplexType):ComplexType {
		var pack = ["smalluniverse", "generated", "routes"];
		var name = "Route_" + StringTools.replace(pageType.toComplex().toString(), ".", "_");
		var fullName = pack.join(".") + "." + name;

		try {
			// See if the type already exists.
			var type = Context.getType(fullName);
			return type.toComplex();
		} catch (err:String) {
			// If not, define it and return it.
			Context.defineType(getRouteDefinition(pack, name, pageType.toComplex(), actionType));
			return TPath({
				name: name,
				pack: pack,
				params: [],
				sub: null
			});
		}
	}

	static function getRouteDefinition(pack:Array<String>, name:String, page:ComplexType, action:ComplexType) {
		var definition = macro class $name {
			var page:$page;

			public function new(page:$page) {
				this.page = page;
			}

			@:get('/')
			public function get(context:tink.web.routing.Context) {
				return SmallUniverse.render(page, context);
			}

			@:post('/')
			@:consumes('application/json') // tink_querystring doesn't support decoding enums, so we're limiting to JSON only
			public function post(context:tink.web.routing.Context, body:smalluniverse.SURequestBody<$action>) {
				return SmallUniverse.render(page, context, body.action);
			}
		}
		definition.pack = pack;
		return definition;
	}
}
