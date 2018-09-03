package smalluniverse;

#if server
import tink.http.Request;
import tink.io.Source;
import tink.http.Method;
import tink.http.Header;
import httpstatus.HttpStatusCode;
import tink.web.routing.Context;
#elseif client
import js.Browser.document;
#end
import buddy.*;
import smalluniverse.TestUniversalPage;
import tink.Json;

using buddy.Should;
using tink.CoreApi;
using tink.io.Source;

class TestSmallUniverse extends BuddySuite {
	public function new() {
		#if server
		describe("SmallUniverse.render()", {
			var page, backendApi;
			beforeEach(function() {
				page = new MyTestPage();
				backendApi = Std.instance(page.backendApi, MyTestPageBackend);
			});

			function getContext(method:Method, url:String, ?accept) {
				var headers = [];
				if (accept != null) {
					headers.push(new HeaderField(ACCEPT, accept));
				}
				var header = new IncomingRequestHeader(method, url, 'http', headers);
				var body = IncomingRequestBody.Plain(Source.EMPTY);
				return Context.ofRequest(new IncomingRequest('127.0.0.1', header, body));
			}

			function expectRedirect(context:SmallUniverseContext, redirectLocation:String) {
				var su = new SmallUniverse(page, context);
				return su.render().next(function(response) {
					response.header.statusCode.should.be(TemporaryRedirect);
					response.header.get(LOCATION)[0].should.be(redirectLocation);
					return Noise;
				});
			}

			function expectBody(context:SmallUniverseContext, expectedContentType:String, checkBody:String->Void) {
				var su = new SmallUniverse(page, context);
				return su.render().next(function(response) {
					var contentType = response.header.contentType().sure();
					contentType.should.be(expectedContentType);
					response.header.statusCode.should.be(OK);
					return response.body.all().map(function(chunk) {
						checkBody(chunk.toString());
						return Noise;
					});
				});
			}

			describe("when expecting text/html", {
				it("should render the page props as HTML by default", function(done) {
					var context = getContext(GET, '/', 'text/html');
					expectBody(context, 'text/html', function(body) {
						body.should.contain('<div id="small-universe-app"><p class="">Server: 30.</p></div>');
						body.should.contain
							('<script id="small-universe-props" type="text/json" data-page="smalluniverse.MyTestPage">{"age":30,"isAStudent":null,"name":"Server"}</script>');
						backendApi.getCalled.should.be(1);
						backendApi.processActionCalled.should.be(0);
					}).handle(done);
				});

				it("should run an action if an action= parameter was specified, and redirect to the same page (without the action) when done", function(done) {
					var context = getContext(POST, '/somepage?action="TransformToUpper"', 'text/html');
					expectRedirect(context, '/somepage').handle(function() {
						backendApi.getCalled.should.be(0);
						backendApi.processActionCalled.should.be(1);
						done();
					});
				});

				it("should redirect to a new page after an action if the action requested it", function(done) {
					var context = getContext(GET, '/?action="GoToHelpPage"', 'text/html');
					expectRedirect(context, 'http://help.example.com/').handle(function() {
						backendApi.getCalled.should.be(0);
						backendApi.processActionCalled.should.be(1);
						done();
					});
				});
			});

			describe("when expecting applicaton/json", {
				it("should render the props as JSON", function(done) {
					var context = getContext(GET, '/', 'application/json');
					expectBody(context, 'application/json', function(body) {
						body.should.be('{"age":30,"isAStudent":null,"name":"Server"}');
						backendApi.getCalled.should.be(1);
						backendApi.processActionCalled.should.be(0);
					}).handle(done);
				});

				it("should run an action if an action= parameter was specified, and return the new props", function(done) {
					var context = getContext(POST, '/?action="TransformToUpper"', 'application/json');
					expectBody(context, 'application/json', function(body) {
						body.should.be('{"age":30,"isAStudent":null,"name":"Server"}');
						backendApi.getCalled.should.be(1);
						backendApi.processActionCalled.should.be(1);
					}).handle(done);
				});

				it("should return the JSON for a redirect if the action requested it", function(done) {
					var context = getContext(GET, '/?action="GoToHelpPage"', 'application/json');
					expectBody(context, 'application/json', function(body) {
						body.should.be('{"__smallUniverse":{"messages":null,"redirect":"http://help.example.com/"}}');
						backendApi.getCalled.should.be(0);
						backendApi.processActionCalled.should.be(1);
					}).handle(done);
				});
			});

			describe("SmallUniverse.captureTraces()", {
				var oldTrace = haxe.Log.trace;

				beforeEach(function() {
					SmallUniverse.captureTraces();
				});

				afterEach(function() {
					haxe.Log.trace = oldTrace;
				});

				describe('on text/html requests', {
					it("Should not add any scripts if no logs are given", function(done) {
						var context = getContext(GET, '/', 'text/html');
						expectBody(context, 'text/html', function(body) {
							body.should.contain('Server: 30');
							body.should.not.contain('console.log');
						}).handle(done);
					});
					it("Should correctly log using inline scripts, but not on a redirect", function(done) {
						function logsInBuffer() {
							return @:privateAccess SmallUniverse.logs.length;
						}

						logsInBuffer().should.be(0);

						// The action will trace some things, but return a redirect.
						var doActionContext = getContext(POST, '/?action="TraceSomething"', 'text/html');

						expectRedirect(doActionContext, '/').next(function(_) {
							// Check that the logs are sitting in the buffer.
							logsInBuffer().should.be(2);
							return Noise;
						}).next(function(_) {
							var renderPageContext = getContext(GET, '/', 'text/html');
							return expectBody(renderPageContext, 'text/html', function(body) {
								body.should.contain('<p class="">Server: 30.</p>');
								body.should.contain('console.log');
								body.should.contain('smalluniverse.MyTestPageBackend.processAction()');
								body.should.contain('1');
								body.should.contain('"two"');
								body.should.contain('{"three":3}');
								body.should.contain('"Action was TraceSomething"');
							});
						}).next(function(_) {
							// Check that the logs are no longer in the buffer.
							logsInBuffer().should.be(0);
							return Noise;
						}).handle(done);
					});
				});

				describe('on application/json requests', {
					it("Should not add any JSON instruction in no logs are given on application/json", function(done) {
						var context = getContext(POST, '/?action="TransformToUpper"', 'application/json');
						expectBody(context, 'application/json', function(body) {
							body.should.be('{"age":30,"isAStudent":null,"name":"Server"}');
						}).handle(done);
					});
					it("Should correctly add a JSON instruction for application/json requests", function(done) {
						var context = getContext(POST, '/?action="TraceSomething"', 'application/json');
						expectBody(context, 'application/json', function(body) {
							var instructions:SUApiResponseInstructions = Json.parse(body);
							var data:MyTestPageProps = Json.parse(body);
							data.age.should.be(30);
							data.isAStudent.should.be(null);
							data.name.should.be('Server');
							instructions.__smallUniverse.messages.length.should.be(2);
							instructions.__smallUniverse.messages[0][0].should.contain("smalluniverse.MyTestPageBackend.processAction()");
							instructions.__smallUniverse.messages[0][2].should.be("1");
							instructions.__smallUniverse.messages[0][3].should.be('"two"');
							instructions.__smallUniverse.messages[0][4].should.be('{"three":3}');
							instructions.__smallUniverse.messages[1][0].should.contain("smalluniverse.MyTestPageBackend.processAction()");
							instructions.__smallUniverse.messages[1][2].should.be('"Action was TraceSomething"');
						}).handle(done);
					});
					it("Should correctly add a JSON instruction even on redirects", function(done) {
						var context = getContext(POST, '/?action="TraceSomethingAndRedirect"', 'application/json');
						expectBody(context, 'application/json', function(body) {
							var instructions:SUApiResponseInstructions = Json.parse(body);
							instructions.__smallUniverse.messages.length.should.be(1);
							instructions.__smallUniverse.messages[0][0].should.contain("smalluniverse.MyTestPageBackend.processAction()");
							instructions.__smallUniverse.messages[0][2].should.be('"Action was TraceSomethingAndRedirect"');
							instructions.__smallUniverse.redirect.should.be('http://zombo.com/');
						}).handle(done);
					});
				});
			});
		});
		#end

		#if client
		describe("SmallUniverse.hydrate()", {
			it("Should correctly render when startClientRendering is called", function(done) {
				var container = document.createDivElement();
				container.id = 'small-universe-app';
				document.body.appendChild(container);

				var props = document.createDivElement();
				props.id = 'small-universe-props';
				props.innerText = '{
					"name": "ClientRender",
					"age": 30
				}';
				document.body.appendChild(props);

				var result = SmallUniverse.hydrate(MyTestPage);
				result.handle(function(outcome) {
					outcome.sure();
					var container = document.getElementById('small-universe-app');
					container.innerHTML.should.be('<p class="">ClientRender: 30.</p>');
					done();
				});
			});
		});
		#end
	}
}
