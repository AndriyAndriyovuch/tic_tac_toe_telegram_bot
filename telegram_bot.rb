require_relative "credentials"
require "telegram/bot"

WIN_COMBINATIONS = [
  [:A1, :A2, :A3], [:B1, :B2, :B3], [:C1, :C2, :C3], # Horizontal
  [:A1, :B1, :C1], [:A2, :B2, :C2], [:A3, :B3, :C3], # Vertical
  [:A1, :B2, :C3], [:A3, :B2, :C1] # Diagonal
].freeze

class TelegramBot
  attr_accessor :game, :user_value, :bot_value, :winner

  def run
    @game = new_game
    @user_value = nil
    @bot_value = nil

    bot.listen do |message|
      @message = message
      new_message(message, @game, @user_value, @bot_value)
    end
  end

  def bot
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) { |bot| return bot }
  end

  def new_message(message, game, user_value, bot_value)
    return if message.text.nil?

    my_message = message.text.include?("⬜️") ? "⬜️" : message.text

    case my_message

    when "/start"
      bot.api.send_message(chat_id: message.chat.id, text: "Hi #{message.from.first_name}, let's play the game")
      menu

    when "Start a new game"
      @game = new_game
      select_fighter(message)

    when "I'll start: ✖️"
      pin_sides(my_message)
      next_step

    when "You first: ⚫️"
      pin_sides(my_message)
      bot_choose(game, bot_value)
      next_step

    when "⬜️"
      my_value = message.text[-3..-2].to_sym
      @game[my_value] = user_value

      if game_over?(game)
        finish_game
      else
        if @game.values.include?('⬜️')
          bot_choose(game, bot_value)

          if game_over?(game)
            finish_game
          else
            @game.values.include?('⬜️') ? next_step : nobody_win
          end
        else
          nobody_win
        end
      end

    when "I'm out"
      kb = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[{ text: "/start" }]], one_time_keyboard: true)

      bot.api.send_message(chat_id: message.chat.id, text: 'Sorry to see you go :(', reply_markup: kb)
      @game = nil

    else
      @user_value.nil? ? menu : invalid_input
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

    @game[available[rand(available.length)]] = @bot_value
  end

  def game_over?(game)
    @winner = nil

    WIN_COMBINATIONS.each do |combo|
      values = combo.map { |position| game[position] }

      if values.uniq.length == 1 && values[0] != "⬜️"
        @winner = values[0]
        break
      end
    end

    if @winner.nil?
      false
    else
      @winner_message = (user_value == @winner) ? "You win, great 🏆" : "Bot wins, better luck next time 😔"
    end
  end

  def menu
    answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [
            [{ text: "Start a new game" }, { text: "I'm out" }],
          ],
          one_time_keyboard: true
        )

    bot.api.send_message(chat_id: @message.chat.id, text: 'What you want to do?', reply_markup: answers)

    @user_value = nil
    @bot_value = nil
  end

  def nobody_win
    bot.api.send_message(chat_id: @message.chat.id, text: @game.values.join(''))
    bot.api.send_message(chat_id: @message.chat.id, text: 'No one wins, great game')
    menu
  end

  def finish_game
    bot.api.send_message(chat_id: @message.chat.id, text: @game.values.join(''))
    bot.api.send_message(chat_id: @message.chat.id, text: @winner_message)
    menu
  end

  def next_step
    bot.api.send_message(chat_id: @message.chat.id, text: 'Select one:')
    bot.api.send_message(chat_id: @message.chat.id, text: @game.values.join(''),reply_markup: collect_keyboard(@game))
  end

  def pin_sides(side)
    @user_value = (side.include?("✖️")) ? "✖️" : "⚫️"
    @bot_value = (side.include?("✖️")) ? "⚫️" : "✖️"

    pinned = bot.api.send_message(chat_id: @message.chat.id, text: "Bot:#{@bot_value}\nYou:#{@user_value}")
    bot.api.pin_chat_message(chat_id: @message.chat.id, message_id: pinned['result']['message_id'])
  end

  def invalid_input
    bot.api.send_message(chat_id: @message.chat.id, text: "It's not correct")
    bot.api.send_message(chat_id: @message.chat.id, text: @game.values.join(''),reply_markup: collect_keyboard(game))
  end
end
