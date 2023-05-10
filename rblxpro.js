var JSON_DATA = {}

function getrblxPro() {
    return JSON_DATA.MainProfile
}

// HTTP Request 'fetch'

fetch('https://proxy.bitx96.com/data.json')
  .then(response => response.json())
  .then(data => {
    // Setting response data
    JSON_DATA = data
  })
  .catch(error => {
    // Handling error requests
    console.error('HTTP Error: ', error);
  });
