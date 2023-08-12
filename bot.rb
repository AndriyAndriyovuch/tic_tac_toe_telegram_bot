require "telegram/bot"
require_relative "credentials"

token = TELEGRAM_TOKEN.freeze

Telegram::Bot::Client.run(token) do |bot|
  game = {
    'A1': "⬜️" ,  'A2': "⬜️" ,  'A3': "⬜️" , 'next_1': "\n",
    'B1': "⬜️" ,  'B2': "⬜️" ,  'B3': "⬜️" , 'next_2': "\n",
    'C1': "⬜️" ,  'C2': "⬜️" ,  'C3': "⬜️"
  }
  user_value = ""
  bot_value = ""

  bot.listen do |message|
    my_message = message.text.include?("⬜️") ? "⬜️" : message.text


    case my_message

    when "/start"
      game = {
        'A1': "⬜️" ,  'A2': "⬜️" ,  'A3': "⬜️" , 'next_1': "\n",
        'B1': "⬜️" ,  'B2': "⬜️" ,  'B3': "⬜️" , 'next_2': "\n",
        'C1': "⬜️" ,  'C2': "⬜️" ,  'C3': "⬜️"
      }

      bot.api.send_message(chat_id: message.chat.id, text: "Hi #{message.from.first_name}, let's play the game")

      bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''))

      question = 'Choose your fighter?'
      answers =
          Telegram::Bot::Types::ReplyKeyboardMarkup.new(
            keyboard: [
              [{ text: "I'll start: ✖️" }, { text: "You first: ⚫️" }],
            ],
            one_time_keyboard: true
          )
      bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)

    when "I'll start: ✖️"
      user_value = "✖️"
      bot_value = "⚫️"


      answers =
      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: [
          [{ text: "⬜️ (A1)" }, { text: "⬜️ (A2)" }, { text: "⬜️ (A3)" }],
          [{ text: "⬜️ (B1)" }, { text: "⬜️ (B2)" }, { text: "⬜️ (B3)" }],
          [{ text: "⬜️ (C1)" }, { text: "⬜️ (C2)" }, { text: "⬜️ (C3)" }]
        ],
        one_time_keyboard: true
      )

      bot.api.send_message(chat_id: message.chat.id, text: "Select one:")

      bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''),reply_markup: answers)

    when "You first: ⚫️"
      user_value = "⚫️"
      bot_value = "✖️"

      # ========== Bot selects ===============
      available = []

      game.map do |key,value|
        if value == "⬜️"
          available << key
        end
      end

      game[available[rand(available.length)]] = bot_value
      # ======================================


      # ============ New keyboard ============
      new_keyboard = []
      line_hash = []

      game.each do |key, value|
        if key[0] != "n"
          line_hash << {text: "#{value} (#{key})"}
        else
          new_keyboard << line_hash
          line_hash = []
        end
      end

      new_keyboard << line_hash
      # ======================================

      if game[:A1] == game[:A2] && game[:A1] == game[:A3] && game[:A3] != "⬜️" ||
        game[:B1] == game[:B2] && game[:B1] == game[:B3] && game[:B3] != "⬜️"  || # HORIZONTAL
        game[:C1] == game[:C2] && game[:C1] == game[:C3] && game[:C3] != "⬜️"  || # HORIZONTAL
        game[:A1] == game[:B1] && game[:A1] == game[:C1] && game[:C1] != "⬜️"  || # VERTICAL
        game[:A2] == game[:B2] && game[:A2] == game[:C2] && game[:C2] != "⬜️"  || # VERTICAL
        game[:A3] == game[:B3] && game[:A3] == game[:C3] && game[:C3] != "⬜️"  || # VERTICAL
        game[:A1] == game[:B2] && game[:A1] == game[:C3] && game[:C3] != "⬜️"  || # DIAGONAL
        game[:A3] == game[:B2] && game[:A3] == game[:C1] && game[:C1] != "⬜️"  # DIAGONAL
        bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''))
        bot.api.send_message(chat_id: message.chat.id, text: "Game Over")
      else
        answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: new_keyboard, one_time_keyboard: true)

        bot.api.send_message(chat_id: message.chat.id, text: "Select one:")

        bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''),reply_markup: answers)
      end

    when "⬜️"
      my_value = message.text[-3..-2].to_sym
      game[my_value] = user_value

      if game[:A1] == game[:A2] && game[:A1] == game[:A3] && game[:A3] != "⬜️" ||
        game[:B1] == game[:B2] && game[:B1] == game[:B3] && game[:B3] != "⬜️"  || # HORIZONTAL
        game[:C1] == game[:C2] && game[:C1] == game[:C3] && game[:C3] != "⬜️"  || # HORIZONTAL
        game[:A1] == game[:B1] && game[:A1] == game[:C1] && game[:C1] != "⬜️"  || # VERTICAL
        game[:A2] == game[:B2] && game[:A2] == game[:C2] && game[:C2] != "⬜️"  || # VERTICAL
        game[:A3] == game[:B3] && game[:A3] == game[:C3] && game[:C3] != "⬜️"  || # VERTICAL
        game[:A1] == game[:B2] && game[:A1] == game[:C3] && game[:C3] != "⬜️"  || # DIAGONAL
        game[:A3] == game[:B2] && game[:A3] == game[:C1] && game[:C1] != "⬜️"  # DIAGONAL

        bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''))
        bot.api.send_message(chat_id: message.chat.id, text: "Game Over")
      else
        # ============ New keyboard ============
        new_keyboard = []
        line_hash = []

        game.each do |key, value|
          if key[0] != "n"
            line_hash << {text: "#{value} (#{key})"}
          else
            new_keyboard << line_hash
            line_hash = []
          end
        end

        new_keyboard << line_hash
        # ======================================

        # ========== Bot selects ===============
        available = []

        game.map do |key,value|
          if value == "⬜️"
            available << key
          end
        end

        game[available[rand(available.length)]] = bot_value
        if game[:A1] == game[:A2] && game[:A1] == game[:A3] && game[:A3] != "⬜️" ||
          game[:B1] == game[:B2] && game[:B1] == game[:B3] && game[:B3] != "⬜️"  || # HORIZONTAL
          game[:C1] == game[:C2] && game[:C1] == game[:C3] && game[:C3] != "⬜️"  || # HORIZONTAL
          game[:A1] == game[:B1] && game[:A1] == game[:C1] && game[:C1] != "⬜️"  || # VERTICAL
          game[:A2] == game[:B2] && game[:A2] == game[:C2] && game[:C2] != "⬜️"  || # VERTICAL
          game[:A3] == game[:B3] && game[:A3] == game[:C3] && game[:C3] != "⬜️"  || # VERTICAL
          game[:A1] == game[:B2] && game[:A1] == game[:C3] && game[:C3] != "⬜️"  || # DIAGONAL
          game[:A3] == game[:B2] && game[:A3] == game[:C1] && game[:C1] != "⬜️"  # DIAGONAL

          bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''))
          bot.api.send_message(chat_id: message.chat.id, text: "Game Over")
        else
      # ======================================
          answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: new_keyboard, one_time_keyboard: true)

          bot.api.send_message(chat_id: message.chat.id, text: "Select one:" )
          bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''),reply_markup: answers)
        end
      end
    else
      p game
      bot.api.send_message(chat_id: message.chat.id, text: "Your wrong" )

      bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''),reply_markup: answers)
    end

  end
end
