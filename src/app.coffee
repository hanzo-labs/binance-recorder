# import binance from 'node-binance-api'
binance     = require 'node-binance-api'
MongoClient = require 'mongodb'

binance.options
  APIKEY:    'KdVTR61jfhhOj26FXTLDfg4CcvpVlkGV4Zj4COgh1xwdHY3Sug21o96g0MkeR8YN'
  APISECRET: '5jT3Klj4TXlNunhcKOKOjyMjBLacxMKkJCdbpcw5KdcUtT0JE5MBWOvOtnZGq3N4'

# initialize a member of the dict as a struct or update a specific field in the
# struct
initOrMerge = (dict, key, field, value) ->
  if !dict[key]?
    dict[key] = {}

  dict[key][field] = value

  return dict

# baseUrl for manual request
baseUrl = 'https://api.binance.com/api/'

# Period list
periods = [
  '1m'
]
  # '3m'
  # '5m'
  # '15m'
  # '30m'
  # '2h'
  # '4h'
  # '6h'
  # '8h'
  # '12h'
  # '3d'
  # '1h'
  # '1d'
  # '1w'
  # '1M'

# Mongodb client
client = null

# Main loop
go = ->
  # Phase 1 promises
  p1s = []

  # Time
  millis = (new Date()).getTime()

  # Dictionary
  dict = {
    # time: millis
  }

  p1s.push new Promise((resolve, reject)->
    # Instantaneous Price of Stock
    binance.prices (prices) ->
      for code, price in prices
        initOrMerge dict, code, 'price', parseFloat(price)

      # console.log 'prices()', dict
      resolve dict
  ).catch (err)->
    console.log 'prices() error', err

  p1s.push new Promise((resolve, reject)->
    # Instantenous Bid/Ask Summary
    binance.bookTickers (tickers) ->
      for code, ticker of tickers
        for k, v of ticker
          ticker[k] = parseFloat v
        initOrMerge dict, code, 'ticker', ticker

      # console.log 'bookTickers()', dict
      resolve dict
  ).catch (err)->
    console.log 'bookTickers() error', err

  Promise.all(p1s).then ->
    # console.log 'Phase 1', dict

    # Phase 2 promises
    p2s = []

    for code, obj of dict
      p2s.push new Promise((resolve, reject) ->
        # Instantenous Bid/Ask List
        binance.depth code, (depth, symbol) ->
          dict[symbol].depth = depth

          # console.log 'depth()', dict
          resolve dict
      ).catch (err)->
        console.log 'depth() error', err

      offset = 0

      for period in periods
        p2s.push new Promise((resolve, reject) ->
          do (period, code) ->
            # stagger the calls so we don't spam it to death
            setTimeout ->
              # Historic Candle Sticks
              # console.log offset, code, period
              binance.publicRequest baseUrl+'v1/klines', {symbol: code, interval: period, limit: 1}, (ticks) ->
                lastTick = ticks[ticks.length - 1]
                [time, open, high, low, close, volume, closeTime, assetVolume, trades, buyBaseVolume, buyAssetVolume, ignored] = lastTick

                dict[code]['candlestick' +period] =
                  time:           time
                  open:           parseFloat open
                  high:           parseFloat high
                  low:            parseFloat low
                  close:          parseFloat close
                  volume:         parseFloat volume
                  closeTime:      closeTime
                  assetVolume:    parseFloat assetVolume
                  trades:         trades
                  buyBaseVolume:  parseFloat buyBaseVolume
                  buyAssetVolume: parseFloat buyAssetVolume
                  ignored:        parseFloat ignored

                # console.log 'candlesticks()', dict[code]
                resolve dict
            , offset * 200
            # increment offset
            offset++
          ).catch (err)->
            console.log 'candlesticks() error', err

    Promise.all(p2s).then ->
      # Get collection
      col = client.db('binance').collection('records')

      datas = []
      for code, data of dict
        data.code = code
        datas.push data

      # console.log 'datas', datas

      col.insert datas, {w: 1}, (err, result) ->
        if err?
          console.log 'insert() error', err
        else
          console.log 'insert() success'

  setTimeout go, 60000

# Mongodb
MongoClient.connect 'mongodb://binance-recorder-mongo:27017', (err, cl)->
  if err?
    console.log 'connect() error', err

  client = cl
  go()

