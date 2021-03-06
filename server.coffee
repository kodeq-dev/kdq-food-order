express = require "express"
Spreadsheet = require "edit-google-spreadsheet"
_ = require "lodash"

module.exports = (opts) ->

  app = express()

  app.use "/", express.static __dirname + "/app"

  app.listen opts.port

  app.get "/food", (req, res) ->
    token = req.query.token
    username = req.query.user_name
    command = req.query.text

    if token isnt "wHyoVmVpoXMGWOjJXTV0A1FC"
      return res.send "ERROR"

    if command is "menu"
      loadSheet "menu", (err, ss) ->
        return if err

        ss.receive (err, rows, info) ->
          return if err
          content = ""
          _.each rows, (row) ->
            content += row["1"] + ": " + row["2"] + "\n"

          return res.send content

    if command is ""
      loadSheet "orders", (err, ss) ->
        return if err
        ss.receive (err, rows, info) ->
          return if err
          content = ""
          _.each rows, (row) ->
            return if row["5"] is 1
            content += row["4"] + ": " + row["3"] + "\n"
          return res.send content

    if command.indexOf("order") > -1
      loadSheet "orders", (err, ss) ->
        return if err
        stt = command.split(" ")[1]

        loadSheet "menu", (err, ssMenu) ->
          return if err
          ssMenu.receive (err, rowsMenu, info) ->
            result = undefined
            _.each rowsMenu, (row) ->
              console.log row["1"]
              result = row if row["1"] is Number(stt)
            return res.send "ERROR" if !result

            ss.receive (err, rows, info) ->
              len = _.size(rows) + 1
              order = {}
              order[len] = { 1: len - 1, 2: stt, 3: result["2"], 4: username, 5: 0 }
              ss.add order
              ss.send (err) ->
                return if err
                res.send "Bạn đã đặt món thành công"

    if command is "cancel"
      loadSheet "orders", (err, ss) ->
        return if err
        ss.receive (err, rows, info) ->
          newOrder = {}
          _.each rows, (row, index) ->
            if row["4"] is username
              row[5] = 1
              newOrder[index] = row

          ss.add newOrder
          ss.send (err) ->
            return if err
            res.send "Bạn đã hủy món thành công"

    # console.log req.query
    # res.send "NOT SUPPORT"

  loadSheet = (sheetName, loadSuccess) ->
    Spreadsheet.load
      debug: true
      useCellTextValues: false
      spreadsheetName: "kdq-food-orders"
      worksheetName: sheetName
      oauth:
        email: "174490504370-s80tnmbic7hl2cthccdke4e188j0790i@developer.gserviceaccount.com"
        keyFile: "google-oauth.pem"
    , loadSuccess
