require_relative "credentials"
require "telegram/bot"

class TelegramBot
  TOKEN = TELEGRAM_TOKEN.freeze

  def run
    game = new_game

    bot.listen do |message|
      new_message(message, game)
    end
  end

  def bot
    Telegram::Bot::Client.run(TOKEN) { |bot| return bot }
  end

  def new_message(message, game)
    my_message = message.text.include?("⬜️") ? "⬜️" : message.text

    case my_message

    when "/start"
      game = new_game

      send_message(message, "Hi #{message.from.first_name}, let's play the game")
      send_message(message, game[:fields].values.join(''))

      select_fighter(message)
    when "I'll start: ✖️"
      game[:user_value] = "✖️"
      game[:bot_value] = "⚫️"

      send_message(message, "Select one:")
      bot.api.send_message(chat_id: message.chat.id, text: game[:fields].values.join(''),reply_markup: collect_keyboard(game))

    when "You first: ⚫️"
      game[:user_value] = "⚫️"
      game[:bot_value] = "✖️"

      bot_choose(game)

      if game_over?(game)
        send_message(message, game[:fields].values.join(''))
        send_message(message, "Game Over")
      else
        send_message(message, "Select one:")
        bot.api.send_message(chat_id: message.chat.id, text: game[:fields].values.join(''),reply_markup: collect_keyboard(game))
      end

    when "⬜️"
      my_value = message.text[-3..-2].to_sym
      game[:user_value]
      game[:fields][my_value] = game[:user_value]

      if game_over?(game)
        bot.api.send_message(chat_id: message.chat.id, text: game[:fields].values.join(''))
        send_message(message, "Game Over")
      else
        bot_choose(game)

        if game_over?(game)
          bot.api.send_message(chat_id: message.chat.id, text: game[:fields].values.join(''))
          send_message(message, "Game Over")
        else
          send_message(message, "Select one:")
          bot.api.send_message(chat_id: message.chat.id, text: game[:fields].values.join(''),reply_markup: collect_keyboard(game))
        end
      end
    end
  end

  def new_game
    {
      fields: {
        'A1': "⬜️" ,  'A2': "⬜️" ,  'A3': "⬜️" , 'next_1': "\n",
        'B1': "⬜️" ,  'B2': "⬜️" ,  'B3': "⬜️" , 'next_2': "\n",
        'C1': "⬜️" ,  'C2': "⬜️" ,  'C3': "⬜️"
      },
      user_value: "",
      bot_value: ""
    }
  end

  def select_fighter(message)
    answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [
            [{ text: "I'll start: ✖️" }, { text: "You first: ⚫️" }],
          ],
          one_time_keyboard: true
        )

    bot.api.send_message(chat_id: message.chat.id, text: 'Choose your fighter?', reply_markup: answers)
  end

  def collect_keyboard(game)
    new_keyboard = []
    line_hash = []

    game[:fields].each do |key, value|
      if key[0] != "n"
        line_hash << {text: "#{value} (#{key})"}
      else
        new_keyboard << line_hash
        line_hash = []
      end
    end

    new_keyboard << line_hash

    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: new_keyboard, one_time_keyboard: true)
  end

  def bot_choose(game)
    available = []

    game[:fields].map do |key,value|
      if value == "⬜️"
        available << key
      end
    end

    game[:fields][available[rand(available.length)]] = game[:bot_value]
  end

  def game_over?(game)
    game[:fields][:A1] == game[:fields][:A2] && game[:fields][:A1] == game[:fields][:A3] && game[:fields][:A3] != "⬜️" ||
        game[:fields][:B1] == game[:fields][:B2] && game[:fields][:B1] == game[:fields][:B3] && game[:fields][:B3] != "⬜️"  || # HORIZONTAL
        game[:fields][:C1] == game[:fields][:C2] && game[:fields][:C1] == game[:fields][:C3] && game[:fields][:C3] != "⬜️"  || # HORIZONTAL
        game[:fields][:A1] == game[:fields][:B1] && game[:fields][:A1] == game[:fields][:C1] && game[:fields][:C1] != "⬜️"  || # VERTICAL
        game[:fields][:A2] == game[:fields][:B2] && game[:fields][:A2] == game[:fields][:C2] && game[:fields][:C2] != "⬜️"  || # VERTICAL
        game[:fields][:A3] == game[:fields][:B3] && game[:fields][:A3] == game[:fields][:C3] && game[:fields][:C3] != "⬜️"  || # VERTICAL
        game[:fields][:A1] == game[:fields][:B2] && game[:fields][:A1] == game[:fields][:C3] && game[:fields][:C3] != "⬜️"  || # DIAGONAL
        game[:fields][:A3] == game[:fields][:B2] && game[:fields][:A3] == game[:fields][:C1] && game[:fields][:C1] != "⬜️"  # DIAGONAL
  end

  def send_message(message, text)
    bot.api.send_message(chat_id: message.chat.id, text:)
  end
end
