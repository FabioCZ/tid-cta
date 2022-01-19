const { exec } = require("child_process");

const token = ""
const deviceId = ""

function pushPixlet() {
	exec("pixlet render tid-cta.star", (err, out, stderr) => {
		exec("pixlet push --api-token " + token + " --installation-id TIDCTA " + deviceId + " tid-cta.webp", (err1, out1, stderr1) => {

		})
	})
}

pushPixlet()
setInterval(pushPixlet, 1000 * 30)
