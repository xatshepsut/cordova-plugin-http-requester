var HttpRequester = function() {};
var PLUGIN_NAME = 'HttpRequester';

HttpRequester.prototype.post = function(params, success, fail) {
  if (!params || !params.url || !params.body) {
    fail();
    return;
  }
  return cordova.exec(success, fail, PLUGIN_NAME, 'post', [params]);
};

HttpRequester.prototype.put = function(params, success, fail) {
  if (!params || !params.url || !params.body) {
    fail();
    return;
  }
  return cordova.exec(success, fail, PLUGIN_NAME, 'put', [params]);
};

window.HttpRequester = new HttpRequester();
