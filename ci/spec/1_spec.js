var frisby = require('frisby');
var config = require('./config');

frisby.create('case-1-1')
  .get("http://{httptables}:8000/".format(config))
  .expectStatus(200)
  .expectJSON({
        status: 200,
  })
.toss();

frisby.create('case-1-2')
  .get("http://{httptables}:8000/test/user".format(config))
  .expectStatus(200)
  .expectJSON({
        status: 200,
  })
.toss();

frisby.create('case-1-3')
  .get("http://{httptables}:8000/test/device".format(config))
  .expectStatus(200)
  .expectJSON({
        status: 200,
  })
.toss();

frisby.create('case-1-4')
  .get("http://{httptables}:8000/test/origin".format(config))
  .expectStatus(200)
  .expectJSON({
        status: 200,
  })
.toss();

