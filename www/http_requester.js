var HttpRequester = function() {};

HttpRequester.prototype.post = function(params, success, fail) {
  if (!params || !params.url || !params.body) {
    fail();
    return;
  }
  return cordova.exec(success, fail, "HttpRequester", "post", [params]);
};

window.HttpRequester = new HttpRequester();