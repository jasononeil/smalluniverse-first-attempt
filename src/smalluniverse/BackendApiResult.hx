package smalluniverse;

/**
	The result of a `BackendApi.processAction()` call.

	After an action has been processed, it either is finished and the page should be updated, or it is finished and the user should be redirected to a new page.
**/
enum BackendApiResult {
	Done;
	Redirect(url:String);
}
