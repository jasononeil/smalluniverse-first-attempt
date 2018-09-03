package smalluniverse;

import buddy.*;
import js.html.*;
import js.Browser.*;
import smalluniverse.SUMacro.jsx;

using buddy.Should;
using tink.CoreApi;

class TestUniversalPage extends BuddySuite {
	public function new() {
		var container;
		function setupContainer() {
			#if client
			container = document.createDivElement();
			container.id = 'small-universe-app';
			document.body.appendChild(container);
			#end
		}

		function teardownContainer() {
			#if client
			if (container.parentNode == document.body) {
				document.body.removeChild(container);
			}
			#end
		}

		describe("UniversalPage", {
			var page;
			beforeEach({
				page = new MyTestPage();
				setupContainer();
			});
			afterEach({
				teardownContainer();
			});

			it("should compile seamlessly on both client and server", {
				@:privateAccess page.props = {
					name: 'Jason',
					age: 30
				};
				var node = page.render();
				node.renderToString().should.be('<p class="">Jason: 30.</p>');
			});

			describe("the automatically generated deserializeProps() method", {
				it("should correctly load valid data", {
					var aaron = page.deserializeProps('{ "name": "Aaron", "age": 27, "isAStudent": true }');
					aaron.name.should.be('Aaron');
					aaron.age.should.be(27);
					aaron.isAStudent.should.be(true);
				});

				it("should correctly load valid data that is missing optional fields", {
					var jason = page.deserializeProps('{    "name":"Jason"  ,   "age":30}');
					jason.name.should.be('Jason');
					jason.age.should.be(30);
					jason.isAStudent.should.be(null);
				});

				it("Should throw an error if the JSON is bad", {
					(function() {
						page.deserializeProps('{bad json}');
					}).should.throwType(tink.core.Error);
				});

				it("should throw an error if the JSON is missing a field", {
					(function() {
						page.deserializeProps('{"name":"Aaron"}');
					}).should.throwType(tink.core.Error);
				});

				it("should silently ignore extra fields", {
					(function() {
						page.deserializeProps('{"name":"Aaron","age":27,"color":"green"}');
					}).should.not.throwType(tink.core.Error);
				});
			});

			describe("the automatically generated serializeProps() method", {
				function checkJson(json:String, expectedName:String, expectedAge:Int, expectedStudent:Bool, ?pos:haxe.PosInfos) {
					var parsedObj:{name:String, age:Int, isAStudent:Bool} = haxe.Json.parse(json);
					parsedObj.name.should.be(expectedName, pos);
					parsedObj.age.should.be(expectedAge, pos);
					parsedObj.isAStudent.should.be(expectedStudent, pos);
				}
				it("should correctly serialize", {
					var json = page.serializeProps({name: "Aaron", age: 27, isAStudent: true});
					checkJson(json, "Aaron", 27, true);
				});
				it("should ignore optional fields that are not set", {
					var json = page.serializeProps({name: "Jason", age: 30});
					checkJson(json, "Jason", 30, null);
				});
				it("should ignore extra fields that are not part of the type", {
					var data:MyTestPageProps = cast {name: "Jason", age: 30, password: "secret"};
					var json = page.serializeProps(data);
					checkJson(json, "Jason", 30, null);
				});
			});

			describe("the automatically generated deserializeAction() method", {
				it("should correctly load valid data", {
					var action1 = page.deserializeAction('"TransformToUpper"');
					action1.should.equal(TransformToUpper);

					var action2 = page.deserializeAction('{"SetName":{"name":"Jason","age":30}}');
					action2.should.equal(SetName("Jason", 30));
				});

				it("should correctly load valid data with optional fields", {
					var action3 = page.deserializeAction('{"GetOlder":{"howMuch":null}}');
					action3.should.equal(GetOlder());

					var action4 = page.deserializeAction('{"GetOlder":{"howMuch":3}}');
					action4.should.equal(GetOlder(3));
				});

				it("Should throw an error if the JSON is bad", {
					(function() {
						page.deserializeAction('{bad json}');
					}).should.throwType(tink.core.Error);
				});

				it("should throw an error if the JSON is missing a field", {
					(function() {
						page.deserializeAction('{"SetName":{"name":"Jason"}}');
					}).should.throwType(tink.core.Error);
				});

				it("should silently ignore extra fields", {
					var action5 = page.deserializeAction('{"SetName":{"name":"Jason","age":30,"other":"thing"},"other":"thing"}');
					action5.should.equal(SetName("Jason", 30));
				});
			});

			describe("the automatically generated serializeAction() method", {
				it("should correctly serialize", {
					var action1 = TransformToUpper;
					var action2 = GetOlder();
					var action3 = GetOlder(3);
					var action4 = SetName("Jason", 30);

					page.serializeAction(action1).should.be('"TransformToUpper"');
					page.serializeAction(action2).should.be('{"GetOlder":{"howMuch":null}}');
					page.serializeAction(action3).should.be('{"GetOlder":{"howMuch":3}}');
					page.serializeAction(action4).should.be('{"SetName":{"name":"Jason","age":30}}');
				});
			});

			it("should, when get() is called, use the BackendApi on the server or a GET request on the client", function(done) {
				page.mockResponseBody = '{
					"name": "Client",
					"age": 30
				}';
				page.mockResponseStatus = 200;
				var propsPromise = page.get();
				propsPromise.handle(function(outcome) {
					switch outcome {
						case Success(props):
							props.name.should.be(#if server 'Server' #elseif client 'Client' #end);
							props.age.should.be(30);
							#if server
							var backendApi = Std.instance(page.backendApi, MyTestPageBackend);
							backendApi.getCalled.should.be(1);
							page.interceptedRequest.should.be(null);
							#elseif client
							page.interceptedRequest.should.not.be(null);
							page.interceptedRequest.method.should.be('GET');
							#end
						case Failure(err):
							fail('Expected page.get() call to succeed, but it did not: ' + err.toString());
					}
					done();
				});
			});

			#if client
			it("should make a POST request when trigger() is called", function(done) {
				page.mockResponseBody = '{
					"name": "AfterAction",
					"age": 30
				}';
				page.mockResponseStatus = 200;
				var propsPromise = page.trigger(TransformToUpper);
				propsPromise.handle(function(outcome) {
					switch outcome {
						case Success(Noise):
							page.interceptedRequest.method.should.be('POST');
						case Failure(err):
							fail('Expected page.trigger() call to succeed, but it did not: ' + err.toString());
					}
					done();
				});
			});
			#end

			#if server
			it("should render HTML with current props when getPageHtml() is called", function(done) {
				page.getPageHtml().handle(function(outcome) {
					switch outcome {
						case Success(str):
							str.should.be('<p class="">Server: 30.</p>');
						case Failure(err):
							fail('Expected page.getPageHtml() to succeed, but it did not: ' + err.toString);
					}
					done();
				});
			});
			#end
		});

		#if client
		describe("UniversalPage.callServerAction", {
			var page;
			beforeEach(function() {
				page = new MyTestPage();
				setupContainer();
			});
			afterEach(function() {
				teardownContainer();
			});

			describe("getRequestForAction", {
				it("should request an application/json response", {
					var req1 = @:privateAccess page.getRequestForAction(None);
					req1.headers.get('Accept').should.be('application/json');

					var req2 = @:privateAccess page.getRequestForAction(Some(TransformToUpper));
					req2.headers.get('Accept').should.be('application/json');
				});

				it("should be a GET request if there is no action", {
					var req1 = @:privateAccess page.getRequestForAction(None);
					req1.method.should.be('GET');
				});

				it("should be a POST request if there is an action", {
					var req2 = @:privateAccess page.getRequestForAction(Some(TransformToUpper));
					req2.method.should.be('POST');
				});

				it("should not have an action= parameter if there is an action", function(done) {
					var req1 = @:privateAccess page.getRequestForAction(None);
					req1.text().then(function(text) {
						(text : String).should.be('');
						done();
					});
				});

				it("should have an action= parameter if there is an action", function(done) {
					var req2 = @:privateAccess page.getRequestForAction(Some(TransformToUpper));
					req2.json().then(function(body) {
						(body.action : String).should.be('"TransformToUpper"');
						done();
					});
				});
			});

			describe("getResponseText", {
				it("should return the text if the status is 200 OK", function(done) {
					var res1 = new Response('{"name": "Jason"}', {
						status: 200,
					});
					var prom1 = @:privateAccess page.getResponseText(res1);
					prom1.handle(function(outcome) {
						outcome.should.equal(Success('{"name": "Jason"}'));
						done();
					});
				});
				it("should provide the error text if a JSON error could not be decoded", function(done) {
					var res1 = new Response('You are not allowed', {
						status: 401,
					});
					var prom1 = @:privateAccess page.getResponseText(res1);
					prom1.handle(function(outcome) {
						switch outcome {
							case Failure(err):
								err.code.should.be(401);
								err.message.should.be('You are not allowed');
							case Success(_):
								fail('getResponseText() returned a Success, was expecting a Failure');
						}
						done();
					});
				});
			});

			describe("handleResponseSpecialInstructions", {
				it("should not cause issues if no __smallUniverse property is present", {
					var option = @:privateAccess page.handleResponseSpecialInstructions('{"name": "Jason"}');
					option.should.be(Success(Some('{"name": "Jason"}')));
				});

				it("should handle redirects", {
					var option = @:privateAccess page.handleResponseSpecialInstructions
						('{
						"name": "Jason",
						"__smallUniverse": {
							"redirect": "http://gotonewpage.com"
						}
					}');
					option.should.be(Success(None));
					page.redirect.should.be('http://gotonewpage.com');
				});

				it("should print any traces to the browser console", {
					var json = '{
						"name": "Jason",
						"__smallUniverse": {
							"messages": [["1","\\"a\\""],["2","\\"b\\""]]
						}
					}';
					haxe.Json.parse(json);
					var option = @:privateAccess page.handleResponseSpecialInstructions(json);
					option.should.be(Success(Some(json)));
					page.logs.length.should.be(2);
					page.logs[0].should.be('1, a');
					page.logs[1].should.be('2, b');
				});
			});

			describe("rerenderUsingUpdatedJson", {
				it("should not re-render if we are redirecting", {
					@:privateAccess page.rerenderUsingUpdatedJson(None);
					page.renders.length.should.be(0);
				});
				it("should trigger a client render otherwise", {
					@:privateAccess page.rerenderUsingUpdatedJson(Some('{
						"name": "Jason",
						"age": 30
					}'));
					page.renders.length.should.be(1);
					page.renders[0].name.should.be('Jason');
					page.renders[0].age.should.be(30);
					page.renders[0].isAStudent.should.be(null);
				});
			});

			// TODO: mock "fetchRequest" so we can test this as a whole
			it("should all work together nicely", function(done) {
				page
				.mockResponseBody = '{
					"name": "ANNA",
					"age": 27,
					"isAStudent": true,
					"__smallUniverse": {
						"messages": [
							["\\"Log 1\\"", "1"],
							["\\"Log 2\\"", "2"]
						]
					}
				}';
				page.mockResponseStatus = 200;
				var promise = @:privateAccess page.trigger(TransformToUpper);
				promise.handle(function(outcome) switch outcome {
					case Success(Noise):
						trace('Made it to resolve');
						page.interceptedRequest.json().then(function(body) {
							// The request should be a POST (action).
							page.interceptedRequest.method.should.be('POST');
								(body.action : String).should.be('"TransformToUpper"');

							// The props should be correctly deserialised and set.
							page.props.name.should.be('ANNA');
							page.props.age.should.be(27);
							page.props.isAStudent.should.be(true);

							// The console logs should have happened.
							page.logs.length.should.be(2);
							page.logs[0].should.be('Log 1, 1');
							page.logs[1].should.be('Log 2, 2');

							// The render should be live.
							var p = document.querySelector('.is-student');
							p.should.not.be(null);
							p.innerText.should.be('ANNA: 27.');
							done();
						});
					case Failure(err):
						fail('Expected request to succeed but it failed:' + err.toString());
						done();
				});
			});
		});
		#end
	}
}

enum MyTestPageActions {
	TransformToUpper;
	GetOlder(?howMuch:Int);
	SetName(name:String, age:Int);
	GoToHelpPage;
	TraceSomething;
	TraceSomethingAndRedirect;
}

typedef MyTestPageProps = {
	name:String,
	age:Int,
	?isAStudent:Bool,
}

typedef MyTestPageState = {}

class MyTestPageBackend implements BackendApi<MyTestPageActions, MyTestPageProps> {
	public var getCalled = 0;
	public var processActionCalled = 0;

	public function new() {}

	public function get(context:SmallUniverseContext):Promise<MyTestPageProps> {
		getCalled++;
		// Have some could never possibly run on the client.
		Sys.cpuTime();
		return {
			name: 'Server',
			age: 30
		};
	}

	public function processAction(context:SmallUniverseContext, action:MyTestPageActions):Promise<BackendApiResult> {
		processActionCalled++;
		if (action.match(GoToHelpPage)) {}
		switch action {
			case GoToHelpPage:
				return BackendApiResult.Redirect('http://help.example.com/');
			case TraceSomething:
				trace(1, "two", {"three": 3});
				trace('Action was TraceSomething');
			case TraceSomethingAndRedirect:
				trace('Action was TraceSomethingAndRedirect');
				return BackendApiResult.Redirect('http://zombo.com/');
			default:
		}
		// Have some could never possibly run on the client.
		Sys.cpuTime();
		return BackendApiResult.Done;
	}
}

class MyTestPage extends UniversalPage<MyTestPageActions, MyTestPageProps, MyTestPageState> {
	public var redirect:String = null;
	public var logs:Array<String> = [];
	public var renders:Array<MyTestPageProps> = [];
	public var interceptedRequest:Request;
	public var mockResponseBody:String;
	public var mockResponseStatus:Int;

	public function new() {
		super(new MyTestPageBackend());
	}

	override public function render():UniversalNode {
		var className = props.isAStudent ? "is-student" : "";
		return jsx('<p className=${className}>${props.name}: ${props.age}.</p>');
	}

	#if client
	override function fetchRequest(req:Request):Promise<Response> {
		this.interceptedRequest = req;
		trace('faking a request');
		return Future.sync(new Response(mockResponseBody, {status: mockResponseStatus}));
	}

	override function redirectWindow(newUrl:String) {
		this.redirect = newUrl;
	}

	override function logToConsole(values:Array<Dynamic>) {
		this.logs.push(values.join(', '));
	}

	override function doClientRender(?cb) {
		renders.push(this.props);
		super.doClientRender(cb);
	}
	#end
}
