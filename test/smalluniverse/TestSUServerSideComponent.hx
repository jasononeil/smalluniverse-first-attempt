package smalluniverse;

import buddy.*;
import smalluniverse.SUServerSideComponent;
import smalluniverse.SUMacro.jsx;
using buddy.Should;

class TestComponent361 extends UniversalComponent<{}, {}> {
	override public function render() {
		return jsx('<div>Class</div>');
	}
}

class TestSUServerSideComponent extends BuddySuite {
	public function new() {
		#if server
		describe("SUServerSideComponent.SUServerSideNode", {
			it("should render null correctly", {
			});

			it("should render text correctly", {
			});

			it("should render html correctly", {
			});

			it("should render a component correctly", {
			});

			it("should render a node list correctly", {
			});

			it("should render a combination correctly", {
			});

			it("should automatically be cast to from a string", {
			});

			it("should automatically be cast to from an array", {
			});

			it("should automatically be cast to from an enum", {
			});

			it("should automatically cast to an enum", {
			});

			it("should create a node from a component", {
			});

			it("should create a node from html", {
			});
		});

		describe("SUServerSideComponent.SUServerSideRenderFn", {
			it("should correctly render()", {
			});

			it("should automatically cast from a functional component", {
				var renderFn: SUServerSideRenderFn<{}> = function (props: {}) {
					return jsx('<div>Function!</div>');
				};
				var result = renderFn.render({});
				result.renderToString().should.be('<div>Function!</div>');
			});

			it("should automatically cast from a class component", {
				var renderFn: SUServerSideRenderFn<{}> = TestComponent361;
				var result = renderFn.render({});
				result.renderToString().should.be('<div>Class</div>');
			});
		});
		#end
	}
}