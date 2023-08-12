require "telegram/bot"

token = "6521163894:AAH86A9HMU37My4dS-NA1LyKrwqBumerW1k"

Telegram::Bot::Client.run(token) do |bot|
  game = {
     a1: '⬜️' ,  a2: '⬜️' ,  a3: '⬜️' , next_1: "\n",
     b1: '⬜️' ,  b2: '⬜️' ,  b3: '⬜️' , next_2: "\n",
     c1: '⬜️' ,  c2: '⬜️' ,  c3: '⬜️'
  }

  bot.listen do |message|
    case message.text
    when "/start"
      bot.api.send_message(chat_id: message.chat.id, text: "Hi #{message.from.first_name}, let's play the game")

      # question = 'Choose your fighter?'
      # # See more: https://core.telegram.org/bots/api#replykeyboardmarkup
      # answers =
      #     Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      #       keyboard: [
      #         [{ text: '✖️' }, { text: '⚫️' }],
      #       ],
      #       one_time_keyboard: true
      #     )
      # bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
      bot.api.send_message(chat_id: message.chat.id, text: game.values.join(''))
    end
  end
end
