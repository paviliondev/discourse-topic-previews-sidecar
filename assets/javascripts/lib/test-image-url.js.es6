var testImageUrl = function(url) {
  return new Promise(function (resolve, reject) {
    let timeout = 5000;
    let timer, img = new Image();
    img.onerror = img.onabort = function () {
      clearTimeout(timer);
      resolve("error");
    };
    img.onload = function () {
      clearTimeout(timer);
      resolve("success");
    };
    timer = setTimeout(function () {
      resolve("error");
    }, timeout);
    img.src = url;
  });
}

export default testImageUrl
