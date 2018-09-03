package smalluniverse;

import buddy.*;

using buddy.Should;

class MyComponent extends UniversalComponent<{name:String}, {time:Float}> {
	public function new(props) {
		super(props);
		this.state = {
			time: 1
		};
	}

	@:client
	public function shouldOnlyBeOnClient() {
		return js.Browser.window;
	}

	@:server
	public function shouldOnlyBeOnServer() {
		return Sys.programPath();
	}
}

class TestUniversalComponent extends BuddySuite {
	public function new() {
		describe("UniversalComponent", {
			var myComponent;
			beforeEach(function() {
				myComponent = new MyComponent({
					name: 'Jason'
				});
			});

			it("should be able to be extended seamlessly on both client and server", {
				myComponent.props.name.should.be('Jason');
				myComponent.state.time.should.be(1);
			});

			it("should remove @:client methods on the server", {
				var result = myComponent.shouldOnlyBeOnClient();
				#if server
				result.should.be(null);
				#else
				result.should.not.be(null);
				#end
			});

			it("should remove @:server methods on the client", {
				var result = myComponent.shouldOnlyBeOnServer();
				#if client
				result.should.be(null);
				#else
				result.should.not.be(null);
				#end
			});
		});
	}
}
