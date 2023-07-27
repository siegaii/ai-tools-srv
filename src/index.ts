import fs from 'fs'
import https from 'https'
import express from 'express'
import type { RequestProps } from './types'
import type { ChatMessage } from './chatgpt'
import { chatConfig, chatReplyProcess } from './chatgpt'
import { auth } from './middleware/auth'
import { limiter } from './middleware/limiter'

const app = express()
const router = express.Router()

const httpsOptions = {
  key: fs.readFileSync('/etc/nginx/certs/privkey1.pem'),
  cert: fs.readFileSync('/etc/nginx/certs/fullchain1.pem'),
}

app.use(express.static('public'))
app.use(express.json())

app.all('*', (_, res, next) => {
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Headers', 'authorization, Content-Type')
  res.header('Access-Control-Allow-Methods', '*')
  next()
})

router.post('/chat-process', [auth, limiter], async (req, res) => {
  res.setHeader('Content-type', 'application/octet-stream')

  try {
    const { prompt, options = {}, systemMessage, temperature, top_p } = req.body as RequestProps
    let firstChunk = true
    await chatReplyProcess({
      message: prompt,
      lastContext: options,
      process: (chat: ChatMessage) => {
        res.write(firstChunk ? JSON.stringify(chat) : `\n${JSON.stringify(chat)}`)
        firstChunk = false
      },
      systemMessage,
      temperature,
      top_p,
    })
  }
  catch (error) {
    res.write(JSON.stringify(error))
  }
  finally {
    res.end()
  }
})

router.post('/config', auth, async (req, res) => {
  try {
    const response = await chatConfig()
    res.send(response)
  }
  catch (error) {
    res.send(error)
  }
})

app.use('', router)
app.use('/api', router)
app.set('trust proxy', 1)

if (process.env.NODE_ENV === 'production') {
  // Start HTTPS server
  https.createServer(httpsOptions, app).listen(7002, () => {
    globalThis.console.log('HTTPS Server running on port 7002')
  })
}
else {
  app.listen(7001, () => globalThis.console.log('Server is running on port 7001'))
}
