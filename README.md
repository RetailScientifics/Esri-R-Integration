# Integrating Modeling and Forecasting with R

## Creating a Blank Web AppBuilder App
*Note: you can skip this step by simply downloading this repository*
- If you don't have it already, install node.js
- Download the latest version of [Web AppBuilder for ArcGIS](https://developers.arcgis.com/web-appbuilder/)
- Unzip and open a terminal in the resulting directory
- `cd server`
- `npm install`
- `npm run start`
- Open a browser to the https page that is served up - in this case, `localhost:3346`. It should look something like this: ![orgurl](images/2018/07/orgurl.png)
- Enter the URL for your ArcGIS Online Portal (in our case, `http://scientifics.maps.arcgis.com/`)
- It will now ask for an App ID - click "Help" and follow the instructions laid out there. For the URL, use `http://localhost:3346/webappbuilder`. When it is created, go to "Settings -> App Registration" to register an ID, using the same URL as the redirect.
	- Alternatively: Back on your localhost page, create a default 2D web map and save it. Navigate back to the main page, find the map you just made, and save it.
	- Unzip it to a directory.

## Run the Frontend App
- Option 1: Simply copy all of these files to a server somewhere and host them online to access.
- Option 2: Start a local https server:
	- Run `openssl req -new -x509 -keyout server.pem -out server.pem -days 365 -nodes` to generate a self-signed SSL certificate
	- Run `python2 server.py` (note: this does require python 2) and navigate to `https://localhost:4443/`
- You should now be able to see a basic webmap: ![basic](images/2018/07/basic.png)

## Add a Custom Widget
- Install the widget generator with `npm install -g yo && npm install -g generator-esri-appbuilder-js`
- Make a new directory for your project and run `yo esri-appbuilder-js` to generate some initial files and set some settings.
- Run `yo esri-appbuilder-js:widget` to create your actual widget in the `./widgets` directory.
- Copy your newly minted widget back into your frontend app's widget directory.
