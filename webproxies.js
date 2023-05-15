var Proxies = {}

function openproxy(name) {
    if (Proxies[name]) {
        if (Proxies[name].Status == "Slow") {
            alert("This website may be running slow. Keep in mind this website was last checked on " + Proxies[name].Updated)
        } else if (Proxies[name].Status == "Error") {
            return alert("This website is down or something went wrong.")
        }
        window.open(Proxies[name].Url)
    }
}

fetch('https://proxy.bitx96.com/webproxies.json')
  .then(response => response.json())
  .then(data => {
    // Setting response data
    Proxies = data
  })
  .catch(error => {
    // Handling error requests
    console.error('HTTP Error: ', error);
  });
