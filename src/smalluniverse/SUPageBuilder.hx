package smalluniverse;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class SUPageBuilder {
	public static function buildUniversalPage():Array<Field> {
		return ClassBuilder.run([
			processGetMethod,
			processServerActionMethods,
			addRoutingMethod,
			addDeserializePropsMethod
		]);
	}

	static function getPropsTypeForClass(cb:ClassBuilder):ComplexType {
		// Note: we are assuming we are extending UniversalPage<TProps,...>. Which may not be the case.
		return cb.target.superClass.params[0].toComplex();
	}

	static function processGetMethod(cb:ClassBuilder):Void {
		var propsComplexType = getPropsTypeForClass(cb);
		for (member in cb) {
			if (member.name == "get") {
				#if client
					var fn = member.getFunction().sure();
					fn.expr = macro {
						return this.callServerApi('get').next(function (serializedProps:String) {
							var props:$propsComplexType =
								try {
									tink.Json.parse(serializedProps);
								} catch (e:Dynamic) {
									trace('Error parsing properties: '+e);
									js.Lib.rethrow();
									null;
								}
							return props;
						});
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
			var resultType = checkReturnTypeIsPromise(fn.ret, member.pos);
			checkArgumentsAreExplicitlyTyped(fn.args, member.pos);

			#if client
			// Transform the client to make a HTTP call and still return a promise of the same type.
			var setArgsInFormData = [for (arg in fn.args) {
				macro formData.append($v{arg.name}, tink.Json.stringify($i{arg.name}));
			}];
			fn.expr = macro {
				var formData = new js.html.FormData();
				$b{setArgsInFormData};
				return this.callServerApi($v{member.name}, formData).next(function (serializedResult:String) {
					var result:$resultType =
						try {
							tink.Json.parse(serializedResult);
						} catch (e:Dynamic) {
							trace('Error parsing server action result: '+e);
							js.Lib.rethrow();
							null;
						}
					return result;
				});
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

	static function checkReturnTypeIsPromise(ret:ComplexType, pos:Position):ComplexType {
		var type = ret.toType(pos).sure();
		switch Context.follow(type) {
			case TAbstract(_.toString() => "tink.core.Promise", [subType]):
				return subType.toComplex();
			case _:
				Context.error('Function should return a tink.core.Promise', pos);
				return null;
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
			var fn = member.getFunction().sure();
			var argNames = [for (a in fn.args) a.name];
			var resultComplexType = checkReturnTypeIsPromise(fn.ret, member.pos);
			actionCases.push({
				values: [macro $v{member.name}],
				expr: getExprForExecuteActionAndRenderJson(member.name, resultComplexType, argNames, member.pos),
				guard: macro isApiRequest
			});
			actionCases.push({
				values: [macro $v{member.name}],
				expr: getExprForExecuteActionAndSetRedirect(member.name, resultComplexType, argNames, member.pos),
				guard: macro !isApiRequest
			});
		}

		// Add cases for "get" method, which is also called if no action is specified.
		actionCases.push({
			values: [macro "get", macro null],
			expr: getExprForRenderPagePropsToJson(cb.target.pos),
			guard: macro isApiRequest
		});
		actionCases.push({
			values: [macro "get", macro null],
			expr: getExprForRenderPageToHtml(cb.target.pos),
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
				var isApiRequest = tink.CoreApi.OutcomeTools.isSuccess(req.header.byName('x-small-universe-api'));
				$switchExpr;
			}
		}).fields[0];
		cb.addMember(routingMethod);
		#end
	}

	static function getExprForExecuteActionAndRenderJson(action:String, expectedType:ComplexType, argNames:Array<String>, pos:Position) {
		var actionArgs = [for (argName in argNames) macro tink.Json.parse(params[$v{argName}])];
		return macro
			@:access(smalluniverse.SmallUniverse)
			@:pos(pos)
			smalluniverse.SmallUniverse.getArgsFromBody(req)
				.next(function (params):tink.core.Promise<$expectedType> {
					return this.$action($a{actionArgs});
				})
				.next(function (val) {
					return this.get().next(function (props) {
						return {
							props: props,
							returnValue: val
						}
					});
				})
				.handle(function (outcome) {
					var data = tink.CoreApi.OutcomeTools.sure(outcome);
					var serializedData:String = tink.Json.stringify(data);
					res.send(serializedData);
				});
	}

	static function getExprForExecuteActionAndSetRedirect(action:String, expectedType:ComplexType, argNames:Array<String>, pos:Position) {
		var actionArgs = [for (argName in argNames) macro tink.Json.parse(params[$v{argName}])];
		return macro
			@:access(smalluniverse.SmallUniverse)
			@:pos(pos)
			smalluniverse.SmallUniverse.getArgsFromBody(req)
				.next(function (params):tink.core.Promise<$expectedType> {
					return this.$action($a{actionArgs});
				})
				.handle(function (outcome) {
					tink.CoreApi.OutcomeTools.sure(outcome);
					var redirectUrl = req.url;
					res.redirect(redirectUrl);
				});
	}

	static function getExprForRenderPageToHtml(pos:Position) {
		return macro
			@:access(smalluniverse.SmallUniverse)
			@:pos(pos)
			this.renderToString().handle(function (outcome) {
				var appHtml = tink.CoreApi.OutcomeTools.sure(outcome);
				var pageName = Type.getClassName(Type.getClass(this));
				var propsJson = tink.Json.stringify(this.props);
				var html = smalluniverse.SmallUniverse.template;
				html = StringTools.replace(html, '{BODY}', appHtml);
				html = StringTools.replace(html, '{PAGE}', pageName);
				html = StringTools.replace(html, '{PROPS}', propsJson);
				res.send(html);
			});
	}

	static function getExprForRenderPagePropsToJson(pos:Position) {
		return macro
			@:access(smalluniverse.SmallUniverse)
			@:pos(pos)
			this.get().handle(function (outcome) {
				var props = tink.CoreApi.OutcomeTools.sure(outcome);
				var responseData = {
					props: props
				};
				var serializedProps = tink.Json.stringify(responseData);
				res.send(serializedProps);
			});
	}

	static function addDeserializePropsMethod(cb:ClassBuilder) {
		#if client
		var propsCt = getPropsTypeForClass(cb);
		var routingMethod = (macro class Tmp {
			@:access(smalluniverse.SmallUniverse)
			override public function deserializeProps(serializedProps:String):$propsCt {
				return try {
					tink.Json.parse(serializedProps);
				} catch (e:Dynamic) {
					trace('Error parsing properties: '+e);
					js.Lib.rethrow();
					null;
				}
			}
		}).fields[0];
		cb.addMember(routingMethod);
		#end
	}
}
