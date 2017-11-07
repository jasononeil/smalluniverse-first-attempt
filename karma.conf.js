module.exports = function(config) {
	config.set({
		basePath: 'www',
		// No frameworks needed: just configure buddy to use the reporter.
		frameworks: [],
		browsers: ['Chrome'],
		files: ['js/test-client.bundle.js']
	});
};