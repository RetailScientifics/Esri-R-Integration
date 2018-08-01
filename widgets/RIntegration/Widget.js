define(
	['dojo/_base/declare', 'jimu/BaseWidget', 'https://cdn.plot.ly/plotly-latest.min.js', 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.2.1/Chart.min.js'],
	function (
		declare, BaseWidget,
		Plotly, Chart) {
		return declare([BaseWidget], {
			baseClass: 'r-integration',
			postCreate: function () {
				this.inherited(arguments);
				console.log('RIntegration::postCreate');
			}
		});
	});
