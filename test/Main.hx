import buddy.*;
using buddy.Should;

class Main implements Buddy<[Tests]> {
	public function new() {
	}
}

class Tests extends BuddySuite {
	public function new() {
		describe("Using Buddy", {
			var experience = "?";
			var mood = "?";

			beforeEach({
				experience = "great";
			});

			it("should be a great testing experience", {
				experience.should.be("great");
			});

			it("should make the tester really happy", {
				mood.should.be("happy");
			});

			afterEach({
				mood = "happy";
			});
		});
	}
}