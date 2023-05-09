var web = "https://bitproxy.github.io/data.json"
var JSON_DATA = {"MainProfile":94111, PublicAnnouncement:"N/A", LastUpdated:"Mar 2nd 2021 AT 12:32:46 PDT"}

function getmainprofile() {
    return JSON.parse(PROFILE_MAIN).MainProfile
}

function openrblxprofile(profile) {
    if (isNaN(profile)) {
        profile = getmainprofile()
    }
    window.open("https://roblox.com/users/" + toString(profile) + "/profile")
}

function setjsonData(any) {
    JSON_DATA = any
}

// HTTP Request 'fetch'

fetch(web)
    .then(response => response.json())
    .then(data => setjsonData(data))