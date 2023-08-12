require_relative "credentials"
require "telegram/bot"

class TelegramBot
  attr_accessor :game, :user_value, :bot_value

  TOKEN = TELEGRAM_TOKEN.freeze

  def run
    @game = new_game
    @user_value = nil
    @bot_value = nil

    bot.listen do |message|
      new_message(message, @game, @user_value, @bot_value)
    end
  end

  def bot
    Telegram::Bot::Client.run(TOKEN) { |bot| return bot }
  end

  def new_message(message, game, user_value, bot_value)
    my_message = message.text.include?("⬜️") ? "⬜️" : message.text

    case my_message

    when "/new_game"
      @game = new_game

      bot.api.send_message(chat_id: message.chat.id, text: "Hi #{message.from.first_name}, let's play the game")
      bot.api.send_message(chat_id: message.chat.id, text: @game.values.join(''))

      select_fighter(message)
      
    when "I'll start: ✖️"
      @user_value = "✖️"
      @bot_value = "⚫️"

      bot.api.send_message(chat_id: message.chat.id, text: 'Select one:')      
      bot.api.send_message(chat_id: message.chat.id, text: @game.values.join(''),reply_markup: collect_keyboard(game))

    when "You first: ⚫️"
      @user_value = "⚫️"
      @bot_value = "✖️"

      bot_choose(game, bot_value)

      bot.api.send_message(chat_id: message.chat.id, text: 'Select one:')
      bot.api.send_message(chat_id: message.chat.id, text: @game.values.join(''),reply_markup: collect_keyboard(game))

    when "⬜️"
      my_value = message.text[-3..-2].to_sym
      @game[my_value] = user_value

      if game_over?(game)
        bot.api.send_message(chat_id: message.chat.id, text: @game.values.join(''))
        bot.api.send_message(chat_id: message.chat.id, text: 'Game Over!')
      else
        bot_choose(game, bot_value)

        if game_over?(game)
          bot.api.send_message(chat_id: message.chat.id, text: @game.values.join(''))
          bot.api.send_message(chat_id: message.chat.id, text: 'Game Over!')
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'Select one:')
          bot.api.send_message(chat_id: message.chat.id, text: @game.values.join(''),reply_markup: collect_keyboard(game))
        end
      end

    when '/stop'
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

      bot.api.send_message(chat_id: message.chat.id, text: 'Sorry to see you go :(', reply_markup: kb)
      @game = nil
    end
  end

  def new_game
    {
      'A1': "⬜️" ,  'A2': "⬜️" ,  'A3': "⬜️" , 'next_1': "\n",
      'B1': "⬜️" ,  'B2': "⬜️" ,  'B3': "⬜️" , 'next_2': "\n",
      'C1': "⬜️" ,  'C2': "⬜️" ,  'C3': "⬜️"
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

    @game.each do |key, value|
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

  def bot_choose(game, bot_value)
    available = []

    @game.map do |key,value|
      if value == "⬜️"
        available << key
      end
    end

    @game[available[rand(available.length)]] = bot_value
  end

  def game_over?(game)
    @game[:A1] == @game[:A2] && @game[:A1] == @game[:A3] && @game[:A3] != "⬜️" ||
        @game[:B1] == @game[:B2] && @game[:B1] == @game[:B3] && @game[:B3] != "⬜️"  || # HORIZONTAL
        @game[:C1] == @game[:C2] && @game[:C1] == @game[:C3] && @game[:C3] != "⬜️"  || # HORIZONTAL
        @game[:A1] == @game[:B1] && @game[:A1] == @game[:C1] && @game[:C1] != "⬜️"  || # VERTICAL
        @game[:A2] == @game[:B2] && @game[:A2] == @game[:C2] && @game[:C2] != "⬜️"  || # VERTICAL
        @game[:A3] == @game[:B3] && @game[:A3] == @game[:C3] && @game[:C3] != "⬜️"  || # VERTICAL
        @game[:A1] == @game[:B2] && @game[:A1] == @game[:C3] && @game[:C3] != "⬜️"  || # DIAGONAL
        @game[:A3] == @game[:B2] && @game[:A3] == @game[:C1] && @game[:C1] != "⬜️"  # DIAGONAL
  end
end
