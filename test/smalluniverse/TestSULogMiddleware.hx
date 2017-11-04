package smalluniverse;

import buddy.*;
using buddy.Should;

class TestSULogMiddleware extends BuddySuite {
	public function new() {
		describe("SULogMiddleware", {
			it("should not do anything if there are no traces", {
			});

			it("should add console.log scripts if the content type is HTML", {
			});

			it("should add a `__smallUniverse` key if the content type is JSON", {
			});
		});
	}
}