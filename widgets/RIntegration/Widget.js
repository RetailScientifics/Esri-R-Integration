/* global define, $ */

define([
	'dojo/_base/declare',
	'jimu/BaseWidget',
	'esri/toolbars/draw',
	'esri/graphic',
	'esri/symbols/SimpleMarkerSymbol'
], function (
	declare,
	BaseWidget,
	Draw,
	Graphic,
	SimpleMarkerSymbol
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
			const map = this.map;
			const graphicsLayer = this.map.graphics;
			const tb = new Draw(map);
			let formLatitude;
			let formLongitude;
			const rform = document.getElementById('rform');

			tb.on('draw-end', evt => {
				tb.deactivate();
				map.enableMapNavigation();
				graphicsLayer.add(
					new Graphic(evt.geometry, new SimpleMarkerSymbol())
				);
				formLatitude = evt.geometry.getLatitude();
				formLongitude = evt.geometry.getLongitude();
				$('input[name=locationLatitudeLongitude').val(
					`${formLatitude.toFixed(5)}, ${formLongitude.toFixed(5)}`
				);
				$('#formSubmitButton').prop('disabled', false);
			});

			$('#drawPoint').click(() => {
				map.graphics.clear();
				map.disableMapNavigation();
				tb.activate('point');
			});


			$('#formSubmitButton').click(evt => {
				const isFormValid = rform.checkValidity();
				rform.classList.add('was-validated');
				if (!isFormValid) {
					evt.preventDefault();
					evt.stopPropagation();
					return;
				}

				// Convert form into an object to send to R
				let f = new FormData(rform);
				let dataframe = {
					Latitude: formLatitude,
					Longitude: formLongitude
				};
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
						inputDataframe: JSON.stringify(dataframe),
						apikey: 'some_secret_key'
					},
					success: data => {
						this.processResponse(data);
					},
					error: (resp, status, err) => {
						if (resp.status === 0) {
							alert('The R model is currently down. Please try again later.');
						} else {
							alert(`There was an error calling the R model endpoint: ${err}, ${resp.responseJSON.error[0] || 'Unknown error'}`);
						}
					}
				}); // End Ajax call

				evt.preventDefault();
			}); // End form submit
		} // End onOpen

	}); // End declare
}); // End define
