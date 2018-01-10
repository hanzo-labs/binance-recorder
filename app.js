'use strict';

// src/app.coffee
// import binance from 'node-binance-api'
var baseUrl;
var binance;
var go;
var initOrMerge;
var periods;

binance = require('node-binance-api');

binance.options({
  APIKEY: 'KdVTR61jfhhOj26FXTLDfg4CcvpVlkGV4Zj4COgh1xwdHY3Sug21o96g0MkeR8YN',
  APISECRET: '5jT3Klj4TXlNunhcKOKOjyMjBLacxMKkJCdbpcw5KdcUtT0JE5MBWOvOtnZGq3N4'
});

// initialize a member of the dict as a struct or update a specific field in the
// struct
initOrMerge = function(dict, key, field, value) {
  if (dict[key] == null) {
    dict[key] = {};
  }
  dict[key][field] = value;
  return dict;
};

// baseUrl for manual request
baseUrl = 'https://api.binance.com/api/';

// Period list
periods = ['1m', '3m', '5m', '15m', '30m', '1h', '1d', '3d', '1w', '1M'];

// '2h'
// '4h'
// '6h'
// '8h'
// '12h'

// Main loop
go = function() {
  var dict, millis, p1s;
  // Phase 1 promises
  p1s = [];
  // Time
  millis = (new Date).getTime();
  // Dictionary
  dict = {};
  // time: millis
  p1s.push(new Promise(function(resolve, reject) {
    // Instantaneous Price of Stock
    return binance.prices(function(prices) {
      var code, price;
      for (code in prices) {
        price = prices[code];
        initOrMerge(dict, code, 'price', parseFloat(price));
      }
      // console.log 'prices()', dict
      return resolve(dict);
    });
  }).catch(function(err) {
    return console.log('prices() error', err);
  }));
  p1s.push(new Promise(function(resolve, reject) {
    // Instantenous Bid/Ask Summary
    return binance.bookTickers(function(tickers) {
      var code, k, ticker, v;
      for (code in tickers) {
        ticker = tickers[code];
        for (k in ticker) {
          v = ticker[k];
          ticker[k] = parseFloat(v);
        }
        initOrMerge(dict, code, 'ticker', ticker);
      }
      // console.log 'bookTickers()', dict
      return resolve(dict);
    });
  }).catch(function(err) {
    return console.log('bookTickers() error', err);
  }));
  return Promise.all(p1s).then(function() {
    var code, obj, offset, p2s, period, results;
    console.log('Phase 1', dict);
    // Phase 2 promises
    p2s = [];
    results = [];
    for (code in dict) {
      obj = dict[code];
      p2s.push(new Promise(function(resolve, reject) {
        // Instantenous Bid/Ask List
        return binance.depth(code, function(depth, symbol) {
          dict[symbol].depth = depth;
          // console.log 'depth()', dict
          return resolve(dict);
        });
      }).catch(function(err) {
        return console.log('depth() error', err);
      }));
      offset = 0;
      results.push((function() {
        var i, len, results1;
        results1 = [];
        // Seems like overkill, we
        for (i = 0, len = periods.length; i < len; i++) {
          period = periods[i];
          results1.push(p2s.push(new Promise(function(resolve, reject) {
            // stagget the calls so we don't spam it to death
            setTimeout(function() {
              // Historic Candle Sticks
              console.log(offset, code, period);
              return binance.publicRequest(baseUrl + 'v1/klines', {
                symbol: code,
                interval: period,
                limit: 1
              }, function(ticks) {
                var assetVolume, buyAssetVolume, buyBaseVolume, close, closeTime, high, ignored, lastTick, low, open, time, trades, volume;
                lastTick = ticks[ticks.length - 1];
                [time, open, high, low, close, volume, closeTime, assetVolume, trades, buyBaseVolume, buyAssetVolume, ignored] = lastTick;
                dict[code]['candlestick' + period] = {
                  time: time,
                  open: parseFloat(open),
                  high: parseFloat(high),
                  low: parseFloat(low),
                  close: parseFloat(close),
                  volume: parseFloat(volume),
                  closeTime: closeTime,
                  assetVolume: parseFloat(assetVolume),
                  trades: trades,
                  buyBaseVolume: parseFloat(buyBaseVolume),
                  buyAssetVolume: parseFloat(buyAssetVolume),
                  ignored: parseFloat(ignored)
                };
                console.log('candlesticks()', dict[code]);
                return resolve(dict);
              });
            }, offset * 40);
            // increment offset
            return offset++;
          }).catch(function(err) {
            return console.log('candlesticks() error', err);
          })));
        }
        return results1;
      })());
    }
    return results;
  });
};

// setTimeout go, 10000
go();
//# sourceMappingURL=app.js.map
