package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUPageBuilder {
	public static function buildUniversalPage():Array<Field> {
		return ClassBuilder.run([
			processGetMethod,
			processServerActionMethods,
			addRoutingMethod
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
					fn.expr = macro {
						var args = haxe.Serializer.run([]);
						return this.callServerApi('get', args);
					}
				#end
				return;
			}
		}
	}

	static function processServerActionMethods(cb:ClassBuilder):Void {
		for (member in getServerActions(cb)) {
			// Check that all arguments are typed, and return type is a promise.
			var fn = member.getFunction().sure();
			checkReturnTypeIsPromise(fn.ret, member.pos);
			checkArgumentsAreExplicitlyTyped(fn.args, member.pos);

			#if client
			// Transform the client to make a HTTP call and still return a promise of the same type.
			var argExprs = [for (arg in fn.args) macro $i{arg.name}];
			fn.expr = macro {
				var args = $a{argExprs};
				var argsString = haxe.Serializer.run(args);
				return this.callServerApi($v{member.name}, argsString);
			}
			#end
		}
	}

	static function getServerActions(cb:ClassBuilder):Array<Member> {
		var members = [for (member in cb) member];
		return members.filter(function (member) {
			return member.asField().meta.filter(function (metaEntry) {
				return metaEntry.name == ':serverAction';
			}).length > 0;
		});
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

	static function addRoutingMethod(cb:ClassBuilder) {
		#if server
		var actionCases = [];

		// Add cases for all server actions
		for (member in getServerActions(cb)) {
			actionCases.push({
				values: [macro $v{member.name}],
				expr: macro smalluniverse.SmallUniverse.executeActionAndRenderJson(this, $v{member.name}, req, res),
				guard: macro isApiRequest
			});
			actionCases.push({
				values: [macro $v{member.name}],
				expr: macro smalluniverse.SmallUniverse.executeActionAndSetRedirect(this, $v{member.name}, req, res),
				guard: macro !isApiRequest
			});
		}

		// Add cases for "get" method, which is also called if no action is specified.
		actionCases.push({
			values: [macro "get", macro null],
			expr: macro smalluniverse.SmallUniverse.renderPagePropsJson(this, res),
			guard: macro isApiRequest
		});
		actionCases.push({
			values: [macro "get", macro null],
			expr: macro smalluniverse.SmallUniverse.renderPageToHtml(this, res),
			guard: macro !isApiRequest
		});

		// Add a default case that 404s, and combine it
		var defaultCase = macro super.route(req, res);
		var switchExpr = {
			expr: ESwitch(macro action, actionCases, defaultCase),
			pos: cb.target.pos
		};

		// Create the method.
		var routingMethod = (macro class Tmp {
			@:access(smalluniverse.SmallUniverse)
			override public function route(req:monsoon.Request, res:monsoon.Response) {
				var action = req.query.get('small-universe-action');
				var isApiRequest = req.header.byName('x-small-universe-api').isSuccess();
				$switchExpr;
			}
		}).fields[0];
		cb.addMember(routingMethod);
		#end
	}
}
