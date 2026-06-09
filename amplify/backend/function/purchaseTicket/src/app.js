/*
Copyright 2017 - 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at
    http://aws.amazon.com/apache2.0/
or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/


/* Amplify Params - DO NOT EDIT
	ENV
	REGION
	STORAGE_PROFILEDATA_BUCKETNAME
	API_N3ON_USERTABLE_NAME
	API_N3ON_USERTABLE_ARN
	API_N3ON_GRAPHQLAPIIDOUTPUT
	API_N3ON_VENUETABLE_NAME
	API_N3ON_VENUETABLE_ARN
	API_N3ON_DAILYUSERCOUNTTABLE_NAME
	API_N3ON_DAILYUSERCOUNTTABLE_ARN
	API_N3ON_REVIEWTABLE_NAME
	API_N3ON_REVIEWTABLE_ARN
	API_N3ON_CHATROOMTABLE_NAME
	API_N3ON_CHATROOMTABLE_ARN
	API_N3ON_MESSAGETABLE_NAME
	API_N3ON_MESSAGETABLE_ARN
	API_N3ON_POSTTABLE_NAME
	API_N3ON_POSTTABLE_ARN
	API_N3ON_EVENTTABLE_NAME
	API_N3ON_EVENTTABLE_ARN
	API_N3ON_TICKETTABLE_NAME
	API_N3ON_TICKETTABLE_ARN
	API_N3ON_ENDORSEMENTREQUESTTABLE_NAME
	API_N3ON_ENDORSEMENTREQUESTTABLE_ARN
	API_N3ON_ATTENDANCETABLE_NAME
	API_N3ON_ATTENDANCETABLE_ARN
	API_N3ON_EVENTDJLINKTABLE_NAME
	API_N3ON_EVENTDJLINKTABLE_ARN
	API_N3ON_USERFOLLOWSTABLE_NAME
	API_N3ON_USERFOLLOWSTABLE_ARN
	API_N3ON_TRANSACTIONTABLE_NAME
	API_N3ON_TRANSACTIONTABLE_ARN
	API_N3ON_VENUECOMPLIANCESUBMISSIONTABLE_NAME
	API_N3ON_VENUECOMPLIANCESUBMISSIONTABLE_ARN
	TABLE_PREFIX
Amplify Params - DO NOT EDIT */

const express = require('express')
const bodyParser = require('body-parser')
const awsServerlessExpressMiddleware = require('aws-serverless-express/middleware')

// declare a new express app
const app = express()
app.use(bodyParser.json())
app.use(awsServerlessExpressMiddleware.eventContext())

// Enable CORS for all methods
app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "*")
  next()
});


/**********************
 * Example get method *
 **********************/

app.get('/tickets/purchase', function(req, res) {
  // Add your code here
  res.json({success: 'get call succeed!', url: req.url});
});

app.get('/tickets/purchase/*', function(req, res) {
  // Add your code here
  res.json({success: 'get call succeed!', url: req.url});
});

/****************************
* Example post method *
****************************/

app.post('/tickets/purchase', function(req, res) {
  // Add your code here
  res.json({success: 'post call succeed!', url: req.url, body: req.body})
});

app.post('/tickets/purchase/*', function(req, res) {
  // Add your code here
  res.json({success: 'post call succeed!', url: req.url, body: req.body})
});

/****************************
* Example put method *
****************************/

app.put('/tickets/purchase', function(req, res) {
  // Add your code here
  res.json({success: 'put call succeed!', url: req.url, body: req.body})
});

app.put('/tickets/purchase/*', function(req, res) {
  // Add your code here
  res.json({success: 'put call succeed!', url: req.url, body: req.body})
});

/****************************
* Example delete method *
****************************/

app.delete('/tickets/purchase', function(req, res) {
  // Add your code here
  res.json({success: 'delete call succeed!', url: req.url});
});

app.delete('/tickets/purchase/*', function(req, res) {
  // Add your code here
  res.json({success: 'delete call succeed!', url: req.url});
});

app.listen(3000, function() {
    console.log("App started")
});

// Export the app object. When executing the application local this does nothing. However,
// to port it to AWS Lambda we will create a wrapper around that will load the app from
// this file
module.exports = app
