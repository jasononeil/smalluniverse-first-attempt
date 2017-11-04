package smalluniverse;

import buddy.*;
using buddy.Should;

class TestUniversalPage extends BuddySuite {
	public function new() {
		describe("UniversalPage", {
			it("should automatically have a deserializeProps() method", {
			});

			it("should automatically have a serializeProps() method", {
			});

			it("should automatically have a deserializeAction() method", {
			});

			it("should automatically have a serializeAction() method", {
			});

			it("should call the backendApi when get() is called on the server", {
			});

			it("should make a GET request when get() is called on the client", {
			});

			it("should render HTML with current props when getPageHtml() is called", {
			});

			it("should render HTML with current props when getPageJson() is called", {
			});

			it("should make a POST request when trigger() is called", {
			});

			it("should trigger re-renders when startClientRendering is called", {
			});
		});

		describe("UniversalPage.callServerAction", {
			it("should call fetch()", {});
			it("should correctly handle an error returned as JSON", {});
			it("should correctly handle an error returned as text", {});
			it("should handle redirects", {});
			it("should print any traces to the console", {});
			it("should not error if __smallUniverse was not present in the JSON", {});
			it("correctly rerender the client if there was no redirect or error", {});
		});
	}
}