var JSON_DATA = {"MainProfile":94111, PublicAnnouncement:"N/A", LastUpdated:"Mar 2nd 2021 AT 12:32:46 PDT"}

function getmainprofile() {
    return JSON.parse(JSON_DATA).MainProfile
}

function openrblxprofile(profile) {
    if (isNaN(profile)) {
        profile = getmainprofile()
    }
    window.open("https://roblox.com/users/" + toString(profile) + "/profile")
}

// HTTP Request 'fetch'

fetch('https://bitproxy.github.io/data.json')
  .then(response => response.json())
  .then(data => {
    // Setting response data
    JSON_DATA = data
  })
  .catch(error => {
    // Handling error requests
    console.error('HTTP Error: ', error);
  });
