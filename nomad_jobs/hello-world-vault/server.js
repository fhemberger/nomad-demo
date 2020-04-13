const http = require('http')

const server = http.createServer((req, res) => {
  if (req.method !== 'GET') {
    return
  }

  const body = `
  These secrets from Vault were put in environment variables by Nomad:

  VAULT_SECRET_URL=${process.env.VAULT_SECRET_URL}
  VAULT_SECRET_USERNAME=${process.env.VAULT_SECRET_USERNAME}
  VAULT_SECRET_PASSWORD=${process.env.VAULT_SECRET_PASSWORD}
  `
  res.writeHead(200, { 'Content-Type': 'text/plain' })
  res.end(body)
})

const port = 8080
const host = '0.0.0.0'
server.listen(port, host)
console.log(`Listening at http://${host}:${port}`)

process.on('SIGINT', () => process.exit())
process.on('SIGHUP', () => console.log('Notification from Nomad: Vault secrets have been updated.'))
