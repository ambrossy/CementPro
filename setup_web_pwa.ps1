# Configura el soporte para web en Flutter
flutter config --enable-web

# Compila el proyecto para la web
flutter build web --release

# Crea un directorio para la versión web
$webDir = "version_web"
if (-Not (Test-Path -Path $webDir)) {
    New-Item -Path $webDir -ItemType Directory
}

# Copia los archivos construidos a la carpeta de la versión web
Copy-Item -Path "build\web\*" -Destination $webDir -Recurse -Force

# Cambia al directorio web
Set-Location $webDir

# Crea un archivo manifest.json básico
@"
{
  "name": "Cement Pro",
  "short_name": "CementPro",
  "description": "Cement calculator application",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#000000",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "icons/Icon-512.png",
      "type": "image/png",
      "sizes": "512x512"
    }
  ]
}
"@ | Out-File -Encoding UTF8 -NoNewline -FilePath "manifest.json"

# Crea un service worker básico si no existe
if (-Not (Test-Path -Path "flutter_service_worker.js")) {
    @"
var CACHE_NAME = "pwa-cache";
var urlsToCache = [
  ".",
];

self.addEventListener("install", function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener("fetch", function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        return response || fetch(event.request);
      })
  );
});
"@ | Out-File -Encoding UTF8 -NoNewline -FilePath "flutter_service_worker.js"
}

# Modifica el index.html para incluir el manifest y registrar el service worker
$indexFile = "index.html"
$content = Get-Content -Path $indexFile

if ($content -notcontains '<link rel="manifest" href="manifest.json">') {
    $content = $content -replace '(?<=<head>.*)\n', "`n<link rel='manifest' href='manifest.json'>`n"
}

if ($content -notcontains 'navigator.serviceWorker.register("/flutter_service_worker.js");') {
    $scriptTag = @"
<script>
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('/flutter_service_worker.js');
  });
}
</script>
"@
    $content = $content -replace '(?=<\/body>)', "$scriptTag`n"
}

Set-Content -Path $indexFile -Value $content

Write-Host "La versión web ha sido preparada en el directorio 'version_web'. Ahora puedes desplegar este directorio en tu servidor web o en GitHub Pages."