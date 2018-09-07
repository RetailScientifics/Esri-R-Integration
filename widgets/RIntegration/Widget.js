/* global define, $ */

define([
	'dojo/_base/declare',
	'jimu/BaseWidget',
	'jimu/loaderplugins/jquery-loader!https://code.jquery.com/jquery-2.2.0.min.js'
], function (
	declare,
	BaseWidget,
	$
) {
	return declare([BaseWidget], {
		baseClass: 'r-integration',
		postCreate: function () {
			this.inherited(arguments);
			console.log('RIntegration::postCreate');
		},
		processResponse: function (data) {
			$('#r-output').html(JSON.stringify(data));
		},
		onOpen: function () {
			$('#r-form').submit(e => {
				// Convert form into an object to send to R
				let f = new FormData(document.getElementById('r-form'));
				let dataframe = {};
				f.forEach((value, key) => dataframe[key] = value);
				/*
				{
					"LocationName":"NewLocation",
					"LocationSquareFootage":"1000",
					"LocationType":"type1",
					"LocationGroup":"group-a"
				}
				*/

				$.ajax({
					type: 'POST',
					url: 'https://api2.retailscientifics.com/esri_demo/runmodel',
					data: {
						...dataframe,
						apikey: 'some_secret_key'
					},
					success: data => {
						this.processResponse(data);
					},
					error: (resp, status, err) => {
						alert(`There was an error calling the R model endpoint: ${err}, ${resp.responseJSON.error[0]}`);
					}
				});
				e.preventDefault();
			});
		}
	});
});
