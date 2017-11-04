package smalluniverse;

import buddy.*;
using buddy.Should;

class MyPage extends UniversalPage<{}, {}, {type: String}> {
	public function new() {
		super();
		this.state = {
			type: 'class-default'
		}
	}
}

class TestLazyUniversalPage extends BuddySuite {
	public function new() {
		describe("LazyUniversalPage", {
			it("should accept a plain UniversalPage class", {
				var lazy: LazyUniversalPage = MyPage;
				lazy().state.type.should.be('class-default');
			});

			it("should accept an already instantiated UniversalPage", {
				var myPage = new MyPage();
				myPage.setState({type: 'instance'});
				var lazy: LazyUniversalPage = myPage;
				lazy().state.type.should.be('instance');
			});

			it("should accept a function that produces a UniversalPage", {
				var lazy: LazyUniversalPage = function () {
					var myPage = new MyPage();
					myPage.setState({type: 'factory'});
					return myPage;
				};
				lazy().state.type.should.be('factory');
			});
		});
	}
}