import buddy.*;
import smalluniverse.*;

/**
The entry point for our unit tests.

Buddy will automatically build the appropriate main() function.
**/
class Main implements Buddy<[
	TestBackendApi,
	TestLazyUniversalPage,
	TestSmallUniverse,
	TestSUMacro,
	TestSUServerSideComponent,
	TestUniversalComponent,
	TestUniversalNode,
	TestUniversalPage,
	TestUniversalPageHead,
]> {}
