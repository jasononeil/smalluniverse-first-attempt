package smalluniverse;

import buddy.*;
#if server
import smalluniverse.SUServerSideComponent;
#end
import smalluniverse.SUMacro.jsx;
using buddy.Should;

class TestSUServerSideComponent extends BuddySuite {
	public function new() {
		#if server
		describe("SUServerSideComponent.SUServerSideRenderFn", {
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

class TestComponent361 extends UniversalComponent<{}, {}> {
	override public function render() {
		return jsx('<div>Class</div>');
	}
}