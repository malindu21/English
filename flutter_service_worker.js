'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "d5ac8b0107a719957f38746d45cec437",
"version.json": "ddd2c3e15948fc18f7c7de4ea6b3f32d",
"index.html": "b22b112e3160db785f00221f9535e141",
"/": "b22b112e3160db785f00221f9535e141",
"IMG_3687.JPG": "c8edd66acaa7fa4aa61354ac4f61784e",
"styles.css": "282ae4f47d3cde16abeb1cdbb418eebe",
"CNAME": "766ea81efb7c319da3dd38b5abcd3fd5",
"main.dart.js": "8c57e1710260149ddbca69f05f4f65a5",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "f439fe7c5a442a7ae75ba17edd457100",
".git/config": "90a73f7e2772768362f62dc4e1ddfd4a",
".git/objects/59/f7f21a866e4c9095f1df29bbb6f35964d96c64": "1a9d9abb3ec916a9be9585c8b27c8f76",
".git/objects/92/55721bdf0ce93e7c29970bcdff2972903cc21b": "c56376484bf7754d475dd8c7c59cfd88",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/3c/0b3a6f84fc03852074927a143662fb65e986bc": "dbbc71a184ef8eac56c1c53bb66afa6c",
".git/objects/67/be01a1508520a35a98709e6dda7312d2b225c5": "1c3c14d7220098d0f8009b0b305a69d6",
".git/objects/0b/8394d435f9ed8e3860e6938f747bdc9bbe1ed6": "e721bff3218aba23ff14e4c800d477b3",
".git/objects/0e/cb6a2d4e1d33995636e0a0ff5b38b0aa1c45b0": "5fe10ea50efede252311180effb00d1a",
".git/objects/ad/e52bcace2eadb5ef54e880f39b1ee8e4187cac": "4673186fc0e6c67132c674439556f86b",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/e5/d0aa4b895b906bb6171714f2ecfe506389fbe7": "ac3c5d7db71268fc8aea8b3387028f07",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ee/0e319c5539dbb17d9167d3b7194b5e1a963b42": "b8904b0dc33f998f23b01fa587059178",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fe/6a18f492275612f01c7724772b25e4e93e955b": "a048529e17957c495cdb8044d38d08d0",
".git/objects/fe/71288d956c7a4e1b20c29dc14443618eae3279": "dbe26ae38f26438413bc7fa504dfb226",
".git/objects/c8/08fb85f7e1f0bf2055866aed144791a1409207": "92cdd8b3553e66b1f3185e40eb77684e",
".git/objects/4e/0a3f1255cceeeb40129a88ac354b551c93c0d0": "229b1ed652095b36aeff5ebf8d153eb2",
".git/objects/11/f5b49f5fd1f63453d76b01515aaaa608681f81": "c2d91facf8a30eb2b4ddd897752fed94",
".git/objects/7c/0e177c3518951a7918fc9e8ba1f17670a5702b": "0b7c78e57bb01b2606aa3048237e7f9a",
".git/objects/73/c63bcf89a317ff882ba74ecb132b01c374a66f": "6ae390f0843274091d1e2838d9399c51",
".git/objects/1a/d7683b343914430a62157ebf451b9b2aa95cac": "94fdc36a022769ae6a8c6c98e87b3452",
".git/objects/8a/c64d08ab3c42ea99d9518f333b7e8bd8e57714": "0beacb2a0ed2afb210539adc6ef408e2",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/7e/848aee4a291d02c9906a731eaa083c32db4c17": "34d0013de04f266e14248e74f628e09c",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/9f/55ca9001151426a0aa89a9fbe7d5e3773b6477": "5420fb43b1535a2f7c9240c887952ec1",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6b/96f52ab347de642fed410049daf7e43ac3cd39": "fbb96ffac25eb416ac9588525fa3ce22",
".git/objects/53/743a109078c8300fd7b412126cec943e00dcea": "c0acbf7dc8a414de0b1615d589141ee3",
".git/objects/53/2d0f2e08de35b98be9c0891cb5246299cc7540": "0e8c59a0cc9ce0f428712ab99fe09bbe",
".git/objects/53/18a6956a86af56edbf5d2c8fdd654bcc943e88": "a686c83ba0910f09872b90fd86a98a8f",
".git/objects/53/3d2508cc1abb665366c7c8368963561d8c24e0": "4592c949830452e9c2bb87f305940304",
".git/objects/d3/4ab8f0127e6883ef1acfb83d9e274082ad2ae8": "79a6100fe018d27312d782c904d9f08e",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "761c08dfe3c67fe7f31a98f6e2be3c9c",
".git/objects/b6/f4a42e5a3ebd314fc361e2147ec5d7904b8f08": "b5424f55785fdc8405d0ee7a5532bb4b",
".git/objects/aa/7fe108f906603d8da7fc6515a996b97ad54bde": "cb23a53f2e770df94bb49f333c12aeaa",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/a6/672e2605e83c20f2551267e544c70dff8d8cca": "baccebcf8a02ff5bbbbc064b19bd0481",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "4227e5e94459652d40710ef438055fe5",
".git/objects/a1/76245d602068ea5ab74ba0cfa4ecc01b41a634": "5f46fb2dadee8b6a2727962364ccf74f",
".git/objects/f9/c0ddb5542f148d62d5965603ee38a82e00594e": "9748f0f862d92c24603b641b99c1505b",
".git/objects/e8/028e03090f786586f7e07b4acf428081af26e8": "44c26e41f87a8ced883ed718d9bc1a44",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/cb/19bffe505a0aae94eed15f934adadc836ae7a1": "3487fedda683909647512be801982c0c",
".git/objects/e0/7ac7b837115a3d31ed52874a73bd277791e6bf": "74ebcb23eb10724ed101c9ff99cfa39f",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/77/1cf83fe1b6c1e066e3466bfbfa233890d83904": "8c4581e5cc148dd799211f74243e6f50",
".git/objects/77/a274eba9e9663eefce7db77a9ef77f4775ad54": "af8ffe023586765f250068b6cbc11d55",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/70/a3b3cfcb1bbcce1fa85a38a9332b6e6e371706": "43de2665fcf2b07e67725a1224a61a86",
".git/objects/78/e8f944aafba40061b9772cca1935b13c67dbba": "30fd09d1d5b2679f60e0a8b5d16af759",
".git/objects/13/ceb48a3b8acb80a85138f917c6d7e4690ffe22": "851d631bf2e2951061eddfa4fbe21051",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "d55b95d24f877df8e40a9255ce2a4c37",
".git/logs/refs/heads/gh-pages": "945cc760337472d1162301ad09fa3a1f",
".git/logs/refs/remotes/origin/gh-pages": "6fbe9026430971e85f66d4662345d8ba",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/gh-pages": "7eef10b915a55804a540801ff7680b45",
".git/refs/remotes/origin/gh-pages": "7eef10b915a55804a540801ff7680b45",
".git/index": "37e203e12a173d80a42a217e9ef0c836",
".git/COMMIT_EDITMSG": "daf53f5082d2ca04bae22b020936b443",
"assets/AssetManifest.json": "f4c72f7e1ee04301c845088585302eb2",
"assets/NOTICES": "a4e1e58108be935f5b543ebefa491d4a",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "5d2ab5f632f3e6dcdaf4ac20adb736d7",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "6fc23728df93ccf1129436ebf905c3e9",
"assets/fonts/MaterialIcons-Regular.otf": "6121478d4883e127f3f8223604157aca",
"assets/assets/images/building2.png": "25b0fcc759847bd55a9492ec02eb4021",
"assets/assets/images/slider_1.jpg": "a1fade07f3baac3787259c95a96f4f5f",
"assets/assets/images/building.png": "6fa02f7e88679e0c1a0aea77f8a7744e",
"assets/assets/images/logo.png": "85037eee16eff7bd75ae7893f1d95452",
"favicon-32x32.png": "e758f8c8d921da7c39ff2ba212dc8467",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
