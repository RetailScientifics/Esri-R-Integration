/* global define, $ */

define([
	'jimu/loaderplugins/jquery-loader!https://code.jquery.com/jquery-2.2.0.min.js',
	'dojo/_base/declare',
	'jimu/BaseWidget',
	'esri/toolbars/draw',
	'esri/graphic',
	'esri/symbols/SimpleMarkerSymbol',
	'esri/Color'
], function (
	$,
	declare,
	BaseWidget,
	Draw,
	Graphic,
	SimpleMarkerSymbol,
	Color
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
			let pointSelected = false;
			let formLatitude;
			let formLongitude;

			const markerSymbol = new SimpleMarkerSymbol().setPath(
				'M16,4.938c-7.732,0-14,4.701-14,10.5c0,1.981,0.741,3.833,2.016,5.414L2,25.272l5.613-1.44c2.339,1.316,5.237,2.106,8.387,2.106c7.732,0,14-4.701,14-10.5S23.732,4.938,16,4.938zM16.868,21.375h-1.969v-1.889h1.969V21.375zM16.772,18.094h-1.777l-0.176-8.083h2.113L16.772,18.094z'
			).setColor(
				new Color('#00FFFF')
			);

			tb.on('draw-end', evt => {
				tb.deactivate();
				map.enableMapNavigation();
				graphicsLayer.add(new Graphic(evt.geometry, markerSymbol));
				formLatitude = evt.geometry.getLatitude();
				formLongitude = evt.geometry.getLongitude();
				$('input[name=locationLatitudeLongitude').val(`${formLatitude.toFixed(5)}, ${formLongitude.toFixed(5)}`);
				pointSelected = true;
			});

			$('#drawPoint').click(() => {
				map.graphics.clear();
				map.disableMapNavigation();
				tb.activate('point');
			});

			$('#r-form').submit(e => {
				if (!pointSelected) {
					alert('Please select a point on the map first.');
					e.preventDefault();
					return;
				}
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
						inputDataframe: JSON.stringify(dataframe),
						latitude: formLatitude,
						longitude: formLongitude,
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

				e.preventDefault();
			}); // End form submit
		} // End onOpen

	}); // End declare
}); // End define
