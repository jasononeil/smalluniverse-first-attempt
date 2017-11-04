package smalluniverse;

import buddy.*;
using buddy.Should;

class MyPage extends UniversalPage<{}, {}, {type: String}> {
	public var type: String;
	public function new() {
		super();
		this.type = 'class-default';
	}
}

class TestLazyUniversalPage extends BuddySuite {
	public function new() {
		describe("LazyUniversalPage", {
			it("should accept a plain UniversalPage class", {
				var lazy: LazyUniversalPage = MyPage;
				Reflect.field(lazy(), 'type').should.be('class-default');
			});

			it("should accept an already instantiated UniversalPage", {
				var myPage = new MyPage();
				myPage.type = 'instance';
				var lazy: LazyUniversalPage = myPage;
				Reflect.field(lazy(), 'type').should.be('instance');
			});

			it("should accept a function that produces a UniversalPage", {
				var lazy: LazyUniversalPage = function () {
					var myPage = new MyPage();
					myPage.type = 'factory';
					return myPage;
				};
				Reflect.field(lazy(), 'type').should.be('factory');
			});
		});
	}
}