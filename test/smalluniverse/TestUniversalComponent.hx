package smalluniverse;

import buddy.*;
using buddy.Should;

class TestUniversalComponent extends BuddySuite {
	public function new() {
		describe("UniversalComponent", {
			it("should be able to be extended seamlessly on both client and server", {
			});

			it("should remove @:client methods on the server", {
			});

			it("should remove @:server methods on the client", {
			});
		});
	}
}