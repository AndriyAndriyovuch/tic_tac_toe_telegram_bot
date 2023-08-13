FROM ruby:3.1.2

WORKDIR /app

COPY . /app

RUN gem install bundler && \
    bundle install

CMD ["ruby", "run_bot.rb"]
